import 'dart:async';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/tom_execucao.dart';
import 'package:appcifras/aplicacao/portas/repositorio_tom_execucao.dart';
import 'package:appcifras/apresentacao/musica/contexto_navegacao_lista_culto.dart';
import 'package:appcifras/apresentacao/musica/controle_tela_ativa.dart';
import 'package:appcifras/apresentacao/musica/tela_visualizacao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_item_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_lista_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

RenderPointerListener _listenerDaCifra(WidgetTester tester) {
  final areaDaCifra = find.byKey(const ValueKey('conteudo-cifra'));
  expect(areaDaCifra, findsOneWidget);
  final listener = tester.renderObject<RenderPointerListener>(areaDaCifra);
  expect(listener.hasSize, isTrue);
  expect(listener.size.isEmpty, isFalse);
  return listener;
}

Rect _retanguloInterativoDaCifra(WidgetTester tester) {
  final listener = _listenerDaCifra(tester);
  final retangulo = listener.localToGlobal(Offset.zero) & listener.size;
  expect(retangulo.width, greaterThan(0));
  expect(retangulo.height, greaterThan(0));
  return retangulo;
}

void _confirmarPontoInterativoDaCifra(WidgetTester tester, Offset ponto) {
  final listener = _listenerDaCifra(tester);
  final cadeia = tester.hitTestOnBinding(ponto).path;
  final cadeiaFormatada = cadeia
      .map((entrada) => entrada.target.runtimeType)
      .join(' -> ');
  expect(
    cadeia.any((entrada) => identical(entrada.target, listener)),
    isTrue,
    reason:
        'O ponto $ponto não atingiu o Listener da cifra. '
        'Retângulo: ${_retanguloInterativoDaCifra(tester)}. '
        'Cadeia: $cadeiaFormatada',
  );
}

