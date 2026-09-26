import 'package:appcifras/aplicacao/casos_de_uso/listas_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_item_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_lista_culto.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_listas_culto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria, renomeia, lista e exclui lista', () async {
    final repositorio = _RepositorioListasCultoFake();
    final criar = CriarListaCulto(
      repositorio,
      _GeradorListaFake(IdListaCulto('lista-1')),
    );
    final lista = await criar.executar(' Culto ');

    expect(lista.nome, 'Culto');
    expect(await ListarListasCulto(repositorio).executar(), [lista]);

    await RenomearListaCulto(repositorio).executar(lista.id, 'Ensaio');
    expect(
      (await ObterListaCulto(repositorio).executar(lista.id))!.nome,
      'Ensaio',
    );

    await ExcluirListaCulto(repositorio).executar(lista.id);
    expect(await ObterListaCulto(repositorio).executar(lista.id), isNull);
  });

  test('adiciona a mesma música como itens independentes e reordena', () async {
    final repositorio = _RepositorioListasCultoFake();
    final idLista = IdListaCulto('lista-1');
    await repositorio.salvar(ListaCulto(id: idLista, nome: 'Culto'));
    final adicionar = AdicionarMusicaAListaCulto(
      repositorio,
      _GeradorItemFake([
        IdItemListaCulto('item-1'),
        IdItemListaCulto('item-2'),
        IdItemListaCulto('item-3'),
      ]),
    );

    final primeiro = await adicionar.executar(idLista, IdMusica('musica-a'));
    final segundo = await adicionar.executar(idLista, IdMusica('musica-b'));
    final terceiro = await adicionar.executar(idLista, IdMusica('musica-a'));

    expect(primeiro.id, isNot(terceiro.id));
    expect(
      (await ListarItensListaCulto(repositorio).executar(idLista))
          .map((item) => item.idMusica.valor),
      ['musica-a', 'musica-b', 'musica-a'],
    );

    await ReordenarItensListaCulto(repositorio)
        .executar(idLista, [terceiro.id, primeiro.id, segundo.id]);
    expect(
      (await ListarItensListaCulto(repositorio).executar(idLista))
          .map((item) => item.posicao),
      [0, 1, 2],
    );

    await RemoverItemListaCulto(repositorio).executar(idLista, primeiro.id);
    expect(
      (await ListarItensListaCulto(repositorio).executar(idLista))
          .map((item) => item.posicao),
      [0, 1],
    );
  });
}

class _GeradorListaFake implements GeradorIdListaCulto {
  const _GeradorListaFake(this._id);

  final IdListaCulto _id;

  @override
  IdListaCulto gerar() => _id;
}

class _GeradorItemFake implements GeradorIdItemListaCulto {
  _GeradorItemFake(this._ids);

  final List<IdItemListaCulto> _ids;

  @override
  IdItemListaCulto gerar() => _ids.removeAt(0);
}

class _RepositorioListasCultoFake implements RepositorioListasCulto {
  final Map<IdListaCulto, ListaCulto> _listas = {};
  final Map<IdListaCulto, List<ItemListaCulto>> _itens = {};

  @override
  Future<void> adicionarItem(ItemListaCulto item) async {
    _itens.putIfAbsent(item.idLista, () => []).add(item);
  }

  @override
  Future<void> excluir(IdListaCulto id) async {
    _listas.remove(id);
    _itens.remove(id);
  }

  @override
  Future<List<ListaCulto>> listar() async => _listas.values.toList();

  @override
  Future<List<ItemListaCulto>> listarItens(IdListaCulto idLista) async {
    final itens = List<ItemListaCulto>.of(_itens[idLista] ?? [])
      ..sort((a, b) => a.posicao.compareTo(b.posicao));
    return itens;
  }

  @override
  Future<ListaCulto?> obterPorId(IdListaCulto id) async => _listas[id];

  @override
  Future<void> removerItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
  ) async {
    final itens = _itens[idLista] ?? [];
    itens.removeWhere((item) => item.id == idItem);
    _itens[idLista] = [
      for (var indice = 0; indice < itens.length; indice++)
        ItemListaCulto(
          id: itens[indice].id,
          idLista: itens[indice].idLista,
          idMusica: itens[indice].idMusica,
          posicao: indice,
        ),
    ];
  }

  @override
  Future<void> renomear(IdListaCulto id, String nome) async {
    _listas[id] = ListaCulto(id: id, nome: nome);
  }

  @override
  Future<void> reordenarItens(
    IdListaCulto idLista,
    List<IdItemListaCulto> ordem,
  ) async {
    final porId = {for (final item in _itens[idLista] ?? []) item.id: item};
    _itens[idLista] = [
      for (var indice = 0; indice < ordem.length; indice++)
        ItemListaCulto(
          id: porId[ordem[indice]]!.id,
          idLista: idLista,
          idMusica: porId[ordem[indice]]!.idMusica,
          posicao: indice,
        ),
    ];
  }

  @override
  Future<void> salvar(ListaCulto lista) async {
    _listas[lista.id] = lista;
  }
}
