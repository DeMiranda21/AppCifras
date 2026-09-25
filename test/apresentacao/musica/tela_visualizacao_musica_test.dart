import 'dart:async';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/tom_execucao.dart';
import 'package:appcifras/aplicacao/portas/repositorio_tom_execucao.dart';
import 'package:appcifras/apresentacao/musica/tela_visualizacao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> montarTelaComRepositorio(
    WidgetTester tester,
    RepositorioMusicas repositorio, {
    TextScaler? textScaler,
    RepositorioTomExecucao? repositorioTomExecucao,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
        child: MaterialApp(
          home: TelaVisualizacaoMusica(
            idMusica: IdMusica('musica-1'),
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
    expect(find.textContaining('H7'), findsNWidgets(2));
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
