import 'dart:io';

import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:appcifras/aplicacao/casos_de_uso/editar_versao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/classificacao_musica.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_versao_musica.dart';
import 'package:appcifras/aplicacao/versoes/politica_edicao_versao.dart';
import 'package:appcifras/aplicacao/portas/repositorio_classificacao_musica.dart';
import 'package:appcifras/apresentacao/musica/tela_edicao_musica.dart';
import 'package:appcifras/aplicacao/entrada/conteudo_chordpro_editavel.dart';
import 'package:appcifras/aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_tom_execucao_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';

void main() {
  late Directory dir;
  late BancoBiblioteca banco;
  late RepositorioMusicasLocal repo;
  late EditarVersaoMusica editar;
  late CriarVersaoMusica criar;
  late RepositorioTomExecucaoLocal tons;
  late RepositorioClassificacaoMusicaLocal classificacao;
  late Musica musica;
  late VersaoMusica principal;
  final parser = ParserDocumentoChordPro();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('appcifras_c2_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    repo = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: ArmazenamentoArquivosChordPro(dir),
    );
    tons = RepositorioTomExecucaoLocal(banco);
    classificacao = RepositorioClassificacaoMusicaLocal(banco);
    criar = CriarVersaoMusica(repositorio: repo, geradorId: _Gerador());
    editar = EditarVersaoMusica(
      repositorio: repo,
      repositorioMusicas: repo,
      criarVersao: criar,
      avaliarPolitica: AvaliarPoliticaEdicaoVersao(repo),
      repositorioTom: tons,
    );
    await repo.salvar(
      Musica(
        id: IdMusica('musica'),
        documento: parser.interpretar(
          '{title: T}\n{artist: A}\n{key: C}\n[C]Principal',
        ),
      ),
    );
    musica = (await repo.obterPorId(IdMusica('musica')))!;
    principal = musica.versaoPrincipal;
  });
  tearDown(() async {
    await banco.close();
    await dir.delete(recursive: true);
  });

  Future<VersaoMusica> alternativa() async {
    final v = await criar.executar(origem: principal, nome: 'Alternativa');
    return v;
  }

  Future<void> usar(VersaoMusica v) async {
    await banco.inserirListaCulto(id: 'lista', nome: 'Culto');
    await banco.inserirItemListaCulto(
      id: 'item',
      idLista: 'lista',
      idMusica: v.idMusica.valor,
      idVersaoMusica: v.id.valor,
      posicao: 0,
    );
  }

  VersaoMusica mudar(VersaoMusica v, {String? tom, String? titulo}) =>
      editar.preparar(
        v,
        ConteudoChordProEditavel.extrair(v.documento.conteudoOriginal)
            .replaceAll('[C]Principal', '[D]Alternativa'),
        RevisaoMetadadosChordPro(tom: tom, titulo: titulo),
      );

  test('principal pode sobrescrever o mesmo ID, inclusive usada, e preserva último tom', () async {
    await usar(principal);
    await tons.salvarUltimoTom(principal.id, principal.tomOriginal);

    final resultado = await editar.executar(
      origem: principal,
      editada: mudar(principal, tom: 'D'),
      acaoConteudo: AcaoEdicaoConteudoVersao.sobrescrever,
    );

    expect(resultado.id, principal.id);
    expect(resultado.documento.conteudoOriginal, contains('[D]Alternativa'));
    expect((await repo.listarPorMusica(musica.id)), hasLength(1));
    expect(await tons.obterUltimoTom(principal.id), principal.tomOriginal);
    final item = await banco
        .customSelect('SELECT * FROM itens_lista_culto')
        .getSingle();
    expect(item.read<String>('id_versao_musica'), principal.id.valor);
  });

  test('principal alterada exige escolha explícita no caso de uso', () async {
    await expectLater(
      editar.executar(origem: principal, editada: mudar(principal)),
      throwsArgumentError,
    );
    expect((await repo.listarPorMusica(musica.id)), hasLength(1));
  });

  test('principal alterada cria nova versão e não herda último tom', () async {
    await tons.salvarUltimoTom(
      principal.id,
      parser
          .interpretar('{key: G}')
          .elementos
          .whereType<DiretivaTomChordPro>()
          .single
          .tom!,
    );
    final resultado = await editar.executar(
      origem: principal,
      editada: mudar(principal, tom: 'D'),
      nomeNovaVersao: '  Nova  ',
      acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
    );
    expect(resultado.id, isNot(principal.id));
    expect(resultado.idMusica, principal.idMusica);
    expect(resultado.nome, 'Nova');
    expect(resultado.principal, isFalse);
    expect(
      (await repo.obterVersaoPorId(principal.id))!.documento.conteudoOriginal,
      principal.documento.conteudoOriginal,
    );
    expect(await tons.obterUltimoTom(resultado.id), isNull);
    expect(await tons.obterUltimoTom(principal.id), isNotNull);
  });

  test(
    'somente título/artista e classificação não criam versão musical',
    () async {
      await usar(principal);
      final editada = editar.preparar(
        principal,
        ConteudoChordProEditavel.extrair(principal.documento.conteudoOriginal),
        const RevisaoMetadadosChordPro(
          titulo: 'Novo título',
          artista: 'Outro artista',
        ),
      );
      expect(editar.conteudoMusicalAlterado(principal, editada), isFalse);
      await editar.executar(origem: principal, editada: editada);
      await SalvarClassificacaoMusica(classificacao)
          .executar(musica.id, energia: EnergiaMusica.animada, tags: []);
      expect((await repo.listarPorMusica(musica.id)).length, 1);
      expect((await repo.obterPorId(musica.id))!.titulo, 'Novo título');
      expect(
        (await repo.obterVersaoPorId(principal.id))!.documento.conteudoOriginal,
        contains('[C]Principal'),
      );
      expect(
        (await classificacao.obter(musica.id)).energia,
        EnergiaMusica.animada,
      );
    },
  );

  test(
    'alternativa não usada atualiza o mesmo ID e invalida último tom próprio',
    () async {
      final v = await alternativa();
      await tons.salvarUltimoTom(v.id, principal.tomOriginal);
      final resultado = await editar.executar(
        origem: v,
        editada: mudar(v, tom: 'D'),
      );
      expect(resultado.id, v.id);
      expect(resultado.documento.conteudoOriginal, contains('[D]Alternativa'));
      expect((await repo.listarPorMusica(musica.id)).length, 2);
      expect(
        (await repo.obterVersaoPorId(principal.id))!.documento.conteudoOriginal,
        principal.documento.conteudoOriginal,
      );
      expect(await tons.obterUltimoTom(v.id), isNull);
    },
  );

  test(
    'atualização explícita preserva o ChordPro e os metadados da versão',
    () async {
      final v = await alternativa();
      final conteudo = v.documento.conteudoOriginal
          .replaceAll('{title: T}', '{title:  T  }')
          .replaceAll(
            '[C]Principal',
            '{diretiva_desconhecida: preservar}\n[D]Novo',
          );
      final editada = VersaoMusica(
        id: v.id,
        idMusica: v.idMusica,
        nome: v.nome,
        documento: parser.interpretar(conteudo),
        principal: v.principal,
        arquivada: v.arquivada,
      );
      await AtualizarConteudoVersaoMusica(repo).executar(editada);
      final salva = (await repo.obterVersaoPorId(v.id))!;
      expect(salva.documento.conteudoOriginal, conteudo);
      expect(salva.nome, v.nome);
      expect(salva.principal, v.principal);
      expect(salva.arquivada, v.arquivada);
      expect(
        dir.listSync().where(
          (f) => f.path.endsWith('.tmp') || f.path.endsWith('.bak'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'alternativa usada cria nova versão com origem e Lista intactas',
    () async {
      final v = await alternativa();
      await usar(v);
      final resultado = await editar.executar(
        origem: v,
        editada: mudar(v),
        nomeNovaVersao: 'Nova',
        acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
      );
      expect(resultado.id, isNot(v.id));
      expect(
        (await repo.obterVersaoPorId(v.id))!.documento.conteudoOriginal,
        v.documento.conteudoOriginal,
      );
      final item = await banco
          .customSelect('SELECT * FROM itens_lista_culto')
          .getSingle();
      expect(item.read<String>('id_versao_musica'), v.id.valor);
      await expectLater(
        repo.atualizarConteudoVersao(mudar(v)),
        throwsStateError,
      );
    },
  );

  test('conteúdo alterado e restaurado não cria versão', () async {
    final editada = mudar(principal);
    final restaurada = editar.preparar(
      editada,
      ConteudoChordProEditavel.extrair(principal.documento.conteudoOriginal),
      const RevisaoMetadadosChordPro(),
    );
    expect(editar.conteudoMusicalAlterado(principal, restaurada), isFalse);
    await editar.executar(origem: principal, editada: restaurada);
    expect((await repo.listarPorMusica(musica.id)).length, 1);
  });

  test('nome vazio rejeitado antes de persistir', () async {
    await expectLater(
      editar.executar(
        origem: principal,
        editada: mudar(principal),
        nomeNovaVersao: '  ',
        acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
      ),
      throwsArgumentError,
    );
    expect((await repo.listarPorMusica(musica.id)).length, 1);
  });

  test(
    'retry após falha de catálogo reutiliza a nova versão já criada',
    () async {
      final catalogo = _RepositorioMusicasFalhaUmaVez(repo);
      final editor = EditarVersaoMusica(
        repositorio: repo,
        repositorioMusicas: catalogo,
        criarVersao: criar,
        avaliarPolitica: AvaliarPoliticaEdicaoVersao(repo),
        repositorioTom: tons,
      );
      final editada = editor.preparar(
        principal,
        ConteudoChordProEditavel.extrair(principal.documento.conteudoOriginal)
            .replaceAll('[C]Principal', '[D]Nova'),
        const RevisaoMetadadosChordPro(titulo: 'Novo título', tom: 'D'),
      );
      final estado = EstadoSalvamentoEdicaoVersao();

      await expectLater(
        editor.executar(
          origem: principal,
          editada: editada,
          nomeNovaVersao: 'Nova',
          acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
          estadoSalvamento: estado,
        ),
        throwsStateError,
      );
      final idCriado = estado.versaoPersistida!.id;
      expect((await repo.listarPorMusica(musica.id)).length, 2);

      final resultado = await editor.executar(
        origem: principal,
        editada: editada,
        nomeNovaVersao: 'Nova',
        acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
        estadoSalvamento: estado,
      );

      expect(resultado.id, idCriado);
      expect((await repo.listarPorMusica(musica.id)).length, 2);
      expect((await repo.obterPorId(musica.id))!.titulo, 'Novo título');
    },
  );

  test(
    'falha antes da criação permite retry com uma única nova versão',
    () async {
      final versoes = _RepositorioVersoesFalhaUmaVez(repo);
      final editor = EditarVersaoMusica(
        repositorio: versoes,
        repositorioMusicas: repo,
        criarVersao: CriarVersaoMusica(
          repositorio: versoes,
          geradorId: _Gerador(),
        ),
        avaliarPolitica: AvaliarPoliticaEdicaoVersao(versoes),
        repositorioTom: tons,
      );
      final editada = editor.preparar(
        principal,
        ConteudoChordProEditavel.extrair(principal.documento.conteudoOriginal)
            .replaceAll('[C]Principal', '[D]Nova'),
        const RevisaoMetadadosChordPro(tom: 'D'),
      );
      final estado = EstadoSalvamentoEdicaoVersao();

      await expectLater(
        editor.executar(
          origem: principal,
          editada: editada,
          nomeNovaVersao: 'Nova',
          acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
          estadoSalvamento: estado,
        ),
        throwsStateError,
      );
      expect(estado.versaoPersistida, isNull);
      expect((await repo.listarPorMusica(musica.id)).length, 1);

      await editor.executar(
        origem: principal,
        editada: editada,
        nomeNovaVersao: 'Nova',
        acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
        estadoSalvamento: estado,
      );

      expect((await repo.listarPorMusica(musica.id)).length, 2);
    },
  );

  test('retry após falha de classificação não cria segunda versão', () async {
    final classificacaoInstavel = _RepositorioClassificacaoFalhaUmaVez(
      classificacao,
    );
    final salvarClassificacao = SalvarClassificacaoMusica(
      classificacaoInstavel,
    );
    final estado = EstadoSalvamentoEdicaoVersao();
    final editada = mudar(principal, tom: 'D');

    final primeira = await editar.executar(
      origem: principal,
      editada: editada,
      nomeNovaVersao: 'Nova',
      acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
      estadoSalvamento: estado,
    );
    await expectLater(
      salvarClassificacao.executar(
        musica.id,
        energia: EnergiaMusica.animada,
        tags: const [],
      ),
      throwsStateError,
    );
    expect((await repo.listarPorMusica(musica.id)).length, 2);

    final segunda = await editar.executar(
      origem: principal,
      editada: editada,
      nomeNovaVersao: 'Nova',
      acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
      estadoSalvamento: estado,
    );
    await salvarClassificacao.executar(
      musica.id,
      energia: EnergiaMusica.animada,
      tags: const [],
    );

    expect(segunda.id, primeira.id);
    expect((await repo.listarPorMusica(musica.id)).length, 2);
    expect(classificacaoInstavel.falhas, 1);
  });

  test(
    'abandonar salvamento após falha parcial não cria versão adicional',
    () async {
      final classificacaoInstavel = _RepositorioClassificacaoFalhaUmaVez(
        classificacao,
      );
      final estado = EstadoSalvamentoEdicaoVersao();

      await editar.executar(
        origem: principal,
        editada: mudar(principal, tom: 'D'),
        nomeNovaVersao: 'Nova',
        acaoConteudo: AcaoEdicaoConteudoVersao.criarNovaVersao,
        estadoSalvamento: estado,
      );
      await expectLater(
        SalvarClassificacaoMusica(
          classificacaoInstavel,
        ).executar(musica.id, energia: EnergiaMusica.animada, tags: const []),
        throwsStateError,
      );

      expect(estado.versaoPersistida, isNotNull);
      expect((await repo.listarPorMusica(musica.id)).length, 2);
    },
  );

  testWidgets(
    'cancelar escolha da principal não persiste conteúdo, catálogo ou classificação',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TelaEdicaoMusica(
            musica: musica,
            versao: principal,
            editarVersaoMusica: editar,
            obterClassificacaoMusica: ObterClassificacaoMusica(classificacao),
            salvarClassificacaoMusica: SalvarClassificacaoMusica(classificacao),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Título não salvo',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'D');
      await tester.tap(find.text('Animada'));
      await tester.ensureVisible(find.text('Salvar alterações'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Salvar alterações'));
        await banco.possuiItemListaParaVersao(principal.id.valor);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Como salvar as alterações?'), findsOneWidget);
      expect(find.text('Salvar alterações nesta versão'), findsOneWidget);
      expect(find.text('Salvar como nova versão'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Cancelar'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect((await repo.listarPorMusica(musica.id)).length, 1);
        expect((await repo.obterPorId(musica.id))!.titulo, 'T');
        expect(
          (await repo.obterVersaoPorId(principal.id))!
              .documento
              .conteudoOriginal,
          principal.documento.conteudoOriginal,
        );
        expect((await classificacao.obter(musica.id)).energia, isNull);
      });
      expect(find.text('Editar música'), findsOneWidget);
    },
  );
}

class _Gerador implements GeradorIdVersaoMusica {
  var numero = 0;
  @override
  IdVersaoMusica gerar() => IdVersaoMusica('versao-${++numero}');
}

class _RepositorioMusicasFalhaUmaVez implements RepositorioMusicas {
  _RepositorioMusicasFalhaUmaVez(this._delegate);

  final RepositorioMusicas _delegate;
  var _falharAtualizacao = true;

  @override
  Future<void> atualizar(Musica musica) {
    if (_falharAtualizacao) {
      _falharAtualizacao = false;
      throw StateError('falha de catálogo');
    }
    return _delegate.atualizar(musica);
  }

  @override
  Future<void> excluir(IdMusica id) => _delegate.excluir(id);

  @override
  Future<List<Musica>> listar() => _delegate.listar();

  @override
  Future<Musica?> obterPorId(IdMusica id) => _delegate.obterPorId(id);

  @override
  Future<void> salvar(Musica musica) => _delegate.salvar(musica);
}

class _RepositorioVersoesFalhaUmaVez implements RepositorioVersoesMusicas {
  _RepositorioVersoesFalhaUmaVez(this._delegate);

  final RepositorioVersoesMusicas _delegate;
  var _falharCriacao = true;

  @override
  Future<void> salvarVersao(VersaoMusica versao) {
    if (_falharCriacao) {
      _falharCriacao = false;
      throw StateError('falha antes da criação');
    }
    return _delegate.salvarVersao(versao);
  }

  @override
  Future<void> atualizarConteudoVersao(VersaoMusica versao) =>
      _delegate.atualizarConteudoVersao(versao);

  @override
  Future<void> arquivar(IdVersaoMusica id) => _delegate.arquivar(id);

  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) =>
      _delegate.definirComoPrincipal(id);

  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) =>
      _delegate.estaUsadaEmLista(id);

  @override
  Future<void> excluirVersao(IdVersaoMusica id) => _delegate.excluirVersao(id);

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) =>
      _delegate.listarPorMusica(idMusica);

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) =>
      _delegate.obterPrincipalPorMusica(idMusica);

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) =>
      _delegate.obterVersaoPorId(id);

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) =>
      _delegate.renomear(id, nome);

  @override
  Future<void> restaurar(IdVersaoMusica id) => _delegate.restaurar(id);
}

class _RepositorioClassificacaoFalhaUmaVez
    implements RepositorioClassificacaoMusica {
  _RepositorioClassificacaoFalhaUmaVez(this._delegate);

  final RepositorioClassificacaoMusica _delegate;
  var _falharTags = true;
  var falhas = 0;

  @override
  Future<void> substituirTags(IdMusica idMusica, Iterable<TagMusica> tags) {
    if (_falharTags) {
      _falharTags = false;
      falhas++;
      throw StateError('falha de classificação');
    }
    return _delegate.substituirTags(idMusica, tags);
  }

  @override
  Future<void> definirEnergia(IdMusica idMusica, EnergiaMusica? energia) =>
      _delegate.definirEnergia(idMusica, energia);

  @override
  Future<Map<IdMusica, ClassificacaoMusica>> listar() => _delegate.listar();

  @override
  Future<ClassificacaoMusica> obter(IdMusica idMusica) =>
      _delegate.obter(idMusica);

  @override
  Future<void> removerPorMusica(IdMusica idMusica) =>
      _delegate.removerPorMusica(idMusica);
}
