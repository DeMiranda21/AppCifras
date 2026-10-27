import 'dart:io';

import 'package:appcifras/aplicacao/biblioteca_oficial/estado_biblioteca_oficial.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migra schema 6 e preserva origem e tabela legada', () async {
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_migracao_v7_',
    );
    final arquivo = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final legado = NativeDatabase(arquivo);
    await legado.ensureOpen(const _UsuarioExecutorSchema6());
    for (final comando in _schema6) {
      await legado.runCustom(comando, const []);
    }
    await legado.runCustom(
      "INSERT INTO indice_musicas VALUES ('m1', 'Título', 'Artista', 'v1.cho')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO versoes_musicas VALUES ('v1', 'm1', 'Principal', 'v1.cho', 1, 0)",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO origens_sincronizadas_versoes VALUES ('v1', 'content://saf/v1.cho', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 1)",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO configuracoes_pasta_sincronizada VALUES (1, 'content://saf', 1, 'Curada', 1772013600)",
      const [],
    );
    await legado.runCustom('PRAGMA user_version = 6', const []);
    await legado.close();

    final banco = BancoBiblioteca(NativeDatabase(arquivo));
    await banco.inicializar();
    final repositorio = RepositorioSincronizacaoLocal(banco);

    expect(
      (await repositorio.obterPorVersao(IdVersaoMusica('v1')))
          ?.localizadorExterno,
      'content://saf/v1.cho',
    );
    final configuracaoLegada = await banco
        .select(banco.configuracoesPastaSincronizada)
        .getSingle();
    expect(configuracaoLegada.uriArvore, 'content://saf');
    expect(await repositorio.obterEstadoBibliotecaOficial(), isNull);

    final data = DateTime.utc(2026, 10, 25, 15);
    await repositorio.salvarEstadoBibliotecaOficial(
      EstadoBibliotecaOficial(
        ultimaGeracao: '20261025T142427167404Z',
        ultimaAtualizacao: data,
      ),
    );
    final estado = await repositorio.obterEstadoBibliotecaOficial();
    expect(estado?.ultimaGeracao, '20261025T142427167404Z');
    expect(estado?.ultimaAtualizacao.toUtc(), data);

    await banco.close();
    await diretorio.delete(recursive: true);
  });
}

const _schema6 = [
  'CREATE TABLE indice_musicas (id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
  'CREATE TABLE versoes_musicas (id TEXT NOT NULL PRIMARY KEY, id_musica TEXT NOT NULL, nome TEXT NOT NULL, arquivo TEXT NOT NULL, principal INTEGER NOT NULL, arquivada INTEGER NOT NULL)',
  'CREATE TABLE origens_sincronizadas_versoes (id_versao_musica TEXT NOT NULL PRIMARY KEY, localizador_externo TEXT NOT NULL, hash_sha256 TEXT NOT NULL, presente INTEGER NOT NULL)',
  'CREATE TABLE configuracoes_pasta_sincronizada (id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1), uri_arvore TEXT NOT NULL, autorizacao_persistente INTEGER NOT NULL, nome_legivel TEXT NULL, ultima_sincronizacao_concluida INTEGER NULL)',
  'CREATE TABLE preferencias_tom_execucao (id_versao_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
  'CREATE TABLE energias_musicas (id_musica TEXT NOT NULL PRIMARY KEY, energia TEXT NOT NULL)',
  'CREATE TABLE tags_musicas (id_musica TEXT NOT NULL, chave TEXT NOT NULL, valor TEXT NOT NULL, PRIMARY KEY (id_musica, chave))',
  'CREATE TABLE listas_culto (id TEXT NOT NULL PRIMARY KEY, nome TEXT NOT NULL)',
  'CREATE TABLE itens_lista_culto (id TEXT NOT NULL PRIMARY KEY, id_lista TEXT NOT NULL, id_musica TEXT NOT NULL, id_versao_musica TEXT NOT NULL, posicao INTEGER NOT NULL)',
];

class _UsuarioExecutorSchema6 implements QueryExecutorUser {
  const _UsuarioExecutorSchema6();

  @override
  int get schemaVersion => 6;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
