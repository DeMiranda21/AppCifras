import '../entidades/item_lista_culto.dart';
import '../entidades/lista_culto.dart';
import '../objetos_de_valor/id_item_lista_culto.dart';
import '../objetos_de_valor/id_lista_culto.dart';

abstract interface class RepositorioListasCulto {
  Future<void> salvar(ListaCulto lista);

  Future<ListaCulto?> obterPorId(IdListaCulto id);

  Future<List<ListaCulto>> listar();

  Future<void> renomear(IdListaCulto id, String nome);

  Future<void> excluir(IdListaCulto id);

  Future<List<ItemListaCulto>> listarItens(IdListaCulto idLista);

  Future<void> adicionarItem(ItemListaCulto item);

  Future<void> removerItem(IdListaCulto idLista, IdItemListaCulto idItem);

  Future<void> reordenarItens(
    IdListaCulto idLista,
    List<IdItemListaCulto> ordem,
  );
}
