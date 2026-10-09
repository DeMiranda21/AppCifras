import 'dart:io';

import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/erros/id_musica_ja_existente.dart';
import 'package:appcifras/dominio/erros/musica_nao_encontrada.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/dominio/erros/operacao_versao_musica_nao_permitida.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_tom_execucao_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';
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
    final principal = await repositorio.obterPrincipalPorMusica(original.id);
    expect(recuperada, original);
    expect(recuperada!.titulo, 'Título');
    expect(recuperada.artista, 'Artista');
    expect(
      recuperada.documento.conteudoOriginal,
      await arquivos.obter(original.versaoPrincipal.id),
    );
    expect(principal, isNotNull);
    expect(principal!.id, IdVersaoMusica(original.id.valor));
    expect(principal.idMusica, original.id);
    expect(await repositorio.obterVersaoPorId(principal.id), principal);
  });

  test('gera arquivo gerenciado com schema e ID sem alterar o documento original', () async {
    final original = musica('musica-1');

    await repositorio.salvar(original);

    expect(
      await arquivos.obter(original.versaoPrincipal.id),
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

  test(
    'persiste nova versão em arquivo próprio sem alterar a origem',
    () async {
      final original = musica('musica-1');
      await repositorio.salvar(original);
      final origem = (await repositorio.obterPrincipalPorMusica(original.id))!;
      final nova = VersaoMusica(
        id: IdVersaoMusica('versao-simplificada'),
        idMusica: original.id,
        nome: 'Simplificada',
        documento: origem.documento,
        principal: false,
        arquivada: false,
      );

      await repositorio.salvarVersao(nova);

      expect(await arquivos.existe(origem.id), isTrue);
      expect(await arquivos.existe(nova.id), isTrue);
      expect(await arquivos.obter(nova.id), await arquivos.obter(origem.id));
      expect(
        await repositorio.obterVersaoPorId(nova.id),
        isA<VersaoMusica>()
            .having((versao) => versao.idMusica, 'idMusica', original.id)
            .having((versao) => versao.nome, 'nome', 'Simplificada')
            .having((versao) => versao.principal, 'principal', isFalse),
      );
      expect(await repositorio.listarPorMusica(original.id), hasLength(2));
    },
  );

  test('retorna nulo para ID que não está indexado', () async {
    expect(await repositorio.obterPorId(IdMusica('inexistente')), isNull);
  });

  test('detecta índice que referencia arquivo inexistente', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    await arquivos.excluir(original.versaoPrincipal.id);

    await expectLater(
      repositorio.obterPorId(original.id),
      throwsA(isA<EstadoPersistenciaMusicaInconsistente>()),
    );
  });

  test('exclui arquivo e índice da música', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);

    await repositorio.excluir(original.id);

    expect(await arquivos.existe(original.versaoPrincipal.id), isFalse);
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
    expect(
      await arquivos.obter(original.versaoPrincipal.id),
      contains('{comment: manter}'),
    );
  });

  test(
    'sincroniza título e artista do catálogo nas versões já existentes',
    () async {
      final original = musica('musica-1');
      final idAlternativa = IdVersaoMusica('versao-acustica');
      const conteudoAlternativo =
          '{appcifras_schema: 1}\n'
          '{appcifras_id: musica-1}\n'
          '{title: Título}\n'
          '{artist: Artista}\n'
          '{key: G}\n'
          '{comment: manter}\n'
          '[G]Arranjo acústico';
      await repositorio.salvar(original);
      await arquivos.salvar(idAlternativa, conteudoAlternativo);
      await banco.inserirVersaoMusica(
        id: idAlternativa.valor,
        idMusica: original.id.valor,
        nome: 'Acústica',
        arquivo: arquivos.nomeArquivo(idAlternativa),
        principal: false,
        arquivada: false,
      );

      await repositorio.atualizar(
        musica(
          'musica-1',
          conteudo:
              '{title: Título revisado}\n'
              '{artist: Artista revisado}\n'
              '{key: C}\n'
              '[C]Letra',
        ),
      );

      final alternativo = await arquivos.obter(idAlternativa);
      expect(alternativo, contains('{title: Título revisado}'));
      expect(alternativo, contains('{artist: Artista revisado}'));
      expect(alternativo, contains('{key: G}'));
      expect(alternativo, contains('{comment: manter}'));
      expect(alternativo, contains('[G]Arranjo acústico'));
    },
  );

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

    final conteudo = await arquivos.obter(original.versaoPrincipal.id);
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
    expect(await arquivos.existe(original.versaoPrincipal.id), isFalse);
    expect(await banco.obterPorId(original.id.valor), isNull);
  });
  test('persiste ciclo de vida de versões sem afetar listas, tom ou classificação indevidamente', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    final principal = (await repositorio.obterPrincipalPorMusica(original.id))!;
    VersaoMusica alternativa(String id, String nome) => VersaoMusica(
      id: IdVersaoMusica(id),
      idMusica: original.id,
      nome: nome,
      documento: principal.documento,
      principal: false,
      arquivada: false,
    );
    final usada = alternativa('usada', 'Usada');
    final livre = alternativa('livre', 'Livre');
    await repositorio.salvarVersao(usada);
    await repositorio.salvarVersao(livre);
    final tons = RepositorioTomExecucaoLocal(banco);
    final tomD = Tom(
      notaFundamental: Nota(nome: NomeNota.d),
      modo: ModoTom.maior,
    );
    final tomE = Tom(
      notaFundamental: Nota(nome: NomeNota.e),
      modo: ModoTom.maior,
    );
    await tons.salvarUltimoTom(principal.id, tomD);
    await tons.salvarUltimoTom(usada.id, tomE);
    await banco.inserirListaCulto(id: 'lista-1', nome: 'Lista 1');
    await banco.inserirListaCulto(id: 'lista-2', nome: 'Lista 2');
    await banco.inserirItemListaCulto(
      id: 'item-1',
      idLista: 'lista-1',
      idMusica: original.id.valor,
      idVersaoMusica: usada.id.valor,
      posicao: 0,
    );
    await banco.inserirItemListaCulto(
      id: 'item-2',
      idLista: 'lista-2',
      idMusica: original.id.valor,
      idVersaoMusica: usada.id.valor,
      posicao: 0,
    );
    expect(await repositorio.estaUsadaEmLista(principal.id), isFalse);
    expect(await repositorio.estaUsadaEmLista(usada.id), isTrue);
    expect(await repositorio.estaUsadaEmLista(livre.id), isFalse);

    await repositorio.renomear(usada.id, '  Arranjo usado  ');
    final renomeada = (await repositorio.obterVersaoPorId(usada.id))!;
    expect(renomeada.nome, 'Arranjo usado');
    expect(renomeada.idMusica, original.id);
    expect(
      renomeada.documento.conteudoOriginal,
      principal.documento.conteudoOriginal,
    );
    expect(await arquivos.existe(usada.id), isTrue);

    await repositorio.definirComoPrincipal(livre.id);
    final versoes = await repositorio.listarPorMusica(original.id);
    expect(
      versoes.where((versao) => versao.principal).map((versao) => versao.id),
      [livre.id],
    );
    expect(await tons.obterUltimoTom(principal.id), tomD);
    expect(await tons.obterUltimoTom(usada.id), tomE);
    expect(
      (await banco.listarItensListaCulto('lista-1')).single.idVersaoMusica,
      usada.id.valor,
    );

    await repositorio.arquivar(usada.id);
    expect((await repositorio.obterVersaoPorId(usada.id))!.arquivada, isTrue);
    expect(await arquivos.existe(usada.id), isTrue);
    expect(await tons.obterUltimoTom(usada.id), tomE);
    expect(
      (await banco.listarItensListaCulto('lista-2')).single.idVersaoMusica,
      usada.id.valor,
    );
    await repositorio.restaurar(usada.id);
    expect((await repositorio.obterVersaoPorId(usada.id))!.arquivada, isFalse);
    await expectLater(
      repositorio.arquivar(livre.id),
      throwsA(isA<VersaoPrincipalNaoPodeSerArquivada>()),
    );

    final classificacoes = RepositorioClassificacaoMusicaLocal(banco);
    await classificacoes.definirEnergia(original.id, EnergiaMusica.animada);
    await classificacoes.substituirTags(original.id, [TagMusica('Culto')]);
    await tons.salvarUltimoTom(principal.id, tomD);
    await repositorio.excluirVersao(principal.id);
    expect(await repositorio.obterVersaoPorId(principal.id), isNull);
    expect(await arquivos.existe(principal.id), isFalse);
    expect(await tons.obterUltimoTom(principal.id), isNull);
    expect(await repositorio.obterPorId(original.id), isNotNull);
    expect(await arquivos.existe(livre.id), isTrue);
    expect(
      (await classificacoes.obter(original.id)).energia,
      EnergiaMusica.animada,
    );
    expect((await classificacoes.obter(original.id)).tags, [
      TagMusica('Culto'),
    ]);
    await expectLater(
      repositorio.excluirVersao(livre.id),
      throwsA(isA<VersaoPrincipalNaoPodeSerExcluida>()),
    );
    await expectLater(
      repositorio.excluirVersao(usada.id),
      throwsA(isA<VersaoMusicaEmUsoEmLista>()),
    );
    expect(await arquivos.existe(usada.id), isTrue);
    expect(await tons.obterUltimoTom(usada.id), tomE);
  });
}
