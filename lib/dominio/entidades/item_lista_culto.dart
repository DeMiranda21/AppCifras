import '../objetos_de_valor/id_item_lista_culto.dart';
import '../objetos_de_valor/id_lista_culto.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/id_versao_musica.dart';

class ItemListaCulto {
  ItemListaCulto({
    required this.id,
    required this.idLista,
    required this.idMusica,
    IdVersaoMusica? idVersaoMusica,
    required this.posicao,
  }) : idVersaoMusica = idVersaoMusica ?? IdVersaoMusica(idMusica.valor) {
    if (posicao < 0) {
      throw ArgumentError.value(
        posicao,
        'posicao',
        'A posição do item não pode ser negativa.',
      );
    }
  }

  final IdItemListaCulto id;
  final IdListaCulto idLista;
  final IdMusica idMusica;
  final IdVersaoMusica idVersaoMusica;
  final int posicao;

  @override
  bool operator ==(Object other) => other is ItemListaCulto && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
