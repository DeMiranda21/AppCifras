import 'dart:io';

import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migra schema 7 de forma aditiva preservando Listas legadas', () async {
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_migracao_v8_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final legado = NativeDatabase(arquivo);
    await legado.ensureOpen(const _UsuarioExecutorSchema7());
    for (final comando in _schema7) {
      await legado.runCustom(comando, const []);
    }
    await legado.runCustom(
      "INSERT INTO indice_musicas VALUES ('musica-1', 'Título', 'Artista', 'versao-1.cho')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO versoes_musicas VALUES ('versao-1', 'musica-1', 'Principal', 'versao-1.cho', 1, 0)",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO listas_culto VALUES ('lista-1', 'Culto legado')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO itens_lista_culto VALUES ('item-2', 'lista-1', 'musica-1', 'versao-1', 1)",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO itens_lista_culto VALUES ('item-1', 'lista-1', 'musica-1', 'versao-1', 0)",
      const [],
    );
    await legado.runCustom('PRAGMA user_version = 7', const []);
    await legado.close();

    final banco = BancoBiblioteca(NativeDatabase(arquivo));
    await banco.inicializar();
    final repositorio = RepositorioListasCultoLocal(banco);

    final lista = await repositorio.obterPorId(IdListaCulto('lista-1'));
    final itens = await repositorio.listarItens(IdListaCulto('lista-1'));
    expect(lista?.nome, 'Culto legado');
    expect(lista?.data, isNull);
    expect(lista?.idMinistrante, isNull);
    expect(lista?.criadaEm, isNull);
    expect(itens.map((item) => item.id.valor), ['item-1', 'item-2']);
    expect(itens.map((item) => item.posicao), [0, 1]);
    expect(itens.map((item) => item.idMusica.valor), everyElement('musica-1'));
    expect(
      itens.map((item) => item.idVersaoMusica.valor),
      everyElement('versao-1'),
    );
    expect(itens.map((item) => item.tom), everyElement(isNull));

    final tabelas = await banco
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'ministrantes'",
        )
        .get();
    expect(tabelas, hasLength(1));
    expect(
      (await banco.customSelect('PRAGMA table_info(listas_culto)').get())
          .map((linha) => linha.read<String>('name')),
      containsAll(['data', 'id_ministrante', 'criada_em']),
    );
    expect(
      (await banco.customSelect('PRAGMA table_info(itens_lista_culto)').get())
          .map((linha) => linha.read<String>('name')),
      contains('tom'),
    );
    expect(
      await banco.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );

    await banco.close();
    await diretorio.delete(recursive: true);
  });
}

const _schema7 = [
  'CREATE TABLE indice_musicas (id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
  'CREATE TABLE versoes_musicas (id TEXT NOT NULL PRIMARY KEY, id_musica TEXT NOT NULL, nome TEXT NOT NULL, arquivo TEXT NOT NULL, principal INTEGER NOT NULL, arquivada INTEGER NOT NULL)',
  'CREATE TABLE origens_sincronizadas_versoes (id_versao_musica TEXT NOT NULL PRIMARY KEY, localizador_externo TEXT NOT NULL, hash_sha256 TEXT NOT NULL, presente INTEGER NOT NULL)',
  'CREATE TABLE configuracoes_pasta_sincronizada (id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1), uri_arvore TEXT NOT NULL, autorizacao_persistente INTEGER NOT NULL, nome_legivel TEXT NULL, ultima_sincronizacao_concluida INTEGER NULL)',
  'CREATE TABLE estados_biblioteca_oficial (id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1), ultima_geracao TEXT NOT NULL, ultima_atualizacao INTEGER NOT NULL)',
  'CREATE TABLE preferencias_tom_execucao (id_versao_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
  'CREATE TABLE energias_musicas (id_musica TEXT NOT NULL PRIMARY KEY, energia TEXT NOT NULL)',
  'CREATE TABLE tags_musicas (id_musica TEXT NOT NULL, chave TEXT NOT NULL, valor TEXT NOT NULL, PRIMARY KEY (id_musica, chave))',
  'CREATE TABLE listas_culto (id TEXT NOT NULL PRIMARY KEY, nome TEXT NOT NULL)',
  'CREATE TABLE itens_lista_culto (id TEXT NOT NULL PRIMARY KEY, id_lista TEXT NOT NULL, id_musica TEXT NOT NULL, id_versao_musica TEXT NOT NULL, posicao INTEGER NOT NULL)',
];

class _UsuarioExecutorSchema7 implements QueryExecutorUser {
  const _UsuarioExecutorSchema7();

  @override
  int get schemaVersion => 7;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
