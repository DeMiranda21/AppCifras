import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';

class ItemDetalheListaCulto {
  const ItemDetalheListaCulto({
    required this.item,
    required this.titulo,
    required this.artista,
    required this.versao,
  });

  final ItemListaCulto item;
  final String titulo;
  final String artista;
  final VersaoMusica? versao;
}

abstract interface class ConsultaDetalheListaCulto {
  Future<List<ItemDetalheListaCulto>> carregar(IdListaCulto idLista);
}