void main() {
  final parser = ParserDocumentoChordPro();

  Musica musica(String conteudo) => Musica(
    id: IdMusica('musica-1'),
    documento: parser.interpretar(
      '{title: Grande é o Senhor}\n'
      '{artist: Exemplo}\n'
      '{key: C}\n'
      '{appcifras_schema: 1}\n'
      '{appcifras_id: musica-1}\n$conteudo',
    ),
  );

  Musica musicaComId(String id, String titulo, String conteudo) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      '{title: $titulo}\n'
      '{artist: Exemplo}\n'
      '{key: C}\n'
      '{appcifras_schema: 1}\n'
      '{appcifras_id: $id}\n$conteudo',
    ),
  );

  ContextoNavegacaoListaCulto contextoDaLista(
    List<Musica> musicas, {
    required int indiceAtual,
  }) => ContextoNavegacaoListaCulto(
    idLista: IdListaCulto('lista-1'),
    itens: [
      for (var indice = 0; indice < musicas.length; indice += 1)
        ItemListaCulto(
          id: IdItemListaCulto('item-${indice + 1}'),
          idLista: IdListaCulto('lista-1'),
          idMusica: musicas[indice].id,
          posicao: indice,
        ),
    ],
    indiceAtual: indiceAtual,
  );

  Future<void> montarTelaComRepositorio(
    WidgetTester tester,
    RepositorioMusicas repositorio, {
    TextScaler? textScaler,
    RepositorioTomExecucao? repositorioTomExecucao,
    ContextoNavegacaoListaCulto? contextoListaCulto,
    ControleTelaAtiva? controleTelaAtiva,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
        child: MaterialApp(
          home: TelaVisualizacaoMusica(
            idMusica:
                contextoListaCulto?.itemAtual.idMusica ?? IdMusica('musica-1'),
            obterMusicaPorId: ObterMusicaPorId(repositorio),
            atualizarMusica: AtualizarMusica(
              repositorio: repositorio,
              parserDocumento: parser,
            ),
            excluirMusica: ExcluirMusica(repositorio),
            obterUltimoTomExecucao: repositorioTomExecucao == null
                ? null
                : ObterUltimoTomExecucao(repositorioTomExecucao),
            salvarUltimoTomExecucao: repositorioTomExecucao == null
                ? null
                : SalvarUltimoTomExecucao(repositorioTomExecucao),
            removerUltimoTomExecucao: repositorioTomExecucao == null
                ? null
                : RemoverUltimoTomExecucao(repositorioTomExecucao),
            contextoListaCulto: contextoListaCulto,
            controleTelaAtiva: controleTelaAtiva ?? _ControleTelaAtivaFake(),
          ),
        ),
      ),
    );
  }

  Future<void> montarTela(
    WidgetTester tester,
    Future<Musica?> Function(IdMusica) obter, {
    TextScaler? textScaler,
  }) {
    final repositorio = _RepositorioObterFake(obter);
    return montarTelaComRepositorio(
      tester,
      repositorio,
      textScaler: textScaler,
    );
  }

  Future<void> aplicarPinca(
    WidgetTester tester, {
    required double fator,
  }) async {
    final retangulo = _retanguloInterativoDaCifra(tester);
    final centro = retangulo.center;
    final distanciaInicial = ((retangulo.width - 32) * 0.4)
        .clamp(80.0, 160.0)
        .toDouble();
    final primeiroPonto = centro - Offset(distanciaInicial / 2, 0);
    final segundoPonto = centro + Offset(distanciaInicial / 2, 0);
    _confirmarPontoInterativoDaCifra(tester, primeiroPonto);
    _confirmarPontoInterativoDaCifra(tester, segundoPonto);
    final primeiro = await tester.startGesture(primeiroPonto, pointer: 1);
    await tester.pump();
    final segundo = await tester.startGesture(segundoPonto, pointer: 2);
    await tester.pump();
    await segundo.moveBy(Offset(distanciaInicial * (fator - 1), 0));
    await tester.pump();
    await primeiro.up();
    await segundo.up();
    await tester.pump();
  }

  Future<void> arrastarCifra(WidgetTester tester, Offset deslocamento) async {
    final pontoInicial = _retanguloInterativoDaCifra(tester).center;
    _confirmarPontoInterativoDaCifra(tester, pontoInicial);
    final gesto = await tester.startGesture(pontoInicial);
    await tester.pump();
    await gesto.moveBy(deslocamento);
    await gesto.up();
    await tester.pump();
    await tester.pump();
  }

  Finder trechoDaLinha(int indice, String texto) => find.descendant(
    of: find.byKey(ValueKey('linha-$indice')),
    matching: find.text(texto),
  );

  double tamanhoDaFonte(WidgetTester tester, Finder texto) =>
      tester.widget<Text>(texto).style!.fontSize!;

  testWidgets('exibe carregamento enquanto obtém a música por ID', (
    tester,
  ) async {
    final carregamento = Completer<Musica?>();
    await montarTela(tester, (_) => carregamento.future);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    carregamento.complete(musica('Letra'));
    await tester.pump();
  });

  testWidgets('exibe título, artista e tom de execução original da música', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('Letra'));
    await tester.pumpAndSettle();

    expect(find.text('Grande é o Senhor'), findsOneWidget);
    expect(find.text('Exemplo'), findsOneWidget);
    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('Original: C'), findsNothing);
    expect(find.text('{title: Grande é o Senhor}'), findsNothing);
    expect(find.text('{appcifras_id: musica-1}'), findsNothing);
  });

  testWidgets('exibe linha somente com letra', (tester) async {
    await montarTela(tester, (_) async => musica('Somente letra'));
    await tester.pumpAndSettle();

    expect(find.text('Somente letra'), findsOneWidget);
  });

  testWidgets('associa um acorde ao trecho de letra subsequente', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[G]Grande é o Senhor'));
    await tester.pumpAndSettle();

    final linhaMusical = find.byKey(const ValueKey('linha-0'));
    expect(linhaMusical, findsOneWidget);
    expect(
      find.descendant(of: linhaMusical, matching: find.text('G')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: linhaMusical,
        matching: find.text('Grande é o Senhor'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('exibe múltiplos acordes e seus trechos subsequentes', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Digno de lou[D]vor'));
    await tester.pumpAndSettle();

    expect(find.text('C'), findsOneWidget);
    expect(find.text('Digno de lou'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('vor'), findsOneWidget);
  });

  testWidgets(
    'quebra linha longa entre unidades sem cortar acordes em tela estreita',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(240, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await montarTela(
        tester,
        (_) async =>
            musica('Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]'),
      );
      await tester.pumpAndSettle();

      final a9 = tester.getRect(find.text('A9/C#'));
      final b11 = tester.getRect(find.text('B11/D#'));
      final d2 = tester.getRect(find.text('D2(6)'));
      expect(a9.right, lessThanOrEqualTo(240));
      expect(b11.right, lessThanOrEqualTo(240));
      expect(d2.right, lessThanOrEqualTo(240));
      expect(d2.top, greaterThan(b11.top));
      expect(a9.top, d2.top);
      expect(find.byType(SingleChildScrollView), findsNothing);
    },
  );

  testWidgets('permite quebra interna da letra em unidade maior que a tela', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await montarTela(
      tester,
      (_) async => musica(
        '[Cmaj7(#11)/G#]uma frase de letra excepcionalmente longa sem outro acorde',
      ),
    );
    await tester.pumpAndSettle();

    final unidade = tester.getRect(find.byKey(const ValueKey('fragmento-0')));
    expect(unidade.right, lessThanOrEqualTo(280));
    expect(unidade.height, greaterThan(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('recalcula a composição com escala textual maior', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(425, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await montarTela(
      tester,
      (_) async =>
          musica('Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]'),
      textScaler: const TextScaler.linear(1.4),
    );
    await tester.pumpAndSettle();

    for (final acorde in ['B11/D#', 'D2(6)', 'A9/C#']) {
      final rect = tester.getRect(find.text(acorde));
      expect(rect.right, lessThanOrEqualTo(425));
      expect(rect.height, greaterThan(0));
    }
  });

  testWidgets('aumenta, diminui e redefine o tamanho da cifra por pinça', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Letra'));
    await tester.pumpAndSettle();
    final tamanhoPadrao = tamanhoDaFonte(tester, find.text('Letra'));

    await aplicarPinca(tester, fator: 1.5);
    final tamanhoMaior = tamanhoDaFonte(tester, find.text('Letra'));
    expect(tamanhoMaior, greaterThan(tamanhoPadrao));
    expect(tamanhoMaior, lessThanOrEqualTo(tamanhoPadrao * 1.8));

    await tester.tap(find.byTooltip('Redefinir tamanho da cifra'));
    await tester.pump();
    expect(tamanhoDaFonte(tester, find.text('Letra')), tamanhoPadrao);

    await aplicarPinca(tester, fator: 0.5);
    final tamanhoMenor = tamanhoDaFonte(tester, find.text('Letra'));
    expect(tamanhoMenor, lessThan(tamanhoPadrao));
    expect(tamanhoMenor, greaterThanOrEqualTo(tamanhoPadrao * 0.75));
  });

  testWidgets('mantém reflow e rolagem vertical após ampliar a cifra', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await montarTela(
      tester,
      (_) async =>
          musica('Tua [B11/D#]misericórdia é pra [D2(6)]sempre [A9/C#]'),
    );
    await tester.pumpAndSettle();

    await aplicarPinca(tester, fator: 1.5);

    for (final acorde in ['B11/D#', 'D2(6)', 'A9/C#']) {
      expect(tester.getRect(find.text(acorde)).right, lessThanOrEqualTo(240));
    }
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantém rolagem vertical de um dedo disponível', (tester) async {
    final conteudo = List.generate(40, (_) => '[C]Letra').join('\n');
    await montarTela(tester, (_) async => musica(conteudo));
    await tester.pumpAndSettle();

    await arrastarCifra(tester, const Offset(0, -240));
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('preserva linha vazia', (tester) async {
    await montarTela(
      tester,
      (_) async => musica('Primeira linha\n\nÚltima linha'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('linha-vazia')), findsOneWidget);
  });

  testWidgets('preserva acorde não interpretável como texto do acorde', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[H7]Texto'));
    await tester.pumpAndSettle();

    expect(find.text('H7'), findsOneWidget);
    expect(find.text('Texto'), findsOneWidget);
  });

  testWidgets('mantém acorde interpretável com a aparência normal', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Texto'));
    await tester.pumpAndSettle();

    final linha = find.byKey(const ValueKey('linha-0'));
    final acorde = tester.widget<Text>(
      find.descendant(of: linha, matching: find.text('C')),
    );

    expect(
      acorde.style?.color,
      Theme.of(tester.element(linha)).colorScheme.primary,
    );
  });

  testWidgets('destaca acorde não interpretável sem alterar seu texto', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[H7]Texto'));
    await tester.pumpAndSettle();

    final linha = find.byKey(const ValueKey('linha-0'));
    final acorde = tester.widget<Text>(
      find.descendant(of: linha, matching: find.text('H7')),
    );

    expect(find.text('H7'), findsOneWidget);
    expect(
      acorde.style?.color,
      Theme.of(tester.element(linha)).colorScheme.error,
    );
  });

  testWidgets('preserva conteúdo de linha não interpretada', (tester) async {
    await montarTela(tester, (_) async => musica('{linha quebrada'));
    await tester.pumpAndSettle();

    expect(find.text('{linha quebrada'), findsOneWidget);
  });

  testWidgets('exibe erro quando não consegue obter a música', (tester) async {
    await montarTela(tester, (_) => Future.error(StateError('falha')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar a música'), findsOneWidget);
  });

  testWidgets('altera o tom temporariamente com os controles de semitom', (
    tester,
  ) async {
    final original = musica('[C]Letra');
    final conteudoOriginal = original.documento.conteudoOriginal;
    final repositorio = _RepositorioObterFake((_) async => original);
    await montarTelaComRepositorio(tester, repositorio);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pumpAndSettle();

    expect(find.text('Tom: C#'), findsOneWidget);
    expect(find.text('Original: C'), findsOneWidget);
    expect(find.text('C#'), findsOneWidget);
    expect(repositorio.atualizacoes, 0);
    expect(original.documento.conteudoOriginal, conteudoOriginal);
    expect(original.tomOriginal.notaFundamental, const Nota(nome: NomeNota.c));

    await tester.tap(find.byTooltip('Diminuir tom'));
    await tester.pumpAndSettle();

    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('Original: C'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('mantém o zoom após transpor a música', (tester) async {
    await montarTela(tester, (_) async => musica('[C]Letra'));
    await tester.pumpAndSettle();
    await aplicarPinca(tester, fator: 1.5);
    final tamanhoAmpliado = tamanhoDaFonte(tester, find.text('Letra'));

    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pumpAndSettle();

    expect(find.text('Tom: C#'), findsOneWidget);
    expect(tamanhoDaFonte(tester, find.text('Letra')), tamanhoAmpliado);
  });

  testWidgets('percorre o ciclo cromático e retorna ao tom original', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Letra'));
    await tester.pumpAndSettle();

    for (var indice = 0; indice < 12; indice += 1) {
      await tester.tap(find.byTooltip('Aumentar tom'));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('Original: C'), findsNothing);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('bloqueia transposição insegura sem alterar a cifra', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Letra [H7]Preservado'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pumpAndSettle();

    expect(find.text('Tom: C'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('H7'), findsOneWidget);
    expect(
      find.textContaining(
        'Não foi possível alterar o tom. Revise os acordes destacados na cifra',
      ),
      findsOneWidget,
    );
    expect(find.text('1 trecho impede a transposição.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('revisar-problema-transposicao')),
      findsOneWidget,
    );
  });

  testWidgets('abre a edição posicionada no primeiro acorde problemático', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Letra [H7]Preservado'));
    await tester.pumpAndSettle();

    final revisar = find.byKey(const ValueKey('revisar-problema-transposicao'));
    await tester.ensureVisible(revisar);
    await tester.tap(revisar);
    await tester.pumpAndSettle();

    expect(find.text('Editar música'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('modo-editor-musica')),
        matching: find.text('ChordPro avançado'),
      ),
    );
    await tester.pump();
    final campoConteudo = find.byKey(const ValueKey('conteudo-edicao'));
    final editor = tester.widget<EditableText>(
      find.descendant(of: campoConteudo, matching: find.byType(EditableText)),
    );
    expect(editor.controller.text, contains('[H7]Preservado'));
    expect(editor.controller.selection.baseOffset, greaterThan(0));
  });

  testWidgets('informa todos os trechos que impedem a transposição', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[H7]Primeiro [X]Segundo'));
    await tester.pumpAndSettle();

    expect(find.text('2 trechos impedem a transposição.'), findsOneWidget);
    expect(find.text('H7'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('mantém revisão de acorde inválido acessível após zoom', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[H7]Texto'));
    await tester.pumpAndSettle();
    await aplicarPinca(tester, fator: 1.5);

    expect(find.text('H7'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('revisar-problema-transposicao')),
      findsOneWidget,
    );
  });

  testWidgets('navega por swipe e atualiza o indicador da Lista de Culto', (
    tester,
  ) async {
    final musicas = [
      musicaComId('musica-1', 'Primeira', '[C]Primeira letra'),
      musicaComId('musica-2', 'Segunda', '[C]Segunda letra'),
      musicaComId('musica-3', 'Terceira', '[C]Terceira letra'),
    ];
    await montarTelaComRepositorio(
      tester,
      _RepositorioColecao(musicas),
      contextoListaCulto: contextoDaLista(musicas, indiceAtual: 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Segunda'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Terceira'), findsOneWidget);
    expect(find.text('3 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(160, 0));
    expect(find.text('Segunda'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(160, 0));
    expect(find.text('Primeira'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(find.text('Anterior'), findsNothing);
    expect(find.text('Próxima'), findsNothing);
  });

  testWidgets('respeita os limites da Lista de Culto ao arrastar', (
    tester,
  ) async {
    final musicas = [
      musicaComId('musica-1', 'Primeira', '[C]Primeira letra'),
      musicaComId('musica-2', 'Segunda', '[C]Segunda letra'),
      musicaComId('musica-3', 'Terceira', '[C]Terceira letra'),
    ];
    await montarTelaComRepositorio(
      tester,
      _RepositorioColecao(musicas),
      contextoListaCulto: contextoDaLista(musicas, indiceAtual: 0),
    );
    await tester.pumpAndSettle();

    await arrastarCifra(tester, const Offset(160, 0));
    expect(find.text('Primeira'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Terceira'), findsOneWidget);
    expect(find.text('3 de 3'), findsOneWidget);

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(find.text('Terceira'), findsOneWidget);
    expect(find.text('3 de 3'), findsOneWidget);
  });

  testWidgets('não navega por swipe quando aberta fora da Lista de Culto', (
    tester,
  ) async {
    await montarTela(tester, (_) async => musica('[C]Letra da biblioteca'));
    await tester.pumpAndSettle();

    await arrastarCifra(tester, const Offset(-160, 0));

    expect(find.text('Letra da biblioteca'), findsOneWidget);
    expect(find.byKey(const ValueKey('navegacao-lista-posicao')), findsNothing);
  });

  testWidgets('mantém rolagem vertical e ignora gesto de pinça na navegação', (
    tester,
  ) async {
    final musicas = [
      musicaComId(
        'musica-1',
        'Primeira',
        List.generate(40, (_) => '[C]Primeira letra').join('\n'),
      ),
      musicaComId('musica-2', 'Segunda', '[C]Segunda letra'),
    ];
    await montarTelaComRepositorio(
      tester,
      _RepositorioColecao(musicas),
      contextoListaCulto: contextoDaLista(musicas, indiceAtual: 0),
    );
    await tester.pumpAndSettle();

    await arrastarCifra(tester, const Offset(20, -180));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.text('1 de 2'), findsOneWidget);

    await aplicarPinca(tester, fator: 1.5);
    expect(find.text('1 de 2'), findsOneWidget);
  });

  testWidgets('mantém zoom e reinicia a rolagem ao navegar por swipe', (
    tester,
  ) async {
    final musicas = [
      musicaComId(
        'musica-1',
        'Primeira',
        List.generate(40, (_) => '[C]Primeira letra').join('\n'),
      ),
      musicaComId('musica-2', 'Segunda', '[C]Segunda letra'),
    ];
    await montarTelaComRepositorio(
      tester,
      _RepositorioColecao(musicas),
      contextoListaCulto: contextoDaLista(musicas, indiceAtual: 0),
    );
    await tester.pumpAndSettle();
    await aplicarPinca(tester, fator: 1.5);
    final tamanhoAmpliado = tamanhoDaFonte(
      tester,
      trechoDaLinha(0, 'Primeira letra'),
    );

    await arrastarCifra(tester, const Offset(0, -180));
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );

    await arrastarCifra(tester, const Offset(-160, 0));
    expect(
      tamanhoDaFonte(tester, trechoDaLinha(0, 'Segunda letra')),
      tamanhoAmpliado,
    );
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0,
    );
  });

  testWidgets('reabre a visualização no tom original', (tester) async {
    final repositorio = _RepositorioObterFake((_) async => musica('[C]Letra'));
    final preferencias = _RepositorioTomExecucaoFake();
    await montarTelaComRepositorio(
      tester,
      repositorio,
      repositorioTomExecucao: preferencias,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pumpAndSettle();
    expect(find.text('Tom: C#'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await montarTelaComRepositorio(
      tester,
      repositorio,
      repositorioTomExecucao: preferencias,
    );
    await tester.pumpAndSettle();

    expect(find.text('Tom: C#'), findsOneWidget);
    expect(find.text('Original: C'), findsOneWidget);
  });

  testWidgets(
    'redefine o tom de execução após edição salvar novo tom original',
    (tester) async {
      final original = musica('[C]Letra');
      final repositorio = _RepositorioMemoria(original);
      await montarTelaComRepositorio(tester, repositorio);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Aumentar tom'));
      await tester.pumpAndSettle();
      expect(find.text('Tom: C#'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar música'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'D');
      final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
      await tester.ensureVisible(salvar);
      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(find.text('Tom: D'), findsOneWidget);
      expect(find.text('Original: D'), findsNothing);
      expect(repositorio.musica.id, original.id);
      expect(
        repositorio.musica.tomOriginal.notaFundamental,
        const Nota(nome: NomeNota.d),
      );
    },
  );

  testWidgets('mantém a tela ativa durante zoom, transposição e swipe', (
    tester,
  ) async {
    final primeira = musicaComId('musica-1', 'Primeira', '[C]Primeira');
    final segunda = musicaComId('musica-2', 'Segunda', '[D]Segunda');
    final controleTelaAtiva = _ControleTelaAtivaFake();
    await montarTelaComRepositorio(
      tester,
      _RepositorioColecao([primeira, segunda]),
      contextoListaCulto: contextoDaLista([primeira, segunda], indiceAtual: 0),
      controleTelaAtiva: controleTelaAtiva,
    );
    await tester.pumpAndSettle();

    expect(controleTelaAtiva.ativacoes, 1);
    expect(controleTelaAtiva.desativacoes, 0);

    await tester.tap(find.byTooltip('Aumentar tom'));
    await tester.pumpAndSettle();
    await aplicarPinca(tester, fator: 1.2);
    await arrastarCifra(tester, const Offset(-160, 0));

    expect(find.text('2 de 2'), findsOneWidget);
    expect(controleTelaAtiva.ativacoes, 1);
    expect(controleTelaAtiva.desativacoes, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(controleTelaAtiva.desativacoes, 1);
  });
}

class _RepositorioObterFake implements RepositorioMusicas {
  _RepositorioObterFake(this._obter);

  final Future<Musica?> Function(IdMusica) _obter;
  var atualizacoes = 0;

  @override
  Future<void> excluir(IdMusica id) async {}

  @override
  Future<List<Musica>> listar() async => [];

  @override
  Future<Musica?> obterPorId(IdMusica id) => _obter(id);

  @override
  Future<void> salvar(Musica musica) async {}

  @override
  Future<void> atualizar(Musica musica) async {
    atualizacoes += 1;
  }
}

class _RepositorioMemoria implements RepositorioMusicas {
  _RepositorioMemoria(this.musica);

  Musica musica;

  @override
  Future<void> atualizar(Musica musicaAtualizada) async {
    musica = musicaAtualizada;
  }

  @override
  Future<void> excluir(IdMusica id) async {}

  @override
  Future<List<Musica>> listar() async => [musica];

  @override
  Future<Musica?> obterPorId(IdMusica id) async =>
      musica.id == id ? musica : null;

  @override
  Future<void> salvar(Musica musicaNova) async {
    musica = musicaNova;
  }
}

class _RepositorioColecao implements RepositorioMusicas {
  _RepositorioColecao(Iterable<Musica> musicas)
    : _musicas = {for (final musica in musicas) musica.id: musica};

  final Map<IdMusica, Musica> _musicas;

  @override
  Future<void> atualizar(Musica musica) async => _musicas[musica.id] = musica;

  @override
  Future<void> excluir(IdMusica id) async => _musicas.remove(id);

  @override
  Future<List<Musica>> listar() async => _musicas.values.toList();

  @override
  Future<Musica?> obterPorId(IdMusica id) async => _musicas[id];

  @override
  Future<void> salvar(Musica musica) async => _musicas[musica.id] = musica;
}

class _RepositorioTomExecucaoFake implements RepositorioTomExecucao {
  final Map<IdMusica, Tom> _tons = {};

  @override
  Future<Tom?> obterUltimoTom(IdMusica idMusica) async => _tons[idMusica];

  @override
  Future<void> removerUltimoTom(IdMusica idMusica) async {
    _tons.remove(idMusica);
  }

  @override
  Future<void> salvarUltimoTom(IdMusica idMusica, Tom tom) async {
    _tons[idMusica] = tom;
  }
}

class _ControleTelaAtivaFake implements ControleTelaAtiva {
  var ativacoes = 0;
  var desativacoes = 0;

  @override
  Future<void> ativar() async {
    ativacoes += 1;
  }

  @override
  Future<void> desativar() async {
    desativacoes += 1;
  }
}
