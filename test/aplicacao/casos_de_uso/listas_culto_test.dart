import 'package:appcifras/aplicacao/casos_de_uso/listas_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_item_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_lista_culto.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/entidades/ministrante.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/erros/ministrante_nao_encontrado.dart';
import 'package:appcifras/dominio/objetos_de_valor/data_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_ministrante.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/repositorios/repositorio_listas_culto.dart';
import 'package:appcifras/dominio/repositorios/repositorio_ministrantes.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria, renomeia, lista e exclui lista', () async {
    final repositorio = _RepositorioListasCultoFake();
    final instante = DateTime.utc(2026, 10, 29, 15, 30);
    final criar = CriarListaCulto(
      repositorio,
      _GeradorListaFake(IdListaCulto('lista-1')),
      agora: () => instante,
    );
    final lista = await criar.executar(' Culto ');

    expect(lista.nome, 'Culto');
    expect(lista.criadaEm, instante);
    expect(await ListarListasCulto(repositorio).executar(), [lista]);

    await RenomearListaCulto(repositorio).executar(lista.id, 'Ensaio');
    expect(
      await ObterListaCulto(repositorio).executar(lista.id),
      isA<ListaCulto>()
          .having((lista) => lista.nome, 'nome', 'Ensaio')
          .having((lista) => lista.criadaEm, 'criadaEm', instante),
    );

    await ExcluirListaCulto(repositorio).executar(lista.id);
    expect(await ObterListaCulto(repositorio).executar(lista.id), isNull);
  });

  test('criação converte o instante fornecido para UTC', () async {
    final local = DateTime.parse('2026-10-29T12:30:00-03:00');
    final lista = await CriarListaCulto(
      _RepositorioListasCultoFake(),
      _GeradorListaFake(IdListaCulto('lista-utc')),
      agora: () => local,
    ).executar('Culto');

    expect(lista.criadaEm, DateTime.utc(2026, 10, 29, 15, 30));
    expect(lista.criadaEm?.isUtc, isTrue);
  });

  test(
    'atualiza e limpa contexto preservando identidade, nome, criação e itens',
    () async {
      final listas = _RepositorioListasCultoFake();
      final ministrantes = _RepositorioMinistrantesFake();
      final criadaEm = DateTime.utc(2026, 10, 20, 18);
      final idLista = IdListaCulto('lista-contexto');
      final primeiroMinistrante = Ministrante(
        id: IdMinistrante('ministrante-1'),
        nome: 'Primeiro',
        arquivado: false,
      );
      final segundoMinistrante = Ministrante(
        id: IdMinistrante('ministrante-2'),
        nome: 'Segundo',
        arquivado: false,
      );
      await ministrantes.salvar(primeiroMinistrante);
      await ministrantes.salvar(segundoMinistrante);
      await listas.salvar(
        ListaCulto(id: idLista, nome: 'Culto', criadaEm: criadaEm),
      );
      const tom = Tom(
        notaFundamental: Nota(nome: NomeNota.d),
        modo: ModoTom.maior,
      );
      final item = ItemListaCulto(
        id: IdItemListaCulto('item-1'),
        idLista: idLista,
        idMusica: IdMusica('musica-1'),
        idVersaoMusica: IdVersaoMusica('versao-1'),
        posicao: 0,
        tom: tom,
      );
      await listas.adicionarItem(item);
      final atualizar = AtualizarContextoListaCulto(listas, ministrantes);

      final definida = await atualizar.executar(
        idLista,
        data: DataCulto(ano: 2026, mes: 11, dia: 2),
        idMinistrante: primeiroMinistrante.id,
      );
      final alterada = await atualizar.executar(
        idLista,
        data: DataCulto(ano: 2026, mes: 11, dia: 9),
        idMinistrante: segundoMinistrante.id,
      );
      final limpa = await atualizar.executar(
        idLista,
        data: null,
        idMinistrante: null,
      );

      expect(definida.idMinistrante, primeiroMinistrante.id);
      expect(alterada.idMinistrante, segundoMinistrante.id);
      expect(limpa.id, idLista);
      expect(limpa.nome, 'Culto');
      expect(limpa.data, isNull);
      expect(limpa.idMinistrante, isNull);
      expect(limpa.criadaEm, criadaEm);
      expect(await listas.listarItens(idLista), [item]);
    },
  );

  test('rejeita Ministrante inexistente sem alterar o contexto', () async {
    final listas = _RepositorioListasCultoFake();
    final lista = ListaCulto(
      id: IdListaCulto('lista-1'),
      nome: 'Culto',
      criadaEm: DateTime.utc(2026, 10, 20),
    );
    await listas.salvar(lista);

    await expectLater(
      AtualizarContextoListaCulto(
        listas,
        _RepositorioMinistrantesFake(),
      ).executar(
        lista.id,
        data: DataCulto(ano: 2026, mes: 11, dia: 2),
        idMinistrante: IdMinistrante('inexistente'),
      ),
      throwsA(isA<MinistranteNaoEncontrado>()),
    );
    expect(await listas.obterPorId(lista.id), same(lista));
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

  test('adiciona a versão principal da música ao ItemListaCulto', () async {
    final repositorio = _RepositorioListasCultoFake();
    final idLista = IdListaCulto('lista-1');
    final idMusica = IdMusica('musica-1');
    final versao = _versaoPrincipal(idMusica, IdVersaoMusica('versao-1'));
    await repositorio.salvar(ListaCulto(id: idLista, nome: 'Culto'));

    final item = await AdicionarMusicaAListaCulto(
      repositorio,
      _GeradorItemFake([IdItemListaCulto('item-1')]),
      repositorioVersoes: _RepositorioVersoesFake(versao),
    ).executar(idLista, idMusica);

    expect(item.idMusica, idMusica);
    expect(item.idVersaoMusica, versao.id);
  });
  test(
    'troca somente a versão do item por outra ativa da mesma música',
    () async {
      final listas = _RepositorioListasCultoFake();
      final idLista = IdListaCulto('lista-1');
      final idMusica = IdMusica('musica-1');
      final principal = _versaoPrincipal(idMusica, IdVersaoMusica('principal'));
      final alternativa = VersaoMusica(
        id: IdVersaoMusica('alternativa'),
        idMusica: idMusica,
        nome: 'Acústica',
        documento: principal.documento,
        principal: false,
        arquivada: false,
      );
      await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
      final item = ItemListaCulto(
        id: IdItemListaCulto('item-1'),
        idLista: idLista,
        idMusica: idMusica,
        idVersaoMusica: principal.id,
        posicao: 0,
      );
      await listas.adicionarItem(item);

      final trocado = await TrocarVersaoItemListaCulto(
        listas,
        _RepositorioVersoesColecao([principal, alternativa]),
      ).executar(idLista, item.id, alternativa.id);

      expect(trocado.id, item.id);
      expect(trocado.idMusica, item.idMusica);
      expect(trocado.posicao, item.posicao);
      expect(trocado.idVersaoMusica, alternativa.id);
      expect((await listas.listarItens(idLista)).single, trocado);
    },
  );

  test('rejeita versão arquivada e versão de outra música', () async {
    final listas = _RepositorioListasCultoFake();
    final idLista = IdListaCulto('lista-1');
    final principal = _versaoPrincipal(
      IdMusica('musica-1'),
      IdVersaoMusica('principal'),
    );
    final arquivada = VersaoMusica(
      id: IdVersaoMusica('arquivada'),
      idMusica: principal.idMusica,
      nome: 'Arquivada',
      documento: principal.documento,
      principal: false,
      arquivada: true,
    );
    final outra = _versaoPrincipal(
      IdMusica('musica-2'),
      IdVersaoMusica('outra'),
    );
    await listas.salvar(ListaCulto(id: idLista, nome: 'Culto'));
    final item = ItemListaCulto(
      id: IdItemListaCulto('item-1'),
      idLista: idLista,
      idMusica: principal.idMusica,
      idVersaoMusica: principal.id,
      posicao: 0,
    );
    await listas.adicionarItem(item);
    final trocar = TrocarVersaoItemListaCulto(
      listas,
      _RepositorioVersoesColecao([principal, arquivada, outra]),
    );

    await expectLater(
      trocar.executar(idLista, item.id, arquivada.id),
      throwsArgumentError,
    );
    await expectLater(
      trocar.executar(idLista, item.id, outra.id),
      throwsArgumentError,
    );
    expect(
      (await listas.listarItens(idLista)).single.idVersaoMusica,
      principal.id,
    );
  });
}

VersaoMusica _versaoPrincipal(IdMusica idMusica, IdVersaoMusica idVersao) =>
    VersaoMusica(
      id: idVersao,
      idMusica: idMusica,
      nome: 'Principal',
      documento: ParserDocumentoChordPro().interpretar(
        '{title: Título}\n{artist: Artista}\n{key: C}\n[C]Letra',
      ),
      principal: true,
      arquivada: false,
    );

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
          idVersaoMusica: itens[indice].idVersaoMusica,
          posicao: indice,
          tom: itens[indice].tom,
        ),
    ];
  }

  @override
  Future<void> renomear(IdListaCulto id, String nome) async {
    final atual = _listas[id]!;
    _listas[id] = ListaCulto(
      id: id,
      nome: nome,
      data: atual.data,
      idMinistrante: atual.idMinistrante,
      criadaEm: atual.criadaEm,
    );
  }

  @override
  Future<void> atualizarContexto(
    IdListaCulto id, {
    required DataCulto? data,
    required IdMinistrante? idMinistrante,
  }) async {
    final atual = _listas[id]!;
    _listas[id] = ListaCulto(
      id: id,
      nome: atual.nome,
      data: data,
      idMinistrante: idMinistrante,
      criadaEm: atual.criadaEm,
    );
  }

  @override
  Future<void> atualizarVersaoItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
    IdVersaoMusica idVersaoMusica,
  ) async {
    final itens = _itens[idLista]!;
    final indice = itens.indexWhere((item) => item.id == idItem);
    final item = itens[indice];
    itens[indice] = ItemListaCulto(
      id: item.id,
      idLista: item.idLista,
      idMusica: item.idMusica,
      idVersaoMusica: idVersaoMusica,
      posicao: item.posicao,
      tom: item.tom,
    );
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
          idVersaoMusica: porId[ordem[indice]]!.idVersaoMusica,
          posicao: indice,
          tom: porId[ordem[indice]]!.tom,
        ),
    ];
  }

  @override
  Future<void> salvar(ListaCulto lista) async {
    _listas[lista.id] = lista;
  }
}

