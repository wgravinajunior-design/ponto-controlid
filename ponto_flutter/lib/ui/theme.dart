import 'package:flutter/material.dart';

class AppCores {
  static const azul = Color(0xFF2563EB);
  static const verde = Color(0xFF16A34A);
  static const vermelho = Color(0xFFDC2626);
  static const laranja = Color(0xFFEA580C);
  static const roxo = Color(0xFF7C3AED);
  static const fundo = Color(0xFFF1F5F9);
  static const sidebar = Color(0xFF0F172A);
  static const sidebar2 = Color(0xFF1E293B);
}

ThemeData temaApp() {
  final cs = ColorScheme.fromSeed(seedColor: AppCores.azul, primary: AppCores.azul, surface: Colors.white);
  final raio = BorderRadius.circular(12);
  return ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: AppCores.fundo,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: raio, borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: raio, borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: raio, borderSide: const BorderSide(color: AppCores.azul, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: raio),
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: raio)),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    tabBarTheme: const TabBarThemeData(labelStyle: TextStyle(fontWeight: FontWeight.w600)),
    dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
  );
}

/// Cartão de indicador (KPI) com ícone em destaque.
class KpiCard extends StatelessWidget {
  final String titulo, valor;
  final IconData icone;
  final Color cor;
  final String rodape;
  const KpiCard(this.titulo, this.valor, this.icone, this.cor, {super.key, this.rodape = ''});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(titulo, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [cor, Color.lerp(cor, Colors.white, .3)!]),
                  boxShadow: [BoxShadow(color: cor.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icone, color: Colors.white, size: 22),
              ),
            ]),
            const SizedBox(height: 6),
            Text(valor, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            if (rodape.isNotEmpty)
              Text(rodape, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cor)),
          ]),
        ),
      );
}

/// Painel com título para agrupar gráficos e listas.
class Painel extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Widget child;
  final double? altura;
  const Painel(this.titulo, this.icone, this.child, {super.key, this.altura});

  @override
  Widget build(BuildContext context) {
    final corpo = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icone, size: 20, color: AppCores.azul),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 14),
        if (altura != null) Expanded(child: child) else child,
      ]),
    );
    return Card(child: altura == null ? corpo : SizedBox(height: altura, child: corpo));
  }
}

class Avatar extends StatelessWidget {
  final String nome;
  final Color cor;
  const Avatar(this.nome, this.cor, {super.key});

  @override
  Widget build(BuildContext context) {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final ini = partes.isEmpty ? '?' : (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: cor.withValues(alpha: .14),
      child: Text(ini, style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String texto;
  final Color cor;
  const StatusChip(this.texto, this.cor, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: cor.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
