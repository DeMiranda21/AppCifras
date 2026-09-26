import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/entidades/lista_culto.dart';
import '../../dominio/erros/item_lista_culto_nao_encontrado.dart';
import '../../dominio/erros/lista_culto_nao_encontrada.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_item_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/repositorios/repositorio_listas_culto.dart';
import 'banco_biblioteca.dart';

class RepositorioListasCultoLocal implements RepositorioListasCulto {
  const RepositorioListasCultoLocal(this._banco);

  final BancoBiblioteca _banco;

  @override
  Future<void> salvar(ListaCulto lista) =>
      _banco.inserirListaCulto(id: lista.id.valor, nome: lista.nome);

  @override
  Future<ListaCulto?> obterPorId(IdListaCulto id) async {
    final lista = await _banco.obterListaCultoPorId(id.valor);
    if (lista == null) {
      return null;
    }
    return ListaCulto(id: IdListaCulto(lista.id), nome: lista.nome);
  }

  @override
  Future<List<ListaCulto>> listar() async {
    final listas = await _banco.listarListasCulto();
    return listas
        .map(
          (lista) => ListaCulto(id: IdListaCulto(lista.id), nome: lista.nome),
        )
        .toList(growable: false);
  }

  @override
  Future<void> renomear(IdListaCulto id, String nome) async {
    final lista = ListaCulto(id: id, nome: nome);
    final linhasAtualizadas = await _banco.renomearListaCulto(
      id: lista.id.valor,
      nome: lista.nome,
    );
    if (linhasAtualizadas != 1) {
      throw ListaCultoNaoEncontrada(id);
    }
  }

  @override
  Future<void> excluir(IdListaCulto id) async {
    final linhasExcluidas = await _banco.excluirListaCulto(id.valor);
    if (linhasExcluidas != 1) {
      throw ListaCultoNaoEncontrada(id);
    }
  }

  @override
  Future<List<ItemListaCulto>> listarItens(IdListaCulto idLista) async {
    await _exigirLista(idLista);
    final itens = await _banco.listarItensListaCulto(idLista.valor);
    return itens
        .map(
          (item) => ItemListaCulto(
            id: IdItemListaCulto(item.id),
            idLista: IdListaCulto(item.idLista),
            idMusica: IdMusica(item.idMusica),
            posicao: item.posicao,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> adicionarItem(ItemListaCulto item) async {
    await _exigirLista(item.idLista);
    if (await _banco.obterPorId(item.idMusica.valor) == null) {
      throw MusicaNaoEncontrada(item.idMusica);
    }
    final itens = await _banco.listarItensListaCulto(item.idLista.valor);
    if (item.posicao != itens.length) {
      throw ArgumentError.value(
        item.posicao,
        'item.posicao',
        'Novos itens devem ser adicionados ao final da lista.',
      );
    }
    await _banco.inserirItemListaCulto(
      id: item.id.valor,
      idLista: item.idLista.valor,
      idMusica: item.idMusica.valor,
      posicao: item.posicao,
    );
  }

  @override
  Future<void> removerItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
  ) async {
    await _exigirLista(idLista);
    final removidos = await _banco.removerItemListaCulto(
      idLista: idLista.valor,
      idItem: idItem.valor,
    );
    if (removidos != 1) {
      throw ItemListaCultoNaoEncontrado(idItem);
    }
  }

  @override
  Future<void> reordenarItens(
    IdListaCulto idLista,
    List<IdItemListaCulto> ordem,
  ) async {
    await _exigirLista(idLista);
    final itens = await _banco.listarItensListaCulto(idLista.valor);
    final idsAtuais = itens.map((item) => item.id).toSet();
    final idsInformados = ordem.map((id) => id.valor).toSet();
    if (ordem.length != itens.length ||
        idsInformados.length != ordem.length ||
        !idsInformados.containsAll(idsAtuais) ||
        !idsAtuais.containsAll(idsInformados)) {
      throw ArgumentError.value(
        ordem,
        'ordem',
        'A ordem deve conter exatamente todos os itens da lista, sem repetição.',
      );
    }
    await _banco.reordenarItensListaCulto(
      idLista: idLista.valor,
      idsNaOrdem: ordem.map((id) => id.valor).toList(growable: false),
    );
  }

  Future<void> _exigirLista(IdListaCulto id) async {
    if (await _banco.obterListaCultoPorId(id.valor) == null) {
      throw ListaCultoNaoEncontrada(id);
    }
  }
}
