import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../services/contabilidade_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class ContabilidadePage extends StatefulWidget {
  const ContabilidadePage({super.key});
  @override
  State<ContabilidadePage> createState() => _ContabilidadePageState();
}

class _ContabilidadePageState extends State<ContabilidadePage> {
  final _app = AppState.instance;
  final _cfg = AppConfig.instance.folha;
  late DateTime _competencia; // primeiro dia do mês
  DateTime? _ini, _fim; // período personalizado
  bool _aej = true, _afd = true, _folha = true, _espelhos = true;
  bool _gerando = false;
  String _progresso = '';
  ResultadoContabil? _resultado;

  late final _rNormais = TextEditingController(text: _cfg.rubricaHorasNormais);
  late final _r50 = TextEditingController(text: _cfg.rubricaExtras50);
  late final _r100 = TextEditingController(text: _cfg.rubricaExtras100);
  late final _rNot = TextEditingController(text: _cfg.rubricaNoturno);
  late final _rFaltas = TextEditingController(text: _cfg.rubricaFaltas);
  late final _rAtrasos = TextEditingController(text: _cfg.rubricaAtrasos);
  late final _rDsr = TextEditingController(text: _cfg.rubricaDsr);
  late final _rFaixa2 = TextEditingController(text: _cfg.rubricaExtrasFaixa2);
  late final _faixa1 = TextEditingController(text: minutosParaHora(_cfg.extraFaixa1Min));
  late final _pct1 = TextEditingController(text: '${_cfg.pctFaixa1}');
  late final _pct2 = TextEditingController(text: '${_cfg.pctFaixa2}');
  late final _pctDom = TextEditingController(text: '${_cfg.pctDomingoFeriado}');
  late final _rIntervalo = TextEditingController(text: _cfg.rubricaIntervalo);
  late final _rInterjornada = TextEditingController(text: _cfg.rubricaInterjornada);
  late final _validadeBh = TextEditingController(text: '${_cfg.bancoHorasValidadeMeses}');
  late final _certificado = TextEditingController(text: _cfg.certificadoA1);
  late final _certSenha = TextEditingController(text: _cfg.certificadoSenha);
  late final _devCnpj = TextEditingController(text: _cfg.desenvolvedorCnpj);
  late final _devNome = TextEditingController(text: _cfg.desenvolvedorNome);
  late final _devEmail = TextEditingController(text: _cfg.desenvolvedorEmail);
  late String _formato = _cfg.formatoHoras;
  late bool _reduzida = _cfg.noturnaReduzida;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now();
    // Padrão: mês anterior (fechamento da folha)
    _competencia = DateTime(h.year, h.month - 1, 1);
  }

  DateTime get _periodoIni => _ini ?? _competencia;
  DateTime get _periodoFim => _fim ?? DateTime(_competencia.year, _competencia.month + 1, 0);

  void _salvarRubricas() {
    _cfg
      ..rubricaHorasNormais = _rNormais.text.trim()
      ..rubricaExtras50 = _r50.text.trim()
      ..rubricaExtras100 = _r100.text.trim()
      ..rubricaNoturno = _rNot.text.trim()
      ..rubricaFaltas = _rFaltas.text.trim()
      ..rubricaAtrasos = _rAtrasos.text.trim()
      ..rubricaDsr = _rDsr.text.trim()
      ..rubricaExtrasFaixa2 = _rFaixa2.text.trim()
      ..extraFaixa1Min = horaParaMinutos(_faixa1.text) > 0 ? horaParaMinutos(_faixa1.text) : 120
      ..pctFaixa1 = int.tryParse(_pct1.text.trim()) ?? 50
      ..pctFaixa2 = int.tryParse(_pct2.text.trim()) ?? 50
      ..pctDomingoFeriado = int.tryParse(_pctDom.text.trim()) ?? 100
      ..rubricaIntervalo = _rIntervalo.text.trim()
      ..rubricaInterjornada = _rInterjornada.text.trim()
      ..bancoHorasValidadeMeses = (int.tryParse(_validadeBh.text.trim()) ?? 6).clamp(1, 12)
      ..certificadoA1 = _certificado.text.trim()
      ..certificadoSenha = _certSenha.text
      ..formatoHoras = _formato
      ..noturnaReduzida = _reduzida
      ..desenvolvedorCnpj = _devCnpj.text.trim()
      ..desenvolvedorNome = _devNome.text.trim()
      ..desenvolvedorEmail = _devEmail.text.trim();
    AppConfig.instance.save();
  }

  Future<void> _gerar() async {
    if (!_aej && !_afd && !_folha && !_espelhos) return mensagem(context, 'Selecione ao menos um arquivo para gerar.');
    _salvarRubricas();
    setState(() {
      _gerando = true;
      _resultado = null;
      _progresso = 'Iniciando...';
    });
    try {
      final r = await ContabilidadeService.gerar(
        inicio: _periodoIni,
        fim: _periodoFim,
        aej: _aej,
        afd: _afd,
        folha: _folha,
        espelhos: _espelhos,
        onProgresso: (m) {
          if (mounted) setState(() => _progresso = m);
        },
      );
      _app.logTs('📁 Arquivos da contabilidade gerados (${fmtData(_periodoIni)} a ${fmtData(_periodoFim)}): ${r.pasta}');
      for (final a in r.avisos) {
        _app.logTs('⚠️ $a', true);
      }
      if (mounted) setState(() => _resultado = r);
    } catch (e) {
      _app.logTs('❌ Falha ao gerar arquivos da contabilidade: $e', true);
      if (mounted) await mensagem(context, 'Falha ao gerar os arquivos: $e');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  void _abrirPasta(String caminho, {bool selecionar = false}) =>
      Process.start('explorer.exe', [if (selecionar) '/select,$caminho' else caminho]);

  Widget _opcao(String titulo, String sub, IconData icone, bool valor, ValueChanged<bool> f) => Card(
        child: CheckboxListTile(
          value: valor,
          onChanged: (v) => setState(() => f(v!)),
          secondary: Icon(icone, color: AppCores.azul),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final meses = [for (var i = 0; i < 18; i++) DateTime(DateTime.now().year, DateTime.now().month - i, 1)];
    final fmtMes = DateFormat("MMMM 'de' y", 'pt_BR');
    return ListView(children: [
      Secao('Período', [
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<DateTime>(
              initialValue: _competencia,
              decoration: const InputDecoration(labelText: 'Competência (mês da folha)'),
              items: [
                for (final m in meses)
                  DropdownMenuItem(value: m, child: Text(toBeginningOfSentenceCase(fmtMes.format(m)) ?? '')),
              ],
              onChanged: (v) => setState(() {
                _competencia = v!;
                _ini = _fim = null;
              }),
            ),
          ),
          OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('De ${fmtData(_periodoIni)}'),
              onPressed: () async {
                final d = await escolherData(context, _periodoIni);
                if (d != null) setState(() => _ini = d);
              }),
          OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('Até ${fmtData(_periodoFim)}'),
              onPressed: () async {
                final d = await escolherData(context, _periodoFim);
                if (d != null) setState(() => _fim = d);
              }),
        ]),
      ]),
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth > 900 ? (c.maxWidth - 12) / 2 : c.maxWidth;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
              width: w,
              child: _opcao('AEJ - Arquivo Eletrônico de Jornada', 'Portaria 671/2021: vínculos, jornadas, marcações e ausências',
                  Icons.gavel_rounded, _aej, (v) => _aej = v)),
          SizedBox(
              width: w,
              child: _opcao('AFD dos relógios', 'Arquivo Fonte de Dados original, exportado de cada REP Control iD',
                  Icons.router_rounded, _afd && !AppConfig.instance.modoHamsterDx, (v) => _afd = v)),
          SizedBox(
              width: w,
              child: _opcao('Folha de pagamento', 'Eventos por rubrica (importação) + resumo de horas em planilha',
                  Icons.payments_rounded, _folha, (v) => _folha = v)),
          SizedBox(
              width: w,
              child: _opcao('Espelhos e cartão de ponto', 'Espelho de todos os colaboradores e relatório de entradas/saídas',
                  Icons.description_rounded, _espelhos, (v) => _espelhos = v)),
        ]);
      }),
      const SizedBox(height: 12),
      Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: const Icon(Icons.tune_rounded, color: AppCores.azul),
          title: const Text('Códigos das rubricas e formato do arquivo da folha',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Use os mesmos códigos de evento do sistema de folha da contabilidade',
              style: TextStyle(fontSize: 12)),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            _subtitulo(Icons.payments_rounded, 'Rubricas (códigos de evento)'),
            LayoutBuilder(builder: (context, c) {
              final colunas = c.maxWidth > 1000 ? 6 : (c.maxWidth > 640 ? 3 : 2);
              final w = (c.maxWidth - (colunas - 1) * 12) / colunas;
              return Wrap(spacing: 12, runSpacing: 16, children: [
                Campo('Horas normais', _rNormais, largura: w),
                Campo('Extras 50%', _r50, largura: w),
                Campo('Extras 100%', _r100, largura: w),
                Campo('Adicional noturno', _rNot, largura: w),
                Campo('Faltas (dias)', _rFaltas, largura: w),
                Campo('Atrasos', _rAtrasos, largura: w),
                Campo('DSR descontado (dias)', _rDsr, largura: w),
                Campo('Intervalo suprimido', _rIntervalo, largura: w),
                Campo('Interjornada', _rInterjornada, largura: w),
              ]);
            }),
            const SizedBox(height: 24),
            _subtitulo(Icons.percent_rounded, 'Percentuais de hora extra (conforme convenção coletiva)'),
            Wrap(spacing: 12, runSpacing: 16, children: [
              Campo('% até a faixa', _pct1, largura: 130),
              Campo('Faixa (horas por dia)', _faixa1, largura: 160, dica: '02:00'),
              Campo('% acima da faixa', _pct2, largura: 150),
              Campo('Rubrica acima da faixa', _rFaixa2, largura: 180),
              Campo('% domingo e feriado', _pctDom, largura: 170),
            ]),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Com percentuais iguais não há divisão. Ex.: 50% nas 2 primeiras horas e 70% nas demais.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
            const SizedBox(height: 24),
            _subtitulo(Icons.schedule_rounded, 'Formato das horas'),
            Wrap(spacing: 24, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'DECIMAL', label: Text('Horas decimais (8,50)')),
                  ButtonSegment(value: 'HHMM', label: Text('Horas e minutos (08:30)')),
                ],
                selected: {_formato},
                onSelectionChanged: (s) => setState(() => _formato = s.first),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _reduzida = !_reduzida),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Checkbox(value: _reduzida, onChanged: (v) => setState(() => _reduzida = v!)),
                  const Text('Hora noturna reduzida (52m30s)'),
                  const SizedBox(width: 8),
                ]),
              ),
            ]),
            const SizedBox(height: 24),
            _subtitulo(Icons.code_rounded, 'Desenvolvedor do programa de ponto (registro 08 do AEJ)'),
            LayoutBuilder(builder: (context, c) {
              final colunas = c.maxWidth > 760 ? 3 : 1;
              final w = (c.maxWidth - (colunas - 1) * 12) / colunas;
              return Wrap(spacing: 12, runSpacing: 16, children: [
                Campo('CNPJ/CPF do desenvolvedor', _devCnpj, largura: w),
                Campo('Razão social / nome', _devNome, largura: w),
                Campo('E-mail', _devEmail, largura: w),
              ]);
            }),
            const SizedBox(height: 24),
            _subtitulo(Icons.verified_user_rounded, 'Banco de horas e assinatura eletrônica'),
            Wrap(spacing: 12, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Campo('Validade do banco (meses)', _validadeBh, largura: 200),
              Campo('Certificado A1 (.pfx) para assinar AEJ e AFD', _certificado, largura: 420),
              IconButton(
                  tooltip: 'Escolher certificado',
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pfx', 'p12']);
                    if (r.isNotEmpty && r.first.path != null) setState(() => _certificado.text = r.first.path!);
                  }),
              Campo('Senha do certificado', _certSenha, largura: 200, senha: true),
            ]),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                  'Com o certificado informado, cada AEJ e AFD recebe a assinatura em arquivo .p7s (CAdES). '
                  'Banco de horas individual: até 6 meses (CLT art. 59 §5º); por acordo coletivo: até 12.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20)),
          onPressed: _gerando ? null : _gerar,
          icon: _gerando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.folder_zip_rounded),
          label: Text(_gerando ? 'Gerando...' : 'Gerar arquivos para a contabilidade'),
        ),
        const SizedBox(width: 16),
        if (_gerando) Expanded(child: Text(_progresso, style: const TextStyle(color: Color(0xFF64748B)))),
      ]),
      if (_resultado != null) ...[const SizedBox(height: 16), _resultadoCard(_resultado!)],
    ]);
  }

  Widget _subtitulo(IconData icone, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Icon(icone, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        ]),
      );

  Widget _resultadoCard(ResultadoContabil r) => Painel(
        'Arquivos gerados',
        Icons.task_alt_rounded,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final a in r.arquivos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_rounded, color: AppCores.azul),
              title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.descricao}  •  ${a.registros} registro(s)'),
              trailing: IconButton(
                  tooltip: 'Mostrar na pasta',
                  icon: const Icon(Icons.folder_open_rounded),
                  onPressed: () => _abrirPasta(a.caminho, selecionar: true)),
            ),
          for (final a in r.avisos)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppCores.laranja.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: AppCores.laranja, width: 4))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppCores.laranja),
                const SizedBox(width: 8),
                Expanded(child: Text(a)),
              ]),
            ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Btn('Abrir pasta', Icons.folder_open_rounded, () => _abrirPasta(r.pasta)),
            if (r.zip != null)
              Btn('Mostrar pacote .zip para enviar', Icons.folder_zip_rounded, () => _abrirPasta(r.zip!, selecionar: true),
                  tonal: true),
          ]),
          const SizedBox(height: 6),
          Text(r.zip ?? r.pasta, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      );
}
