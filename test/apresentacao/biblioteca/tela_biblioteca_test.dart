import 'dart:async';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import 'package:appcifras/aplicacao/entrada/preparar_entrada_musica.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/apresentacao/biblioteca/tela_biblioteca.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  SalvarRascunhoChordPro salvador(_RepositorioFake repositorio) =>
      SalvarRascunhoChordPro(
        repositorio: repositorio,
        parserDocumento: parser,
        geradorId: _GeradorIdFake(IdMusica('musica-nova')),
      );

  Future<void> montar(WidgetTester tester, _RepositorioFake repositorio) =>
      tester.pumpWidget(
        MaterialApp(
          home: TelaBiblioteca(
            listarMusicas: ListarMusicas(repositorio),
            prepararEntradaMusica: PrepararEntradaMusica(),
            salvarRascunhoChordPro: salvador(repositorio),
            obterMusicaPorId: ObterMusicaPorId(repositorio),
            atualizarMusica: AtualizarMusica(
              repositorio: repositorio,
              parserDocumento: parser,
            ),
            excluirMusica: ExcluirMusica(repositorio),
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
    await tester.tap(find.text('Prévia do conteúdo'));
    await tester.pump();
    expect(find.textContaining('[E5]Senhor'), findsOneWidget);
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
    expect(
      tester.widget<TextFormField>(campos.at(3)).controller!.text,
      contains('[C]Letra antiga'),
    );
    expect(
      tester.widget<TextFormField>(campos.at(3)).controller!.text,
      isNot(contains('appcifras_id')),
    );
    expect(
      tester.widget<TextFormField>(campos.at(3)).controller!.text,
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

  testWidgets('pesquisa por título, artista, acentos e permite limpar', (
    tester,
  ) async {
    final repositorio = _RepositorioFake();
    for (final dados in [
      ('Coração de Adorador', 'Ministério Ágape', 'musica-1'),
      ('Outra Canção', 'Banda Exemplo', 'musica-2'),
    ]) {
      repositorio.musicas.add(
        Musica(
          id: IdMusica(dados.$3),
          documento: parser.interpretar(
            '{title: ${dados.$1}}\n{artist: ${dados.$2}}\n{key: C}\n[C]Letra',
          ),
        ),
      );
    }
    await montar(tester, repositorio);
    await tester.pumpAndSettle();
    final pesquisa = find.byType(TextField);
    await tester.enterText(pesquisa, '  coracao  ');
    await tester.pump();
    expect(find.byKey(const ValueKey('musica-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('musica-2')), findsNothing);
    await tester.enterText(pesquisa, 'ÁGAPE');
    await tester.pump();
    expect(find.byKey(const ValueKey('musica-1')), findsOneWidget);
    await tester.enterText(pesquisa, 'inexistente');
    await tester.pump();
    expect(
      find.text('Nenhuma música encontrada para esta pesquisa.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pump();
    expect(find.byKey(const ValueKey('musica-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('musica-2')), findsOneWidget);
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
    final salvar = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.tap(salvar);
    await tester.tap(salvar);
    await tester.pump();

    expect(repositorio.atualizacoes, 1);
    repositorio.atualizacaoPendente!.complete();
    await tester.pumpAndSettle();
  });
}

class _RepositorioFake implements RepositorioMusicas {
  final List<Musica> musicas = [];
  Object? erroAtualizar;
  Completer<void>? atualizacaoPendente;
  var atualizacoes = 0;
  @override
  Future<void> excluir(IdMusica id) async =>
      musicas.removeWhere((m) => m.id == id);
  @override
  Future<List<Musica>> listar() async => List.of(musicas);
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

class _GeradorIdFake implements GeradorIdMusica {
  const _GeradorIdFake(this._id);
  final IdMusica _id;
  @override
  IdMusica gerar() => _id;
}
