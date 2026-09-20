import 'dart:async';

import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
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

  Musica musica(String id, String titulo, String artista) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      '{title: $titulo}\n{artist: $artista}\n{key: C}',
    ),
  );

  CadastrarMusica cadastrar(_RepositorioFake repositorio) => CadastrarMusica(
    repositorio: repositorio,
    parserDocumento: parser,
    geradorId: _GeradorIdMusicaFake(IdMusica('musica-nova')),
  );

  Future<void> montarBiblioteca(
    WidgetTester tester,
    _RepositorioFake repositorio,
  ) => tester.pumpWidget(
    MaterialApp(
      home: TelaBiblioteca(
        listarMusicas: ListarMusicas(repositorio),
        cadastrarMusica: cadastrar(repositorio),
      ),
    ),
  );

  Future<void> abrirCadastro(
    WidgetTester tester,
    _RepositorioFake repositorio,
  ) async {
    await montarBiblioteca(tester, repositorio);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar música'));
    await tester.pumpAndSettle();
  }

  Future<void> preencherFormulario(
    WidgetTester tester, {
    String tom = 'G',
  }) async {
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Grande é o Senhor');
    await tester.enterText(campos.at(1), 'Exemplo');
    await tester.enterText(campos.at(2), tom);
    await tester.enterText(campos.at(3), '[G]Grande é o [D]Senhor');
  }

  Future<void> tocarSalvar(WidgetTester tester) async {
    final botao = find.widgetWithText(FilledButton, 'Salvar música');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
  }

  testWidgets('exibe carregamento enquanto a lista é obtida', (tester) async {
    final carregamento = Completer<List<Musica>>();
    final repositorio = _RepositorioFake(listagem: () => carregamento.future);

    await montarBiblioteca(tester, repositorio);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    carregamento.complete([]);
    await tester.pump();
  });

  testWidgets('exibe estado vazio quando não há músicas', (tester) async {
    await montarBiblioteca(tester, _RepositorioFake());
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Nenhuma música na biblioteca'), findsOneWidget);
    expect(
      find.text('As músicas adicionadas aparecerão aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('exibe título e artista das músicas carregadas', (tester) async {
    final repositorio = _RepositorioFake(
      musicas: [
        musica('musica-1', 'Grande é o Senhor', 'Exemplo'),
        musica('musica-2', 'Santo', 'Outro artista'),
      ],
    );
    await montarBiblioteca(tester, repositorio);
    await tester.pumpAndSettle();

    expect(find.text('Grande é o Senhor'), findsOneWidget);
    expect(find.text('Exemplo'), findsOneWidget);
    expect(find.text('Santo'), findsOneWidget);
    expect(find.text('Outro artista'), findsOneWidget);
    expect(find.byKey(const ValueKey('musica-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('musica-2')), findsOneWidget);
  });

  testWidgets('exibe estado de erro quando a listagem falha', (tester) async {
    await montarBiblioteca(
      tester,
      _RepositorioFake(listagem: () => Future.error(StateError('falha'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar a biblioteca'), findsOneWidget);
  });

  testWidgets('abre o fluxo de cadastro pela Biblioteca', (tester) async {
    await abrirCadastro(tester, _RepositorioFake());

    expect(find.text('Nova música'), findsOneWidget);
    expect(find.text('Salvar música'), findsOneWidget);
  });

  testWidgets('valida os campos obrigatórios do cadastro', (tester) async {
    await abrirCadastro(tester, _RepositorioFake());

    await tocarSalvar(tester);
    await tester.pump();

    expect(find.text('Título é obrigatório.'), findsOneWidget);
    expect(find.text('Artista é obrigatório.'), findsOneWidget);
    expect(find.text('Tom original é obrigatório.'), findsOneWidget);
    expect(find.text('Conteúdo ChordPro é obrigatório.'), findsOneWidget);
  });

  testWidgets('rejeita tom inválido sem salvar música', (tester) async {
    final repositorio = _RepositorioFake();
    await abrirCadastro(tester, repositorio);
    await preencherFormulario(tester, tom: 'H');

    await tocarSalvar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tom original inválido.'), findsOneWidget);
    expect(repositorio.musicas, isEmpty);
  });

  testWidgets('salva, retorna à Biblioteca e atualiza a lista', (tester) async {
    final repositorio = _RepositorioFake();
    await abrirCadastro(tester, repositorio);
    await preencherFormulario(tester);

    await tocarSalvar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Grande é o Senhor'), findsOneWidget);
    expect(find.text('Exemplo'), findsOneWidget);
    expect(repositorio.musicas, hasLength(1));
  });

  testWidgets('mostra erro compreensível quando o salvamento falha', (
    tester,
  ) async {
    final repositorio = _RepositorioFake(erroAoSalvar: StateError('falha'));
    await abrirCadastro(tester, repositorio);
    await preencherFormulario(tester);

    await tocarSalvar(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar a música. Tente novamente.'),
      findsOneWidget,
    );
  });
}

class _RepositorioFake implements RepositorioMusicas {
  _RepositorioFake({
    Iterable<Musica> musicas = const [],
    this.listagem,
    this.erroAoSalvar,
  }) : musicas = List.of(musicas);

  final List<Musica> musicas;
  final Future<List<Musica>> Function()? listagem;
  final Object? erroAoSalvar;

  @override
  Future<void> excluir(IdMusica id) async {
    musicas.removeWhere((musica) => musica.id == id);
  }

  @override
  Future<List<Musica>> listar() => listagem?.call() ?? Future.value(musicas);

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
  Future<void> salvar(Musica musica) async {
    if (erroAoSalvar != null) {
      throw erroAoSalvar!;
    }
    musicas.add(musica);
  }
}

class _GeradorIdMusicaFake implements GeradorIdMusica {
  const _GeradorIdMusicaFake(this._id);

  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}
