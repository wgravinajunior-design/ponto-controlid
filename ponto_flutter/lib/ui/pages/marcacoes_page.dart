import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/comprovante_service.dart';
import '../../services/relatorio_service.dart';
import '../app_state.dart';
import '../importar_afd_dialog.dart';
import '../theme.dart';
import '../widgets.dart';

class MarcacoesPage extends StatefulWidget {
  const MarcacoesPage({super.key});
  @override
  State<MarcacoesPage> createState() => _MarcacoesPageState();
}

class _MarcacoesPageState extends State<MarcacoesPage> {
  final _app = AppState.instance;
  DateTime _ini = DateTime.now(), _fim = DateTime.now();
  int _relogioId = 0, _pessoaId = 0;
  List<DbRow> _relogios = [], _colabs = [], _itens = [];
  DbRow? _sel;
  bool _verDesconsideradas = false;

  @override
  void initState() {
    super.initState();
    _ini = DateTime(_fim.year, _fim.month, 1);
    _app.versaoDados.addListener(_filtrar);
    _carregarFiltros();
  }

  @override
  void dispose() {
    _app.versaoDados.removeListener(_filtrar);
    super.dispose();
  }

  Future<void> _carregarFiltros() async {
    if (!Db.instance.isConectado) return;
    final rel = await Db.instance.getRelogios();
    final col = await Db.instance.getColaboradores(apenasAtivos: false);
    setState(() {
      _relogios = rel;
      _colabs = col;
    });
    await _filtrar();
  }

  Future<void> _filtrar() async {
    if (!Db.instance.isConectado) return;
    final itens = await Db.instance.getMarcacoes(_ini, _fim,
        relogioId: _relogioId, pessoaId: _pessoaId, incluirDesconsideradas: _verDesconsideradas);
    if (mounted) {
      setState(() {
        _itens = itens;
        _sel = null;
      });
    }
  }

