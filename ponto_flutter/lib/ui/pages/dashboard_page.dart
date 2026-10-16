import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/dashboard_repo.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _app = AppState.instance;
  DashboardInfo? _info;
  String _erro = '';
  Timer? _tmr;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _app.versaoDados.addListener(_carregar);
    _tmr = Timer.periodic(const Duration(seconds: 30), (_) => _carregar());
    _carregar();
  }

  @override
  void dispose() {
    _tmr?.cancel();
    _app.versaoDados.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!Db.instance.isConectado || _carregando) return;
    _carregando = true;
    try {
      final i = await DashboardRepo.carregar();
      if (mounted) setState(() { _info = i; _erro = ''; });
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    } finally {
      _carregando = false;
    }
  }

  String get _saudacao {
    final h = DateTime.now().hour;
    return h < 12 ? 'Bom dia' : (h < 18 ? 'Boa tarde' : 'Boa noite');
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    if (i == null) {
      return Center(
          child: _erro.isEmpty ? const CircularProgressIndicator() : Text(_erro, style: const TextStyle(color: Colors.red)));
    }
    final hamster = AppConfig.instance.modoHamsterDx;
    return ListView(children: [
      _banner(hamster),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 5 : (c.maxWidth > 760 ? 3 : 2);
        final w = (c.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final k in [
            KpiCard('Colaboradores ativos', '${i.colaboradoresAtivos}', Icons.groups_rounded, AppCores.azul,
                rodape: '${i.semHorario} sem jornada definida'),
            KpiCard('Presentes agora', '${i.presentes}', Icons.how_to_reg_rounded, AppCores.verde,
                rodape: '${i.compareceram} registraram ponto hoje'),
            KpiCard('Ausentes hoje', '${i.ausentes}', Icons.person_off_rounded, AppCores.vermelho,
                rodape: 'sem nenhuma batida no dia'),
            KpiCard('Marcações hoje', '${i.marcacoesHoje}', Icons.fingerprint_rounded, AppCores.roxo,
                rodape: '${minutosParaHora(i.minutosTrabalhadosHoje)} h trabalhadas'),
            KpiCard(hamster ? 'Digitais cadastradas' : 'Relógios ativos',
                '${hamster ? i.digitais : i.relogiosAtivos}', hamster ? Icons.touch_app_rounded : Icons.router_rounded,
                AppCores.laranja,
                rodape: hamster ? 'Leitor Hamster DX' : '${i.relogios.length} cadastrado(s)'),
          ])
            SizedBox(width: w, child: k),
        ]);
      }),
      const SizedBox(height: 16),
      _linha([
        (3, Painel('Marcações nos últimos 7 dias', Icons.bar_chart_rounded, _grafico7Dias(i))),
        (2, Painel('Presença de hoje', Icons.donut_large_rounded, _presencaResumo(i))),
      ]),
      const SizedBox(height: 16),
      _linha([
        (2, Painel('Quem registrou ponto hoje', Icons.badge_rounded, _listaPresenca(i), altura: 340)),
        (2, Painel('Últimas batidas', Icons.history_rounded, _ultimasBatidas(i), altura: 340)),
        (2, Painel('Alertas e pendências', Icons.notifications_active_rounded, _alertas(i, hamster), altura: 340)),
      ]),
      const SizedBox(height: 16),
      _linha([
        (3, Painel('Batidas por horário (hoje)', Icons.schedule_rounded, _graficoHoras(i))),
        if (!hamster) (2, Painel('Relógios de ponto', Icons.router_rounded, _relogios(i))),
      ]),
    ]);
  }

  Widget _linha(List<(int, Widget)> itens) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(children: [
            for (final it in itens) Padding(padding: const EdgeInsets.only(bottom: 16), child: it.$2),
          ]);
        }
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var k = 0; k < itens.length; k++) ...[
              if (k > 0) const SizedBox(width: 16),
              Expanded(flex: itens[k].$1, child: itens[k].$2),
            ],
          ]),
        );
      });

  Widget _banner(bool hamster) {
    final agora = DateTime.now();
    final data = DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(agora);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF06B6D4)]),
        boxShadow: [BoxShadow(color: AppCores.azul.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_saudacao! 👋',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${data[0].toUpperCase()}${data.substring(1)}  •  ${Db.instance.nomeBanco}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (_app.empregadorRodape.isNotEmpty)
              Text(_app.empregadorRodape, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (!hamster) ...[
            _bannerBtn('Coletar agora', Icons.download_rounded, () async {
              await _app.coletarAgora();
              _carregar();
            }),
            _bannerBtn(_app.autoColetaAtiva ? 'Parar coleta' : 'Coleta automática',
                _app.autoColetaAtiva ? Icons.pause_rounded : Icons.play_arrow_rounded, () {
              _app.autoColetaAtiva ? _app.pararAutoColeta() : _app.iniciarAutoColeta();
              setState(() {});
            }),
          ],
          _bannerBtn('Atualizar', Icons.refresh_rounded, _carregar),
        ]),
      ]),
    );
  }

  Widget _bannerBtn(String t, IconData i, VoidCallback f) => FilledButton.icon(
        style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .18),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: f,
        icon: Icon(i, size: 18),
        label: Text(t),
      );

  Widget _grafico7Dias(DashboardInfo i) {
    final dias = i.porDia.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maximo = dias.fold<int>(1, (m, e) => math.max(m, e.value));
    final semana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final hoje = soData(DateTime.now());
    return SizedBox(
      height: 210,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final d in dias)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${d.value}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: d.value / maximo),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Container(
                    height: math.max(4, 150 * v),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: d.key == hoje
                            ? [AppCores.azul, const Color(0xFF06B6D4)]
                            : [AppCores.azul.withValues(alpha: .35), AppCores.azul.withValues(alpha: .55)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(semana[d.key.weekday - 1],
                    style: TextStyle(fontSize: 12, fontWeight: d.key == hoje ? FontWeight.w700 : FontWeight.w400)),
                Text(DateFormat('dd/MM').format(d.key), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _graficoHoras(DashboardInfo i) {
    final maximo = i.porHora.fold<int>(1, math.max);
    return SizedBox(
      height: 130,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var h = 5; h <= 22; h++)
          Expanded(
            child: Tooltip(
              message: '${h.toString().padLeft(2, '0')}h: ${i.porHora[h]} batida(s)',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: math.max(3, 90 * i.porHora[h] / maximo),
                    decoration: BoxDecoration(
                        color: AppCores.roxo.withValues(alpha: i.porHora[h] == 0 ? .15 : .75),
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(height: 4),
                  Text('$h', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _presencaResumo(DashboardInfo i) {
    final taxa = i.taxaPresenca;
    return Row(children: [
      SizedBox(
        width: 150,
        height: 150,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: taxa),
              duration: const Duration(milliseconds: 800),
              builder: (_, v, _) => CircularProgressIndicator(
                  value: v, strokeWidth: 14, strokeCap: StrokeCap.round,
                  backgroundColor: AppCores.verde.withValues(alpha: .12), color: AppCores.verde),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(taxa * 100).round()}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const Text('presença', style: TextStyle(color: Colors.grey)),
          ]),
        ]),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _legenda(AppCores.verde, 'Trabalhando agora', i.presentes),
          _legenda(AppCores.azul, 'Já saíram', i.compareceram - i.presentes),
          _legenda(AppCores.vermelho, 'Sem registro', i.ausentes),
          const Divider(height: 20),
          _legenda(Colors.blueGrey, 'Total de colaboradores', i.colaboradoresAtivos),
        ]),
      ),
    ]);
  }

  Widget _legenda(Color c, String t, int v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(child: Text(t)),
          Text('$v', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _listaPresenca(DashboardInfo i) {
    if (i.presenca.isEmpty) return const Center(child: Text('Nenhum colaborador ativo.'));
    return ListView.separated(
      itemCount: i.presenca.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, k) {
        final p = i.presenca[k];
        final (cor, status) = p.presente
            ? (AppCores.verde, 'Trabalhando')
            : (p.batidas.isEmpty ? (AppCores.vermelho, 'Ausente') : (AppCores.azul, 'Saiu'));
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Avatar(p.nome, cor),
          title: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
              p.batidas.isEmpty ? (p.funcao.isEmpty ? 'Sem batidas hoje' : p.funcao) : p.batidas.map(fmtHora).join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: StatusChip(status, cor),
        );
      },
    );
  }

  Widget _ultimasBatidas(DashboardInfo i) {
    if (i.ultimas.isEmpty) return const Center(child: Text('Nenhuma batida registrada nos últimos 30 dias.'));
    return ListView.separated(
      itemCount: i.ultimas.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, k) {
        final m = i.ultimas[k];
        final dh = asDate(m['PMA_DATA_HORA']);
        final o = asStr(m['PMA_ORIGEM']);
        final (icone, cor) = o == 'M'
            ? (Icons.edit_note_rounded, AppCores.laranja)
            : (o == 'B' ? (Icons.fingerprint_rounded, AppCores.roxo) : (Icons.router_rounded, AppCores.azul));
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
              radius: 18, backgroundColor: cor.withValues(alpha: .12), child: Icon(icone, color: cor, size: 20)),
          title: Text(asStr(m['PESSOA_NOME']), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(o == 'M' ? 'Lançamento manual' : (o == 'B' ? 'Biometria' : asStr(m['RELOGIO_NOME']))),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtHora(dh), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(fmtData(dh), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        );
      },
    );
  }

  Widget _alertas(DashboardInfo i, bool hamster) {
    final itens = <(IconData, Color, String, String)>[
      if (i.ausentes > 0 && DateTime.now().weekday <= 5)
        (Icons.person_off_rounded, AppCores.vermelho, '${i.ausentes} colaborador(es) sem registro hoje', 'Confira faltas e atrasos'),
      if (i.impares7dias > 0)
        (Icons.warning_amber_rounded, AppCores.laranja, '${i.impares7dias} dia(s) com batida ímpar', 'Últimos 7 dias — corrija em Marcações'),
      if (!hamster && i.pendentesSincronizacao > 0)
        (Icons.sync_problem_rounded, AppCores.laranja, '${i.pendentesSincronizacao} colaborador(es) não enviados ao relógio', 'Use "Enviar Pendentes" em Colaboradores'),
      if (i.bancoVencido > 0)
        (Icons.savings_rounded, AppCores.vermelho, '${i.bancoVencido} colaborador(es) com banco de horas vencido',
            'Compense ou pague as horas (CLT art. 59 §5º)'),
      if (i.semHorario > 0)
        (Icons.schedule_rounded, AppCores.azul, '${i.semHorario} colaborador(es) sem jornada', 'Será usada a jornada padrão'),
      if (hamster && i.colaboradoresAtivos > i.digitais)
        (Icons.fingerprint_rounded, AppCores.roxo, '${i.colaboradoresAtivos - i.digitais} sem digital cadastrada', 'Cadastre em Colaboradores'),
      if (i.ajustesManuais7dias > 0)
        (Icons.edit_note_rounded, Colors.blueGrey, '${i.ajustesManuais7dias} ajuste(s) manual(is) na semana', 'Registrados com motivo (Portaria 671)'),
      if (!hamster && i.relogios.isEmpty)
        (Icons.router_rounded, AppCores.vermelho, 'Nenhum relógio cadastrado', 'Cadastre na aba Relógios'),
    ];
    if (itens.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, color: AppCores.verde, size: 48),
          SizedBox(height: 8),
          Text('Tudo em dia! Nenhuma pendência.'),
        ]),
      );
    }
    return ListView(children: [
      for (final a in itens)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: a.$2.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: a.$2, width: 4))),
          child: Row(children: [
            Icon(a.$1, color: a.$2),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(a.$4, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          ]),
        ),
    ]);
  }

  Widget _relogios(DashboardInfo i) {
    if (i.relogios.isEmpty) return const Text('Nenhum relógio cadastrado.');
    return Column(children: [
      for (final r in i.relogios)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.router_rounded,
              color: asStr(r['PRE_ATIVO']) == 'S' ? AppCores.verde : Colors.grey),
          title: Text(asStr(r['PRE_NOME'])),
          subtitle: Text('${asStr(r['PRE_IP'])}  •  última coleta: '
              '${asDate(r['PRE_ULTIMA_COLETA']) == null ? 'nunca' : fmtDataHora(asDate(r['PRE_ULTIMA_COLETA']))}'),
          trailing: StatusChip(asStr(r['PRE_ATIVO']) == 'S' ? 'Ativo' : 'Inativo',
              asStr(r['PRE_ATIVO']) == 'S' ? AppCores.verde : Colors.grey),
        ),
    ]);
  }
}
