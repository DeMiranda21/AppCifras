import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/apresentacao/musica/tela_edicao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  Musica musica([String? conteudo]) => Musica(
    id: IdMusica('musica-1'),
    documento: parser.interpretar(
      conteudo ?? '{appcifras_schema: 1}\n{appcifras_id: musica-1}\n{title: T}\n{artist: A}\n{key: C}\n[C]Existente',
    ),
  );
  Future<_Repositorio> montar(
    WidgetTester tester, {
    bool estrutural = false,
    String? conteudo,
  }) async {
    final musicaAtual = musica(conteudo);
    final repositorio = _Repositorio()..salvar(musicaAtual);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaEdicaoMusica(
          musica: musicaAtual,
          atualizarMusica: AtualizarMusica(
            repositorio: repositorio,
            parserDocumento: parser,
          ),
        ),
      ),
    );
    if (!estrutural) {
      await tester.tap(find.text('ChordPro'));
      await tester.pump();
    }
    return repositorio;
  }

  testWidgets('cancelar prévia preserva editor e não persiste', (tester) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    const texto =
        '{title: T}\n{artist: A}\n{key: C}\n[C]Existente\nAm   F\nNova parte';
    await tester.enterText(campo, texto);
    final analisar = find.text('Analisar alterações');
    await tester.ensureVisible(analisar);
    await tester.tap(analisar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(tester.widget<TextFormField>(campo).controller!.text, texto);
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('aplicar modifica editor sem salvar', (tester) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    await tester.enterText(
      campo,
      '{title: T}\n{artist: A}\n{key: C}\n[C]Existente\nAm   F\nNova parte',
    );
    final analisar = find.text('Analisar alterações');
    await tester.ensureVisible(analisar);
    await tester.tap(analisar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar alterações'));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(campo).controller!.text,
      contains('[Am]Nova [F]parte'),
    );
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('aplicar e salvar persiste somente ao salvar', (tester) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    await tester.enterText(
      campo,
      '{title: T}\n{artist: A}\n{key: C}\n[C]Existente\nAm   F\nNova parte',
    );
    final analisar = find.text('Analisar alterações');
    await tester.ensureVisible(analisar);
    await tester.tap(analisar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar alterações'));
    await tester.pump();
    expect(repositorio.atualizacoes, 0);
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(repositorio.atualizacoes, 1);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!.id,
      IdMusica('musica-1'),
    );
  });

  testWidgets('informa quando não há alterações conversíveis', (tester) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    expect(
      tester.widget<TextFormField>(campo).controller!.text,
      isNot(contains('appcifras_id')),
    );
    final analisar = find.text('Analisar alterações');
    await tester.ensureVisible(analisar);
    await tester.tap(analisar);
    await tester.pump();
    expect(find.text('Nenhuma conversão necessária.'), findsOneWidget);
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('marca acorde válido no editor e só persiste ao salvar', (
    tester,
  ) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const conteudo = '{title: T}\n{artist: A}\n{key: C}\n[C]Existente\nAm7';
    final inicioDoAcorde = conteudo.lastIndexOf('Am7');
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection(
        baseOffset: inicioDoAcorde,
        extentOffset: inicioDoAcorde + 3,
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Marcar como acorde'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('acao-assistida-acorde')));
    await tester.pump();
    expect(controlador.text, '${conteudo.substring(0, inicioDoAcorde)}[Am7]');
    expect(repositorio.atualizacoes, 0);

    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(repositorio.atualizacoes, 1);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!
          .documento
          .conteudoOriginal,
      contains('[Am7]'),
    );
  });

  testWidgets('não oferece ação assistida para seleção inválida', (
    tester,
  ) async {
    await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    controlador.value = const TextEditingValue(
      text: 'XYZ',
      selection: TextSelection(baseOffset: 0, extentOffset: 3),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('acao-assistida-acorde')), findsNothing);
  });

  testWidgets('trata acorde selecionado entre colchetes como texto', (
    tester,
  ) async {
    await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    controlador.value = const TextEditingValue(
      text: '[Am7]',
      selection: TextSelection(baseOffset: 1, extentOffset: 4),
    );
    await tester.pump();

    expect(find.byTooltip('Tratar como texto'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('acao-assistida-acorde')));
    await tester.pump();
    expect(controlador.text, 'Am7');
  });

  testWidgets('sair sem salvar descarta a marcação assistida', (tester) async {
    final repositorio = _Repositorio()..salvar(musica());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TelaEdicaoMusica(
                    musica: musica(),
                    atualizarMusica: AtualizarMusica(
                      repositorio: repositorio,
                      parserDocumento: parser,
                    ),
                  ),
                ),
              ),
              child: const Text('Abrir edição'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir edição'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ChordPro'));
    await tester.pump();
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    controlador.value = const TextEditingValue(
      text: 'Am7',
      selection: TextSelection(baseOffset: 0, extentOffset: 3),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('acao-assistida-acorde')));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repositorio.atualizacoes, 0);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!
          .documento
          .conteudoOriginal,
      isNot(contains('[Am7]')),
    );
  });

  testWidgets('marca linha como seção, escolhe tipo e persiste ao salvar', (
    tester,
  ) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const conteudo =
        '{title: T}\n{artist: A}\n{key: C}\nRefrão\n[C]Tu és Senhor';
    final inicioDoRotulo = conteudo.indexOf('Refrão');
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection(
        baseOffset: inicioDoRotulo,
        extentOffset: inicioDoRotulo + 'Refrão'.length,
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Marcar como seção'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('acao-assistida-secao')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Refrão'));
    await tester.pump();
    expect(
      controlador.text,
      '{title: T}\n{artist: A}\n{key: C}\n'
      '{start_of_chorus: label="Refrão"}\n[C]Tu és Senhor\n{end_of_chorus}',
    );
    expect(repositorio.atualizacoes, 0);

    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(repositorio.atualizacoes, 1);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!
          .documento
          .conteudoOriginal,
      contains('{start_of_chorus: label="Refrão"}'),
    );
  });

  testWidgets('não oferece seção para seleção parcial da linha', (
    tester,
  ) async {
    await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    controlador.value = const TextEditingValue(
      text: 'Refrão',
      selection: TextSelection(baseOffset: 1, extentOffset: 6),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('acao-assistida-secao')), findsNothing);
  });

  testWidgets('sair sem salvar descarta a seção marcada', (tester) async {
    final repositorio = _Repositorio()..salvar(musica());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TelaEdicaoMusica(
                    musica: musica(),
                    atualizarMusica: AtualizarMusica(
                      repositorio: repositorio,
                      parserDocumento: parser,
                    ),
                  ),
                ),
              ),
              child: const Text('Abrir edição'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir edição'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ChordPro'));
    await tester.pump();
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    controlador.value = const TextEditingValue(
      text: 'Refrão\n[C]Letra',
      selection: TextSelection(baseOffset: 0, extentOffset: 6),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('acao-assistida-secao')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Refrão'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repositorio.atualizacoes, 0);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!
          .documento
          .conteudoOriginal,
      isNot(contains('{start_of_chorus:')),
    );
  });

  testWidgets('edita tipo e rótulo da seção e só persiste ao salvar', (
    tester,
  ) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const conteudo =
        '{title: T}\n{artist: A}\n{key: C}\n'
        '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}';
    final inicioLetra = conteudo.indexOf('[C]Letra');
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection.collapsed(offset: inicioLetra),
    );
    await tester.pump();

    expect(find.byTooltip('Editar seção'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('acao-assistida-editar-secao')));
    await tester.pumpAndSettle();
    expect(find.text('Editar seção'), findsOneWidget);
    expect(find.text('Verso'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('rotulo-edicao-secao')),
          )
          .initialValue,
      'Verso 1',
    );

    await tester.tap(find.byKey(const ValueKey('tipo-edicao-secao')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refrão').last);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('rotulo-edicao-secao')),
      'Refrão 1',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(
      controlador.text,
      '{title: T}\n{artist: A}\n{key: C}\n'
      '{start_of_chorus: label="Refrão 1"}\n[C]Letra\n{end_of_chorus}',
    );
    expect(repositorio.atualizacoes, 0);

    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(repositorio.atualizacoes, 1);
    expect(
      (await repositorio.obterPorId(IdMusica('musica-1')))!
          .documento
          .conteudoOriginal,
      contains('{start_of_chorus: label="Refrão 1"}'),
    );
  });

  testWidgets('reconhece marcador de seção e cancelar não altera o editor', (
    tester,
  ) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const conteudo =
        '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}';
    final inicioMarcador = conteudo.indexOf('start_of_verse');
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection.collapsed(offset: inicioMarcador),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('acao-assistida-editar-secao')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(controlador.text, conteudo);
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('não oferece edição de seção fora dela ou em seleção cruzada', (
    tester,
  ) async {
    await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const fora = 'Texto livre\n[C]Letra';
    controlador.value = const TextEditingValue(
      text: fora,
      selection: TextSelection.collapsed(offset: 0),
    );
    await tester.pump();
    expect(find.byTooltip('Editar seção'), findsNothing);

    const conteudo =
        '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\n'
        '{start_of_chorus: label="R"}\n[D]B\n{end_of_chorus}';
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection(
        baseOffset: conteudo.indexOf('[C]A'),
        extentOffset: conteudo.indexOf('[D]B') + 5,
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Editar seção'), findsNothing);
  });

  testWidgets('aplicar sem mudança preserva o documento externo byte a byte', (
    tester,
  ) async {
    final repositorio = await montar(tester);
    final campo = find.byType(TextFormField).at(3);
    final controlador = tester.widget<TextFormField>(campo).controller!;
    const conteudo = '{sov: label="Verso 1"}\n[C]Letra\n{eov}';
    controlador.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection.collapsed(offset: conteudo.indexOf('[C]Letra')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('acao-assistida-editar-secao')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(controlador.text, conteudo);
    expect(repositorio.atualizacoes, 0);
  });

  testWidgets('mostra blocos estruturais na ordem e conteúdo implícito', (
    tester,
  ) async {
    await montar(
      tester,
      estrutural: true,
      conteudo:
          '{title: T}\n{artist: A}\n{key: C}\nIntrodução livre\n'
          '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}\n'
          '{start_of_chorus: label="Refrão"}\n[G]Coro\n{end_of_chorus}',
    );

    expect(find.byKey(const ValueKey('modo-editor-musica')), findsOneWidget);
    expect(find.text('Sem seção'), findsOneWidget);
    expect(find.text('Verso 1'), findsOneWidget);
    expect(find.text('Refrão'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Verso 1')).dy,
      lessThan(tester.getTopLeft(find.text('Refrão')).dy),
    );
  });

  testWidgets('alterna da edição por blocos para ChordPro textual', (
    tester,
  ) async {
    await montar(tester, estrutural: true);

    expect(find.byKey(const ValueKey('conteudo-edicao')), findsNothing);
    await tester.tap(find.text('ChordPro'));
    await tester.pump();

    expect(find.byKey(const ValueKey('conteudo-edicao')), findsOneWidget);
  });

  testWidgets('tocar bloco abre a edição existente da seção', (tester) async {
    await montar(
      tester,
      estrutural: true,
      conteudo:
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}',
    );

    await tester.tap(find.byKey(const ValueKey('bloco-secao-3')));
    await tester.pumpAndSettle();

    expect(find.text('Editar seção'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('rotulo-edicao-secao')),
          )
          .initialValue,
      'Verso 1',
    );
  });

  testWidgets('duplica bloco e só persiste ao salvar', (tester) async {
    final repositorio = await montar(
      tester,
      estrutural: true,
      conteudo:
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_chorus: label="Refrão"}\n[C]Coro\n{end_of_chorus}',
    );

    await tester.tap(find.byKey(const ValueKey('acoes-bloco-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final duplicar = find.text('Duplicar');
    await tester.ensureVisible(duplicar);
    await tester.tap(duplicar);
    await tester.pump();

    expect(find.text('Refrão'), findsNWidgets(2));
    expect(repositorio.atualizacoes, 0);
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(repositorio.atualizacoes, 1);
  });

  testWidgets('excluir bloco pede confirmação, cancela e depois remove', (
    tester,
  ) async {
    await montar(
      tester,
      estrutural: true,
      conteudo:
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_chorus: label="Refrão"}\n[C]Coro\n{end_of_chorus}',
    );

    await tester.tap(find.byKey(const ValueKey('acoes-bloco-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final excluir = find.text('Excluir');
    await tester.ensureVisible(excluir);
    await tester.tap(excluir);
    await tester.pumpAndSettle();
    expect(find.text('Excluir "Refrão"?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Refrão'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('acoes-bloco-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(excluir);
    await tester.tap(excluir);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pump();
    expect(find.text('Refrão'), findsNothing);
  });

  testWidgets('seção sem fechamento é exibida sem ações destrutivas', (
    tester,
  ) async {
    await montar(
      tester,
      estrutural: true,
      conteudo:
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_verse: label="Verso"}\n[C]Letra',
    );

    expect(find.text('Verso'), findsOneWidget);
    expect(find.byKey(const ValueKey('acoes-bloco-3')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bloco-secao-3')));
    await tester.pumpAndSettle();
    expect(find.text('Editar seção'), findsOneWidget);
  });
}

class _Repositorio implements RepositorioMusicas {
  final Map<IdMusica, Musica> dados = {};
  var atualizacoes = 0;
  @override
  Future<void> salvar(Musica musica) async => dados[musica.id] = musica;
  @override
  Future<void> atualizar(Musica musica) async {
    atualizacoes++;
    dados[musica.id] = musica;
  }

  @override
  Future<void> excluir(IdMusica id) async => dados.remove(id);
  @override
  Future<List<Musica>> listar() async => dados.values.toList();
  @override
  Future<Musica?> obterPorId(IdMusica id) async => dados[id];
}
