import 'dart:io';

import 'package:ini/ini.dart';
import 'package:path/path.dart' as p;

/// Integrações de relógio de ponto suportadas.
enum TipoRelogio { controlId, hamsterDx }

String tipoRelogioParaStr(TipoRelogio t) =>
    t == TipoRelogio.hamsterDx ? 'HAMSTER_DX' : 'CONTROLID';

TipoRelogio strParaTipoRelogio(String v) =>
    v.trim().toUpperCase() == 'HAMSTER_DX' ? TipoRelogio.hamsterDx : TipoRelogio.controlId;

String tipoRelogioDescricao(TipoRelogio t) => t == TipoRelogio.hamsterDx
    ? 'Leitor Biométrico Nitgen Hamster DX (USB)'
    : 'Relógio de Ponto Control iD (Rede / API)';

class FirebirdConfig {
  String database = r'D:\OneDrive\DADOS\DUSUCO\PONTO.FDB'; // base exclusiva do ponto
  String server = 'localhost';
  int port = 3060;
  String user = 'SYSDBA';
  String password = 'masterkey';
  // Aplicativo Flutter Windows é 64 bits: precisa do fbclient.dll de 64 bits
  String vendorLib = r'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';
  String charset = 'WIN1252';
}

class ControlIdDefaultConfig {
  String ip = '192.168.1.200';
  int porta = 80;
  bool usarSsl = false;
  String usuario = 'admin';
  String senha = 'admin';
  int intervaloColetaSegundos = 60;
  String modoColeta = 'API';
  bool portaria671 = true;
  bool autoIniciarColeta = true;
}

class AtualizacaoConfig {
  bool autoAtualizar = true;
  int intervaloVerificacaoMin = 60;
  String ultimaVista = ''; // última versão/build cujas novidades já foram mostradas ("2.4.0.3")
}

/// Exportação para a folha de pagamento (códigos das rubricas no sistema da contabilidade).
class FolhaConfig {
  String rubricaHorasNormais = '001';
  String rubricaExtras50 = '150';
  String rubricaExtras100 = '200';
  String rubricaNoturno = '025';
  String rubricaFaltas = '040';
  String rubricaAtrasos = '045';
  String rubricaDsr = '046'; // DSR descontado (dias)
  // Faixas de horas extras em dias normais (convenção coletiva): até [extraFaixa1Min] no dia = pctFaixa1; acima = pctFaixa2
  int extraFaixa1Min = 120;
  int pctFaixa1 = 50, pctFaixa2 = 50, pctDomingoFeriado = 100;
  String rubricaExtrasFaixa2 = '155';
  String rubricaIntervalo = '160'; // intervalo intrajornada suprimido (art. 71 §4º)
  String rubricaInterjornada = '170'; // horas faltantes de descanso entre jornadas (art. 66)
  int bancoHorasValidadeMeses = 6; // banco individual: 6 meses (art. 59 §5º)
  String certificadoA1 = ''; // .pfx para assinar AEJ/AFD (.p7s)
  String certificadoSenha = '';
  String formatoHoras = 'DECIMAL'; // DECIMAL (8,50) ou HHMM (08:30)
  bool noturnaReduzida = true; // hora noturna de 52m30s (CLT art. 73)
  String desenvolvedorCnpj = ''; // registro 08 do AEJ
  String desenvolvedorNome = 'Go Up';
  String desenvolvedorEmail = '';
}

/// Modo online Control iD: o equipamento envia cada identificação para este computador.
class OnlineConfig {
  bool ativo = false;
  int porta = 8080;
  int portaFechadura = 1;
}

/// Backup automático da base do ponto.
class BackupConfig {
  bool ativo = true;
  String pasta = '';
  int manter = 15; // quantidade de cópias guardadas
}

class RelogioConfig {
  TipoRelogio tipo = TipoRelogio.controlId;
  int nivelSeguranca = 5; // 1 (tolerante) a 9 (rigoroso)
  int intervaloMinimoBatidaMin = 2;
  bool abrirTerminalAoIniciar = false;
  bool imprimirComprovante = false; // comprovante de registro na impressora padrão a cada batida
}

