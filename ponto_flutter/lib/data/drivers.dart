import 'package:fbdb/fbdb.dart';

typedef DbRow = Map<String, dynamic>;

/// Acesso de baixo nível ao Firebird. Todas as consultas usam parâmetros posicionais `?`.
class FirebirdDriver {
  final FbDb _db;
  FirebirdDriver._(this._db);

  static FbOptions _opcoes(String? lib) => FbOptions(libFbClient: (lib ?? '').isEmpty ? null : lib, dbCharset: 'WIN1252');

  static Future<FirebirdDriver> connect(
      {required String host, required int port, required String database, required String user,
      required String password, String? libFbClient}) async {
    final db = await FbDb.attach(
      host: host.isEmpty ? null : host,
      port: port > 0 ? port : null,
      database: database,
      user: user,
      password: password,
      options: _opcoes(libFbClient),
    );
    return FirebirdDriver._(db);
  }

  /// Cria um novo arquivo de banco (charset WIN1252, igual ao ERP).
  static Future<FirebirdDriver> create(
      {required String host, required int port, required String database, required String user,
      required String password, String? libFbClient}) async {
    final db = await FbDb.createDatabase(
      host: host.isEmpty ? null : host,
      port: port > 0 ? port : null,
      database: database,
      user: user,
      password: password,
      options: _opcoes(libFbClient),
    );
    return FirebirdDriver._(db);
  }

  Future<List<DbRow>> query(String sql, List<dynamic> params) => _db.selectAll(sql: sql, parameters: params);

  Future<int> exec(String sql, List<dynamic> params) =>
      _db.execute(sql: sql, parameters: params, returnAffectedRows: true);

  /// `INSERT ... RETURNING CAMPO`: devolve {CAMPO: valor}.
  Future<DbRow?> execReturning(String sql, List<dynamic> params) async {
    final q = _db.query();
    try {
      await q.execute(sql: sql, parameters: params);
      return await q.getOutputAsMap();
    } finally {
      await q.close();
    }
  }

  Future<void> close() => _db.detach();
}