class _RepositorioMinistrantesFake implements RepositorioMinistrantes {
  final Map<IdMinistrante, Ministrante> _ministrantes = {};

  @override
  Future<void> salvar(Ministrante ministrante) async {
    _ministrantes[ministrante.id] = ministrante;
  }

  @override
  Future<Ministrante?> obterPorId(IdMinistrante id) async => _ministrantes[id];

  @override
  Future<List<Ministrante>> listar({bool incluirArquivados = true}) async =>
      _ministrantes.values
          .where((ministrante) => incluirArquivados || !ministrante.arquivado)
          .toList();

  @override
  Future<void> renomear(IdMinistrante id, String nome) async {
    _ministrantes[id] = _ministrantes[id]!.renomear(nome);
  }

  @override
  Future<void> arquivar(IdMinistrante id) async {
    _ministrantes[id] = _ministrantes[id]!.arquivar();
  }

  @override
  Future<void> restaurar(IdMinistrante id) async {
    _ministrantes[id] = _ministrantes[id]!.restaurar();
  }
}

class _RepositorioVersoesFake implements RepositorioVersoesMusicas {
  const _RepositorioVersoesFake(this._principal);

  final VersaoMusica _principal;

  @override
  Future<void> atualizarConteudoVersao(VersaoMusica versao) async {
    throw UnimplementedError();
  }

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async =>
      idMusica == _principal.idMusica ? [_principal] : const [];

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async =>
      idMusica == _principal.idMusica ? _principal : null;

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async =>
      id == _principal.id ? _principal : null;

  @override
  Future<void> salvarVersao(VersaoMusica versao) async {}

  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) async => false;

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) async {}

  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) async {}

  @override
  Future<void> arquivar(IdVersaoMusica id) async {}

  @override
  Future<void> restaurar(IdVersaoMusica id) async {}

  @override
  Future<void> excluirVersao(IdVersaoMusica id) async {}
}

class _RepositorioVersoesColecao implements RepositorioVersoesMusicas {
  _RepositorioVersoesColecao(this.versoes);
  final List<VersaoMusica> versoes;

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async {
    for (final versao in versoes) {
      if (versao.id == id) return versao;
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
