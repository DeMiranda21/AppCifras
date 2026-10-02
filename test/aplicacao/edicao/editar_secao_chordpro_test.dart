import 'package:appcifras/aplicacao/edicao/editar_secao_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/transformar_selecao_chordpro.dart';
import 'package:appcifras/aplicacao/estrutura/reconhecedor_secao_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final editor = EditarSecaoChordPro();

  SelecaoTextoChordPro cursorEm(String conteudo, String trecho) {
    final inicio = conteudo.indexOf(trecho);
    return SelecaoTextoChordPro(inicio: inicio, fim: inicio);
  }

  ResultadoEdicaoSecaoChordPro editar(
    String conteudo, {
    required TipoSecaoMusica tipo,
    required String label,
    String trecho = '[C]Letra',
  }) => editor.editar(
    conteudo: conteudo,
    selecao: cursorEm(conteudo, trecho),
    novoTipo: tipo,
    novoLabel: label,
  );

  group('EditarSecaoChordPro', () {
    test(
      'troca verse por chorus sem alterar conteúdo, vizinha ou metadata',
      () {
        const conteudo =
            '{title: T}\n{artist: A}\n{key: C}\n'
            '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}\n'
            '{start_of_bridge: label="Ponte"}\n[D]Depois\n{end_of_bridge}';

        final resultado = editar(
          conteudo,
          tipo: TipoSecaoMusica.refrao,
          label: 'Verso 1',
        );

        expect(resultado.estado, EstadoEdicaoSecaoChordPro.alterado);
        expect(
          resultado.conteudo,
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_chorus: label="Verso 1"}\n[C]Letra\n{end_of_chorus}\n'
          '{start_of_bridge: label="Ponte"}\n[D]Depois\n{end_of_bridge}',
        );
        expect(resultado.selecao.inicio, greaterThan(0));
      },
    );

    test('troca chorus por bridge e altera label', () {
      const conteudo =
          '{start_of_chorus: label="Refrão"}\n[C]Letra\n{end_of_chorus}';

      final resultado = editar(
        conteudo,
        tipo: TipoSecaoMusica.ponte,
        label: 'Ponte 1',
      );

      expect(
        resultado.conteudo,
        '{start_of_bridge: label="Ponte 1"}\n[C]Letra\n{end_of_bridge}',
      );
    });

    test('troca intro por outro usando section canônico', () {
      const conteudo =
          '{start_of_intro: label="Intro"}\n[C]Passagem\n{end_of_intro}';

      final resultado = editar(
        conteudo,
        tipo: TipoSecaoMusica.outro,
        label: 'Ministração',
        trecho: '[C]Passagem',
      );

      expect(
        resultado.conteudo,
        '{start_of_section: label="Ministração"}\n[C]Passagem\n{end_of_section}',
      );
    });

    test('renomeia label preservando aspas, barras e conteúdo interno', () {
      const conteudo =
          '{start_of_verse: label="Verso"}\n[C]A\\B\n{comment: x}\n{end_of_verse}';

      final resultado = editar(
        conteudo,
        tipo: TipoSecaoMusica.verso,
        label: 'Verso "2" \\ final',
        trecho: '[C]A\\B',
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="Verso \\"2\\" \\\\ final"}\n'
        '[C]A\\B\n{comment: x}\n{end_of_verse}',
      );
    });

    test('preserva alias byte a byte quando não há mudança semântica', () {
      const conteudo = '{sov: label="Verso 1"}\n[C]Letra\n{eov}';

      final resultado = editar(
        conteudo,
        tipo: TipoSecaoMusica.verso,
        label: 'Verso 1',
      );

      expect(resultado.estado, EstadoEdicaoSecaoChordPro.semAlteracao);
      expect(resultado.conteudo, conteudo);
    });

    test('normaliza alias para forma longa após edição explícita', () {
      const conteudo = '{sov: label="Verso 1"}\n[C]Letra\n{eov}';

      final resultado = editar(
        conteudo,
        tipo: TipoSecaoMusica.verso,
        label: 'Verso 2',
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="Verso 2"}\n[C]Letra\n{end_of_verse}',
      );
    });

    test('preserva ambiente desconhecido sem mudança e normaliza ao editar', () {
      const conteudo =
          '{start_of_spontaneous: label="Espontâneo"}\n[C]Letra\n{end_of_spontaneous}';

      final semMudanca = editar(
        conteudo,
        tipo: TipoSecaoMusica.outro,
        label: 'Espontâneo',
      );
      final editado = editar(
        conteudo,
        tipo: TipoSecaoMusica.outro,
        label: 'Ministração',
      );

      expect(semMudanca.conteudo, conteudo);
      expect(
        editado.conteudo,
        '{start_of_section: label="Ministração"}\n[C]Letra\n{end_of_section}',
      );
    });

    test('normaliza start sem end apenas após edição explícita', () {
      const conteudo = '{start_of_verse: label="Verso 1"}\n[C]Letra';

      final semMudanca = editar(
        conteudo,
        tipo: TipoSecaoMusica.verso,
        label: 'Verso 1',
      );
      final editado = editar(
        conteudo,
        tipo: TipoSecaoMusica.refrao,
        label: 'Refrão 1',
      );

      expect(semMudanca.conteudo, conteudo);
      expect(
        editado.conteudo,
        '{start_of_chorus: label="Refrão 1"}\n[C]Letra\n{end_of_chorus}',
      );
    });

    test('rejeita label vazio e seções implícitas', () {
      const explicita =
          '{start_of_verse: label="Verso"}\n[C]Letra\n{end_of_verse}';
      const implicita = 'Verso\n[C]Letra';

      final vazio = editar(
        explicita,
        tipo: TipoSecaoMusica.verso,
        label: '   ',
      );
      final fora = editor.editar(
        conteudo: implicita,
        selecao: cursorEm(implicita, '[C]Letra'),
        novoTipo: TipoSecaoMusica.verso,
        novoLabel: 'Verso',
      );

      expect(vazio.estado, EstadoEdicaoSecaoChordPro.invalido);
      expect(vazio.conteudo, explicita);
      expect(fora.estado, EstadoEdicaoSecaoChordPro.invalido);
      expect(fora.conteudo, implicita);
    });

    test('aceita cursor no marcador inicial, final e conteúdo', () {
      const conteudo =
          '{start_of_verse: label="Verso"}\n[C]Letra\n{end_of_verse}';

      for (final trecho in ['start_of_verse', '[C]Letra', 'end_of_verse']) {
        final contexto = editor.contextoAtual(
          conteudo: conteudo,
          selecao: cursorEm(conteudo, trecho),
        );
        expect(contexto?.tipo, TipoSecaoMusica.verso);
        expect(contexto?.label, 'Verso');
      }
    });

    test('rejeita seleção que cruza duas seções explícitas', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[D]B\n{end_of_chorus}';
      final selecao = SelecaoTextoChordPro(
        inicio: conteudo.indexOf('[C]A'),
        fim: conteudo.indexOf('[D]B') + '[D]B'.length,
      );

      expect(
        editor.contextoAtual(conteudo: conteudo, selecao: selecao),
        isNull,
      );
    });
  });
}
