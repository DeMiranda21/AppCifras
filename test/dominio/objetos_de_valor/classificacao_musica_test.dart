import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('energia possui opções estáveis para apresentação', () {
    expect(EnergiaMusica.values, [
      EnergiaMusica.calma,
      EnergiaMusica.moderada,
      EnergiaMusica.animada,
    ]);
    expect(EnergiaMusica.calma.titulo, 'Calma');
    expect(EnergiaMusica.moderada.titulo, 'Moderada');
    expect(EnergiaMusica.animada.titulo, 'Animada');
  });

  test('tag remove espaços externos e rejeita valor vazio', () {
    expect(TagMusica('  Ceia  ').valor, 'Ceia');
    expect(() => TagMusica('   '), throwsArgumentError);
  });

  test('identidade da tag ignora maiúsculas mas preserva acentos', () {
    expect(TagMusica('Ceia'), TagMusica('ceia'));
    expect(TagMusica('Graça'), isNot(TagMusica('Graca')));
    expect(TagMusica('Graça').valor, 'Graça');
  });
}
