import 'package:intl/intl.dart';

import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import 'calculo_service.dart';

class SaldoBanco {
  final int pessoaId;
  final String nome, jornada;
  int saldoMin = 0;
  int minutosVencidos = 0; // créditos não compensados além do prazo (devem ser pagos)
  String ultimaCompetencia = '';
  SaldoBanco(this.pessoaId, this.nome, this.jornada);
}

/// Banco de horas (CLT art. 59 §§ 2º, 5º e 6º): créditos e débitos por competência,
/// compensação na ordem dos lançamentos e controle do prazo de validade.
class BancoHorasService {
  static Future<List<SaldoBanco>> saldos() async {
    final db = Db.instance;
    final validade = AppConfig.instance.folha.bancoHorasValidadeMeses;
    final hoje = soData(DateTime.now());
    final limite = DateTime(hoje.year, hoje.month - validade, hoje.day);
    final lanc = await db.getBancoHoras();
    final porPessoa = <int, List<DbRow>>{};
    for (final l in lanc) {
      porPessoa.putIfAbsent(asInt(l['BH_PESSOA']), () => []).add(l);
    }
    final horarios = {for (final h in await db.getHorarios(apenasAtivos: false)) asInt(h['HOR_ID']): h};

    final res = <SaldoBanco>[];
    for (final c in await db.getColaboradores()) {
      final pid = asInt(c['PES_ID']);
      final h = horarios[asInt(c['COL_HORARIO']) > 0 ? asInt(c['COL_HORARIO']) : 1];
      final lista = porPessoa[pid] ?? const <DbRow>[];
      if (asStr(h?['HOR_BANCO_HORAS']) != 'S' && lista.isEmpty) continue;
      final s = SaldoBanco(pid, asStr(c['PES_RSOCIAL_NOME']), asStr(h?['HOR_DESCRICAO']));

      // Compensação FIFO: débitos consomem os créditos mais antigos
      final creditos = <List<dynamic>>[]; // [data, minutos restantes]
      var debitoPendente = 0;
      for (final l in lista) {
        final m = asInt(l['BH_MINUTOS']);
        s.saldoMin += m;
        if (asStr(l['BH_COMPETENCIA']).isNotEmpty) s.ultimaCompetencia = asStr(l['BH_COMPETENCIA']);
        if (m > 0) {
          var resto = m;
          if (debitoPendente > 0) {
            final usa = resto < debitoPendente ? resto : debitoPendente;
            resto -= usa;
            debitoPendente -= usa;
          }
          if (resto > 0) creditos.add([asDate(l['BH_DATA']) ?? hoje, resto]);
        } else if (m < 0) {
          var falta = -m;
          for (final cr in creditos) {
            if (falta == 0) break;
            final usa = (cr[1] as int) < falta ? cr[1] as int : falta;
            cr[1] = (cr[1] as int) - usa;
            falta -= usa;
          }
          debitoPendente += falta;
        }
      }
      for (final cr in creditos) {
        if ((cr[0] as DateTime).isBefore(limite)) s.minutosVencidos += cr[1] as int;
      }
      res.add(s);
    }
    res.sort((a, b) => a.nome.compareTo(b.nome));
    return res;
  }

  /// Lança no banco o crédito (extras 50%) e o débito (atrasos) apurados na competência
  /// para quem tem jornada com banco de horas. Refazer o fechamento substitui o anterior.
  static Future<int> fecharCompetencia(DateTime mes) async {
    final db = Db.instance;
    final ini = DateTime(mes.year, mes.month, 1), fim = DateTime(mes.year, mes.month + 1, 0);
    final comp = DateFormat('MM/yyyy').format(ini);
    var n = 0;
    for (final c in await db.getColaboradores()) {
      final pid = asInt(c['PES_ID']);
      final e = await PontoCalculoService.calcularEspelho(pid, ini, fim);
      if (!e.resumo.usaBancoHoras) continue;
      await db.estornarCompetencia(pid, comp);
      if (e.resumo.bancoCreditoMin > 0) {
        await db.lancarBancoHoras(pid, fim, e.resumo.bancoCreditoMin, 'C', 'Horas extras da competência $comp', comp);
      }
      if (e.resumo.bancoDebitoMin > 0) {
        await db.lancarBancoHoras(pid, fim, -e.resumo.bancoDebitoMin, 'D', 'Atrasos e saídas da competência $comp', comp);
      }
      n++;
    }
    return n;
  }
}
