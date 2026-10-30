import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/entidades/lista_culto.dart';
import '../../dominio/erros/item_lista_culto_nao_encontrado.dart';
import '../../dominio/erros/lista_culto_nao_encontrada.dart';
import '../../dominio/erros/ministrante_nao_encontrado.dart';
import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_item_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';
import '../../dominio/objetos_de_valor/data_culto.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_ministrante.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_listas_culto.dart';
import '../../dominio/repositorios/repositorio_ministrantes.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../portas/consulta_detalhe_lista_culto.dart';
import '../portas/gerador_id_item_lista_culto.dart';
import '../portas/gerador_id_lista_culto.dart';

class CriarListaCulto {
  CriarListaCulto(
    this._repositorio,
    this._geradorId, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  final RepositorioListasCulto _repositorio;
  final GeradorIdListaCulto _geradorId;
  final DateTime Function() _agora;

  Future<ListaCulto> executar(String nome) async {
    final lista = ListaCulto(
      id: _geradorId.gerar(),
      nome: nome,
      criadaEm: _agora().toUtc(),
    );
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

class AtualizarContextoListaCulto {
  const AtualizarContextoListaCulto(this._listas, this._ministrantes);

  final RepositorioListasCulto _listas;
  final RepositorioMinistrantes _ministrantes;

  Future<ListaCulto> executar(
    IdListaCulto id, {
    required DataCulto? data,
    required IdMinistrante? idMinistrante,
  }) async {
    final atual = await _listas.obterPorId(id);
    if (atual == null) throw ListaCultoNaoEncontrada(id);

    if (idMinistrante != null &&
        await _ministrantes.obterPorId(idMinistrante) == null) {
      throw MinistranteNaoEncontrado(idMinistrante);
    }

    await _listas.atualizarContexto(
      id,
      data: data,
      idMinistrante: idMinistrante,
    );
    return ListaCulto(
      id: atual.id,
      nome: atual.nome,
      data: data,
      idMinistrante: idMinistrante,
      criadaEm: atual.criadaEm,
    );
  }
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

class CarregarDetalheListaCulto {
  const CarregarDetalheListaCulto(this._consulta);

  final ConsultaDetalheListaCulto _consulta;

  Future<List<ItemDetalheListaCulto>> executar(IdListaCulto idLista) =>
      _consulta.carregar(idLista);
}

class AdicionarMusicaAListaCulto {
  const AdicionarMusicaAListaCulto(
    this._repositorio,
    this._geradorId, {
    this._repositorioVersoes,
  });

  final RepositorioListasCulto _repositorio;
  final GeradorIdItemListaCulto _geradorId;
  final RepositorioVersoesMusicas? _repositorioVersoes;

  Future<ItemListaCulto> executar(
    IdListaCulto idLista,
    IdMusica idMusica,
  ) async {
    final itens = await _repositorio.listarItens(idLista);
    final versaoPrincipal = await _repositorioVersoes?.obterPrincipalPorMusica(
      idMusica,
    );
    final idVersaoMusica =
        versaoPrincipal?.id ?? IdVersaoMusica(idMusica.valor);
    final item = ItemListaCulto(
      id: _geradorId.gerar(),
      idLista: idLista,
      idMusica: idMusica,
      idVersaoMusica: idVersaoMusica,
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

class TrocarVersaoItemListaCulto {
  const TrocarVersaoItemListaCulto(this._listas, this._versoes);

  final RepositorioListasCulto _listas;
  final RepositorioVersoesMusicas _versoes;

  Future<ItemListaCulto> executar(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
    IdVersaoMusica idVersaoMusica,
  ) async {
    final itens = await _listas.listarItens(idLista);
    ItemListaCulto? item;
    for (final candidato in itens) {
      if (candidato.id == idItem) item = candidato;
    }
    if (item == null) throw ItemListaCultoNaoEncontrado(idItem);

    final versao = await _versoes.obterVersaoPorId(idVersaoMusica);
    if (versao == null) throw VersaoMusicaNaoEncontrada(idVersaoMusica);
    if (versao.idMusica != item.idMusica) {
      throw ArgumentError('A versão deve pertencer à música do item.');
    }
    if (versao.arquivada) {
      throw ArgumentError('Uma versão arquivada não pode ser selecionada.');
    }
    if (item.idVersaoMusica == versao.id) return item;

    await _listas.atualizarVersaoItem(idLista, idItem, versao.id);
    return ItemListaCulto(
      id: item.id,
      idLista: item.idLista,
      idMusica: item.idMusica,
      idVersaoMusica: versao.id,
      posicao: item.posicao,
      tom: item.tom,
    );
  }
}

class ReordenarItensListaCulto {
  const ReordenarItensListaCulto(this._repositorio);

  final RepositorioListasCulto _repositorio;

  Future<void> executar(IdListaCulto idLista, List<IdItemListaCulto> ordem) =>
      _repositorio.reordenarItens(idLista, ordem);
}