  Future<void> _exportar() async {
    if (_itens.isEmpty) return mensagem(context, 'Não há marcações para exportar no período filtrado.');
    final f = DateFormat('yyyyMMdd');
    final sb = StringBuffer('DATA_HORA;PESSOA_ID;COLABORADOR;PIS;CPF;RELOGIO;NSR;ORIGEM\r\n');
    for (final m in _itens) {
      sb.write('${fmtDataHora(asDate(m['PMA_DATA_HORA']))};${asInt(m['PMA_PESSOA'])};${asStr(m['PESSOA_NOME'])};'
          '${asStr(m['PMA_PIS'])};${asStr(m['PMA_CPF'])};${asStr(m['RELOGIO_NOME'])};${asStr(m['PMA_NSR'])};'
          '${asStr(m['PMA_ORIGEM'])}\r\n');
    }
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Exportar marcações',
      fileName: 'Marcacoes_Ponto_${f.format(_ini)}_a_${f.format(_fim)}.txt',
      bytes: Uint8List.fromList(utf8.encode(sb.toString())),
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
    );
    if (uri == null) return;
    final caminho = uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
    _app.logTs('📄 Arquivo de registros exportado com sucesso! ${_itens.length} marcação(ões) salva(s) em: $caminho');
    if (mounted) await mensagem(context, 'Arquivo exportado com sucesso! Total de ${_itens.length} marcações.');
  }

  bool get _selDesconsiderada => _sel != null && asStr(_sel!['PMA_DESCONSIDERADA']) == 'S';

  /// Portaria 671: a batida nunca é apagada; fica desconsiderada com o motivo.
  Future<void> _desconsiderar() async {
    final m = _sel;
    if (m == null) return mensagem(context, 'Selecione uma marcação na grade.');
    if (_selDesconsiderada) return _restaurar();
    final id = asInt(m['PMA_ID']);
    final dh = fmtDataHora(asDate(m['PMA_DATA_HORA']));
    final v = await inputQuery(context, 'Desconsiderar batida #$id - ${asStr(m['PESSOA_NOME'])} ($dh)',
        ['Motivo (obrigatório pela Portaria 671 - a batida original fica guardada):'], ['Batida em duplicidade']);
    if (v == null || !mounted) return;
    if (v[0].trim().length < 5) return mensagem(context, 'Informe o motivo com pelo menos 5 caracteres.');
    if (await Db.instance.desconsiderarMarcacao(id, v[0])) {
      _app.logTs('🚫 Batida #$id (${asStr(m['PESSOA_NOME'])} - $dh) desconsiderada. Motivo: ${v[0].trim()}');
      _app.dadosAlterados();
    } else if (mounted) {
      await mensagem(context, 'Não foi possível desconsiderar a marcação selecionada.');
    }
  }

  Future<void> _restaurar() async {
    final m = _sel!;
    final id = asInt(m['PMA_ID']);
    if (!await confirmar(context, 'Voltar a considerar a batida #$id de ${asStr(m['PESSOA_NOME'])}?')) return;
    await Db.instance.restaurarMarcacao(id);
    _app.logTs('↩️ Batida #$id voltou a ser considerada.');
    _app.dadosAlterados();
  }

  /// Valida data, hora e tipo digitados nos diálogos.
  Future<({DateTime dataHora, String tipo})?> _validar(String data, String hora, String tipo) async {
    final d = parseData(data);
    if (d == null) {
      await mensagem(context, 'Data informada é inválida. Utilize o formato DD/MM/AAAA.');
      return null;
    }
    final h = parseHora(hora);
    if (h == null) {
      if (mounted) await mensagem(context, 'Hora informada é inválida. Utilize o formato HH:MM:SS.');
      return null;
    }
    final t = tipo.trim().toUpperCase();
    if (t != 'E' && t != 'S') {
      if (mounted) await mensagem(context, 'Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
      return null;
    }
    return (dataHora: d.add(h), tipo: t);
  }

  Future<void> _editar() async {
    final m = _sel;
    if (m == null) return mensagem(context, 'Selecione uma marcação de ponto na lista para corrigir.');
    final id = asInt(m['PMA_ID']);
    final dh = asDate(m['PMA_DATA_HORA']);
    var tipo = asStr(m['PMA_TIPO_BATIDA']).trim().toUpperCase();
    if (tipo != 'E' && tipo != 'S') tipo = 'E';
    final v = await inputQuery(context, 'Corrigir Batida de Ponto - [${asStr(m['PESSOA_NOME'])}] (ID $id)', [
      'Data da Batida (DD/MM/AAAA):',
      'Hora da Batida (HH:MM:SS):',
      'Tipo de Batida (E = Entrada, S = Saída):',
      'Motivo da Correção (Portaria 671 MTE):'
    ], [
      fmtData(dh),
      fmtHoraSeg(dh),
      tipo,
      'Esquecimento de registro'
    ]);
    if (v == null || !mounted) return;
    final ok = await _validar(v[0], v[1], v[2]);
    if (ok == null || !mounted) return;
    if (v[3].trim().length < 5) return mensagem(context, 'Informe o motivo da correção (mínimo 5 caracteres).');
    if (_selDesconsiderada) return mensagem(context, 'Esta batida já está desconsiderada. Inclua uma nova batida.');
    final novo = await Db.instance.corrigirMarcacao(id, ok.dataHora, ok.tipo, v[3]);
    if (novo > 0) {
      _app.logTs('✏️ Batida #$id desconsiderada e substituída pela #$novo em ${fmtDataHora(ok.dataHora)} (${ok.tipo}) - Colaborador: '
          '${asStr(m['PESSOA_NOME'])} [Motivo: ${v[3].trim()}]');
      _app.dadosAlterados();
      if (mounted) await mensagem(context, 'Correção registrada! A batida original foi preservada como desconsiderada (Portaria 671).');
    } else if (mounted) {
      await mensagem(context, 'Não foi possível atualizar a marcação de ponto no banco de dados.');
    }
  }

  Future<void> _nova() async {
    final agora = DateTime.now();
    final v = await inputQuery(context, 'Incluir Nova Batida Manual de Ponto', [
      'CPF ou Código do Colaborador:',
      'Data da Batida (DD/MM/AAAA):',
      'Hora da Batida (HH:MM:SS):',
      'Tipo de Batida (E = Entrada, S = Saída):',
      'Motivo da Inclusão (Portaria 671 MTE):'
    ], [
      _pessoaId > 0 ? '$_pessoaId' : '',
      fmtData(agora),
      fmtHoraSeg(agora),
      'E',
      'Esquecimento de registro'
    ]);
    if (v == null || !mounted) return;
    if (v[0].trim().isEmpty) return mensagem(context, 'Informe o CPF ou código do colaborador.');
    final ok = await _validar(v[1], v[2], v[3]);
    if (ok == null) return;
    final p = await Db.instance.buscarPessoaPorCodigoOuCpf(v[0].trim());
    if (!mounted) return;
    if (p == null) return mensagem(context, 'Colaborador não localizado com o identificador informado: ${v[0]}');
    final novo = await Db.instance.inserirMarcacaoManual(asInt(p['PES_ID']), _relogioId, ok.dataHora, ok.tipo, v[4]);
    if (novo > 0) {
      _app.logTs('➕ Batida manual ID $novo incluída para ${asStr(p['PES_RSOCIAL_NOME'])} em '
          '${fmtDataHora(ok.dataHora)} (${ok.tipo}) [Motivo: ${v[4].trim()}]');
      _app.dadosAlterados();
      if (mounted) await mensagem(context, 'Batida incluída com sucesso!');
    } else if (mounted) {
      await mensagem(context, 'Erro ao registrar batida no banco de dados.');
    }
  }

  Future<void> _relatorioES() async {
    final emp = await Db.instance.getEmpresaPrincipal();
    final html = await RelatorioPonto.gerarEntradasSaidasHtml(_ini, _fim, _pessoaId, emp?.razao ?? '', emp?.cnpj ?? '');
    final arq = await abrirHtml('Relatorio_Entradas_Saidas.html', html);
    _app.logTs('🖨️ Relatório de Entradas e Saídas gerado: $arq');
  }

  Widget _data(String rotulo, DateTime valor, ValueChanged<DateTime> onChanged) => OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text('$rotulo ${fmtData(valor)}'),
        onPressed: () async {
          final d = await escolherData(context, valor);
          if (d != null) onChanged(d);
        },
      );

  @override
  Widget build(BuildContext context) {
    final hamster = AppConfig.instance.modoHamsterDx;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Marcações de Ponto', Icons.fact_check_outlined, acoes: [
        _data('De', _ini, (d) => setState(() => _ini = d)),
        _data('Até', _fim, (d) => setState(() => _fim = d)),
        if (!hamster)
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<int>(
              initialValue: _relogioId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Relógio', isDense: true),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Todos os Relógios')),
                for (final r in _relogios) DropdownMenuItem(value: asInt(r['PRE_ID']), child: Text(asStr(r['PRE_NOME'])))
              ],
              onChanged: (v) => setState(() => _relogioId = v ?? 0),
            ),
          ),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<int>(
            initialValue: _pessoaId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Colaborador', isDense: true),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Todos os Colaboradores')),
              for (final c in _colabs)
                DropdownMenuItem(value: asInt(c['PES_ID']), child: Text(asStr(c['PES_RSOCIAL_NOME'])))
            ],
            onChanged: (v) => setState(() => _pessoaId = v ?? 0),
          ),
        ),
        Btn('Filtrar', Icons.filter_alt, _filtrar),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Btn('Nova Batida', Icons.add_alarm, _nova, tonal: true),
        Btn('Corrigir', Icons.edit, _editar, tonal: true),
        Btn(_selDesconsiderada ? 'Restaurar' : 'Desconsiderar', _selDesconsiderada ? Icons.restore : Icons.block,
            _desconsiderar, cor: _selDesconsiderada ? Colors.teal : Colors.red.shade700),
        FilterChip(
          label: const Text('Mostrar desconsideradas'),
          selected: _verDesconsideradas,
          onSelected: (v) {
            setState(() => _verDesconsideradas = v);
            _filtrar();
          },
        ),
        Btn('Exportar TXT', Icons.file_download, _exportar, tonal: true),
        Btn('Relatório E/S', Icons.print, _relatorioES, cor: AppCores.roxo),
        Btn('Importar AFD (pendrive)', Icons.usb_rounded, () async {
          if (await importarAfdDoPendrive(context)) _filtrar();
        }, cor: Colors.teal),
        Btn('Comprovante', Icons.receipt_long, () async {
          final m = _sel;
          if (m == null) return mensagem(context, 'Selecione uma marcação.');
          final txt = await ComprovanteService.gerar(asInt(m['PMA_ID']));
          if (txt != null) await launchUrl(Uri.file(txt.replaceAll('.txt', '.html')));
        }, tonal: true),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: DataGrid<DbRow>(
          itens: _itens,
          selecionado: _sel,
          onSelect: (r) => setState(() => _sel = r),
          onDoubleTap: (r) {
            setState(() => _sel = r);
            _editar();
          },
          corLinha: (r) => asStr(r['PMA_DESCONSIDERADA']) == 'S'
              ? Colors.grey.withValues(alpha: .18)
              : (asStr(r['PMA_ORIGEM']) == 'M' ? Colors.amber.withValues(alpha: .15) : null),
          colunas: [
            GridCol('ID', 60, (r) => '${r['PMA_ID']}'),
            GridCol('Situação', 110, (r) => asStr(r['PMA_DESCONSIDERADA']) == 'S' ? '🚫 Desconsiderada' : '✔ Válida',
                cor: (r) => asStr(r['PMA_DESCONSIDERADA']) == 'S' ? Colors.grey : Colors.green.shade700),
            GridCol('Data/Hora', 140, (r) => fmtDataHora(asDate(r['PMA_DATA_HORA']))),
            GridCol('Colaborador', 220, (r) => asStr(r['PESSOA_NOME']), flex: true),
            GridCol('Tipo', 75, (r) => nomeTipoBatida(asStr(r['PMA_TIPO_BATIDA'])),
                cor: (r) => asStr(r['PMA_TIPO_BATIDA']) == 'E' ? Colors.green.shade700 : (asStr(r['PMA_TIPO_BATIDA']) == 'S' ? AppCores.roxo : null)),
            GridCol('Relógio', 130, (r) => asStr(r['RELOGIO_NOME'])),
            GridCol('NSR', 80, (r) => asStr(r['PMA_NSR'])),
            GridCol('Identificação', 120, (r) => asStr(r['PMA_TIPO_IDENTIFICACAO'])),
            GridCol('Origem', 70, (r) {
              final o = asStr(r['PMA_ORIGEM']);
              return o == 'M' ? 'Manual' : (o == 'B' ? 'Biometria' : 'Coleta');
            }),
            GridCol('Motivo', 220, (r) => asStr(r['PMA_DESCONSIDERADA']) == 'S'
                ? asStr(r['PMA_MOTIVO_DESCONSIDERACAO'])
                : asStr(r['PMA_MOTIVO_AJUSTE'])),
          ],
        ),
      ),
    ]);
  }
}
