import '../objetos_de_valor/id_item_lista_culto.dart';

class ItemListaCultoNaoEncontrado implements Exception {
  const ItemListaCultoNaoEncontrado(this.id);

  final IdItemListaCulto id;
}
