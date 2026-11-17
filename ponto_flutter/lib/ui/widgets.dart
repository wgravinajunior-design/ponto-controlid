import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Coluna da grade.
class GridCol<T> {
  final String titulo;
  final double largura;
  final String Function(T) valor;
  final Color? Function(T)? cor;
  final bool flex;
  const GridCol(this.titulo, this.largura, this.valor, {this.cor, this.flex = false});
}

/// Grade simples, rápida (ListView.builder) e com seleção de linha.
class DataGrid<T> extends StatelessWidget {
  final List<T> itens;
  final List<GridCol<T>> colunas;
  final T? selecionado;
  final ValueChanged<T>? onSelect;
  final ValueChanged<T>? onDoubleTap;
  final Color? Function(T)? corLinha;

  const DataGrid({
    super.key,
    required this.itens,
    required this.colunas,
    this.selecionado,
    this.onSelect,
    this.onDoubleTap,
    this.corLinha,
  });

  Widget _cel(GridCol<T> c, Widget child) =>
      c.flex ? Expanded(child: child) : SizedBox(width: c.largura, child: child);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          color: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            for (final c in colunas)
              _cel(
                  c,
                  Text(c.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          ]),
        ),
        Expanded(
          child: itens.isEmpty
              ? Center(child: Text('Nenhum registro', style: TextStyle(color: cs.outline)))
              : ListView.builder(
                  itemCount: itens.length,
                  itemExtent: 30,
                  itemBuilder: (_, i) {
                    final it = itens[i];
                    final sel = identical(it, selecionado) || it == selecionado;
                    final fundo = sel
                        ? cs.primaryContainer
                        : (corLinha?.call(it) ?? (i.isEven ? null : cs.surfaceContainerHighest.withValues(alpha: .35)));
                    return Material(
                      color: fundo ?? Colors.transparent,
                      child: InkWell(
                        onTap: onSelect == null ? null : () => onSelect!(it),
                        onDoubleTap: onDoubleTap == null ? null : () => onDoubleTap!(it),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(children: [
                            for (final c in colunas)
                              _cel(
                                  c,
                                  Text(c.valor(it),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.5, color: c.cor?.call(it)))),
                          ]),
                        ),
                      ),
                    );
                  }),
        ),
        Container(
          width: double.infinity,
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('${itens.length} registro(s)', style: const TextStyle(fontSize: 11)),
        ),
      ]),
    );
  }
}

/// Cabeçalho de página com título e ações.
class PageHeader extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final List<Widget> acoes;
  const PageHeader(this.titulo, this.icone, {super.key, this.acoes = const []});

  @override
  // O título da página já aparece no topo da janela: aqui ficam só as ações
  Widget build(BuildContext context) => acoes.isEmpty
      ? const SizedBox(height: 4)
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: acoes),
        );
}

class Btn extends StatelessWidget {
  final String texto;
  final IconData icone;
  final VoidCallback? onPressed;
  final Color? cor;
  final bool tonal;
  const Btn(this.texto, this.icone, this.onPressed, {super.key, this.cor, this.tonal = false});

  @override
  Widget build(BuildContext context) {
    final style = cor == null ? null : FilledButton.styleFrom(backgroundColor: cor, foregroundColor: Colors.white);
    return tonal
        ? FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icone, size: 18), label: Text(texto))
        : FilledButton.icon(onPressed: onPressed, icon: Icon(icone, size: 18), label: Text(texto), style: style);
  }
}

class Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final double largura;
  final bool senha;
  final bool somenteLeitura;
  final String? dica;
  const Campo(this.rotulo, this.controller,
      {super.key, this.largura = 220, this.senha = false, this.somenteLeitura = false, this.dica});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: largura,
        child: TextField(
          controller: controller,
          obscureText: senha,
          readOnly: somenteLeitura,
          decoration: InputDecoration(
              labelText: rotulo, hintText: dica, isDense: true),
        ),
      );
}

class Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  const Secao(this.titulo, this.children, {super.key});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );
}

// ======================= Diálogos =======================

Future<void> mensagem(BuildContext context, String texto, {String titulo = 'Ponto Control iD'}) => showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: SelectableText(texto),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );

Future<bool> confirmar(BuildContext context, String texto, {String titulo = 'Confirmação'}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sim')),
        ],
      ),
    ) ??
    false;

/// Equivalente ao InputQuery com vários campos do Delphi.
Future<List<String>?> inputQuery(BuildContext context, String titulo, List<String> rotulos, List<String> valores) {
  final ctrls = [for (final v in valores) TextEditingController(text: v)];
  return showDialog<List<String>>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < rotulos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: ctrls[i],
                autofocus: i == 0,
                decoration: InputDecoration(labelText: rotulos[i], isDense: true),
              ),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, [for (final t in ctrls) t.text]), child: const Text('OK')),
      ],
    ),
  );
}

Future<DateTime?> escolherData(BuildContext context, DateTime inicial) => showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );

/// Grava o HTML em arquivo temporário e abre no navegador padrão (imprimir / salvar PDF).
Future<String> abrirHtml(String nomeArquivo, String html) async {
  final f = File(p.join(Directory.systemTemp.path, nomeArquivo));
  await f.writeAsString(html);
  await launchUrl(Uri.file(f.path));
  return f.path;
}

/// Executa uma ação assíncrona mostrando indicador de progresso.
Future<T?> comProgresso<T>(BuildContext context, Future<T> Function() acao, {String texto = 'Processando...'}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 20), Expanded(child: Text(texto))]),
    ),
  );
  try {
    return await acao();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
