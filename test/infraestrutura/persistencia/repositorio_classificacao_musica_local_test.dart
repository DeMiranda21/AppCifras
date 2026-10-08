import 'dart:io';

import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoBiblioteca banco;
  late RepositorioClassificacaoMusicaLocal repositorio;

  Future<void> inserirMusica(String id) => banco.inserir(
    id: id,
    titulo: 'Título $id',
    artista: 'Artista',
    arquivo: '$id.cho',
  );

  setUp(() async {
    banco = BancoBiblioteca(NativeDatabase.memory());
    await banco.inicializar();
    repositorio = RepositorioClassificacaoMusicaLocal(banco);
  });

  tearDown(() => banco.close());

  test('energia é opcional e pode ser alterada ou removida', () async {
    final id = IdMusica('musica-1');
    await inserirMusica(id.valor);

    expect((await repositorio.obter(id)).energia, isNull);
    await repositorio.definirEnergia(id, EnergiaMusica.calma);
    expect((await repositorio.obter(id)).energia, EnergiaMusica.calma);
    await repositorio.definirEnergia(id, EnergiaMusica.animada);
    expect((await repositorio.obter(id)).energia, EnergiaMusica.animada);
    await repositorio.definirEnergia(id, null);
    expect((await repositorio.obter(id)).energia, isNull);
  });

  test('tags são substituídas, normalizadas e isoladas por música', () async {
    final musicaA = IdMusica('musica-a');
    final musicaB = IdMusica('musica-b');
    await inserirMusica(musicaA.valor);
    await inserirMusica(musicaB.valor);
    await repositorio.substituirTags(musicaA, [
      TagMusica(' Ceia '),
      TagMusica('ceia'),
      TagMusica('Graça'),
    ]);
    await repositorio.substituirTags(musicaB, [TagMusica('Ensaio')]);

    expect((await repositorio.obter(musicaA)).tags, [
      TagMusica('Ceia'),
      TagMusica('Graça'),
    ]);
    expect((await repositorio.obter(musicaB)).tags, [TagMusica('Ensaio')]);
    await repositorio.substituirTags(musicaA, [TagMusica('Culto')]);
    expect((await repositorio.obter(musicaA)).tags, [TagMusica('Culto')]);
    expect((await repositorio.obter(musicaB)).tags, [TagMusica('Ensaio')]);
  });

  test('lista classificações de músicas em lote', () async {
    final musicaA = IdMusica('musica-a');
    final musicaB = IdMusica('musica-b');
    await inserirMusica(musicaA.valor);
    await inserirMusica(musicaB.valor);
    await repositorio.definirEnergia(musicaA, EnergiaMusica.calma);
    await repositorio.substituirTags(musicaA, [TagMusica('Ceia')]);
    await repositorio.substituirTags(musicaB, [TagMusica('Ensaio')]);

    final classificacoes = await repositorio.listar();

    expect(classificacoes[musicaA]?.energia, EnergiaMusica.calma);
    expect(classificacoes[musicaA]?.tags, [TagMusica('Ceia')]);
    expect(classificacoes[musicaB]?.energia, isNull);
    expect(classificacoes[musicaB]?.tags, [TagMusica('Ensaio')]);
  });

  test(
    'exclusão da música remove classificação sem afetar outra música',
    () async {
      final musicaA = IdMusica('musica-a');
      final musicaB = IdMusica('musica-b');
      await inserirMusica(musicaA.valor);
      await inserirMusica(musicaB.valor);
      await repositorio.definirEnergia(musicaA, EnergiaMusica.calma);
      await repositorio.substituirTags(musicaA, [TagMusica('Ceia')]);
      await repositorio.definirEnergia(musicaB, EnergiaMusica.animada);
      await repositorio.substituirTags(musicaB, [TagMusica('Culto')]);
      await banco.excluirPorId(musicaA.valor);
      await repositorio.removerPorMusica(musicaA);

      expect(await banco.obterEnergiaMusica(musicaA.valor), isNull);
      expect(await banco.listarTagsMusica(musicaA.valor), isEmpty);
      expect((await repositorio.obter(musicaB)).energia, EnergiaMusica.animada);
      expect((await repositorio.obter(musicaB)).tags, [TagMusica('Culto')]);
    },
  );

  test('classificação sobrevive à reabertura do mesmo SQLite físico', () async {
    await banco.close();
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_classificacao_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final id = IdMusica('musica-1');
    final primeiro = BancoBiblioteca(NativeDatabase(arquivo));
    await primeiro.inicializar();
    await primeiro.inserir(
      id: id.valor,
      titulo: 'Título',
      artista: 'Artista',
      arquivo: 'musica-1.cho',
    );
    final primeiroRepositorio = RepositorioClassificacaoMusicaLocal(primeiro);
    await primeiroRepositorio.definirEnergia(id, EnergiaMusica.moderada);
    await primeiroRepositorio.substituirTags(id, [TagMusica('Ceia')]);
    await primeiro.close();

    final segundo = BancoBiblioteca(NativeDatabase(arquivo));
    await segundo.inicializar();
    final classificacao = await RepositorioClassificacaoMusicaLocal(segundo)
        .obter(id);
    expect(classificacao.energia, EnergiaMusica.moderada);
    expect(classificacao.tags, [TagMusica('Ceia')]);
    await segundo.close();
    await diretorio.delete(recursive: true);
  });

  test(
    'migra schema 3 preservando dados existentes e inicia classificação vazia',
    () async {
      await banco.close();
      final diretorio = await Directory.systemTemp.createTemp(
        'appcifras_migracao_classificacao_',
      );
      final arquivo = File(
        '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
      );
      final legado = NativeDatabase(arquivo);
      await legado.ensureOpen(const _UsuarioExecutorSchema3());
      await legado.runCustom(
        'CREATE TABLE indice_musicas (id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
        const [],
      );
      await legado.runCustom(
        'CREATE TABLE preferencias_tom_execucao (id_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
        const [],
      );
      await legado.runCustom(
        'CREATE TABLE listas_culto (id TEXT NOT NULL PRIMARY KEY, nome TEXT NOT NULL)',
        const [],
      );
      await legado.runCustom(
        'CREATE TABLE itens_lista_culto (id TEXT NOT NULL PRIMARY KEY, id_lista TEXT NOT NULL, id_musica TEXT NOT NULL, posicao INTEGER NOT NULL)',
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
      await legado.runCustom(
        "INSERT INTO listas_culto VALUES ('lista-1', 'Culto')",
        const [],
      );
      await legado.runCustom(
        "INSERT INTO itens_lista_culto VALUES ('item-1', 'lista-1', 'musica-1', 0)",
        const [],
      );
      await legado.runCustom('PRAGMA user_version = 3', const []);
      await legado.close();

      final migrado = BancoBiblioteca(NativeDatabase(arquivo));
      await migrado.inicializar();
      expect(await migrado.obterPorId('musica-1'), isNotNull);
      expect(
        await migrado.obterTomExecucaoPorVersao('musica-1'),
        isNotNull,
      );
      expect(await migrado.obterListaCultoPorId('lista-1'), isNotNull);
      expect(
        (await migrado.listarItensListaCulto('lista-1')).single.id,
        'item-1',
      );
      expect(await migrado.obterEnergiaMusica('musica-1'), isNull);
      expect(await migrado.listarTagsMusica('musica-1'), isEmpty);
      await migrado.close();
      await diretorio.delete(recursive: true);
    },
  );
}

class _UsuarioExecutorSchema3 implements QueryExecutorUser {
  const _UsuarioExecutorSchema3();

  @override
  int get schemaVersion => 3;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
