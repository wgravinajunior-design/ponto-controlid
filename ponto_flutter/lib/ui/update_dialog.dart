import 'dart:async';

import 'package:flutter/material.dart';

import '../core/build_info.dart';
import '../services/update_service.dart';
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
            child: SingleChildScrollView(child: SelectableText(i.releaseNotes.isEmpty ? i.releaseName : i.releaseNotes)),
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
