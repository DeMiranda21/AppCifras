import 'dart:io';

import 'package:appcifras/dominio/entidades/origem_sincronizada_versao.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migra schema 5 para origens preservando todos os dados atuais', () async {
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_migracao_v6_',
    );
    final arquivoBanco = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final armazenamento = ArmazenamentoArquivosChordPro(diretorio);
    const idMusica = 'musica-1';
    const idVersao = 'versao-1';
    const conteudo =
        '{appcifras_schema: 1}\n'
        '{appcifras_id: musica-1}\n'
        '{title: Título}\n'
        '{artist: Artista}\n'
        '{key: D}\n'
        '[D]Letra';

    final legado = NativeDatabase(arquivoBanco);
    await legado.ensureOpen(const _UsuarioExecutorSchema5());
    for (final comando in _schema5) {
      await legado.runCustom(comando, const []);
    }
    await legado.runCustom(
      "INSERT INTO indice_musicas VALUES ('$idMusica', 'Título', 'Artista', '$idVersao.cho')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO versoes_musicas VALUES ('$idVersao', '$idMusica', 'Principal', '$idVersao.cho', 1, 0)",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO preferencias_tom_execucao VALUES ('$idVersao', 'f', 'sustenido', 'menor')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO energias_musicas VALUES ('$idMusica', 'moderada')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO tags_musicas VALUES ('$idMusica', 'ceia', 'Ceia')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO listas_culto VALUES ('lista-1', 'Culto')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO itens_lista_culto VALUES ('item-1', 'lista-1', '$idMusica', '$idVersao', 0)",
      const [],
    );
    await legado.runCustom('PRAGMA user_version = 5', const []);
    await legado.close();
    await armazenamento.salvar(IdVersaoMusica(idVersao), conteudo);

    final banco = BancoBiblioteca(NativeDatabase(arquivoBanco));
    await banco.inicializar();
    final musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: armazenamento,
    );
    final sincronizacao = RepositorioSincronizacaoLocal(banco);

    expect((await musicas.obterPorId(IdMusica(idMusica)))?.titulo, 'Título');
    expect(
      (await musicas.obterVersaoPorId(IdVersaoMusica(idVersao)))?.nome,
      'Principal',
    );
    expect(await armazenamento.obter(IdVersaoMusica(idVersao)), conteudo);
    expect(await banco.obterTomExecucaoPorVersao(idVersao), isNotNull);
    expect((await banco.obterEnergiaMusica(idMusica))?.energia, 'moderada');
    expect((await banco.listarTagsMusica(idMusica)).single.valor, 'Ceia');
    expect((await banco.listarItensListaCulto('lista-1')).single.id, 'item-1');
    expect(await sincronizacao.obter(), isNull);
    expect(
      await sincronizacao.obterPorVersao(IdVersaoMusica(idVersao)),
      isNull,
    );

    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: IdVersaoMusica(idVersao),
        localizadorExterno: 'content://provedor/document/1',
        hashSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        estado: EstadoOrigemSincronizada.presente,
      ),
    );
    expect(
      (await sincronizacao.obterPorVersao(IdVersaoMusica(idVersao)))?.presente,
      isTrue,
    );

    await banco.close();
    await diretorio.delete(recursive: true);
  });
}

const _schema5 = [
  'CREATE TABLE indice_musicas (id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
  'CREATE TABLE versoes_musicas (id TEXT NOT NULL PRIMARY KEY, id_musica TEXT NOT NULL, nome TEXT NOT NULL, arquivo TEXT NOT NULL, principal INTEGER NOT NULL, arquivada INTEGER NOT NULL)',
  'CREATE TABLE preferencias_tom_execucao (id_versao_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
  'CREATE TABLE energias_musicas (id_musica TEXT NOT NULL PRIMARY KEY, energia TEXT NOT NULL)',
  'CREATE TABLE tags_musicas (id_musica TEXT NOT NULL, chave TEXT NOT NULL, valor TEXT NOT NULL, PRIMARY KEY (id_musica, chave))',
  'CREATE TABLE listas_culto (id TEXT NOT NULL PRIMARY KEY, nome TEXT NOT NULL)',
  'CREATE TABLE itens_lista_culto (id TEXT NOT NULL PRIMARY KEY, id_lista TEXT NOT NULL, id_musica TEXT NOT NULL, id_versao_musica TEXT NOT NULL, posicao INTEGER NOT NULL)',
];

class _UsuarioExecutorSchema5 implements QueryExecutorUser {
  const _UsuarioExecutorSchema5();

  @override
  int get schemaVersion => 5;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
