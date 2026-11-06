// ignore_for_file: avoid_print
// Varre a rede local procurando relógios Control iD. Uso: dart run tool/descoberta_test.dart [usuario] [senha]
import 'package:ponto_flutter/services/descoberta_service.dart';

Future<void> main(List<String> args) async {
  final redes = await DescobertaService.redesLocais();
  print('Redes locais: $redes');
  final inicio = DateTime.now();
  final achados = await DescobertaService.procurar(
    usuario: args.isNotEmpty ? args[0] : 'admin',
    senha: args.length > 1 ? args[1] : 'admin',
    onEncontrado: (r) => print('  ENCONTRADO ${r.ip}:${r.porta} ssl=${r.ssl} auth=${r.autenticado} ${r.descricao}'),
  );
  print('${achados.length} relógio(s) em ${DateTime.now().difference(inicio).inSeconds}s');
}
