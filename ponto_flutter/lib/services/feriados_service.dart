import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/util.dart';
import '../data/database.dart';

class ResultadoFeriados {
  int nacionais = 0, estaduais = 0, municipais = 0;
  final avisos = <String>[];
  int get total => nacionais + estaduais + municipais;
}

class MunicipioIbge {
  final int codigo;
  final String nome, uf;
  MunicipioIbge(this.codigo, this.nome, this.uf);
}

class DadosCnpj {
  final String razao, uf, municipio, endereco;
  final int codIbge;
  DadosCnpj(this.razao, this.uf, this.municipio, this.codIbge, this.endereco);
}

/// Feriados nacionais, estaduais e municipais por ano, conforme a UF e o município da empresa.
///
/// Fonte: base aberta "feriados-brasil" (licença MIT) - github.com/joaopbini/feriados-brasil.
/// Os municipais têm nome genérico e vêm de cadastro colaborativo: confira o calendário oficial
/// do seu município e ajuste manualmente se necessário.
class FeriadosService {
  static const _base = 'https://raw.githubusercontent.com/joaopbini/feriados-brasil/master/dados';
  static const _ufs = {
    'AC': 12, 'AL': 27, 'AP': 16, 'AM': 13, 'BA': 29, 'CE': 23, 'DF': 53, 'ES': 32, 'GO': 52, 'MA': 21, 'MT': 51,
    'MS': 50, 'MG': 31, 'PA': 15, 'PB': 25, 'PR': 41, 'PE': 26, 'PI': 22, 'RJ': 33, 'RN': 24, 'RS': 43, 'RO': 11,
    'RR': 14, 'SC': 42, 'SP': 35, 'SE': 28, 'TO': 17,
  };
  static List<String> get listaUfs => _ufs.keys.toList()..sort();

  static Future<List<dynamic>> _json(String url) async {
    final r = await http.get(Uri.parse(url), headers: {'User-Agent': 'GoUpPonto'}).timeout(const Duration(seconds: 40));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode} ao baixar ${url.split('/').last}');
    final v = jsonDecode(utf8.decode(r.bodyBytes));
    return v is List ? v : <dynamic>[];
  }

  static DateTime? _data(dynamic s) {
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch('$s');
    return m == null ? null : DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }

  /// Importa os feriados do [ano] para a UF e o município informados.
  static Future<ResultadoFeriados> importar(int ano, {required String uf, required int codIbge}) async {
    final db = Db.instance;
    final res = ResultadoFeriados();

    // Nacionais: só entram os que ainda não existem (os fixos já vêm cadastrados e a Sexta-feira Santa é calculada)
    final existentes = await db.feriadosNoPeriodo(DateTime(ano, 1, 1), DateTime(ano, 12, 31));
    for (final f in await _json('$_base/feriados/nacional/json/$ano.json')) {
      final d = _data(f['data']);
      if (d == null || existentes.containsKey(d)) continue;
      await db.inserirFeriadoImportado(d, '${f['nome']}', 'NACIONAL');
      existentes[d] = '${f['nome']}';
      res.nacionais++;
    }

    // Estaduais e municipais: substitui o que foi importado antes para o ano (a UF/município pode ter mudado)
    await db.removerFeriadosImportados(ano);
    if (uf.isEmpty) {
      res.avisos.add('UF da empresa não informada: feriados estaduais não importados.');
    } else {
      for (final f in await _json('$_base/feriados/estadual/json/$ano.json')) {
        if ('${f['uf']}'.toUpperCase() != uf) continue;
        final d = _data(f['data']);
        if (d == null) continue;
        await db.inserirFeriadoImportado(d, '${f['nome']}', 'ESTADUAL');
        res.estaduais++;
      }
    }
    if (codIbge <= 0) {
      res.avisos.add('Município da empresa não informado: feriados municipais não importados.');
    } else {
      for (final f in await _json('$_base/feriados/municipal/json/$ano.json')) {
        if (asInt(f['codigo_ibge']) != codIbge) continue;
        final d = _data(f['data']);
        if (d == null) continue;
        final nome = '${f['nome']}'.trim().isEmpty ? 'Feriado Municipal' : '${f['nome']}';
        await db.inserirFeriadoImportado(d, nome, 'MUNICIPAL');
        res.municipais++;
      }
      if (res.municipais == 0) {
        res.avisos.add('Nenhum feriado municipal encontrado para o município em $ano. Cadastre manualmente se houver.');
      }
    }
    return res;
  }

  /// Importa o ano atual e o próximo (quando ainda não importados). Silencioso: falhas de rede são ignoradas.
  static Future<ResultadoFeriados?> atualizarAutomatico() async {
    try {
      final emp = await Db.instance.getEmpresaPrincipal();
      if (emp == null || (emp.uf.isEmpty && emp.codIbge <= 0)) return null;
      final feitos = await Db.instance.anosComFeriadosImportados();
      final total = ResultadoFeriados();
      final hoje = DateTime.now();
      for (final ano in [hoje.year, hoje.year + 1]) {
        if (feitos.contains(ano)) continue;
        try {
          final r = await importar(ano, uf: emp.uf, codIbge: emp.codIbge);
          total.nacionais += r.nacionais;
          total.estaduais += r.estaduais;
          total.municipais += r.municipais;
        } catch (_) {
          // O arquivo do ano seguinte pode ainda não existir
        }
      }
      return total.total > 0 ? total : null;
    } catch (_) {
      return null;
    }
  }

  /// Lista oficial de municípios do IBGE (nome, UF e código) para escolher o município da empresa.
  static Future<List<MunicipioIbge>> municipios(String uf) async {
    final cod = _ufs[uf];
    if (cod == null) return [];
    final r = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$cod/municipios'),
        headers: {'User-Agent': 'GoUpPonto'}).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('IBGE respondeu HTTP ${r.statusCode}');
    return [
      for (final m in jsonDecode(utf8.decode(r.bodyBytes)) as List) MunicipioIbge(asInt(m['id']), '${m['nome']}', uf)
    ]..sort((a, b) => a.nome.compareTo(b.nome));
  }

  /// Razão social, UF e município a partir do CNPJ (BrasilAPI).
  static Future<DadosCnpj> consultarCnpj(String cnpj) async {
    final d = onlyDigits(cnpj);
    if (d.length != 14) throw Exception('Informe um CNPJ com 14 dígitos.');
    final r = await http.get(Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$d'),
        headers: {'User-Agent': 'GoUpPonto'}).timeout(const Duration(seconds: 25));
    if (r.statusCode == 404) throw Exception('CNPJ não encontrado na Receita Federal.');
    if (r.statusCode != 200) throw Exception('Consulta de CNPJ indisponível (HTTP ${r.statusCode}).');
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final end = [
      '${j['descricao_tipo_de_logradouro'] ?? ''} ${j['logradouro'] ?? ''}'.trim(),
      if ('${j['numero'] ?? ''}'.isNotEmpty) '${j['numero']}',
    ].join(', ');
    final bairro = '${j['bairro'] ?? ''}'.trim();
    return DadosCnpj('${j['razao_social'] ?? ''}', '${j['uf'] ?? ''}'.toUpperCase(), '${j['municipio'] ?? ''}',
        asInt(j['codigo_municipio_ibge']), bairro.isEmpty ? end : '$end - $bairro');
  }
}
