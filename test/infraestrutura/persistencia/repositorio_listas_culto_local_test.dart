import 'dart:io';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/entidades/lista_culto.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/erros/item_lista_culto_nao_encontrado.dart';
import 'package:appcifras/dominio/erros/lista_culto_nao_encontrada.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoBiblioteca banco;
  late RepositorioListasCultoLocal repositorio;
  var bancoDoSetUpFoiFechado = false;

  Future<void> inserirMusicaIndice(String id) => banco.inserir(
    id: id,
    titulo: 'Título $id',
    artista: 'Artista',
    arquivo: '$id.cho',
  );

  ItemListaCulto item({
    required String id,
    required IdListaCulto idLista,
    required String idMusica,
    required int posicao,
  }) => ItemListaCulto(
    id: IdItemListaCulto(id),
    idLista: idLista,
    idMusica: IdMusica(idMusica),
    posicao: posicao,
  );

  setUp(() async {
    bancoDoSetUpFoiFechado = false;
    banco = BancoBiblioteca(NativeDatabase.memory());
    await banco.inicializar();
    repositorio = RepositorioListasCultoLocal(banco);
  });

  tearDown(() async {
    if (!bancoDoSetUpFoiFechado) {
      await banco.close();
    }
  });

  Future<void> fecharBancoDoSetUp() async {
    await banco.close();
    bancoDoSetUpFoiFechado = true;
  }

  test(
    'cria, obtém, lista, renomeia e exclui lista sem alterar músicas',
    () async {
      final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
      await inserirMusicaIndice('musica-1');

      await repositorio.salvar(lista);
      expect(await repositorio.obterPorId(lista.id), lista);
      expect(await repositorio.listar(), [lista]);

      await repositorio.renomear(lista.id, 'Ensaio');
      expect((await repositorio.obterPorId(lista.id))!.nome, 'Ensaio');

      await repositorio.excluir(lista.id);
      expect(await repositorio.obterPorId(lista.id), isNull);
      expect(await banco.obterPorId('musica-1'), isNotNull);
    },
  );

  test(
    'permite repetir música, preserva ordem e normaliza após remoção',
    () async {
      final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
      await repositorio.salvar(lista);
      await inserirMusicaIndice('musica-a');
      await inserirMusicaIndice('musica-b');
      final primeiro = item(
        id: 'item-1',
        idLista: lista.id,
        idMusica: 'musica-a',
        posicao: 0,
      );
      final segundo = item(
        id: 'item-2',
        idLista: lista.id,
        idMusica: 'musica-b',
        posicao: 1,
      );
      final terceiro = item(
        id: 'item-3',
        idLista: lista.id,
        idMusica: 'musica-a',
        posicao: 2,
      );
      await repositorio.adicionarItem(primeiro);
      await repositorio.adicionarItem(segundo);
      await repositorio.adicionarItem(terceiro);

      expect(
        (await repositorio.listarItens(lista.id))
            .map((item) => item.idMusica.valor),
        ['musica-a', 'musica-b', 'musica-a'],
      );

      await repositorio.reordenarItens(lista.id, [
        terceiro.id,
        primeiro.id,
        segundo.id,
      ]);
      expect(
        (await repositorio.listarItens(lista.id)).map((item) => item.id.valor),
        ['item-3', 'item-1', 'item-2'],
      );

      await repositorio.removerItem(lista.id, primeiro.id);
      final restantes = await repositorio.listarItens(lista.id);
      expect(restantes.map((item) => item.posicao), [0, 1]);
      expect(await banco.obterPorId('musica-a'), isNotNull);
    },
  );

  test(
    'reordena primeiro para último, último para primeiro e item intermediário',
    () async {
      final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
      await repositorio.salvar(lista);
      for (var indice = 0; indice < 4; indice++) {
        await inserirMusicaIndice('musica-$indice');
        await repositorio.adicionarItem(
          item(
            id: 'item-$indice',
            idLista: lista.id,
            idMusica: 'musica-$indice',
            posicao: indice,
          ),
        );
      }

      await repositorio.reordenarItens(lista.id, [
        IdItemListaCulto('item-1'),
        IdItemListaCulto('item-2'),
        IdItemListaCulto('item-3'),
        IdItemListaCulto('item-0'),
      ]);
      await repositorio.reordenarItens(lista.id, [
        IdItemListaCulto('item-0'),
        IdItemListaCulto('item-1'),
        IdItemListaCulto('item-3'),
        IdItemListaCulto('item-2'),
      ]);

      final itens = await repositorio.listarItens(lista.id);
      expect(itens.map((item) => item.id.valor), [
        'item-0',
        'item-1',
        'item-3',
        'item-2',
      ]);
      expect(itens.map((item) => item.posicao), [0, 1, 2, 3]);
    },
  );

  test('rejeita lista ou item inexistente', () async {
    final idLista = IdListaCulto('inexistente');

    await expectLater(
      repositorio.listarItens(idLista),
      throwsA(isA<ListaCultoNaoEncontrada>()),
    );
    await repositorio.salvar(ListaCulto(id: idLista, nome: 'Culto'));
    await expectLater(
      repositorio.removerItem(idLista, IdItemListaCulto('inexistente')),
      throwsA(isA<ItemListaCultoNaoEncontrado>()),
    );
  });

  test('excluir lista remove seus itens sem remover músicas', () async {
    final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
    await repositorio.salvar(lista);
    await inserirMusicaIndice('musica-1');
    await repositorio.adicionarItem(
      item(id: 'item-1', idLista: lista.id, idMusica: 'musica-1', posicao: 0),
    );

    await repositorio.excluir(lista.id);

    expect(await banco.obterItemListaCultoPorId('item-1'), isNull);
    expect(await banco.obterPorId('musica-1'), isNotNull);
  });

  test('ordem sobrevive à reabertura do mesmo SQLite físico', () async {
    await fecharBancoDoSetUp();
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_listas_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final primeiroBanco = BancoBiblioteca(NativeDatabase(arquivo));
    var primeiroBancoFechado = false;
    BancoBiblioteca? segundoBanco;
    var segundoBancoFechado = false;
    addTearDown(() async {
      if (!primeiroBancoFechado) {
        await primeiroBanco.close();
      }
      if (segundoBanco != null && !segundoBancoFechado) {
        await segundoBanco.close();
      }
      if (await diretorio.exists()) {
        await diretorio.delete(recursive: true);
      }
    });
    await primeiroBanco.inicializar();
    final primeiroRepositorio = RepositorioListasCultoLocal(primeiroBanco);
    final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
    await primeiroRepositorio.salvar(lista);
    for (var indice = 0; indice < 2; indice++) {
      await primeiroBanco.inserir(
        id: 'musica-$indice',
        titulo: 'Título',
        artista: 'Artista',
        arquivo: 'musica-$indice.cho',
      );
      await primeiroRepositorio.adicionarItem(
        item(
          id: 'item-$indice',
          idLista: lista.id,
          idMusica: 'musica-$indice',
          posicao: indice,
        ),
      );
    }
    await primeiroBanco.close();
    primeiroBancoFechado = true;

    final bancoReaberto = BancoBiblioteca(NativeDatabase(arquivo));
    segundoBanco = bancoReaberto;
    await bancoReaberto.inicializar();
    final itens = await RepositorioListasCultoLocal(bancoReaberto)
        .listarItens(lista.id);

    expect(itens.map((item) => item.id.valor), ['item-0', 'item-1']);
    expect(itens.map((item) => item.posicao), [0, 1]);
    await bancoReaberto.close();
    segundoBancoFechado = true;
  });

  test(
    'excluir música remove explicitamente todos os itens relacionados',
    () async {
      final diretorio = await Directory.systemTemp.createTemp(
        'appcifras_exclusao_',
      );
      final arquivos = ArmazenamentoArquivosChordPro(diretorio);
      final repositorioMusicas = RepositorioMusicasLocal(
        banco: banco,
        armazenamentoArquivos: arquivos,
      );
      final parser = ParserDocumentoChordPro();
      final musicaA = Musica(
        id: IdMusica('musica-a'),
        documento: parser.interpretar(
          '{title: A}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      );
      final musicaB = Musica(
        id: IdMusica('musica-b'),
        documento: parser.interpretar(
          '{title: B}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      );
      final lista = ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto');
      await repositorioMusicas.salvar(musicaA);
      await repositorioMusicas.salvar(musicaB);
      await repositorio.salvar(lista);
      await repositorio.adicionarItem(
        item(
          id: 'item-1',
          idLista: lista.id,
          idMusica: musicaA.id.valor,
          posicao: 0,
        ),
      );
      await repositorio.adicionarItem(
        item(
          id: 'item-2',
          idLista: lista.id,
          idMusica: musicaB.id.valor,
          posicao: 1,
        ),
      );
      await repositorio.adicionarItem(
        item(
          id: 'item-3',
          idLista: lista.id,
          idMusica: musicaA.id.valor,
          posicao: 2,
        ),
      );

      await ExcluirMusica(repositorioMusicas)
          .executar(musicaA.id, confirmada: true);

      final itens = await repositorio.listarItens(lista.id);
      expect(itens.map((item) => item.idMusica), [musicaB.id]);
      expect(itens.single.posicao, 0);
      await diretorio.delete(recursive: true);
    },
  );

  test('migra schema 2 preservando músicas e preferências de tom', () async {
    await fecharBancoDoSetUp();
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_migracao_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final legado = NativeDatabase(arquivo);
    var legadoFechado = false;
    BancoBiblioteca? migrado;
    var migradoFechado = false;
    addTearDown(() async {
      if (!legadoFechado) {
        await legado.close();
      }
      if (migrado != null && !migradoFechado) {
        await migrado.close();
      }
      if (await diretorio.exists()) {
        await diretorio.delete(recursive: true);
      }
    });
    await legado.ensureOpen(const _UsuarioExecutorLegado());
    await legado.runCustom(
      'CREATE TABLE indice_musicas (id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE preferencias_tom_execucao (id_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      "INSERT INTO indice_musicas VALUES ('musica-1', 'Título', 'Artista', 'musica-1.cho')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO preferencias_tom_execucao VALUES ('musica-1', 'c', 'nenhuma', 'maior')",
      const [],
    );
    await legado.runCustom('PRAGMA user_version = 2', const []);
    await legado.close();
    legadoFechado = true;

    final bancoMigrado = BancoBiblioteca(NativeDatabase(arquivo));
    migrado = bancoMigrado;
    await bancoMigrado.inicializar();

    expect(await bancoMigrado.obterPorId('musica-1'), isNotNull);
    expect(await bancoMigrado.obterTomExecucaoPorMusica('musica-1'), isNotNull);
    await RepositorioListasCultoLocal(bancoMigrado)
        .salvar(ListaCulto(id: IdListaCulto('lista-1'), nome: 'Culto'));
    expect(await bancoMigrado.obterListaCultoPorId('lista-1'), isNotNull);
    await bancoMigrado.close();
    migradoFechado = true;
  });
}

class _UsuarioExecutorLegado implements QueryExecutorUser {
  const _UsuarioExecutorLegado();

  @override
  int get schemaVersion => 2;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
