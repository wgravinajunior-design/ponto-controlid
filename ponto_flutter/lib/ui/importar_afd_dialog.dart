import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/util.dart';
import '../data/database.dart';
import '../services/afd_import_service.dart';
import 'app_state.dart';
import 'theme.dart';

/// Coleta manual: lê o AFD gravado pelo relógio em um pendrive e importa as marcações.
/// Retorna true se importou alguma coisa (para a tela recarregar).
Future<bool> importarAfdDoPendrive(BuildContext context) async {
  final r = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const _ImportarAfd());
  return r ?? false;
}

class _Item {
  final ArquivoAfd arquivo;
  bool marcado;
  int relogioId;
  _Item(this.arquivo, this.marcado, this.relogioId);
}

class _ImportarAfd extends StatefulWidget {
  const _ImportarAfd();
  @override
  State<_ImportarAfd> createState() => _ImportarAfdState();
}

class _ImportarAfdState extends State<_ImportarAfd> {
  final _itens = <_Item>[];
  List<DbRow> _relogios = [];
  bool _procurando = true, _importando = false;
  final _resultados = <(String, ResultadoImportacao)>[];
  bool _importou = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _relogios = await Db.instance.getRelogios();
    await _procurar();
  }

  Future<void> _adicionar(ArquivoAfd a, {bool marcado = true}) async {
    if (_itens.any((i) => i.arquivo.caminho == a.caminho)) return;
    var rel = await AfdImportService.relogioDoArquivo(a);
    if (rel == 0 && _relogios.length == 1) rel = asInt(_relogios.first['PRE_ID']);
    _itens.add(_Item(a, marcado, rel));
  }

  Future<void> _procurar() async {
    setState(() => _procurando = true);
    final achados = await AfdImportService.procurarNoPendrive();
    for (final a in achados) {
      await _adicionar(a);
    }
    if (mounted) setState(() => _procurando = false);
  }

  Future<void> _escolher() async {
    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'afd']);
    if (r.isEmpty || r.first.path == null) return;
    await _adicionar(ArquivoAfd(r.first.path!));
    if (mounted) setState(() {});
  }

  Future<void> _importar() async {
    setState(() {
      _importando = true;
      _resultados.clear();
    });
    for (final i in _itens.where((i) => i.marcado)) {
      final res = await AfdImportService.importar(i.arquivo.caminho, i.relogioId);
      _resultados.add((i.arquivo.nome, res));
      if (res.novas > 0) _importou = true;
      AppState.instance.logTs(res.erro != null
          ? '❌ Importação de ${i.arquivo.nome}: ${res.erro}'
          : '📥 AFD ${i.arquivo.nome} importado: ${res.novas} nova(s), ${res.duplicadas} já existente(s)'
              '${res.semColaborador > 0 ? ', ${res.semColaborador} sem colaborador' : ''}.',
          res.erro != null);
    }
    if (_importou) AppState.instance.dadosAlterados();
    if (mounted) setState(() => _importando = false);
  }

  @override
  Widget build(BuildContext context) {
    final temResultado = _resultados.isNotEmpty;
    return AlertDialog(
      title: const Row(children: [Icon(Icons.usb_rounded, color: AppCores.azul), SizedBox(width: 10), Text('Importar AFD do pendrive')]),
      content: SizedBox(
        width: 720,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
              'No relógio, grave o AFD no pendrive (Menu > Pen drive > Exportar AFD), conecte-o a este computador e '
              'clique em Procurar. As marcações já importadas (mesmo NSR) são ignoradas.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          if (temResultado)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(shrinkWrap: true, children: [for (final r in _resultados) _resultado(r.$1, r.$2)]),
            )
          else ...[
            if (_procurando) const LinearProgressIndicator(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, minHeight: 60),
              child: _itens.isEmpty
                  ? Center(
                      child: Text(
                          _procurando
                              ? 'Procurando nos pendrives...'
                              : 'Nenhum arquivo AFD encontrado nos pendrives. Conecte o pendrive e clique em Procurar, ou escolha o arquivo manualmente.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)))
                  : ListView(shrinkWrap: true, children: [
                      for (final i in _itens)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                            child: Row(children: [
                              Checkbox(value: i.marcado, onChanged: (v) => setState(() => i.marcado = v!)),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(i.arquivo.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${(i.arquivo.tamanho / 1024).toStringAsFixed(1)} KB  •  ${fmtDataHora(i.arquivo.modificado)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ]),
                              ),
                              SizedBox(
                                width: 230,
                                child: DropdownButtonFormField<int>(
                                  initialValue: i.relogioId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Relógio de origem'),
                                  items: [
                                    const DropdownMenuItem(value: 0, child: Text('Não informar')),
                                    for (final r in _relogios)
                                      DropdownMenuItem(value: asInt(r['PRE_ID']), child: Text(asStr(r['PRE_NOME']))),
                                  ],
                                  onChanged: (v) => setState(() => i.relogioId = v ?? 0),
                                ),
                              ),
                            ]),
                          ),
                        ),
                    ]),
            ),
          ],
        ]),
      ),
      actions: [
        if (!temResultado) ...[
          TextButton.icon(onPressed: _importando ? null : _escolher, icon: const Icon(Icons.folder_open), label: const Text('Escolher arquivo...')),
          TextButton.icon(onPressed: _procurando || _importando ? null : _procurar, icon: const Icon(Icons.refresh), label: const Text('Procurar')),
        ],
        TextButton(onPressed: _importando ? null : () => Navigator.pop(context, _importou), child: Text(temResultado ? 'Fechar' : 'Cancelar')),
        if (!temResultado)
          FilledButton.icon(
            onPressed: _importando || !_itens.any((i) => i.marcado) ? null : _importar,
            icon: _importando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded),
            label: Text(_importando ? 'Importando...' : 'Importar'),
          ),
      ],
    );
  }

  Widget _resultado(String nome, ResultadoImportacao r) {
    final ok = r.erro == null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ok ? Icons.check_circle : Icons.error, color: ok ? AppCores.verde : AppCores.vermelho),
            const SizedBox(width: 8),
            Expanded(child: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          if (!ok)
            Text(r.erro!, style: const TextStyle(color: AppCores.vermelho))
          else ...[
            Text('${r.lidas} marcação(ões) no arquivo'
                '${r.de == null ? '' : ' (${fmtData(r.de)} a ${fmtData(r.ate)})'}${r.relogio.isEmpty ? '' : '  •  relógio ${r.relogio}'}'),
            Text('✅ ${r.novas} nova(s) importada(s)   •   ♻️ ${r.duplicadas} já existente(s)'
                '${r.vinculadas > 0 ? '   •   🔗 ${r.vinculadas} vinculada(s) a colaborador' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (r.semColaborador > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '⚠️ ${r.semColaborador} marcação(ões) de CPF sem colaborador cadastrado: ${r.naoIdentificados.join(', ')}. '
                    'Cadastre o colaborador e importe o arquivo de novo (as já gravadas são ignoradas).',
                    style: const TextStyle(color: AppCores.laranja, fontSize: 12)),
              ),
          ],
        ]),
      ),
    );
  }
}
