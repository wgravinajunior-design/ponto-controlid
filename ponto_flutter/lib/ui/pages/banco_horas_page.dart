import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/banco_horas_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class BancoHorasPage extends StatefulWidget {
  const BancoHorasPage({super.key});
  @override
  State<BancoHorasPage> createState() => _BancoHorasPageState();
}

class _BancoHorasPageState extends State<BancoHorasPage> {
  final _app = AppState.instance;
  List<SaldoBanco> _saldos = [];
  SaldoBanco? _sel;
  List<DbRow> _lancamentos = [];
  late DateTime _competencia;

  static const _tipos = {
    'C': 'Crédito apurado',
    'D': 'Débito apurado',
    'P': 'Pago em folha',
    'F': 'Folga compensada',
    'A': 'Ajuste',
  };

  @override
  void initState() {
    super.initState();
    final h = DateTime.now();
    _competencia = DateTime(h.year, h.month - 1, 1);
    _carregar();
  }

  Future<void> _carregar() async {
    final s = await BancoHorasService.saldos();
    if (!mounted) return;
    setState(() {
      _saldos = s;
      if (_sel != null) _sel = s.where((x) => x.pessoaId == _sel!.pessoaId).firstOrNull;
    });
    await _carregarLancamentos();
  }

  Future<void> _carregarLancamentos() async {
    final l = _sel == null ? <DbRow>[] : await Db.instance.getBancoHoras(pessoaId: _sel!.pessoaId);
    if (mounted) setState(() => _lancamentos = l.reversed.toList());
  }

  Future<void> _fechar() async {
    final comp = DateFormat('MM/yyyy').format(_competencia);
    if (!await confirmar(context,
        'Lançar no banco de horas o saldo apurado da competência $comp para todos os colaboradores com banco de horas?\n\n'
        'Se a competência já tiver sido fechada, o fechamento anterior é substituído.')) {
      return;
    }
    if (!mounted) return;
    final n = await comProgresso(context, () => BancoHorasService.fecharCompetencia(_competencia),
        texto: 'Fechando competência $comp...');
    _app.logTs('🏦 Banco de horas: competência $comp fechada para ${n ?? 0} colaborador(es).');
    _app.dadosAlterados();
    await _carregar();
  }

  Future<void> _lancar() async {
    final s = _sel;
    if (s == null) return mensagem(context, 'Selecione um colaborador.');
    var tipo = 'P';
    final horas = TextEditingController(), desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('Lançamento no banco de horas - ${s.nome}'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final t in ['P', 'F', 'A']) DropdownMenuItem(value: t, child: Text(_tipos[t]!)),
                ],
                onChanged: (v) => set(() => tipo = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: horas,
                  decoration: InputDecoration(
                      labelText: tipo == 'A' ? 'Horas (HH:MM, use - para débito)' : 'Horas (HH:MM)', hintText: '02:30')),
              const SizedBox(height: 12),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Lançar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final txt = horas.text.trim();
    final neg = txt.startsWith('-');
    var min = horaParaMinutos(txt.replaceAll('-', ''));
    if (min <= 0) {
      if (mounted) await mensagem(context, 'Informe as horas no formato HH:MM.');
      return;
    }
    // Pagamento e folga baixam o saldo; ajuste segue o sinal informado
    if (tipo != 'A' || neg) min = -min;
    await Db.instance.lancarBancoHoras(s.pessoaId, DateTime.now(), min, tipo,
        desc.text.trim().isEmpty ? _tipos[tipo]! : desc.text.trim());
    _app.logTs('🏦 Banco de horas de ${s.nome}: ${_tipos[tipo]} ${minutosParaHora(min, exibirSinal: true)}.');
    await _carregar();
  }

  Future<void> _excluirLancamento(DbRow l) async {
    if (!await confirmar(context, 'Excluir o lançamento "${asStr(l['BH_DESCRICAO'])}"?')) return;
    await Db.instance.excluirLancamentoBancoHoras(asInt(l['BH_ID']));
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final meses = [for (var i = 0; i < 18; i++) DateTime(DateTime.now().year, DateTime.now().month - i, 1)];
    final venc = AppConfig.instance.folha.bancoHorasValidadeMeses;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Banco de Horas', Icons.savings, acoes: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<DateTime>(
            initialValue: _competencia,
            decoration: const InputDecoration(labelText: 'Competência'),
            items: [for (final m in meses) DropdownMenuItem(value: m, child: Text(DateFormat('MM/yyyy').format(m)))],
            onChanged: (v) => setState(() => _competencia = v!),
          ),
        ),
        Btn('Fechar competência no banco', Icons.lock_clock, _fechar),
        Btn('Novo lançamento', Icons.add, _lancar, tonal: true),
        Btn('Atualizar', Icons.refresh, _carregar, tonal: true),
      ]),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: DataGrid<SaldoBanco>(
              itens: _saldos,
              selecionado: _sel,
              onSelect: (s) {
                setState(() => _sel = s);
                _carregarLancamentos();
              },
              corLinha: (s) => s.minutosVencidos > 0 ? Colors.red.withValues(alpha: .08) : null,
              colunas: [
                GridCol('Colaborador', 200, (s) => s.nome, flex: true),
                GridCol('Jornada', 160, (s) => s.jornada),
                GridCol('Saldo', 80, (s) => minutosParaHora(s.saldoMin, exibirSinal: true),
                    cor: (s) => s.saldoMin >= 0 ? AppCores.verde : AppCores.vermelho),
                GridCol('Vencendo ($venc meses)', 120, (s) => s.minutosVencidos > 0 ? minutosParaHora(s.minutosVencidos) : '',
                    cor: (_) => AppCores.vermelho),
                GridCol('Último fechamento', 110, (s) => s.ultimaCompetencia),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 420,
            child: Painel(
              _sel == null ? 'Lançamentos' : 'Lançamentos - ${_sel!.nome}',
              Icons.receipt_long_rounded,
              _sel == null
                  ? const Center(child: Text('Selecione um colaborador.'))
                  : ListView(children: [
                      for (final l in _lancamentos)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(asStr(l['BH_DESCRICAO'])),
                          subtitle: Text('${fmtData(asDate(l['BH_DATA']))}  •  ${_tipos[asStr(l['BH_TIPO'])] ?? ''}'
                              '${asStr(l['BH_COMPETENCIA']).isEmpty ? '' : '  •  ${asStr(l['BH_COMPETENCIA'])}'}'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(minutosParaHora(asInt(l['BH_MINUTOS']), exibirSinal: true),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: asInt(l['BH_MINUTOS']) >= 0 ? AppCores.verde : AppCores.vermelho)),
                            IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _excluirLancamento(l)),
                          ]),
                        ),
                    ]),
              altura: 600,
            ),
          ),
        ]),
      ),
    ]);
  }
}
