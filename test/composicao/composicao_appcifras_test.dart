import 'package:appcifras/aplicacao/portas/gerador_id_item_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_lista_culto.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_ministrante.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/aplicacao/portas/repositorio_tom_execucao.dart';
import 'package:appcifras/composicao/composicao_appcifras.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/data_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_ministrante.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/repositorios/repositorio_listas_culto.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_ministrantes_local.dart';
import 'package:appcifras/apresentacao/biblioteca/tela_biblioteca.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composição expõe fechamento de Listas e Ministrantes', () async {
    final parser = ParserDocumentoChordPro();
    final musica = Musica(
      id: IdMusica('musica-1'),
      documento: parser.interpretar(
        '{title: Música}\n{artist: Artista}\n{key: C}\n[C]Letra',
      ),
    );
    final banco = BancoBiblioteca(NativeDatabase.memory());
    await banco.inicializar();
    addTearDown(banco.close);
    final instante = DateTime.utc(2026, 10, 29, 18);
    final composicao = ComposicaoAppCifras.paraTeste(
      banco: banco,
      repositorio: _RepositorioMusicasMemoria(musica),
      repositorioListasCulto: RepositorioListasCultoLocal(banco),
      repositorioMinistrantes: RepositorioMinistrantesLocal(banco),
      repositorioTomExecucao: _RepositorioTomExecucaoMemoria(),
      geradorId: _GeradorIdFalso(musica.id),
      geradorIdListaCulto: _GeradorIdListaCultoFalso(),
      geradorIdMinistrante: _GeradorIdMinistranteFalso(),
      geradorIdItemListaCulto: _GeradorIdItemListaCultoFalso(),
      parserDocumento: parser,
      agora: () => instante,
    );

    final ministrante = await composicao.criarMinistrante.executar('Nome');
    final lista = await composicao.criarListaCulto.executar('Culto');
    final contextual = await composicao.atualizarContextoListaCulto.executar(
      lista.id,
      data: DataCulto(ano: 2026, mes: 11, dia: 2),
      idMinistrante: ministrante.id,
    );

    expect(await composicao.listarMinistrantesAtivos.executar(), [ministrante]);
    expect(contextual.idMinistrante, ministrante.id);
    expect(contextual.criadaEm, instante);
  });

  testWidgets('composição sem SAF encaminha preferência de tom à visualização', (
    tester,
  ) async {
    final parser = ParserDocumentoChordPro();
    final musica = Musica(
      id: IdMusica('musica-1'),
      documento: parser.interpretar(
        '{title: Música}\n{artist: Artista}\n{key: C}\n[C]Letra',
      ),
    );
    final repositorioMusicas = _RepositorioMusicasMemoria(musica);
    final preferencias = _RepositorioTomExecucaoMemoria();
    final banco = BancoBiblioteca(NativeDatabase.memory());
    final composicao = ComposicaoAppCifras.paraTeste(
      banco: banco,
      repositorio: repositorioMusicas,
      repositorioListasCulto: _RepositorioListasCultoVazio(),
      repositorioTomExecucao: preferencias,
      geradorId: _GeradorIdFalso(musica.id),
      geradorIdListaCulto: _GeradorIdListaCultoFalso(),
      geradorIdItemListaCulto: _GeradorIdItemListaCultoFalso(),
      parserDocumento: parser,
    );
    addTearDown(banco.close);

    await tester.pumpWidget(
      MaterialApp(
        home: TelaBiblioteca(
          listarMusicas: composicao.listarMusicas,
          prepararEntradaMusica: composicao.prepararEntradaMusica,
          salvarRascunhoChordPro: composicao.salvarRascunhoChordPro,
          obterMusicaPorId: composicao.obterMusicaPorId,
          atualizarMusica: composicao.atualizarMusica,
          editarVersaoMusica: composicao.editarVersaoMusica,
          excluirMusica: composicao.excluirMusica,
          obterUltimoTomExecucao: composicao.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: composicao.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: composicao.removerUltimoTomExecucao,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('musica-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Tom: C'), findsOneWidget);

    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Tom: C#'), findsOneWidget);
    expect(
      await preferencias.obterUltimoTom(musica.versaoPrincipal.id),
      isNotNull,
    );

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    final itemMusica = find.byKey(const ValueKey('musica-1'));
    expect(itemMusica.hitTestable(), findsOneWidget);
    await tester.tap(itemMusica);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Tom: C#'), findsOneWidget);
    expect(find.text('Original: C'), findsOneWidget);
  });
}

class _RepositorioMusicasMemoria implements RepositorioMusicas {
  _RepositorioMusicasMemoria(this.musica);

  Musica musica;

  @override
  Future<void> atualizar(Musica musicaAtualizada) async {
    musica = musicaAtualizada;
  }

  @override
  Future<void> excluir(IdMusica id) async {}

  @override
  Future<List<Musica>> listar() async => [musica];

  @override
  Future<Musica?> obterPorId(IdMusica id) async =>
      musica.id == id ? musica : null;

  @override
  Future<void> salvar(Musica musicaNova) async {
    musica = musicaNova;
  }
}

class _RepositorioTomExecucaoMemoria implements RepositorioTomExecucao {
  final Map<IdVersaoMusica, Tom> _tons = {};

  @override
  Future<Tom?> obterUltimoTom(IdVersaoMusica idVersaoMusica) async =>
      _tons[idVersaoMusica];

  @override
  Future<void> removerUltimoTom(IdVersaoMusica idVersaoMusica) async {
    _tons.remove(idVersaoMusica);
  }

  @override
  Future<void> salvarUltimoTom(IdVersaoMusica idVersaoMusica, Tom tom) async {
    _tons[idVersaoMusica] = tom;
  }
}

class _GeradorIdFalso implements GeradorIdMusica {
  const _GeradorIdFalso(this._id);

  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}

class _GeradorIdListaCultoFalso implements GeradorIdListaCulto {
  @override
  IdListaCulto gerar() => IdListaCulto('lista-falsa');
}

class _GeradorIdItemListaCultoFalso implements GeradorIdItemListaCulto {
  @override
  IdItemListaCulto gerar() => IdItemListaCulto('item-falso');
}

class _GeradorIdMinistranteFalso implements GeradorIdMinistrante {
  @override
  IdMinistrante gerar() => IdMinistrante('ministrante-falso');
}

class _RepositorioListasCultoVazio implements RepositorioListasCulto {
  @override
  Future<void> adicionarItem(ItemListaCulto item) async {}

  @override
  Future<void> atualizarContexto(
    IdListaCulto id, {
    required DataCulto? data,
    required IdMinistrante? idMinistrante,
  }) async {}

  @override
  Future<void> excluir(IdListaCulto id) async {}

  @override
  Future<List<ListaCulto>> listar() async => [];

  @override
  Future<List<ItemListaCulto>> listarItens(IdListaCulto idLista) async => [];

  @override
  Future<ListaCulto?> obterPorId(IdListaCulto id) async => null;

  @override
  Future<void> removerItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
  ) async {}

  @override
  Future<void> renomear(IdListaCulto id, String nome) async {}

  @override
  Future<void> atualizarVersaoItem(
    IdListaCulto idLista,
    IdItemListaCulto idItem,
    IdVersaoMusica idVersaoMusica,
  ) async {}

  @override
  Future<void> reordenarItens(
    IdListaCulto idLista,
    List<IdItemListaCulto> ordem,
  ) async {}

  @override
  Future<void> salvar(ListaCulto lista) async {}
}
