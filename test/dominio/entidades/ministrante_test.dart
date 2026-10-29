import 'package:appcifras/dominio/entidades/ministrante.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_ministrante.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IdMinistrante aceita valor válido e rejeita vazio', () {
    expect(IdMinistrante('ministrante-1'), IdMinistrante('ministrante-1'));
    expect(() => IdMinistrante('  '), throwsArgumentError);
  });

  test('normaliza nome e preserva identidade ao renomear e arquivar', () {
    final original = Ministrante(
      id: IdMinistrante('ministrante-1'),
      nome: ' Lucas ',
      arquivado: false,
    );
    final renomeado = original.renomear(' Outro nome ');
    final arquivado = renomeado.arquivar();
    final restaurado = arquivado.restaurar();

    expect(original.nome, 'Lucas');
    expect(renomeado.nome, 'Outro nome');
    expect(renomeado.id, original.id);
    expect(arquivado.arquivado, isTrue);
    expect(restaurado.arquivado, isFalse);
    expect(restaurado.id, original.id);
  });

  test('rejeita nome vazio e permite nomes iguais com IDs distintos', () {
    expect(
      () => Ministrante(
        id: IdMinistrante('ministrante-1'),
        nome: ' ',
        arquivado: false,
      ),
      throwsArgumentError,
    );
    final primeiro = Ministrante(
      id: IdMinistrante('ministrante-1'),
      nome: 'Nome igual',
      arquivado: false,
    );
    final segundo = Ministrante(
      id: IdMinistrante('ministrante-2'),
      nome: 'Nome igual',
      arquivado: false,
    );
    expect(primeiro, isNot(segundo));
  });
}
