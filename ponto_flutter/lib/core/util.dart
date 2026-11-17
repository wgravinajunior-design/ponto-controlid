import 'package:intl/intl.dart';

String onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

final _fData = DateFormat('dd/MM/yyyy');
final _fDataHora = DateFormat('dd/MM/yyyy HH:mm:ss');
final _fHora = DateFormat('HH:mm');
final _fHoraSeg = DateFormat('HH:mm:ss');

String fmtData(DateTime? d) => d == null ? '' : _fData.format(d);
String fmtDataHora(DateTime? d) => d == null ? '' : _fDataHora.format(d);
String fmtHora(DateTime? d) => d == null ? '' : _fHora.format(d);
String fmtHoraSeg(DateTime? d) => d == null ? '' : _fHoraSeg.format(d);

DateTime inicioDoDia(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime fimDoDia(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? parseData(String s) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s.trim());
  if (m == null) return null;
  final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
  final dt = DateTime(y, mo, d);
  if (dt.day != d || dt.month != mo) return null;
  return dt;
}

/// Aceita HH:MM ou HH:MM:SS. Retorna Duration desde 00:00.
Duration? parseHora(String s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(s.trim());
  if (m == null) return null;
  final h = int.parse(m[1]!), mi = int.parse(m[2]!), se = int.parse(m[3] ?? '0');
  if (h > 23 || mi > 59 || se > 59) return null;
  return Duration(hours: h, minutes: mi, seconds: se);
}

/// Equivalente a MinutesBetween do Delphi (diferença absoluta em minutos inteiros).
int minutesBetween(DateTime a, DateTime b) => a.difference(b).inMinutes.abs();

String minutosParaHora(int minutos, {bool exibirSinal = false}) {
  if (minutos == 0) return '00:00';
  final sinal = minutos < 0 ? '-' : (exibirSinal ? '+' : '');
  final abs = minutos.abs();
  return '$sinal${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}';
}

int horaParaMinutos(String s) {
  final t = s.trim();
  final i = t.indexOf(':');
  if (i <= 0) return 0;
  final h = int.tryParse(t.substring(0, i)) ?? 0;
  final rest = t.substring(i + 1);
  final m = int.tryParse(rest.length > 2 ? rest.substring(0, 2) : rest) ?? 0;
  return h * 60 + m;
}

String formatarDoc(String doc) {
  final d = onlyDigits(doc);
  if (d.length == 14) {
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }
  if (d.length == 11) {
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }
  return doc;
}

String esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// Conversores defensivos para valores vindos do banco
String asStr(dynamic v) {
  if (v == null) return '';
  if (v is String) return v.trimRight();
  return v.toString();
}

int asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// "E" -> "Entrada", "S" -> "Saída" (valores antigos como "Batida Ponto" aparecem como estão).
String nomeTipoBatida(String t) {
  switch (t.trim().toUpperCase()) {
    case 'E':
      return 'Entrada';
    case 'S':
      return 'Saída';
    default:
      return t == 'Batida Ponto' ? '' : t;
  }
}
