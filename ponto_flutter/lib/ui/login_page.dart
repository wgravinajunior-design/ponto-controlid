import 'package:flutter/material.dart';

import '../core/build_info.dart';
import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import 'app_state.dart';
import 'home_shell.dart';
import 'pages/config_page.dart';
import 'theme.dart';

/// Tela de entrada: conecta à base e autentica o usuário (perfil ADMIN ou OPERADOR).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _login = TextEditingController(), _senha = TextEditingController();
  bool _conectando = true, _entrando = false;
  String _erroBanco = '', _erro = '';

  @override
  void initState() {
    super.initState();
    _conectar();
  }

  Future<void> _conectar() async {
    setState(() {
      _conectando = true;
      _erroBanco = '';
    });
    final ok = await Db.instance.conectar();
    if (ok) {
      try {
        await Db.instance.garantirUsuarioAdmin();
      } catch (e) {
        _erroBanco = '$e';
      }
    }
    if (mounted) {
      setState(() {
        _conectando = false;
        if (!ok) _erroBanco = Db.instance.lastError;
      });
    }
  }

  Future<void> _entrar() async {
    setState(() {
      _entrando = true;
      _erro = '';
    });
    final u = await Db.instance.autenticar(_login.text, _senha.text);
    if (!mounted) return;
    if (u == null) {
      setState(() {
        _entrando = false;
        _erro = 'Usuário ou senha inválidos.';
      });
      return;
    }
    if (asStr(u['USU_TROCAR_SENHA']) == 'S') {
      final nova = await _trocarSenha();
      if (nova == null) {
        setState(() => _entrando = false);
        return;
      }
      await Db.instance.alterarSenha(asInt(u['USU_ID']), nova);
    }
    final app = AppState.instance
      ..usuarioId = asInt(u['USU_ID'])
      ..usuarioNome = asStr(u['USU_NOME']).isEmpty ? asStr(u['USU_LOGIN']) : asStr(u['USU_NOME'])
      ..perfil = asStr(u['USU_PERFIL']).toUpperCase();
    app.logTs('🔐 Usuário ${asStr(u['USU_LOGIN'])} (${app.perfil}) entrou no sistema.');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  Future<String?> _trocarSenha() {
    final a = TextEditingController(), b = TextEditingController();
    String erro = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Defina uma nova senha'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Por segurança, troque a senha inicial antes de continuar.'),
              const SizedBox(height: 12),
              TextField(controller: a, obscureText: true, decoration: const InputDecoration(labelText: 'Nova senha')),
              const SizedBox(height: 12),
              TextField(controller: b, obscureText: true, decoration: const InputDecoration(labelText: 'Repita a senha')),
              if (erro.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(erro, style: const TextStyle(color: Colors.red))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (a.text.length < 6) return set(() => erro = 'A senha precisa ter pelo menos 6 caracteres.');
                if (a.text != b.text) return set(() => erro = 'As senhas não conferem.');
                if (a.text == 'admin') return set(() => erro = 'Escolha uma senha diferente da inicial.');
                Navigator.pop(c, a.text);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirConfiguracao() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Configurações do banco de dados')),
          body: Padding(padding: const EdgeInsets.all(20), child: ConfigPage(onModoAlterado: () {}, somenteBanco: true)),
        ),
      )).then((_) => _conectar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E0F3D), Color(0xFF2E1A6E), Color(0xFF7B1593)]),
        ),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Card(
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/logo_goup.png', height: 96, filterQuality: FilterQuality.high),
                  const SizedBox(height: 12),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Go Up ', style: TextStyle(color: AppCores.azul)),
                      TextSpan(text: 'Ponto', style: TextStyle(color: Color(0xFF1E0F3D))),
                    ]),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  Text(versaoCompleta(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  if (_conectando)
                    const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                  else if (_erroBanco.isNotEmpty) ...[
                    const Icon(Icons.cloud_off_rounded, color: AppCores.vermelho, size: 40),
                    const SizedBox(height: 8),
                    Text('Não foi possível conectar à base:\n${AppConfig.instance.firebird.database}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(_erroBanco, maxLines: 4, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(onPressed: _conectar, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                      OutlinedButton.icon(onPressed: _abrirConfiguracao, icon: const Icon(Icons.settings), label: const Text('Configurar')),
                    ]),
                  ] else ...[
                    TextField(
                      controller: _login,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Usuário', prefixIcon: Icon(Icons.person_outline)),
                      onSubmitted: (_) => _entrar(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _senha,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                      onSubmitted: (_) => _entrar(),
                    ),
                    if (_erro.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 10), child: Text(_erro, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _entrando ? null : _entrar,
                        child: _entrando
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                        onPressed: _abrirConfiguracao,
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Configurar banco de dados')),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
