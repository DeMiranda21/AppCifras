import 'dart:io';

import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/aplicacao/diagnostico/medicao_desempenho_visualizacao.dart';
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
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  late Directory diretorioTemporario;
  late BancoBiblioteca banco;
  late _ArmazenamentoContado arquivos;
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
    arquivos = _ArmazenamentoContado(diretorioTemporario);
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

  test(
    'listagem leve reutiliza índice textual sem reler ou interpretar arquivos',
    () async {
      final original = musica(
        'musica-1',
        conteudo:
            '{title: Graça}\n{artist: Ministério}\n{key: C}\n'
            '[C]Tua graça me alcançou',
      );
      await repositorio.salvar(original);
      arquivos.leituras = 0;

      final primeira = await repositorio.listarItensBiblioteca();
      final segunda = await repositorio.listarItensBiblioteca();

      expect(primeira, hasLength(1));
      expect(primeira.single.titulo, 'Graça');
      expect(primeira.single.artista, 'Ministério');
      expect(
        primeira.single.conteudoVisivel,
        contains('Tua graça me alcançou'),
      );
      expect(primeira.single.tituloNormalizado, 'graca');
      expect(
        primeira.single.textoNormalizado,
        contains('ministerio tua graca me alcancou'),
      );
      expect(segunda.single.idMusica, original.id);
      expect(arquivos.leituras, 0);

      expect(await repositorio.obterPorId(original.id), isNotNull);
      expect(arquivos.leituras, 1);
    },
  );

  test('instrumenta consultas, arquivos e parsing da abertura atual', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    final mensagens = <String>[];
    final medicao = MedicaoDesempenhoVisualizacao.iniciar(
      origem: OrigemAberturaVisualizacao.biblioteca,
      registrar: mensagens.add,
    )!;

    await medicao.executarNoContexto(() async {
      await repositorio.obterPorId(original.id);
      await repositorio.obterVersaoPorId(original.versaoPrincipal.id);
    });
    medicao.concluirApresentacao();

    expect(mensagens.single, contains('consultas_sqlite=3'));
    expect(mensagens.single, contains('arquivos_lidos=2'));
    expect(mensagens.single, contains('documentos_interpretados=2'));
  });

  test(
    'listagem leve suporta milhares de músicas sem arquivos ChordPro',
    () async {
      const quantidade = 2306;
      await banco.batch((lote) {
        lote.insertAll(banco.indiceMusicas, [
          for (var i = 0; i < quantidade; i++)
            IndiceMusicasCompanion.insert(
              id: 'm$i',
              titulo: 'Título $i',
              artista: 'Artista $i',
              arquivo: 'm$i.cho',
            ),
        ]);
        lote.insertAll(banco.versoesMusicas, [
          for (var i = 0; i < quantidade; i++)
            VersoesMusicasCompanion.insert(
              id: 'v$i',
              idMusica: 'm$i',
              nome: 'Principal',
              arquivo: 'v$i.cho',
              principal: true,
              arquivada: false,
            ),
        ]);
        lote.insertAll(banco.indicesPesquisaMusicas, [
          for (var i = 0; i < quantidade; i++)
            IndicesPesquisaMusicasCompanion.insert(
              idMusica: 'm$i',
              idVersaoMusica: 'v$i',
              conteudoVisivel: 'Letra pesquisável $i',
              tituloNormalizado: Value('titulo $i'),
              textoNormalizado: Value(
                'titulo $i artista $i letra pesquisavel $i',
              ),
            ),
        ]);
      });

      final itens = await repositorio.listarItensBiblioteca();

      expect(itens, hasLength(quantidade));
      expect(arquivos.leituras, 0);
      expect(
        itens
            .singleWhere((item) => item.idMusica == IdMusica('m2305'))
            .conteudoVisivel,
        'Letra pesquisável 2305',
      );
    },
  );

  test('edição e exclusão mantêm o índice leve consistente', () async {
    final original = musica('musica-1');
    await repositorio.salvar(original);
    final atualizada = musica(
      'musica-1',
      conteudo:
          '{title: Título novo}\n{artist: Artista novo}\n{key: G}\n'
          '[G]Conteúdo novo pesquisável',
    );

    await repositorio.atualizar(atualizada);
    final item = (await repositorio.listarItensBiblioteca()).single;
    expect(item.titulo, 'Título novo');
    expect(item.artista, 'Artista novo');
    expect(item.conteudoVisivel, contains('Conteúdo novo pesquisável'));
    expect(item.tituloNormalizado, 'titulo novo');
    expect(
      item.textoNormalizado,
      contains('artista novo conteudo novo pesquisavel'),
    );

    await repositorio.excluir(original.id);
    expect(await repositorio.listarItensBiblioteca(), isEmpty);
  });

  test(
    'troca da principal atualiza somente a projeção da Biblioteca',
    () async {
      final original = musica('musica-1');
      await repositorio.salvar(original);
      final alternativa = VersaoMusica(
        id: IdVersaoMusica('alternativa'),
        idMusica: original.id,
        nome: 'Alternativa',
        documento: parser.interpretar(
          '{title: Título}\n{artist: Artista}\n{key: D}\n[D]Letra alternativa',
        ),
        principal: false,
        arquivada: false,
      );
      await repositorio.salvarVersao(alternativa);

      await repositorio.definirComoPrincipal(alternativa.id);

      final item = (await repositorio.listarItensBiblioteca()).single;
      expect(item.idVersaoPrincipal, alternativa.id);
      expect(item.conteudoVisivel, contains('Letra alternativa'));
      expect(await repositorio.listarPorMusica(original.id), hasLength(2));
    },
  );

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

class _ArmazenamentoContado extends ArmazenamentoArquivosChordPro {
  _ArmazenamentoContado(super.diretorioMusicas);

  var leituras = 0;

  @override
  Future<String> obter(IdVersaoMusica id) {
    leituras++;
    return super.obter(id);
  }
}
