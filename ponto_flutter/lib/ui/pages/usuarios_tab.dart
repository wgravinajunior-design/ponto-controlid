import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../widgets.dart';

/// Cadastro de usuários do sistema (Configurações > Usuários).
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});
  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  List<DbRow> _itens = [];
  DbRow? _sel;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = await Db.instance.getUsuarios();
    if (mounted) setState(() => _itens = u);
  }

  Future<void> _editar([DbRow? atual]) async {
    final login = TextEditingController(text: asStr(atual?['USU_LOGIN']));
    final nome = TextEditingController(text: asStr(atual?['USU_NOME']));
    final senha = TextEditingController();
    var perfil = atual == null ? 'OPERADOR' : asStr(atual['USU_PERFIL']);
    var ativo = atual == null || asStr(atual['USU_ATIVO']) != 'N';
    var trocar = atual == null;
    String erro = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(atual == null ? 'Novo usuário' : 'Usuário ${asStr(atual['USU_LOGIN'])}'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: login, decoration: const InputDecoration(labelText: 'Login')),
              const SizedBox(height: 12),
              TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 12),
              TextField(
                  controller: senha,
                  obscureText: true,
                  decoration: InputDecoration(labelText: atual == null ? 'Senha' : 'Nova senha (deixe em branco para manter)')),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ADMIN', label: Text('Administrador')),
                  ButtonSegment(value: 'OPERADOR', label: Text('Operador')),
                ],
                selected: {perfil},
                onSelectionChanged: (s) => set(() => perfil = s.first),
              ),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exigir troca de senha no próximo acesso'),
                  value: trocar,
                  onChanged: (v) => set(() => trocar = v!)),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativo'),
                  value: ativo,
                  onChanged: (v) => set(() => ativo = v!)),
              if (erro.isNotEmpty) Text(erro, style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (login.text.trim().length < 3) return set(() => erro = 'Login com pelo menos 3 caracteres.');
                if ((atual == null || senha.text.isNotEmpty) && senha.text.length < 6) {
                  return set(() => erro = 'Senha com pelo menos 6 caracteres.');
                }
                if (atual != null && asInt(atual['USU_ID']) == AppState.instance.usuarioId && (!ativo || perfil != 'ADMIN')) {
                  return set(() => erro = 'Você não pode inativar nem rebaixar o seu próprio usuário.');
                }
                Navigator.pop(c, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Db.instance.salvarUsuario(asInt(atual?['USU_ID']), login.text, nome.text, perfil, ativo,
          senha: senha.text.isEmpty ? null : senha.text, trocarSenha: trocar);
      AppState.instance.logTs('👤 Usuário ${login.text.trim().toLowerCase()} salvo ($perfil).');
      await _carregar();
    } catch (e) {
      if (mounted) await mensagem(context, 'Não foi possível salvar (login já existe?): $e');
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [
          Btn('Novo usuário', Icons.person_add, () => _editar()),
          Btn('Editar', Icons.edit, _sel == null ? null : () => _editar(_sel), tonal: true),
        ]),
        const SizedBox(height: 8),
        const Text('Administrador: acesso total. Operador: sem Configurações e Contabilidade. '
            'Todos os ajustes de batidas, justificativas e afastamentos registram o login de quem fez.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Expanded(
          child: DataGrid<DbRow>(
            itens: _itens,
            selecionado: _sel,
            onSelect: (r) => setState(() => _sel = r),
            onDoubleTap: _editar,
            colunas: [
              GridCol('Login', 140, (r) => asStr(r['USU_LOGIN'])),
              GridCol('Nome', 220, (r) => asStr(r['USU_NOME']), flex: true),
              GridCol('Perfil', 110, (r) => asStr(r['USU_PERFIL']) == 'ADMIN' ? 'Administrador' : 'Operador'),
              GridCol('Ativo', 60, (r) => asStr(r['USU_ATIVO']) == 'N' ? 'Não' : 'Sim'),
              GridCol('Último acesso', 140, (r) => fmtDataHora(asDate(r['USU_ULTIMO_ACESSO']))),
            ],
          ),
        ),
      ]);
}
