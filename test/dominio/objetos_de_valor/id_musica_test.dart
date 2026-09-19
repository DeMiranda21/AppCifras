import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdMusica', () {
    test('encapsula um valor não vazio', () {
      expect(IdMusica('musica-1').valor, 'musica-1');
    });

    test('rejeita valor vazio ou composto apenas por espaços', () {
      expect(() => IdMusica(''), throwsArgumentError);
      expect(() => IdMusica(' \t '), throwsArgumentError);
    });

    test('possui igualdade pelo valor', () {
      expect(IdMusica('musica-1'), IdMusica('musica-1'));
      expect(IdMusica('musica-1'), isNot(IdMusica('musica-2')));
    });
  });
}
