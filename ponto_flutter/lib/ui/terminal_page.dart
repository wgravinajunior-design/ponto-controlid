import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import '../services/comprovante_service.dart';
import '../services/hamster.dart';
import 'app_state.dart';

/// Terminal de ponto biométrico (port de uFrmTerminalPonto): identificação 1:N contínua.
class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});
  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _app = AppState.instance;
  HamsterTerminal? _term;
  StreamSubscription<EventoLeitor>? _sub;
  Timer? _relogio, _limpar;
  DateTime _agora = DateTime.now();
  String _status = 'Iniciando leitor biométrico...';
  String _nome = '', _detalhe = '';
  Color _cor = Colors.blueGrey;
  IconData _icone = Icons.fingerprint;
  final _ultimas = <String>[];
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _agora = DateTime.now()));
    _iniciar();
  }

  Future<void> _iniciar() async {
    final digitais = await Db.instance.getDigitaisCadastradas();
    if (digitais.isEmpty) {
      setState(() {
        _status = 'Nenhuma digital cadastrada. Cadastre as digitais na aba Colaboradores.';
        _cor = Colors.orange;
      });
      return;
    }
    _term = await HamsterDx.iniciarTerminal(digitais, AppConfig.instance.relogio.nivelSeguranca);
    _sub = _term!.eventos.listen(_evento, onDone: () {
      if (mounted) setState(() => _status = 'Leitor encerrado.');
    });
    _app.logTs('👆 Terminal de Ponto aberto: ${digitais.length} digital(is) carregada(s).');
  }

  void _mostrar(String nome, String detalhe, Color cor, IconData icone) {
    _limpar?.cancel();
    setState(() {
      _nome = nome;
      _detalhe = detalhe;
      _cor = cor;
      _icone = icone;
    });
    _limpar = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _nome = '';
          _detalhe = '';
          _cor = Colors.blueGrey;
          _icone = Icons.fingerprint;
        });
      }
    });
  }

  Future<void> _evento(EventoLeitor e) async {
    switch (e.tipo) {
      case 'ready':
        setState(() => _status = 'Posicione o dedo no leitor para registrar o ponto');
      case 'nomatch':
        _mostrar('Digital não reconhecida', 'Tente novamente', Colors.red, Icons.block);
      case 'error':
        setState(() => _status = e.mensagem);
      case 'match':
        if (_processando) return;
        _processando = true;
        try {
          final d = e.digital!;
          final agora = DateTime.now();
          final r = await Db.instance
              .registrarBatidaBiometrica(d.pessoaId, agora, AppConfig.instance.relogio.intervaloMinimoBatidaMin);
          final tipo = r.tipoBatida == 'S' ? 'SAÍDA' : 'ENTRADA';
          switch (r.resultado) {
            case ResultadoBatida.registrada:
              _mostrar(d.nome, '$tipo registrada às ${fmtHoraSeg(agora)}', Colors.green.shade700, Icons.check_circle);
              _ultimas.insert(0, '${fmtHoraSeg(agora)}  $tipo  ${d.nome}');
              if (_ultimas.length > 8) _ultimas.removeLast();
              _app.logTs('👆 Batida biométrica: ${d.nome} - $tipo às ${fmtHoraSeg(agora)}');
              // Comprovante de registro (Portaria 671, art. 82)
              final comp = await ComprovanteService.gerar(r.marcacaoId);
              if (comp != null && AppConfig.instance.relogio.imprimirComprovante) await ComprovanteService.imprimir(comp);
              _app.dadosAlterados();
            case ResultadoBatida.repetida:
              _mostrar(d.nome, 'Batida já registrada às ${fmtHora(r.ultimaBatida)}', Colors.orange.shade700, Icons.info);
            case ResultadoBatida.erro:
              _mostrar(d.nome, Db.instance.lastError, Colors.red, Icons.error);
              _app.logTs('❌ ${Db.instance.lastError}', true);
          }
        } finally {
          _processando = false;
        }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _term?.parar();
    _relogio?.cancel();
    _limpar?.cancel();
    _app.logTs('👆 Terminal de Ponto fechado.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14243B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14243B),
        foregroundColor: Colors.white,
        title: const Text('Terminal de Ponto Biométrico'),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(fmtHoraSeg(_agora),
              style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w300, color: Colors.white)),
          Text(fmtData(_agora), style: const TextStyle(fontSize: 26, color: Colors.white70)),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 640,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: _cor, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Icon(_icone, size: 96, color: Colors.white),
              const SizedBox(height: 12),
              Text(_nome.isEmpty ? 'Aguardando digital...' : _nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_detalhe.isNotEmpty)
                Text(_detalhe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 20),
          Text(_status, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 20),
          for (final u in _ultimas) Text(u, style: const TextStyle(color: Colors.white54, fontFamily: 'Consolas')),
        ]),
      ),
    );
  }
}
