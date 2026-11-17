import 'package:flutter/material.dart';

import '../services/descoberta_service.dart';
import 'theme.dart';

/// Procura relógios Control iD na rede e devolve o escolhido.
Future<RelogioEncontrado?> procurarRelogios(BuildContext context, {Set<String> ipsCadastrados = const {}}) =>
    showDialog<RelogioEncontrado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DescobertaDialog(ipsCadastrados),
    );

class _DescobertaDialog extends StatefulWidget {
  final Set<String> ipsCadastrados;
  const _DescobertaDialog(this.ipsCadastrados);
  @override
  State<_DescobertaDialog> createState() => _DescobertaDialogState();
}

class _DescobertaDialogState extends State<_DescobertaDialog> {
  final _redes = TextEditingController();
  final _usuario = TextEditingController(text: 'admin');
  final _senha = TextEditingController(text: 'admin');
  final _achados = <RelogioEncontrado>[];
  bool _buscando = false, _cancelar = false, _terminou = false;
  int _testados = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    DescobertaService.redesLocais().then((r) {
      if (mounted) setState(() => _redes.text = r.map((p) => '$p.0/24').join(', '));
      _buscar();
    });
  }

  Future<void> _buscar() async {
    final redes = _redes.text
        .split(',')
        .map((s) => s.trim().replaceAll(RegExp(r'\.\d+(/\d+)?$'), ''))
        .where((s) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch(s))
        .toList();
    if (redes.isEmpty) return;
    setState(() {
      _buscando = true;
      _cancelar = false;
      _terminou = false;
      _achados.clear();
      _testados = 0;
    });
    await DescobertaService.procurar(
      redes: redes,
      usuario: _usuario.text.trim(),
      senha: _senha.text,
      cancelado: () => _cancelar,
      onProgresso: (t, total) {
        if (mounted) setState(() { _testados = t; _total = total; });
      },
      onEncontrado: (r) {
        if (mounted) setState(() => _achados.add(r));
      },
    );
    if (mounted) {
      setState(() {
        _buscando = false;
        _terminou = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.wifi_find_rounded, color: AppCores.azul),
        SizedBox(width: 10),
        Text('Procurar relógios na rede'),
      ]),
      content: SizedBox(
        width: 640,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: TextField(controller: _redes, decoration: const InputDecoration(labelText: 'Redes'))),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: TextField(controller: _usuario, decoration: const InputDecoration(labelText: 'Usuário'))),
            const SizedBox(width: 8),
            SizedBox(
                width: 110,
                child: TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha'))),
          ]),
          const SizedBox(height: 12),
          if (_buscando || _terminou) ...[
            LinearProgressIndicator(value: _total == 0 ? null : _testados / _total, minHeight: 6, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 6),
            Text(_buscando
                ? 'Verificando $_testados de $_total endereços...'
                : 'Busca concluída: ${_achados.length} relógio(s) encontrado(s).'),
            const SizedBox(height: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300, minHeight: 80),
            child: _achados.isEmpty
                ? Center(
                    child: Text(
                        _terminou
                            ? 'Nenhum relógio Control iD respondeu. Confira se o equipamento está ligado na mesma rede.'
                            : 'Procurando...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)))
                : ListView(shrinkWrap: true, children: [
                    for (final r in _achados)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: (r.autenticado ? AppCores.verde : AppCores.laranja).withValues(alpha: .15),
                              child: Icon(Icons.router_rounded, color: r.autenticado ? AppCores.verde : AppCores.laranja)),
                          title: Text('${r.ip}:${r.porta}${r.ssl ? ' (HTTPS)' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(r.descricao),
                          trailing: widget.ipsCadastrados.contains(r.ip)
                              ? const StatusChip('Já cadastrado', Colors.blueGrey)
                              : FilledButton(onPressed: () => Navigator.pop(context, r), child: const Text('Usar')),
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () {
              _cancelar = true;
              Navigator.pop(context);
            },
            child: const Text('Fechar')),
        FilledButton.icon(
            onPressed: _buscando ? () => setState(() => _cancelar = true) : _buscar,
            icon: Icon(_buscando ? Icons.stop_rounded : Icons.refresh_rounded),
            label: Text(_buscando ? 'Parar' : 'Procurar novamente')),
      ],
    );
  }
}
