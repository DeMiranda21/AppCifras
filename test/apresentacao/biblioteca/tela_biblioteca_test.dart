import 'package:appcifras/aplicacao/casos_de_uso/editar_versao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/versoes_musicas.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_versao_musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';

import 'dart:async';

import 'package:appcifras/aplicacao/biblioteca_oficial/atualizar_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/biblioteca_oficial/estado_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/classificacao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import 'package:appcifras/aplicacao/entrada/preparar_entrada_musica.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/aplicacao/portas/obter_informacoes_app.dart';
import 'package:appcifras/aplicacao/portas/repositorio_classificacao_musica.dart';
import 'package:appcifras/aplicacao/sincronizacao/resultado_sincronizacao.dart';
import 'package:appcifras/apresentacao/biblioteca/tela_biblioteca.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  Musica criarMusica(String id, String titulo, {String artista = 'Artista'}) =>
      Musica(
        id: IdMusica(id),
        documento: parser.interpretar(
          '{title: $titulo}\n{artist: $artista}\n{key: C}\n[C]Letra',
        ),
      );

  List<String> titulosDaLista(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((item) => (item.title as Text).data!)
      .toList();

  SalvarRascunhoChordPro salvador(_RepositorioFake repositorio) =>
      SalvarRascunhoChordPro(
        repositorio: repositorio,
        parserDocumento: parser,
        geradorId: _GeradorIdFake(IdMusica('musica-nova')),
      );

  ResultadoAtualizacaoBibliotecaOficial resultadoAtualizacao({
    String? geracao = 'geracao-1',
    int adicionadas = 0,
    int atualizadas = 0,
    int inalteradas = 0,
    int ausentes = 0,
    bool geracaoRegistrada = true,
    List<ErroAtualizacaoBibliotecaOficial> erros = const [],
    List<AvisoSincronizacao> avisos = const [],
  }) => ResultadoAtualizacaoBibliotecaOficial(
    geracao: geracao,
    adicionadas: adicionadas,
    atualizadas: atualizadas,
    inalteradas: inalteradas,
    origensAusentes: ausentes,
    geracaoRegistrada: geracaoRegistrada,
    erros: erros,
    avisos: avisos,
  );

  Future<void> montar(
    WidgetTester tester,
    _RepositorioFake repositorio, {
    _RepositorioClassificacaoFake? classificacao,
    Future<ResultadoAtualizacaoBibliotecaOficial> Function()?
    atualizarBibliotecaOficial,
    Future<EstadoBibliotecaOficial?> Function()? obterEstadoBibliotecaOficial,
    ObterInformacoesApp? obterInformacoesApp,
  }) => tester.pumpWidget(
    MaterialApp(
      home: TelaBiblioteca(
        listarMusicas: ListarMusicas(repositorio),
        prepararEntradaMusica: PrepararEntradaMusica(),
        salvarRascunhoChordPro: salvador(repositorio),
        obterMusicaPorId: ObterMusicaPorId(repositorio),
        editarVersaoMusica: EditarVersaoMusica(
          repositorio: repositorio,
          repositorioMusicas: repositorio,
          criarVersao: CriarVersaoMusica(
            repositorio: repositorio,
            geradorId: _GeradorVersao(),
          ),
          avaliarPolitica: AvaliarPoliticaEdicaoVersao(repositorio),
        ),
        obterVersaoMusicaPorId: ObterVersaoMusicaPorId(repositorio),
        atualizarMusica: AtualizarMusica(
          repositorio: repositorio,
          parserDocumento: parser,
        ),
        excluirMusica: ExcluirMusica(repositorio),
        listarClassificacoesMusicas: classificacao == null
            ? null
            : ListarClassificacoesMusicas(classificacao),
        obterClassificacaoMusica: classificacao == null
            ? null
            : ObterClassificacaoMusica(classificacao),
        salvarClassificacaoMusica: classificacao == null
            ? null
            : SalvarClassificacaoMusica(classificacao),
        atualizarBibliotecaOficial: atualizarBibliotecaOficial,
        obterEstadoBibliotecaOficial: obterEstadoBibliotecaOficial,
        obterInformacoesApp: obterInformacoesApp,
      ),
    ),
  );

  Future<void> abrirEntrada(
    WidgetTester tester,
    _RepositorioFake repositorio,
  ) async {
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar música'));
    await tester.pumpAndSettle();
  }

  Future<void> analisar(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextFormField), texto);
    await tester.tap(find.widgetWithText(FilledButton, 'Analisar'));
    await tester.pumpAndSettle();
  }

  testWidgets('Biblioteca abre a entrada simples de música', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    expect(find.text('Adicionar música'), findsOneWidget);
    expect(find.text('Cole ou digite sua cifra.'), findsOneWidget);
    expect(find.text('Título'), findsNothing);
  });

  testWidgets('mostra versão e hash do build no diálogo Sobre', (tester) async {
    await montar(
      tester,
      _RepositorioFake(),
      obterInformacoesApp: const _ObterInformacoesAppFake(
        InformacoesApp(versao: '1.0.0', numeroBuild: '1', commitGit: 'abc1234'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('abrir-sobre-app')));
    await tester.pumpAndSettle();

    expect(find.text('Sobre o AppCifras'), findsOneWidget);
    expect(find.text('AppCifras 1.0.0 (1)'), findsOneWidget);
    expect(find.text('Build: abc1234'), findsOneWidget);
  });

  testWidgets('ausência de hash não quebra o diálogo Sobre', (tester) async {
    await montar(
      tester,
      _RepositorioFake(),
      obterInformacoesApp: const _ObterInformacoesAppFake(
        InformacoesApp(versao: '1.0.0', numeroBuild: '1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('abrir-sobre-app')));
    await tester.pumpAndSettle();

    expect(find.text('AppCifras 1.0.0 (1)'), findsOneWidget);
    expect(find.text('Build: não identificado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Biblioteca mistura músicas locais e sincronizadas em A-Z e mantém após recarga',
    (tester) async {
      final repositorio = _RepositorioFake()
        ..musicas.addAll([
          criarMusica('local-z', 'zulu'),
          criarMusica('sincronizada-a', 'Árvore'),
          criarMusica('local-b', 'BETA'),
          criarMusica('local-a', 'âncora'),
        ]);
      await montar(tester, repositorio);
      await tester.pumpAndSettle();

      expect(titulosDaLista(tester), ['âncora', 'Árvore', 'BETA', 'zulu']);

      await tester.tap(find.byKey(const ValueKey('local-b')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(titulosDaLista(tester), ['âncora', 'Árvore', 'BETA', 'zulu']);
    },
  );

  testWidgets('não analisa texto vazio', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    await tester.tap(find.widgetWithText(FilledButton, 'Analisar'));
    await tester.pump();
    expect(find.text('Informe uma cifra para analisar.'), findsOneWidget);
  });

  testWidgets('cifra textual abre revisão com tom e pendências', (
    tester,
  ) async {
    await abrirEntrada(tester, _RepositorioFake());
    await analisar(tester, 'Tom: E\n\n    E5\nSenhor, Tu és bom');
    expect(find.text('Revisar música'), findsOneWidget);
    final campos = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(campos.at(0)).controller!.text, '');
    expect(tester.widget<TextFormField>(campos.at(1)).controller!.text, '');
    expect(tester.widget<TextFormField>(campos.at(2)).controller!.text, 'E');
    expect(find.text('A cifra está pronta para salvar.'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('ChordPro completo preenche os metadados', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    await analisar(
      tester,
      '{title: Senhor}\n{artist: Artista}\n{key: E}\n[E]Letra',
    );
    final campos = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(campos.at(0)).controller!.text,
      'Senhor',
    );
    expect(
      tester.widget<TextFormField>(campos.at(1)).controller!.text,
      'Artista',
    );
    expect(tester.widget<TextFormField>(campos.at(2)).controller!.text, 'E');
  });

  testWidgets('apresenta tom inválido no campo correspondente', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    await analisar(
      tester,
      '{title: Senhor}\n{artist: Artista}\n{key: E}\n[E]Letra',
    );
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(2), 'H');
    final botao = find.widgetWithText(FilledButton, 'Salvar música');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();

    expect(find.text('Tom original inválido.'), findsOneWidget);
  });

  testWidgets('entrada ambígua mantém o texto e informa o usuário', (
    tester,
  ) async {
    await abrirEntrada(tester, _RepositorioFake());
    const texto = 'Senhor, Tu és bom\nTua misericórdia é pra sempre';
    await analisar(tester, texto);
    expect(
      find.textContaining('Não foi possível reconhecer a estrutura'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      texto,
    );
  });

  testWidgets('toque duplo durante análise não abre revisões duplicadas', (
    tester,
  ) async {
    await abrirEntrada(tester, _RepositorioFake());
    await tester.enterText(find.byType(TextFormField), 'Tom: E\n\nE5\nLetra');
    final botao = find.widgetWithText(FilledButton, 'Analisar');
    await tester.tap(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();

    expect(find.text('Revisar música'), findsOneWidget);
  });

  testWidgets('voltar da revisão preserva o texto de entrada', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    const texto = 'Tom: E\n\nE5\nSenhor, Tu és bom';
    await analisar(tester, texto);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      texto,
    );
  });

  testWidgets('conflito impede salvamento', (tester) async {
    await abrirEntrada(tester, _RepositorioFake());
    await analisar(
      tester,
      '{title: Um}\n{title: Dois}\n{artist: Artista}\n{key: C}\n[C]Letra',
    );
    expect(find.textContaining('informações repetidas'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Salvar música'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('revisão salva e atualiza a Biblioteca', (tester) async {
    final repositorio = _RepositorioFake();
    await abrirEntrada(tester, repositorio);
    await analisar(tester, 'Tom: E\n\nE5\nSenhor, Tu és bom');
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Senhor, Tu És Bom');
    await tester.enterText(campos.at(1), 'Israel & New Breed');
    final botao = find.widgetWithText(FilledButton, 'Salvar música');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Senhor, Tu És Bom'), findsOneWidget);
    expect(repositorio.musicas, hasLength(1));
  });

  testWidgets('edita música e recarrega cifra e Biblioteca', (tester) async {
    final repositorio = _RepositorioFake();
    final original = Musica(
      id: IdMusica('musica-existente'),
      documento: parser.interpretar(
        '{appcifras_schema: 1}\n'
        '{appcifras_id: musica-existente}\n'
        '{title: Nome antigo}\n'
        '{artist: Artista antigo}\n'
        '{key: C}\n'
        '[C]Letra antiga',
      ),
    );
    repositorio.musicas.add(original);

    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-existente')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar música'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(campos.at(0)).controller!.text,
      'Nome antigo',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('modo-editor-musica')),
        matching: find.text('ChordPro avançado'),
      ),
    );
    await tester.pump();
    final conteudo = find.byKey(const ValueKey('conteudo-edicao'));
    expect(
      tester.widget<TextFormField>(conteudo).controller!.text,
      contains('[C]Letra antiga'),
    );
    expect(
      tester.widget<TextFormField>(conteudo).controller!.text,
      isNot(contains('appcifras_id')),
    );
    expect(
      tester.widget<TextFormField>(conteudo).controller!.text,
      isNot(contains('appcifras_schema')),
    );
    await tester.enterText(campos.at(0), 'Nome revisado');
    final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();

    expect(find.text('Nome revisado'), findsOneWidget);
    expect(repositorio.musicas, hasLength(1));
    expect(repositorio.musicas.single.id, original.id);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nome revisado'), findsOneWidget);
  });

  testWidgets('cancelar edição não altera a música', (tester) async {
    final repositorio = _RepositorioFake();
    repositorio.musicas.add(
      Musica(
        id: IdMusica('musica-existente'),
        documento: parser.interpretar(
          '{title: Nome}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      ),
    );
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-existente')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar música'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Não salvar');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Nome'), findsOneWidget);
    expect(repositorio.musicas.single.titulo, 'Nome');
  });

  testWidgets('abre a edição de blocos de músicas diferentes em sequência', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    Musica criarMusica(String id, String titulo, String conteudo) => Musica(
      id: IdMusica(id),
      documento: parser.interpretar(
        '{title: $titulo}\n{artist: Artista}\n{key: C}\n$conteudo',
      ),
    );
    repositorio.musicas.addAll([
      criarMusica(
        'musica-a',
        'Música A',
        '{start_of_verse: label="Verso"}\n[C]Letra A\n{end_of_verse}',
      ),
      criarMusica(
        'musica-b',
        'Música B',
        '[Verso]\n[C]Letra B\n[Refrão]\n[G]Letra B2',
      ),
      criarMusica(
        'musica-c',
        'Música C',
        '[C]Trecho livre\n{start_of_chorus: label="Refrão"}\n[G]Letra C\n{end_of_chorus}',
      ),
    ]);

    await montar(tester, repositorio);
    await tester.pumpAndSettle();

    Future<void> abrirEEditarBloco(
      String id,
      Key bloco,
      String identificadorBloco,
    ) async {
      await tester.tap(find.byKey(ValueKey(id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar música'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('arrastar-bloco-$identificadorBloco')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('acoes-bloco-$identificadorBloco')),
        findsOneWidget,
      );
      final blocoEditavel = find.byKey(bloco);
      await tester.ensureVisible(blocoEditavel);
      await tester.tap(blocoEditavel);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('conteudo-edicao-secao')),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await abrirEEditarBloco('musica-a', const ValueKey('bloco-secao-3'), '3');
    await abrirEEditarBloco('musica-b', const ValueKey('bloco-secao-3'), '3');
    await abrirEEditarBloco('musica-c', const ValueKey('bloco-trecho-3'), '3');
  });

  testWidgets('confirma exclusão e atualiza a Biblioteca', (tester) async {
    final repositorio = _RepositorioFake();
    repositorio.musicas.add(
      Musica(
        id: IdMusica('musica-excluir'),
        documento: parser.interpretar(
          '{title: Música para excluir}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      ),
    );
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-excluir')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(find.text('Excluir "Música para excluir"?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repositorio.musicas, hasLength(1));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Nenhuma música na biblioteca'), findsOneWidget);
    expect(repositorio.musicas, isEmpty);
  });

  testWidgets(
    'combina texto, energia e tags sem recarregar a Biblioteca por filtro',
    (tester) async {
      final repositorio = _RepositorioFake();
      final classificacao = _RepositorioClassificacaoFake();
      final dados = [
        (
          'musica-a',
          'Graça A',
          '[C]Tua graça me alcançou',
          EnergiaMusica.calma,
          [TagMusica('Ceia'), TagMusica('Congregacional')],
        ),
        (
          'musica-b',
          'Graça B',
          '[C]Tua graça me alcançou',
          EnergiaMusica.animada,
          [TagMusica('Celebração')],
        ),
        (
          'musica-c',
          'Música C',
          '[C]Outra letra',
          EnergiaMusica.calma,
          [TagMusica('Ceia')],
        ),
        ('musica-d', 'Música D', '[C]Outra letra', null, <TagMusica>[]),
      ];
      for (final dado in dados) {
        final musica = Musica(
          id: IdMusica(dado.$1),
          documento: parser.interpretar(
            '{title: ${dado.$2}}\n{artist: Artista}\n{key: C}\n${dado.$3}',
          ),
        );
        repositorio.musicas.add(musica);
        classificacao.dados[musica.id] = ClassificacaoMusica(
          energia: dado.$4,
          tags: dado.$5,
        );
      }

      await montar(tester, repositorio, classificacao: classificacao);
      await tester.pumpAndSettle();
      final listagensIniciais = repositorio.listagens;
      final pesquisa = find.byType(TextField);
      await tester.enterText(pesquisa, 'graca');
      await tester.pump();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-b')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-c')), findsNothing);

      Future<void> abrirFiltros() async {
        await tester.tap(
          find.byKey(const ValueKey('abrir-filtros-biblioteca')),
        );
        await tester.pumpAndSettle();
      }

      Future<void> aplicarFiltros() async {
        await tester.tap(
          find.byKey(const ValueKey('aplicar-filtros-biblioteca')),
        );
        await tester.pumpAndSettle();
      }

      await abrirFiltros();
      await tester.tap(find.byKey(const ValueKey('filtro-energia-calma')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-b')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('indicador-filtros-ativos')),
        findsNothing,
      );

      await abrirFiltros();
      await tester.tap(find.byKey(const ValueKey('filtro-energia-calma')));
      await tester.tap(find.byKey(const ValueKey('filtro-tag-ceia')));
      await aplicarFiltros();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-b')), findsNothing);
      expect(
        find.byKey(const ValueKey('indicador-filtros-ativos')),
        findsOneWidget,
      );
      expect(repositorio.listagens, listagensIniciais);

      await tester.enterText(pesquisa, '');
      await tester.pump();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-d')), findsNothing);

      await abrirFiltros();
      await tester.tap(find.byKey(const ValueKey('filtro-tag-congregacional')));
      await aplicarFiltros();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-c')), findsNothing);

      await tester.enterText(pesquisa, 'graca');
      await tester.pump();
      await abrirFiltros();
      await tester.tap(find.byKey(const ValueKey('limpar-filtros-biblioteca')));
      await aplicarFiltros();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-b')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-c')), findsNothing);

      await tester.enterText(pesquisa, '');
      await tester.pump();
      for (final id in ['musica-a', 'musica-b', 'musica-c', 'musica-d']) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }

      await abrirFiltros();
      await tester.tap(find.byKey(const ValueKey('filtro-energia-calma')));
      await tester.tap(find.byKey(const ValueKey('filtro-tag-celebração')));
      await aplicarFiltros();
      expect(
        find.text('Nenhuma música encontrada para esta pesquisa.'),
        findsOneWidget,
      );
      expect(repositorio.listagens, listagensIniciais);
    },
  );

  testWidgets('recarrega classificações após editar música com filtro ativo', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    final classificacao = _RepositorioClassificacaoFake();
    final musica = Musica(
      id: IdMusica('musica-1'),
      documento: parser.interpretar(
        '{title: Música}\n{artist: Artista}\n{key: C}\n[C]Letra',
      ),
    );
    repositorio.musicas.add(musica);
    classificacao.dados[musica.id] = const ClassificacaoMusica(
      energia: EnergiaMusica.calma,
    );
    await montar(tester, repositorio, classificacao: classificacao);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('abrir-filtros-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filtro-energia-calma')));
    await tester.tap(find.byKey(const ValueKey('aplicar-filtros-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar música'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Animada'));
    final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma música encontrada para esta pesquisa.'),
      findsOneWidget,
    );
    expect(
      (await classificacao.obter(musica.id)).energia,
      EnergiaMusica.animada,
    );
  });

  testWidgets('remove filtro de tag que deixa de existir ao recarregar', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    final classificacao = _RepositorioClassificacaoFake();
    final musica = Musica(
      id: IdMusica('musica-1'),
      documento: parser.interpretar(
        '{title: Música}\n{artist: Artista}\n{key: C}\n[C]Letra',
      ),
    );
    repositorio.musicas.add(musica);
    classificacao.dados[musica.id] = ClassificacaoMusica(
      tags: [TagMusica('Ceia')],
    );
    await montar(tester, repositorio, classificacao: classificacao);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('abrir-filtros-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filtro-tag-ceia')));
    await tester.tap(find.byKey(const ValueKey('aplicar-filtros-biblioteca')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('musica-1')));
    await tester.pumpAndSettle();
    await classificacao.substituirTags(musica.id, []);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('musica-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('indicador-filtros-ativos')),
      findsNothing,
    );
  });

  testWidgets(
    'pesquisa título, artista e letra sem nova leitura e permite limpar',
    (tester) async {
      final repositorio = _RepositorioFake();
      for (final dados in [
        ('Graça Suprema', 'Artista A', '[C]Letra A', 'musica-a'),
        ('Outra Canção', 'Ministério da Graça', '[C]Letra B', 'musica-b'),
        (
          'Canção C',
          'Artista C',
          '[C]Tua graça me alcançou\nO Espírito Santo está aqui',
          'musica-c',
        ),
        (
          'Canção D',
          'Artista D',
          '[C]Conteúdo sem correspondência',
          'musica-d',
        ),
      ]) {
        repositorio.musicas.add(
          Musica(
            id: IdMusica(dados.$4),
            documento: parser.interpretar(
              '{title: ${dados.$1}}\n{artist: ${dados.$2}}\n{key: C}\n${dados.$3}',
            ),
          ),
        );
      }
      await montar(tester, repositorio);
      await tester.pumpAndSettle();
      final leiturasIniciais = repositorio.listagens;
      final pesquisa = find.byType(TextField);
      await tester.enterText(pesquisa, '  graca  ');
      await tester.pump();
      expect(find.byKey(const ValueKey('musica-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-b')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('musica-d')), findsNothing);
      expect(repositorio.listagens, leiturasIniciais);

      await tester.enterText(pesquisa, '  ESPIRITO   SANTO ');
      await tester.pump();
      expect(repositorio.listagens, leiturasIniciais);
      final musicaDaLetra = find.byKey(const ValueKey('musica-c'));
      expect(musicaDaLetra, findsOneWidget);
      await tester.tap(musicaDaLetra);
      await tester.pumpAndSettle();
      expect(find.text('Cifra'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final leiturasAposNavegacao = repositorio.listagens;

      await tester.enterText(pesquisa, 'inexistente');
      await tester.pump();
      expect(
        find.text('Nenhuma música encontrada para esta pesquisa.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Limpar pesquisa'));
      await tester.pump();
      for (final id in ['musica-a', 'musica-b', 'musica-c', 'musica-d']) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }
      expect(repositorio.listagens, leiturasAposNavegacao);
    },
  );

  testWidgets('mostra trecho da letra somente quando a busca o corresponde', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    for (final dados in [
      (
        'Graça no título',
        'Artista A',
        '[C]Letra sem correspondência',
        'titulo',
      ),
      ('Canção B', 'Artista B', '[C]Tua graça me alcançou', 'letra'),
      ('Canção C', 'Artista C', '[C]Pela graça [G]somos salvos', 'acordes'),
      ('Canção D', 'Artista D', '[C]Outra letra', 'fora'),
    ]) {
      repositorio.musicas.add(
        Musica(
          id: IdMusica(dados.$4),
          documento: parser.interpretar(
            '{title: ${dados.$1}}\n{artist: ${dados.$2}}\n{key: C}\n${dados.$3}',
          ),
        ),
      );
    }
    await montar(tester, repositorio);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  GRACA ');
    await tester.pump();

    expect(find.byKey(const ValueKey('titulo')), findsOneWidget);
    expect(find.byKey(const ValueKey('letra')), findsOneWidget);
    expect(find.byKey(const ValueKey('acordes')), findsOneWidget);
    expect(find.byKey(const ValueKey('fora')), findsNothing);
    expect(find.text('Tua graça me alcançou'), findsOneWidget);
    expect(find.text('Pela graça somos salvos'), findsOneWidget);
    expect(find.text('[C]Pela graça [G]somos salvos'), findsNothing);
    expect(find.text('Letra sem correspondência'), findsNothing);

    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pump();

    expect(find.byKey(const ValueKey('fora')), findsOneWidget);
    expect(find.text('Tua graça me alcançou'), findsNothing);
    expect(find.text('Pela graça somos salvos'), findsNothing);
  });

  testWidgets('falha ao salvar mantém o usuário na edição', (tester) async {
    final repositorio = _RepositorioFake()..erroAtualizar = StateError('falha');
    repositorio.musicas.add(
      Musica(
        id: IdMusica('musica-existente'),
        documento: parser.interpretar(
          '{title: Nome}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      ),
    );
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-existente')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar música'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Nome alterado');
    final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();

    expect(find.text('Editar música'), findsOneWidget);
    expect(
      find.text('Não foi possível salvar as alterações. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('toque duplo em salvar não duplica a atualização', (
    tester,
  ) async {
    final repositorio = _RepositorioFake()
      ..atualizacaoPendente = Completer<void>();
    repositorio.musicas.add(
      Musica(
        id: IdMusica('musica-existente'),
        documento: parser.interpretar(
          '{title: Nome}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      ),
    );
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('musica-existente')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar música'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Nome alterado');
    final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.tap(salvar);
    await tester.pump();

    expect(repositorio.atualizacoes, 1);
    repositorio.atualizacaoPendente!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('expõe Atualizar biblioteca e oculta o fluxo SAF', (
    tester,
  ) async {
    await montar(
      tester,
      _RepositorioFake(),
      atualizarBibliotecaOficial: () async => resultadoAtualizacao(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atualizar-biblioteca')), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
    expect(find.byKey(const ValueKey('abrir-pasta-curada')), findsNothing);
    expect(find.byTooltip('Pasta da biblioteca'), findsNothing);
  });

  testWidgets('mostra loading e bloqueia execução simultânea', (tester) async {
    final conclusao = Completer<ResultadoAtualizacaoBibliotecaOficial>();
    var execucoes = 0;
    await montar(
      tester,
      _RepositorioFake(),
      atualizarBibliotecaOficial: () {
        execucoes++;
        return conclusao.future;
      },
    );
    await tester.pumpAndSettle();

    final botao = find.byKey(const ValueKey('atualizar-biblioteca'));
    await tester.tap(botao);
    await tester.tap(botao);
    await tester.pump();

    expect(execucoes, 1);
    expect(find.text('Atualizando'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    conclusao.complete(resultadoAtualizacao());
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca atualizada'), findsOneWidget);
  });

  testWidgets('sucesso sem mudanças mostra resumo, geração e data', (
    tester,
  ) async {
    final estado = EstadoBibliotecaOficial(
      ultimaGeracao: 'geracao-42',
      ultimaAtualizacao: DateTime.now(),
    );
    await montar(
      tester,
      _RepositorioFake()..musicas.add(criarMusica('local', 'Local')),
      atualizarBibliotecaOficial: () async =>
          resultadoAtualizacao(geracao: 'geracao-42', inalteradas: 1),
      obterEstadoBibliotecaOficial: () async => estado,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ultima-atualizacao-biblioteca')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca atualizada'), findsOneWidget);
    expect(find.text('1 inalterada'), findsOneWidget);
    expect(find.text('0 adicionadas'), findsOneWidget);
    expect(find.text('0 atualizadas'), findsOneWidget);
    expect(find.text('0 ausentes'), findsOneWidget);
    expect(find.text('0 erros'), findsOneWidget);
    expect(find.text('Geração: geracao-42'), findsOneWidget);
    expect(find.textContaining('Última atualização:'), findsNWidgets(2));
  });

  testWidgets('primeira atualização preenche Biblioteca e mantém A-Z', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    await montar(
      tester,
      repositorio,
      atualizarBibliotecaOficial: () async {
        repositorio.musicas.addAll([
          criarMusica('oficial-z', 'Zelo'),
          criarMusica('oficial-a', 'Árvore'),
        ]);
        return resultadoAtualizacao(adicionadas: 2);
      },
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma música na biblioteca'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await tester.pumpAndSettle();

    expect(titulosDaLista(tester), ['Árvore', 'Zelo']);
  });

  testWidgets('música atualizada aparece após o refresh', (tester) async {
    final repositorio = _RepositorioFake()
      ..musicas.add(criarMusica('oficial', 'Título antigo'));
    await montar(
      tester,
      repositorio,
      atualizarBibliotecaOficial: () async {
        repositorio.musicas[0] = criarMusica('oficial', 'Título novo');
        return resultadoAtualizacao(atualizadas: 1);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();
    expect(find.text('1 atualizada'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Título novo'), findsOneWidget);
    expect(find.text('Título antigo'), findsNothing);
  });

  testWidgets('pesquisa e filtros permanecem ativos após atualização', (
    tester,
  ) async {
    final repositorio = _RepositorioFake()
      ..musicas.addAll([
        criarMusica('calma-antiga', 'Graça antiga'),
        criarMusica('animada', 'Graça animada'),
      ]);
    final classificacao = _RepositorioClassificacaoFake()
      ..dados[IdMusica('calma-antiga')] = const ClassificacaoMusica(
        energia: EnergiaMusica.calma,
      )
      ..dados[IdMusica('animada')] = const ClassificacaoMusica(
        energia: EnergiaMusica.animada,
      );
    await montar(
      tester,
      repositorio,
      classificacao: classificacao,
      atualizarBibliotecaOficial: () async {
        repositorio.musicas.add(criarMusica('calma-nova', 'Graça nova'));
        classificacao.dados[IdMusica('calma-nova')] = const ClassificacaoMusica(
          energia: EnergiaMusica.calma,
        );
        return resultadoAtualizacao(adicionadas: 1);
      },
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'graca');
    await tester.tap(find.byKey(const ValueKey('abrir-filtros-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filtro-energia-calma')));
    await tester.tap(find.byKey(const ValueKey('aplicar-filtros-biblioteca')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calma-antiga')), findsOneWidget);
    expect(find.byKey(const ValueKey('calma-nova')), findsOneWidget);
    expect(find.byKey(const ValueKey('animada')), findsNothing);
    expect(
      find.byKey(const ValueKey('indicador-filtros-ativos')),
      findsOneWidget,
    );
    expect(find.text('graca'), findsOneWidget);
  });

  testWidgets('ausências, erros isolados e avisos aparecem sem falso sucesso', (
    tester,
  ) async {
    await montar(
      tester,
      _RepositorioFake()..musicas.add(criarMusica('local', 'Local')),
      atualizarBibliotecaOficial: () async => resultadoAtualizacao(
        geracao: 'geracao-parcial',
        adicionadas: 1,
        ausentes: 1,
        geracaoRegistrada: false,
        erros: const [
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.aplicacao,
            mensagem: 'Versão usada em Lista não pôde ser sobrescrita.',
            localizador: 'musicas/versao.cho',
          ),
        ],
        avisos: const [
          AvisoSincronizacao(
            codigo: CodigoAvisoSincronizacao.alternativaUsadaEmLista,
            mensagem: 'A versão antiga foi preservada.',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();

    expect(find.text('Atualização incompleta'), findsOneWidget);
    expect(find.text('1 adicionada'), findsOneWidget);
    expect(find.text('1 ausente'), findsOneWidget);
    expect(find.text('1 erro'), findsOneWidget);
    expect(find.text('Erros'), findsOneWidget);
    expect(find.textContaining('versao.cho'), findsOneWidget);
    expect(find.text('Avisos'), findsOneWidget);
    expect(
      find.textContaining('A versão antiga foi preservada.'),
      findsOneWidget,
    );
  });

  testWidgets('falha offline preserva Biblioteca e não informa conclusão', (
    tester,
  ) async {
    final repositorio = _RepositorioFake()
      ..musicas.add(criarMusica('local', 'Música local'));
    await montar(
      tester,
      repositorio,
      atualizarBibliotecaOficial: () async => resultadoAtualizacao(
        geracao: null,
        geracaoRegistrada: false,
        erros: const [
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.preparacao,
            mensagem: 'Sem conexão com a biblioteca oficial.',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final listagensAntes = repositorio.listagens;

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();

    expect(find.text('Atualização não concluída'), findsOneWidget);
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    expect(find.text('Biblioteca atualizada'), findsNothing);
    expect(repositorio.listagens, listagensAntes);
    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Música local'), findsOneWidget);
  });

  testWidgets('base URL ausente mostra erro claro sem crash', (tester) async {
    await montar(
      tester,
      _RepositorioFake(),
      atualizarBibliotecaOficial: () async => resultadoAtualizacao(
        geracao: null,
        geracaoRegistrada: false,
        erros: const [
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.preparacao,
            mensagem:
                'APPCIFRAS_LIBRARY_BASE_URL não foi configurada no build.',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('atualizar-biblioteca')));
    await tester.pumpAndSettle();

    expect(find.text('Atualização não concluída'), findsOneWidget);
    expect(find.textContaining('não foi configurada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ObterInformacoesAppFake implements ObterInformacoesApp {
  const _ObterInformacoesAppFake(this.informacoes);

  final InformacoesApp informacoes;

  @override
  Future<InformacoesApp> executar() async => informacoes;
}

class _RepositorioFake
    implements RepositorioMusicas, RepositorioVersoesMusicas {
  final List<VersaoMusica> alternativas = [];
  @override
  Future<void> atualizarConteudoVersao(VersaoMusica versao) async {
    alternativas[alternativas.indexWhere((v) => v.id == versao.id)] = versao;
  }

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async {
    for (final v in [
      ...musicas.map((m) => m.versaoPrincipal),
      ...alternativas,
    ]) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica id) async =>
      (await obterPorId(id))?.versaoPrincipal;
  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica id) async {
    final principal = await obterPrincipalPorMusica(id);
    return [?principal, ...alternativas.where((v) => v.idMusica == id)];
  }

  @override
  Future<void> salvarVersao(VersaoMusica versao) async =>
      alternativas.add(versao);
  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<Musica> musicas = [];
  Object? erroAtualizar;
  Completer<void>? atualizacaoPendente;
  var atualizacoes = 0;
  var listagens = 0;
  @override
  Future<void> excluir(IdMusica id) async =>
      musicas.removeWhere((m) => m.id == id);
  @override
  Future<List<Musica>> listar() async {
    listagens += 1;
    return List.of(musicas);
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    for (final musica in musicas) {
      if (musica.id == id) {
        return musica;
      }
    }
    return null;
  }

  @override
  Future<void> salvar(Musica musica) async => musicas.add(musica);

  @override
  Future<void> atualizar(Musica musica) async {
    atualizacoes += 1;
    if (erroAtualizar != null) {
      throw erroAtualizar!;
    }
    if (atualizacaoPendente != null) {
      await atualizacaoPendente!.future;
    }
    final indice = musicas.indexWhere((atual) => atual.id == musica.id);
    if (indice < 0) {
      throw StateError('Música não encontrada.');
    }
    musicas[indice] = musica;
  }
}

class _RepositorioClassificacaoFake implements RepositorioClassificacaoMusica {
  final Map<IdMusica, ClassificacaoMusica> dados = {};

  @override
  Future<void> definirEnergia(IdMusica id, EnergiaMusica? energia) async {
    final atual = await obter(id);
    dados[id] = ClassificacaoMusica(energia: energia, tags: atual.tags);
  }

  @override
  Future<ClassificacaoMusica> obter(IdMusica id) async =>
      dados[id] ?? const ClassificacaoMusica();

  @override
  Future<Map<IdMusica, ClassificacaoMusica>> listar() async =>
      Map.unmodifiable(dados);

  @override
  Future<void> removerPorMusica(IdMusica id) async => dados.remove(id);

  @override
  Future<void> substituirTags(IdMusica id, Iterable<TagMusica> tags) async {
    final atual = await obter(id);
    dados[id] = ClassificacaoMusica(
      energia: atual.energia,
      tags: tags.toList(),
    );
  }
}

class _GeradorIdFake implements GeradorIdMusica {
  const _GeradorIdFake(this._id);
  final IdMusica _id;
  @override
  IdMusica gerar() => _id;
}

class _GeradorVersao implements GeradorIdVersaoMusica {
  var numero = 0;
  @override
  IdVersaoMusica gerar() => IdVersaoMusica('nova-${++numero}');
}
