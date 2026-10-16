import 'package:appcifras/aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import 'package:appcifras/aplicacao/entrada/preparar_entrada_musica.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/apresentacao/entrada/tela_revisao_entrada_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<_RepositorioFake> montar(WidgetTester tester, String conteudo) async {
    final repositorio = _RepositorioFake();
    final entrada = PrepararEntradaMusica().executar(conteudo);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaRevisaoEntradaMusica(
          entrada: entrada,
          salvarRascunhoChordPro: SalvarRascunhoChordPro(
            repositorio: repositorio,
            parserDocumento: ParserDocumentoChordPro(),
            geradorId: const _GeradorIdFake(),
          ),
        ),
      ),
    );
    await tester.pump();
    return repositorio;
  }

  String alvo(WidgetTester tester) {
    final texto = find.descendant(
      of: find.byKey(const ValueKey('problema-alvo')),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(texto).data!;
  }

  String contexto(WidgetTester tester) {
    final richText = find.descendant(
      of: find.byKey(const ValueKey('problema-contexto')),
      matching: find.byType(RichText),
    );
    return tester.widgetList<RichText>(richText).first.text.toPlainText();
  }

  Future<void> tocar(WidgetTester tester, Key chave) async {
    final finder = find.byKey(chave);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  const cabecalho = '{title: Canção}\n{artist: Artista}\n{key: C}\n';

  group('revisão contextual sequencial', () {
    testWidgets('1. mostra o primeiro problema com contador', (tester) async {
      await montar(tester, '${cabecalho}Primeira [H7] linha\nOutra [X9] linha');

      expect(find.text('Problema 1 de 2'), findsOneWidget);
      expect(alvo(tester), 'H7');
    });

    testWidgets('2. contexto identifica a ocorrência sem sintaxe ChordPro', (
      tester,
    ) async {
      await montar(tester, '${cabecalho}Antes [H7] depois');

      expect(contexto(tester), contains('Antes'));
      expect(contexto(tester), contains('depois'));
      expect(alvo(tester), 'H7');
      expect(contexto(tester), isNot(contains('[H7]')));
    });

    testWidgets('3. ocorrências iguais são resolvidas separadamente', (
      tester,
    ) async {
      await montar(
        tester,
        '${cabecalho}Primeira [H7] linha\nSegunda [H7] linha',
      );

      expect(contexto(tester), contains('Primeira'));
      await tocar(tester, const ValueKey('acao-eh-texto'));

      expect(find.text('Problema 1 de 1'), findsOneWidget);
      expect(contexto(tester), contains('Segunda'));
      expect(alvo(tester), 'H7');
    });

    testWidgets('4. É acorde resolve e avança', (tester) async {
      await montar(tester, 'Am7 G/B\n\nC D');

      expect(find.byKey(const ValueKey('acao-eh-acorde')), findsOneWidget);
      await tocar(tester, const ValueKey('acao-eh-acorde'));

      expect(find.text('Problema 1 de 1'), findsOneWidget);
      expect(alvo(tester), 'C D');
    });

    testWidgets('5. É texto resolve e avança', (tester) async {
      await montar(tester, '$cabecalho[H7] primeira\n[X9] segunda');

      await tocar(tester, const ValueKey('acao-eh-texto'));

      expect(find.text('Problema 1 de 1'), findsOneWidget);
      expect(alvo(tester), 'X9');
    });

    testWidgets('6. Corrigir acorde válido resolve e avança', (tester) async {
      await montar(tester, '$cabecalho[H7] primeira\n[X9] segunda');

      await tocar(tester, const ValueKey('acao-corrigir-acorde'));
      await tester.enterText(
        find.byKey(const ValueKey('correcao-acorde-campo')),
        'G/B',
      );
      await tocar(tester, const ValueKey('correcao-acorde-confirmar'));

      expect(find.text('Problema 1 de 1'), findsOneWidget);
      expect(alvo(tester), 'X9');
    });

    testWidgets('7. acorde inválido mantém diálogo e rascunho', (tester) async {
      await montar(tester, '${cabecalho}Antes [H7] depois');

      await tocar(tester, const ValueKey('acao-corrigir-acorde'));
      await tester.enterText(
        find.byKey(const ValueKey('correcao-acorde-campo')),
        'SOL',
      );
      await tocar(tester, const ValueKey('correcao-acorde-confirmar'));

      expect(find.textContaining('Acorde inválido'), findsOneWidget);
      expect(find.text('Corrigir acorde'), findsWidgets);
      await tocar(tester, const ValueKey('correcao-acorde-cancelar'));
      expect(alvo(tester), 'H7');
      expect(find.text('Problema 1 de 1'), findsOneWidget);
    });

    testWidgets('8. Anterior e Próximo navegam entre problemas', (
      tester,
    ) async {
      await montar(tester, '$cabecalho[H7] primeira\n[X9] segunda');

      await tocar(tester, const ValueKey('problema-proximo'));
      expect(find.text('Problema 2 de 2'), findsOneWidget);
      expect(alvo(tester), 'X9');

      await tocar(tester, const ValueKey('problema-anterior'));
      expect(find.text('Problema 1 de 2'), findsOneWidget);
      expect(alvo(tester), 'H7');
    });

    testWidgets('9. reanálise mantém índice dentro da nova lista', (
      tester,
    ) async {
      await montar(tester, '$cabecalho[H7] primeira\n[X9] segunda');

      await tocar(tester, const ValueKey('problema-proximo'));
      await tocar(tester, const ValueKey('acao-eh-texto'));

      expect(find.text('Problema 1 de 1'), findsOneWidget);
      expect(alvo(tester), 'H7');
    });

    testWidgets('10. resolver o último problema mostra estado pronto', (
      tester,
    ) async {
      await montar(tester, '${cabecalho}Antes [H7] depois');

      await tocar(tester, const ValueKey('acao-eh-texto'));

      expect(
        find.byKey(const ValueKey('estado-revisao-pronto')),
        findsOneWidget,
      );
      expect(find.text('A cifra está pronta para salvar.'), findsOneWidget);
      expect(find.textContaining('Problema 0 de 0'), findsNothing);
    });

    testWidgets('11. aviso sem ação fica fora da sequência', (tester) async {
      await montar(tester, 'Tom: C\n\nC          G\nOi');

      expect(
        find.byKey(const ValueKey('avisos-nao-acionaveis')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('problema-contador')), findsNothing);
      expect(
        find.byKey(const ValueKey('estado-revisao-pronto')),
        findsOneWidget,
      );
    });

    testWidgets('12. fluxo sem problemas mostra somente estado pronto', (
      tester,
    ) async {
      await montar(tester, '$cabecalho[C]Letra');

      expect(find.text('A cifra está pronta para salvar.'), findsOneWidget);
      expect(find.byKey(const ValueKey('problema-cifra')), findsNothing);
      expect(find.textContaining('Problema 0'), findsNothing);
    });

    testWidgets('13. salvamento produz DocumentoChordPro corrigido', (
      tester,
    ) async {
      final repositorio = await montar(tester, '${cabecalho}Antes [H7] depois');

      await tocar(tester, const ValueKey('acao-corrigir-acorde'));
      await tester.enterText(
        find.byKey(const ValueKey('correcao-acorde-campo')),
        'Am7',
      );
      await tocar(tester, const ValueKey('correcao-acorde-confirmar'));
      final salvar = find.widgetWithText(FilledButton, 'Salvar música');
      await tester.ensureVisible(salvar);
      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(repositorio.musicas, hasLength(1));
      expect(
        repositorio.musicas.single.documento.conteudoOriginal,
        contains('Antes [Am7] depois'),
      );
    });

    testWidgets('14. fluxo não depende de seleção ou menu contextual', (
      tester,
    ) async {
      await montar(tester, '${cabecalho}Antes [H7] depois');

      expect(find.byType(SelectableText), findsNothing);
      expect(find.byType(SelectionArea), findsNothing);
      expect(find.byKey(const ValueKey('problema-alvo')), findsOneWidget);
      expect(find.byKey(const ValueKey('acao-eh-texto')), findsOneWidget);
    });

    testWidgets('metadados continuam em campos próprios', (tester) async {
      await montar(tester, '$cabecalho[C]Letra');

      final campos = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(campos.at(0)).controller!.text,
        'Canção',
      );
      expect(
        tester.widget<TextFormField>(campos.at(1)).controller!.text,
        'Artista',
      );
      expect(tester.widget<TextFormField>(campos.at(2)).controller!.text, 'C');
    });
  });
}

class _RepositorioFake implements RepositorioMusicas {
  final List<Musica> musicas = [];

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    for (final musica in musicas) {
      if (musica.id == id) return musica;
    }
    return null;
  }

  @override
  Future<void> salvar(Musica musica) async => musicas.add(musica);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GeradorIdFake implements GeradorIdMusica {
  const _GeradorIdFake();

  @override
  IdMusica gerar() => IdMusica('musica-r2');
}
