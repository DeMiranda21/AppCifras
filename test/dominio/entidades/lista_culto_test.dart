import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ids de Lista de Culto', () {
    test('encapsulam valores não vazios e possuem igualdade pelo valor', () {
      expect(IdListaCulto('lista-1'), IdListaCulto('lista-1'));
      expect(IdItemListaCulto('item-1'), IdItemListaCulto('item-1'));
      expect(() => IdListaCulto('  '), throwsArgumentError);
      expect(() => IdItemListaCulto(''), throwsArgumentError);
    });
  });

  group('ListaCulto', () {
    test('normaliza nome válido e tem identidade definida pelo ID', () {
      final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: ' Culto ');
      final mesma = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Outro');

      expect(lista.nome, 'Culto');
      expect(lista, mesma);
    });

    test('rejeita nome vazio ou composto somente por espaços', () {
      expect(
        () => ListaCulto(id: IdListaCulto('lista-1'), nome: ' \t '),
        throwsArgumentError,
      );
    });
  });

  group('ItemListaCulto', () {
    test('guarda somente IDs e posição explícita', () {
      final item = ItemListaCulto(
        id: IdItemListaCulto('item-1'),
        idLista: IdListaCulto('lista-1'),
        idMusica: IdMusica('musica-1'),
        posicao: 2,
      );

      expect(item.idLista, IdListaCulto('lista-1'));
      expect(item.idMusica, IdMusica('musica-1'));
      expect(item.posicao, 2);
      expect(
        () => ItemListaCulto(
          id: IdItemListaCulto('item-2'),
          idLista: IdListaCulto('lista-1'),
          idMusica: IdMusica('musica-1'),
          posicao: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
