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
  Musica musica() => Musica(
    id: IdMusica('musica-1'),
    documento: parser.interpretar(
      '{appcifras_schema: 1}\n{appcifras_id: musica-1}\n{title: T}\n{artist: A}\n{key: C}\n[C]Existente',
    ),
  );
  Future<_Repositorio> montar(WidgetTester tester) async {
    final repositorio = _Repositorio()..salvar(musica());
    await tester.pumpWidget(
      MaterialApp(
        home: TelaEdicaoMusica(
          musica: musica(),
          atualizarMusica: AtualizarMusica(
            repositorio: repositorio,
            parserDocumento: parser,
          ),
        ),
      ),
    );
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
