import 'dart:async';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/apresentacao/musica/tela_visualizacao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
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

  Future<void> montarTela(
    WidgetTester tester,
    Future<Musica?> Function(IdMusica) obter, {
    TextScaler? textScaler,
  }) {
    final repositorio = _RepositorioObterFake(obter);
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
          ),
        ),
      ),
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

  testWidgets('exibe título, artista e tom original da música', (tester) async {
    await montarTela(tester, (_) async => musica('Letra'));
    await tester.pumpAndSettle();

    expect(find.text('Grande é o Senhor'), findsOneWidget);
    expect(find.text('Exemplo'), findsOneWidget);
    expect(find.text('Tom original: C'), findsOneWidget);
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
}

class _RepositorioObterFake implements RepositorioMusicas {
  const _RepositorioObterFake(this._obter);

  final Future<Musica?> Function(IdMusica) _obter;

  @override
  Future<void> excluir(IdMusica id) async {}

  @override
  Future<List<Musica>> listar() async => [];

  @override
  Future<Musica?> obterPorId(IdMusica id) => _obter(id);

  @override
  Future<void> salvar(Musica musica) async {}

  @override
  Future<void> atualizar(Musica musica) async {}
}
