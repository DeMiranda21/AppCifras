import 'package:appcifras/infraestrutura/identidade/gerador_id_musica_uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera UUID v4 não vazio para a identidade da música', () {
    final gerador = GeradorIdMusicaUuid();

    final primeiro = gerador.gerar();
    final segundo = gerador.gerar();

    expect(primeiro.valor, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4')));
    expect(segundo.valor, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4')));
    expect(primeiro, isNot(segundo));
  });
}
