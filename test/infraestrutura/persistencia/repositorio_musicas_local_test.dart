import 'dart:io';

import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/erros/id_musica_ja_existente.dart';
import 'package:appcifras/dominio/erros/musica_nao_encontrada.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  late Directory diretorioTemporario;
  late BancoBiblioteca banco;
  late ArmazenamentoArquivosChordPro arquivos;
  late RepositorioMusicasLocal repositorio;

  Musica musica(String id, {String? conteudo}) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      conteudo ?? '{title: Título}\n{artist: Artista}\n{key: C}\n[C]Letra',
    ),
  );

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'appcifras_repositorio_',
    );
    banco = BancoBiblioteca(NativeDatabase.memory());
    arquivos = ArmazenamentoArquivosChordPro(diretorioTemporario);
    repositorio = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: arquivos,
    );
  });

  tearDown(() async {
    await banco.close();
    await diretorioTemporario.delete(recursive: true);
  });

  test('persiste e reconstrói música a partir do arquivo ChordPro', () async {
    final original = musica('musica-1');

    await repositorio.salvar(original);

    final recuperada = await repositorio.obterPorId(original.id);
    expect(recuperada, original);
    expect(recuperada!.titulo, 'Título');
    expect(recuperada.artista, 'Artista');
    expect(
      recuperada.documento.conteudoOriginal,
      await arquivos.obter(original.id),
    );
  });

  test('gera arquivo gerenciado com schema e ID sem alterar o documento original', () async {
    final original = musica('musica-1');

    await repositorio.salvar(original);

    expect(
      await arquivos.obter(original.id),
      '{appcifras_schema: 1}\n{appcifras_id: musica-1}\n${original.documento.conteudoOriginal}',
    );
    expect(original.documento.conteudoOriginal, startsWith('{title:'));
  });

  test('mantém no SQLite apenas os dados de índice', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);

    final colunas = await banco
        .customSelect('PRAGMA table_info(indice_musicas)')
        .get();

    expect(colunas.map((coluna) => coluna.read<String>('name')), [
      'id',
      'titulo',
      'artista',
      'arquivo',
    ]);
  });

  test('retorna nulo para ID que não está indexado', () async {
    expect(await repositorio.obterPorId(IdMusica('inexistente')), isNull);
  });

  test('detecta índice que referencia arquivo inexistente', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    await arquivos.excluir(original.id);

    await expectLater(
      repositorio.obterPorId(original.id),
      throwsA(isA<EstadoPersistenciaMusicaInconsistente>()),
    );
  });

  test('exclui arquivo e índice da música', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);

    await repositorio.excluir(original.id);

    expect(await arquivos.existe(original.id), isFalse);
    expect(await banco.obterPorId(original.id.valor), isNull);
  });

  test('rejeita ID duplicado sem sobrescrever arquivo ou índice', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);

    await expectLater(
      repositorio.salvar(original),
      throwsA(isA<IdMusicaJaExistente>()),
    );
    expect(await repositorio.obterPorId(original.id), original);
  });

  test('atualiza arquivo e índice mantendo a identidade da música', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    final atualizada = musica(
      'musica-1',
      conteudo:
          '{appcifras_schema: 1}\n'
          '{appcifras_id: musica-1}\n'
          '{title: Título revisado}\n'
          '{artist: Artista revisado}\n'
          '{key: G}\n'
          '{comment: manter}\n[G]Novo conteúdo',
    );

    await repositorio.atualizar(atualizada);

    final recuperada = await repositorio.obterPorId(original.id);
    expect(recuperada!.id, original.id);
    expect(recuperada.titulo, 'Título revisado');
    expect(recuperada.artista, 'Artista revisado');
    expect(await banco.listar(), hasLength(1));
    expect(await arquivos.obter(original.id), contains('{comment: manter}'));
  });

  test('rejeita atualização de música inexistente', () async {
    await expectLater(
      repositorio.atualizar(musica('inexistente')),
      throwsA(isA<MusicaNaoEncontrada>()),
    );
  });

  test('reaplica identidade e schema gerenciados ao atualizar', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    final atualizada = musica(
      'musica-1',
      conteudo: '{title: Título}\n{artist: Artista}\n{key: C}\n[C]Letra',
    );

    await repositorio.atualizar(atualizada);

    final conteudo = await arquivos.obter(original.id);
    expect(conteudo, contains('{appcifras_schema: 1}'));
    expect(conteudo, contains('{appcifras_id: musica-1}'));
  });

  test('rejeita schema AppCifras não suportado sem criar arquivo ou índice', () async {
    final original = musica(
      'musica-1',
      conteudo:
          '{appcifras_schema: 2}\n{title: Título}\n{artist: Artista}\n{key: C}',
    );

    await expectLater(
      repositorio.salvar(original),
      throwsA(isA<SchemaAppCifrasNaoSuportado>()),
    );
    expect(await arquivos.existe(original.id), isFalse);
    expect(await banco.obterPorId(original.id.valor), isNull);
  });
}
