import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/entidades/lista_culto.dart';
import '../../dominio/objetos_de_valor/id_item_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/repositorios/repositorio_listas_culto.dart';
import '../portas/gerador_id_item_lista_culto.dart';
import '../portas/gerador_id_lista_culto.dart';

class CriarListaCulto {
  const CriarListaCulto(this._repositorio, this._geradorId);

  final RepositorioListasCulto _repositorio;
  final GeradorIdListaCulto _geradorId;

  Future<ListaCulto> executar(String nome) async {
    final lista = ListaCulto(id: _geradorId.gerar(), nome: nome);
    await _repositorio.salvar(lista);
    return lista;
  }
}

class ListarListasCulto {
  const ListarListasCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<List<ListaCulto>> executar() => _repositorio.listar();
}

class ObterListaCulto {
  const ObterListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<ListaCulto?> executar(IdListaCulto id) => _repositorio.obterPorId(id);
}

class RenomearListaCulto {
  const RenomearListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<void> executar(IdListaCulto id, String nome) =>
      _repositorio.renomear(id, nome);
}

class ExcluirListaCulto {
  const ExcluirListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<void> executar(IdListaCulto id) => _repositorio.excluir(id);
}

class ListarItensListaCulto {
  const ListarItensListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<List<ItemListaCulto>> executar(IdListaCulto idLista) =>
      _repositorio.listarItens(idLista);
}

class AdicionarMusicaAListaCulto {
  const AdicionarMusicaAListaCulto(this._repositorio, this._geradorId);

  final RepositorioListasCulto _repositorio;
  final GeradorIdItemListaCulto _geradorId;

  Future<ItemListaCulto> executar(
    IdListaCulto idLista,
    IdMusica idMusica,
  ) async {
    final itens = await _repositorio.listarItens(idLista);
    final item = ItemListaCulto(
      id: _geradorId.gerar(),
      idLista: idLista,
      idMusica: idMusica,
      posicao: itens.length,
    );
    await _repositorio.adicionarItem(item);
    return item;
  }
}

class RemoverItemListaCulto {
  const RemoverItemListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<void> executar(IdListaCulto idLista, IdItemListaCulto idItem) =>
      _repositorio.removerItem(idLista, idItem);
}

class ReordenarItensListaCulto {
  const ReordenarItensListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<void> executar(IdListaCulto idLista, List<IdItemListaCulto> ordem) =>
      _repositorio.reordenarItens(idLista, ordem);
}
