import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/build_info.dart';
import '../core/util.dart';
import '../data/database.dart';

/// Comprovante de Registro de Ponto do Trabalhador (Portaria 671, art. 82), emitido a cada batida
/// registrada pelo programa (leitor biométrico). Gera texto (impressora térmica) e HTML.
class ComprovanteService {
  static String pasta(DateTime d) {
    final docs = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(docs, 'Documents', 'Go Up Ponto', 'Comprovantes',
        '${d.year}-${d.month.toString().padLeft(2, '0')}');
  }

  /// Monta o comprovante da marcação; retorna o caminho do .txt gerado (o .html fica ao lado).
  static Future<String?> gerar(int marcacaoId) async {
    final db = Db.instance;
    final m = await db.queryOne(
        'SELECT M.PMA_ID, M.PMA_NSR, M.PMA_DATA_HORA, M.PMA_PESSOA, M.PMA_ORIGEM, M.PMA_TIPO_IDENTIFICACAO, '
        'P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, C.COL_CPF FROM TB_PONTO_MARCACAO M '
        'LEFT JOIN TB_PESSOA P ON P.PES_ID = M.PMA_PESSOA LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = M.PMA_PESSOA '
        'WHERE M.PMA_ID = ?',
        [marcacaoId]);
    if (m == null) return null;
    final emp = await db.getEmpresaPrincipal();
    final dh = asDate(m['PMA_DATA_HORA']) ?? DateTime.now();
    final cpf = asStr(m['COL_CPF']).isNotEmpty ? asStr(m['COL_CPF']) : asStr(m['PES_CNPJ_CPF']);
    final nsr = asInt(m['PMA_NSR']) > 0 ? asInt(m['PMA_NSR']) : asInt(m['PMA_ID']);
    final linhas = <String>[
      'COMPROVANTE DE REGISTRO DE PONTO DO TRABALHADOR',
      '',
      'Empregador: ${emp?.razao ?? ''}',
      'CNPJ/CPF: ${formatarDoc(emp?.cnpj ?? '')}',
      'Local: ${emp?.endereco ?? ''}',
      '',
      'Trabalhador: ${asStr(m['PES_RSOCIAL_NOME'])}',
      'CPF: ${formatarDoc(cpf)}',
      '',
      'Data: ${fmtData(dh)}   Hora: ${fmtHora(dh)}',
      'NSR: ${nsr.toString().padLeft(9, '0')}',
      'Identificação: ${asStr(m['PMA_TIPO_IDENTIFICACAO']).isEmpty ? 'BIOMETRIA' : asStr(m['PMA_TIPO_IDENTIFICACAO'])}',
      '',
      'Programa de ponto: Go Up Ponto v$buildVersion.$buildNumber',
      'Emitido em ${fmtDataHora(DateTime.now())}',
    ];
    final dir = Directory(pasta(dh))..createSync(recursive: true);
    final base = p.join(dir.path, 'Comprovante_${onlyDigits(cpf)}_${nsr.toString().padLeft(9, '0')}');
    await File('$base.txt').writeAsString('${linhas.join('\r\n')}\r\n', encoding: latin1);
    await File('$base.html').writeAsString('<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8">'
        '<title>Comprovante NSR $nsr</title><style>body{font-family:Consolas,monospace;font-size:12px;width:76mm;margin:4mm}'
        'h3{font-size:13px;text-align:center;margin:0 0 8px}p{margin:2px 0}@media print{button{display:none}}</style></head><body>'
        '<button onclick="window.print()">Imprimir</button><h3>${esc(linhas.first)}</h3>'
        '${linhas.skip(1).map((l) => l.isEmpty ? '<br>' : '<p>${esc(l)}</p>').join()}</body></html>');
    return '$base.txt';
  }

  /// Imprime o comprovante na impressora padrão do Windows (ex.: impressora térmica).
  static Future<void> imprimir(String txt) => Process.run('notepad.exe', ['/p', txt]);
}