/// Configuração do aplicativo, lida/gravada em Config.ini ao lado do executável
/// (mesmo formato do sistema Delphi, então o arquivo antigo pode ser reaproveitado).
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  late String iniPath;
  final firebird = FirebirdConfig();
  final controlId = ControlIdDefaultConfig();
  final atualizacao = AtualizacaoConfig();
  final relogio = RelogioConfig();
  final online = OnlineConfig();
  final backup = BackupConfig();
  final folha = FolhaConfig();

  bool get modoHamsterDx => relogio.tipo == TipoRelogio.hamsterDx;

  static String get pastaExe => p.dirname(Platform.resolvedExecutable);

  void load([String? path]) {
    iniPath = path ?? p.join(pastaExe, 'Config.ini');
    final f = File(iniPath);
    if (!f.existsSync()) {
      save();
      return;
    }
    final ini = Config.fromStrings(f.readAsLinesSync());
    String s(String sec, String key, String def) {
      final v = ini.get(sec, key);
      return (v == null) ? def : v.trim();
    }

    int i(String sec, String key, int def) => int.tryParse(s(sec, key, '$def')) ?? def;
    bool b(String sec, String key, bool def) => s(sec, key, def ? 'S' : 'N').toUpperCase() == 'S';

    firebird
      // Base exclusiva do ponto ([PONTO]): nunca reaproveita o Database do ERP gravado pelo sistema Delphi
      ..database = s('PONTO', 'Database', firebird.database)
      ..server = s('FIREBIRD', 'Server', firebird.server)
      ..port = i('FIREBIRD', 'Port', firebird.port)
      ..user = s('FIREBIRD', 'User', firebird.user)
      ..password = s('FIREBIRD', 'Password', firebird.password)
      ..vendorLib = s('FIREBIRD', 'VendorLib', firebird.vendorLib)
      ..charset = s('FIREBIRD', 'Charset', firebird.charset);
    if (!File(firebird.vendorLib).existsSync()) {
      final local = p.join(pastaExe, 'fbclient.dll');
      if (File(local).existsSync()) {
        firebird.vendorLib = local;
      } else if (File(r'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll').existsSync()) {
        firebird.vendorLib = r'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';
      }
    }


    controlId
      ..ip = s('CONTROLID', 'IP', controlId.ip)
      ..porta = i('CONTROLID', 'Porta', controlId.porta)
      ..usarSsl = b('CONTROLID', 'UsarSSL', false)
      ..usuario = s('CONTROLID', 'Usuario', controlId.usuario)
      ..senha = s('CONTROLID', 'Senha', controlId.senha)
      ..intervaloColetaSegundos = i('CONTROLID', 'IntervaloColetaSegundos', controlId.intervaloColetaSegundos)
      ..modoColeta = s('CONTROLID', 'ModoColeta', controlId.modoColeta)
      ..portaria671 = b('CONTROLID', 'Portaria671', true)
      // Coleta automática: ligada por padrão (chave nova; o AutoIniciarColeta=N do Config.ini do Delphi é ignorado)
      ..autoIniciarColeta = b('COLETA', 'Automatica', true);

    atualizacao
      ..autoAtualizar = b('ATUALIZACAO', 'AutoAtualizar', true)
      ..intervaloVerificacaoMin = i('ATUALIZACAO', 'IntervaloVerificacaoMin', 60);
    atualizacao.ultimaVista = s('ATUALIZACAO', 'UltimaVista', '');
    if (atualizacao.intervaloVerificacaoMin < 5) atualizacao.intervaloVerificacaoMin = 5;

    relogio
      ..tipo = strParaTipoRelogio(s('RELOGIO', 'Tipo', tipoRelogioParaStr(relogio.tipo)))
      ..nivelSeguranca = i('RELOGIO', 'NivelSeguranca', 5)
      ..intervaloMinimoBatidaMin = i('RELOGIO', 'IntervaloMinimoBatidaMin', 2)
      ..abrirTerminalAoIniciar = b('RELOGIO', 'AbrirTerminalAoIniciar', false)
      ..imprimirComprovante = b('RELOGIO', 'ImprimirComprovante', false);
    if (relogio.nivelSeguranca < 1 || relogio.nivelSeguranca > 9) relogio.nivelSeguranca = 5;
    online
      ..ativo = b('ONLINE', 'Ativo', false)
      ..porta = i('ONLINE', 'Porta', 8080)
      ..portaFechadura = i('ONLINE', 'PortaFechadura', 1);
    backup
      ..ativo = b('BACKUP', 'Ativo', true)
      ..pasta = s('BACKUP', 'Pasta', '')
      ..manter = i('BACKUP', 'Manter', 15);
    folha
      ..rubricaHorasNormais = s('FOLHA', 'RubricaHorasNormais', folha.rubricaHorasNormais)
      ..rubricaExtras50 = s('FOLHA', 'RubricaExtras50', folha.rubricaExtras50)
      ..rubricaExtras100 = s('FOLHA', 'RubricaExtras100', folha.rubricaExtras100)
      ..rubricaNoturno = s('FOLHA', 'RubricaNoturno', folha.rubricaNoturno)
      ..rubricaFaltas = s('FOLHA', 'RubricaFaltas', folha.rubricaFaltas)
      ..rubricaAtrasos = s('FOLHA', 'RubricaAtrasos', folha.rubricaAtrasos)
      ..rubricaDsr = s('FOLHA', 'RubricaDsr', folha.rubricaDsr)
      ..extraFaixa1Min = i('FOLHA', 'ExtraFaixa1Min', 120)
      ..pctFaixa1 = i('FOLHA', 'PctFaixa1', 50)
      ..pctFaixa2 = i('FOLHA', 'PctFaixa2', 50)
      ..pctDomingoFeriado = i('FOLHA', 'PctDomingoFeriado', 100)
      ..rubricaExtrasFaixa2 = s('FOLHA', 'RubricaExtrasFaixa2', folha.rubricaExtrasFaixa2)
      ..rubricaIntervalo = s('FOLHA', 'RubricaIntervalo', folha.rubricaIntervalo)
      ..rubricaInterjornada = s('FOLHA', 'RubricaInterjornada', folha.rubricaInterjornada)
      ..bancoHorasValidadeMeses = i('FOLHA', 'BancoHorasValidadeMeses', 6)
      ..certificadoA1 = s('FOLHA', 'CertificadoA1', '')
      ..certificadoSenha = s('FOLHA', 'CertificadoSenha', '')
      ..formatoHoras = s('FOLHA', 'FormatoHoras', folha.formatoHoras).toUpperCase() == 'HHMM' ? 'HHMM' : 'DECIMAL'
      ..noturnaReduzida = b('FOLHA', 'NoturnaReduzida', true)
      ..desenvolvedorCnpj = s('FOLHA', 'DesenvolvedorCnpj', folha.desenvolvedorCnpj)
      ..desenvolvedorNome = s('FOLHA', 'DesenvolvedorNome', folha.desenvolvedorNome)
      ..desenvolvedorEmail = s('FOLHA', 'DesenvolvedorEmail', folha.desenvolvedorEmail);
    if (relogio.intervaloMinimoBatidaMin < 0) relogio.intervaloMinimoBatidaMin = 0;
  }

  void save() {
    final ini = Config();
    void w(String sec, String key, Object v) {
      if (!ini.hasSection(sec)) ini.addSection(sec);
      ini.set(sec, key, '$v');
    }

    String sn(bool v) => v ? 'S' : 'N';


    w('PONTO', 'Database', firebird.database);
    w('FIREBIRD', 'Server', firebird.server);
    w('FIREBIRD', 'Port', firebird.port);
    w('FIREBIRD', 'User', firebird.user);
    w('FIREBIRD', 'Password', firebird.password);
    w('FIREBIRD', 'VendorLib', firebird.vendorLib);
    w('FIREBIRD', 'Charset', firebird.charset);

    w('CONTROLID', 'IP', controlId.ip);
    w('CONTROLID', 'Porta', controlId.porta);
    w('CONTROLID', 'UsarSSL', sn(controlId.usarSsl));
    w('CONTROLID', 'Usuario', controlId.usuario);
    w('CONTROLID', 'Senha', controlId.senha);
    w('CONTROLID', 'IntervaloColetaSegundos', controlId.intervaloColetaSegundos);
    w('CONTROLID', 'ModoColeta', controlId.modoColeta);
    w('CONTROLID', 'Portaria671', sn(controlId.portaria671));
    w('COLETA', 'Automatica', sn(controlId.autoIniciarColeta));

    w('ATUALIZACAO', 'AutoAtualizar', sn(atualizacao.autoAtualizar));
    w('ATUALIZACAO', 'IntervaloVerificacaoMin', atualizacao.intervaloVerificacaoMin);
    w('ATUALIZACAO', 'UltimaVista', atualizacao.ultimaVista);

    w('RELOGIO', 'Tipo', tipoRelogioParaStr(relogio.tipo));
    w('RELOGIO', 'NivelSeguranca', relogio.nivelSeguranca);
    w('RELOGIO', 'IntervaloMinimoBatidaMin', relogio.intervaloMinimoBatidaMin);
    w('RELOGIO', 'AbrirTerminalAoIniciar', sn(relogio.abrirTerminalAoIniciar));
    w('RELOGIO', 'ImprimirComprovante', sn(relogio.imprimirComprovante));

    w('ONLINE', 'Ativo', sn(online.ativo));
    w('ONLINE', 'Porta', online.porta);
    w('ONLINE', 'PortaFechadura', online.portaFechadura);
    w('BACKUP', 'Ativo', sn(backup.ativo));
    w('BACKUP', 'Pasta', backup.pasta);
    w('BACKUP', 'Manter', backup.manter);
    w('FOLHA', 'RubricaHorasNormais', folha.rubricaHorasNormais);
    w('FOLHA', 'RubricaExtras50', folha.rubricaExtras50);
    w('FOLHA', 'RubricaExtras100', folha.rubricaExtras100);
    w('FOLHA', 'RubricaNoturno', folha.rubricaNoturno);
    w('FOLHA', 'RubricaFaltas', folha.rubricaFaltas);
    w('FOLHA', 'RubricaAtrasos', folha.rubricaAtrasos);
    w('FOLHA', 'RubricaDsr', folha.rubricaDsr);
    w('FOLHA', 'ExtraFaixa1Min', folha.extraFaixa1Min);
    w('FOLHA', 'PctFaixa1', folha.pctFaixa1);
    w('FOLHA', 'PctFaixa2', folha.pctFaixa2);
    w('FOLHA', 'PctDomingoFeriado', folha.pctDomingoFeriado);
    w('FOLHA', 'RubricaExtrasFaixa2', folha.rubricaExtrasFaixa2);
    w('FOLHA', 'RubricaIntervalo', folha.rubricaIntervalo);
    w('FOLHA', 'RubricaInterjornada', folha.rubricaInterjornada);
    w('FOLHA', 'BancoHorasValidadeMeses', folha.bancoHorasValidadeMeses);
    w('FOLHA', 'CertificadoA1', folha.certificadoA1);
    w('FOLHA', 'CertificadoSenha', folha.certificadoSenha);
    w('FOLHA', 'FormatoHoras', folha.formatoHoras);
    w('FOLHA', 'NoturnaReduzida', sn(folha.noturnaReduzida));
    w('FOLHA', 'DesenvolvedorCnpj', folha.desenvolvedorCnpj);
    w('FOLHA', 'DesenvolvedorNome', folha.desenvolvedorNome);
    w('FOLHA', 'DesenvolvedorEmail', folha.desenvolvedorEmail);

    File(iniPath).writeAsStringSync(ini.toString());
  }
}
