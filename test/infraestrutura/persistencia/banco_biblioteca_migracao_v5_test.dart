import 'dart:io';

import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migra schema 4 para versões preservando dados e arquivo físico', () async {
    final diretorio = await Directory.systemTemp.createTemp(
      'appcifras_migracao_v5_',
    );
    final arquivoBanco = File(
      '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
    );
    final armazenamento = ArmazenamentoArquivosChordPro(diretorio);
    const idMusica = 'musica-1';
    const conteudo =
        '{appcifras_schema: 1}\n'
        '{appcifras_id: musica-1}\n'
        '{title: Título}\n'
        '{artist: Artista}\n'
        '{key: D}\n'
        '[D]Letra';

    final legado = NativeDatabase(arquivoBanco);
    await legado.ensureOpen(const _UsuarioExecutorSchema4());
    await legado.runCustom(
      'CREATE TABLE indice_musicas ('
      'id TEXT NOT NULL PRIMARY KEY, titulo TEXT NOT NULL, '
      'artista TEXT NOT NULL, arquivo TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE preferencias_tom_execucao ('
      'id_musica TEXT NOT NULL PRIMARY KEY, nome_nota TEXT NOT NULL, '
      'alteracao TEXT NOT NULL, modo TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE energias_musicas ('
      'id_musica TEXT NOT NULL PRIMARY KEY, energia TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE tags_musicas ('
      'id_musica TEXT NOT NULL, chave TEXT NOT NULL, valor TEXT NOT NULL, '
      'PRIMARY KEY (id_musica, chave))',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE listas_culto (id TEXT NOT NULL PRIMARY KEY, nome TEXT NOT NULL)',
      const [],
    );
    await legado.runCustom(
      'CREATE TABLE itens_lista_culto ('
      'id TEXT NOT NULL PRIMARY KEY, id_lista TEXT NOT NULL, '
      'id_musica TEXT NOT NULL, posicao INTEGER NOT NULL)',
      const [],
    );
    await legado.runCustom(
      "INSERT INTO indice_musicas VALUES ('$idMusica', 'Título', 'Artista', '$idMusica.cho')",
      const [],
    );
    await legado.runCustom(
      "INSERT INTO preferencias_tom_execucao VALUES ('$idMusica', 'f', 'sustenido', 'menor')",
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
      "INSERT INTO itens_lista_culto VALUES ('item-1', 'lista-1', '$idMusica', 0)",
      const [],
    );
    await legado.runCustom('PRAGMA user_version = 4', const []);
    await legado.close();
    await armazenamento.salvar(IdVersaoMusica(idMusica), conteudo);

    final banco = BancoBiblioteca(NativeDatabase(arquivoBanco));
    await banco.inicializar();
    final repositorio = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: armazenamento,
    );

    final musica = await repositorio.obterPorId(IdMusica(idMusica));
    final versao = await repositorio.obterPrincipalPorMusica(
      IdMusica(idMusica),
    );
    final item = (await banco.listarItensListaCulto('lista-1')).single;

    expect(musica, isNotNull);
    expect(musica!.id, IdMusica(idMusica));
    expect(versao, isNotNull);
    expect(versao!.id, IdVersaoMusica(idMusica));
    expect(versao.principal, isTrue);
    expect(versao.arquivada, isFalse);
    expect(await armazenamento.obter(versao.id), conteudo);
    expect(versao.documento.conteudoOriginal, conteudo);
    expect(item.idMusica, idMusica);
    expect(item.idVersaoMusica, idMusica);
    expect(await banco.obterTomExecucaoPorVersao(idMusica), isNotNull);
    expect((await banco.obterEnergiaMusica(idMusica))!.energia, 'moderada');
    expect((await banco.listarTagsMusica(idMusica)).single.valor, 'Ceia');
    expect(await banco.listar(), hasLength(1));
    expect(await banco.obterListaCultoPorId('lista-1'), isNotNull);

    await banco.close();
    await diretorio.delete(recursive: true);
  });
}

class _UsuarioExecutorSchema4 implements QueryExecutorUser {
  const _UsuarioExecutorSchema4();

  @override
  int get schemaVersion => 4;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
