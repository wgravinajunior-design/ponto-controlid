import '../core/util.dart';
import '../services/banco_horas_service.dart';
import 'database.dart';

class PresencaColab {
  final int pessoaId;
  final String nome;
  final String funcao;
  final List<DateTime> batidas;
  PresencaColab(this.pessoaId, this.nome, this.funcao, this.batidas);
  bool get presente => batidas.length.isOdd;
  DateTime? get primeira => batidas.isEmpty ? null : batidas.first;
  DateTime? get ultima => batidas.isEmpty ? null : batidas.last;
}

class DashboardInfo {
  int colaboradoresAtivos = 0, marcacoesHoje = 0, relogiosAtivos = 0, digitais = 0;
  int pendentesSincronizacao = 0, semHorario = 0, impares7dias = 0, ajustesManuais7dias = 0;
  int bancoVencido = 0; // colaboradores com horas do banco além do prazo de validade
  final presenca = <PresencaColab>[];
  final porDia = <DateTime, int>{}; // últimos 7 dias
  final porHora = List<int>.filled(24, 0); // distribuição das batidas de hoje
  final ultimas = <DbRow>[];
  final relogios = <DbRow>[];
  int minutosTrabalhadosHoje = 0;

  int get presentes => presenca.where((p) => p.presente).length;
  int get compareceram => presenca.where((p) => p.batidas.isNotEmpty).length;
  int get ausentes => presenca.where((p) => p.batidas.isEmpty).length;
  double get taxaPresenca => colaboradoresAtivos == 0 ? 0 : compareceram / colaboradoresAtivos;
}

/// Indicadores do painel inicial.
class DashboardRepo {
  static Future<DashboardInfo> carregar() async {
    final db = Db.instance;
    final info = DashboardInfo();
    final hoje = soData(DateTime.now());
    final ini7 = hoje.subtract(const Duration(days: 6));

    final colabs = await db.getColaboradores();
    info.colaboradoresAtivos = colabs.length;
    info.pendentesSincronizacao = colabs.where((c) => asStr(c['COL_SINCRONIZADO_RELOGIO']) != 'S').length;
    info.semHorario = colabs.where((c) => asInt(c['COL_HORARIO']) <= 0).length;
    info.digitais = colabs.where((c) => asStr(c['COL_BIOMETRIA_CADASTRADA']) == 'S').length;

    final rows = await db.query(
        'SELECT PMA_PESSOA, PMA_DATA_HORA, PMA_ORIGEM FROM TB_PONTO_MARCACAO '
        'WHERE PMA_DATA_HORA BETWEEN ? AND ? AND ${Db.validas} ORDER BY PMA_DATA_HORA',
        [ini7, fimDoDia(hoje)]);

    for (var i = 0; i < 7; i++) {
      info.porDia[ini7.add(Duration(days: i))] = 0;
    }
    final hojePorPessoa = <int, List<DateTime>>{};
    final porPessoaDia = <String, int>{};
    for (final r in rows) {
      final dh = asDate(r['PMA_DATA_HORA']);
      if (dh == null) continue;
      final dia = soData(dh);
      info.porDia[dia] = (info.porDia[dia] ?? 0) + 1;
      if (asStr(r['PMA_ORIGEM']) == 'M') info.ajustesManuais7dias++;
      final pid = asInt(r['PMA_PESSOA']);
      if (dia == hoje) {
        info.marcacoesHoje++;
        info.porHora[dh.hour]++;
        if (pid > 0) hojePorPessoa.putIfAbsent(pid, () => []).add(dh);
      } else if (pid > 0) {
        porPessoaDia['$pid-$dia'] = (porPessoaDia['$pid-$dia'] ?? 0) + 1;
      }
    }
    info.impares7dias = porPessoaDia.values.where((n) => n.isOdd).length;

    for (final c in colabs) {
      final pid = asInt(c['PES_ID']);
      final b = hojePorPessoa[pid] ?? <DateTime>[];
      info.presenca.add(PresencaColab(pid, asStr(c['PES_RSOCIAL_NOME']), asStr(c['COL_FUNCAO']), b));
      for (var i = 0; i + 1 < b.length; i += 2) {
        info.minutosTrabalhadosHoje += minutesBetween(b[i + 1], b[i]);
      }
    }
    info.presenca.sort((a, b) {
      if (a.presente != b.presente) return a.presente ? -1 : 1;
      if (a.batidas.isEmpty != b.batidas.isEmpty) return a.batidas.isEmpty ? 1 : -1;
      return a.nome.compareTo(b.nome);
    });

    final ult = await db.getMarcacoes(hoje.subtract(const Duration(days: 30)), hoje);
    info.ultimas.addAll(ult.take(12));

    try {
      info.bancoVencido = (await BancoHorasService.saldos()).where((s) => s.minutosVencidos > 0).length;
    } catch (_) {}
    final rel = await db.getRelogios();
    info.relogios.addAll(rel);
    info.relogiosAtivos = rel.where((r) => asStr(r['PRE_ATIVO']) == 'S').length;
    return info;
  }
}
