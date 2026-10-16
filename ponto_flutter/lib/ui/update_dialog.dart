import 'dart:async';

import 'package:flutter/material.dart';

import '../core/build_info.dart';
import '../services/update_service.dart';
import 'theme.dart';
import 'app_state.dart';

/// Tela de atualização (port de TfrmUpdate). Em modo automático, contagem regressiva de 15s.
Future<void> mostrarAtualizacao(BuildContext context, UpdateInfo info, {bool automatico = false}) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(info, automatico),
    );

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final bool automatico;
  const _UpdateDialog(this.info, this.automatico);
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  Timer? _tmr;
  int _segundos = 15;
  double? _progresso;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    if (widget.automatico) {
      _tmr = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _segundos--);
        if (_segundos <= 0) _atualizar();
      });
    }
  }

  @override
  void dispose() {
    _tmr?.cancel();
    super.dispose();
  }

  Future<void> _atualizar() async {
    _tmr?.cancel();
    setState(() {
      _progresso = 0;
      _erro = '';
    });
    try {
      AppState.instance.logTs('⬇️ Baixando atualização ${widget.info.descricao}...');
      await UpdateService.baixarEInstalar(widget.info, (p) {
        if (mounted) setState(() => _progresso = p);
      });
    } catch (e) {
      AppState.instance.logTs('❌ Falha na atualização: $e', true);
      if (mounted) {
        setState(() {
          _progresso = null;
          _erro = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    return AlertDialog(
      title: const Row(children: [Icon(Icons.rocket_launch), SizedBox(width: 8), Text('Nova versão disponível')]),
      content: SizedBox(
        width: 560,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Versão atual: ${versaoCompleta()}'),
          Text('Nova versão: ${i.descricao}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (i.assetSize > 0) Text('Pacote: ${i.assetFileName} (${(i.assetSize / 1048576).toStringAsFixed(1)} MB)'),
          const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(child: NotasVersao(i.releaseNotes.isEmpty ? i.releaseName : i.releaseNotes)),
          ),
          const SizedBox(height: 12),
          if (_progresso != null) ...[
            LinearProgressIndicator(value: _progresso == 0 ? null : _progresso),
            const SizedBox(height: 4),
            Text('Baixando... ${((_progresso ?? 0) * 100).toStringAsFixed(0)}%'),
          ],
          if (widget.automatico && _tmr != null && _tmr!.isActive)
            Text('A atualização começará automaticamente em $_segundos s.'),
          if (_erro.isNotEmpty) Text(_erro, style: const TextStyle(color: Colors.red)),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: _progresso != null && _erro.isEmpty ? null : () => Navigator.pop(context),
            child: const Text('Adiar')),
        FilledButton.icon(
            onPressed: _progresso != null && _erro.isEmpty ? null : _atualizar,
            icon: const Icon(Icons.download),
            label: const Text('Atualizar agora')),
      ],
    );
  }
}

/// Notas da versão (Markdown simples): títulos "##" viram seções com ícone e "-" viram tópicos.
class NotasVersao extends StatelessWidget {
  final String notas;
  const NotasVersao(this.notas, {super.key});

  static (IconData, Color) _estilo(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('novidade')) return (Icons.auto_awesome_rounded, AppCores.roxo);
    if (t.contains('melhoria')) return (Icons.trending_up_rounded, AppCores.azul);
    if (t.contains('corre')) return (Icons.build_circle_rounded, AppCores.laranja);
    return (Icons.info_outline_rounded, Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
    final itens = <Widget>[];
    for (final bruta in notas.split(RegExp(r'\r?\n'))) {
      final l = bruta.trimRight();
      if (l.trim().isEmpty) continue;
      if (l.startsWith('#')) {
        final titulo = l.replaceFirst(RegExp(r'^#+\s*'), '');
        final (icone, cor) = _estilo(titulo);
        itens.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Row(children: [
            Icon(icone, size: 20, color: cor),
            const SizedBox(width: 8),
            Text(titulo, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cor)),
          ]),
        ));
      } else if (RegExp(r'^\s*[-*•]\s+').hasMatch(l)) {
        itens.add(Padding(
          padding: const EdgeInsets.only(left: 28, top: 3, bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  ', style: TextStyle(fontWeight: FontWeight.w700)),
            Expanded(child: SelectableText(l.replaceFirst(RegExp(r'^\s*[-*•]\s+'), ''))),
          ]),
        ));
      } else {
        itens.add(Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: SelectableText(l)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: itens);
  }
}

/// "O que há de novo": exibido na primeira abertura após uma atualização.
Future<void> mostrarNovidades(BuildContext context, Novidades n) => showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppCores.azul, Color(0xFF06B6D4)]), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.celebration_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Sistema atualizado!', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('Go Up Ponto ${n.descricao}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
          ),
        ]),
        content: SizedBox(
          width: 580,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(child: NotasVersao(n.notas)),
          ),
        ),
        actions: [FilledButton.icon(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.check), label: const Text('Entendi'))],
      ),
    );
