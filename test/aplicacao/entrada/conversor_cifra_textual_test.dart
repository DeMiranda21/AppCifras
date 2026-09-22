import 'package:appcifras/aplicacao/entrada/conversor_cifra_textual.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final conversor = ConversorCifraTextual();

  bool temAviso(
    ResultadoConversaoCifraTextual resultado,
    TipoAvisoConversaoCifra tipo,
  ) => resultado.avisos.any((aviso) => aviso.tipo == tipo);

  group('ConversorCifraTextual', () {
    test('associa acorde único ao início da linha de letra', () {
      final resultado = conversor.converter(
        '    E5\n'
        'Senhor, Tu és bom',
      );

      expect(resultado.chordProSugerido, '[E5]Senhor, Tu és bom');
    });

    test('associa vários acordes às palavras mais próximas', () {
      final resultado = conversor.converter(
        '     B11/D#             D2(6) A9/C#\n'
        'Tua misericórdia é pra sempre',
      );

      expect(resultado.chordProSugerido, contains('[B11/D#]misericórdia'));
      expect(resultado.chordProSugerido, contains('[D2(6)]sempre'));
      expect(resultado.chordProSugerido, endsWith('[A9/C#]'));
    });

    test('associa acorde no interior da palavra ao seu início', () {
      final resultado = conversor.converter('E   G\nabcdef');

      expect(resultado.chordProSugerido, '[E][G]abcdef');
    });

    test('preserva acorde após o fim da letra e emite aviso', () {
      final resultado = conversor.converter('C          G\nOi');

      expect(resultado.chordProSugerido, '[C]Oi[G]');
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.acordeAposLetra),
        isTrue,
      );
    });

    test('considera múltiplos espaços e tabulações como colunas', () {
      final resultado = conversor.converter('\tE5\tB11/D#\nSenhor, Tu és bom');

      expect(resultado.chordProSugerido, contains('[E5]Senhor'));
      expect(resultado.chordProSugerido, contains('[B11/D#]'));
    });

    test('converte linha sem letra adjacente em passagem instrumental', () {
      final resultado = conversor.converter('E5 B11/D# D2(6) A9/C#\n\n[Final]');

      expect(
        resultado.chordProSugerido,
        startsWith('[E5] [B11/D#] [D2(6)] [A9/C#]'),
      );
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.linhaInstrumental),
        isTrue,
      );
    });

    test('não associa a primeira de duas linhas de acordes consecutivas', () {
      final resultado = conversor.converter('E5 B11/D#\nC7M D2(6)\nLetra');

      expect(resultado.chordProSugerido, startsWith('[E5] [B11/D#]\n'));
      expect(resultado.chordProSugerido, contains('[C7M][D2(6)]Letra'));
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.linhaInstrumental),
        isTrue,
      );
    });

    test('não associa linha de acordes a uma linha vazia', () {
      final resultado = conversor.converter('E5 B11/D#\n\nLetra');

      expect(resultado.chordProSugerido, '[E5] [B11/D#]\n\nLetra');
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.linhaInstrumental),
        isTrue,
      );
    });

    test('não associa linha de acordes a rótulo de seção', () {
      final resultado = conversor.converter('E5 B11/D#\n[Primeira Parte]');

      expect(
        resultado.chordProSugerido,
        '[E5] [B11/D#]\n{comment: [Primeira Parte]}',
      );
    });

    test(
      'converte Tom explícito em diretiva key sem manter a linha textual',
      () {
        final resultado = conversor.converter('Tom: E\n\nE B\nSenhor');

        expect(resultado.chordProSugerido, startsWith('{key: E}\n\n'));
        expect(resultado.chordProSugerido, isNot(contains('Tom: E')));
        expect(
          resultado.trechos.first.tipo,
          TipoTrechoConversaoCifra.tomConvertido,
        );
      },
    );

    test('preserva texto comum e linhas vazias', () {
      const conteudo = 'Uma letra comum\n\nSem acordes';

      final resultado = conversor.converter(conteudo);

      expect(resultado.chordProSugerido, conteudo);
    });

    test('preserva acordes plausíveis ainda não interpretáveis', () {
      final resultado = conversor.converter('A2 D2(6)\nTodos os povos');

      expect(resultado.chordProSugerido, '[A2][D2(6)]Todos os povos');
    });

    test('preserva os acordes suportados no ChordPro sugerido', () {
      final resultado = conversor.converter(
        'E5 B11/D# A9/C# E/G# Bm7 C7M G6\nLetra',
      );

      for (final acorde in [
        'E5',
        'B11/D#',
        'A9/C#',
        'E/G#',
        'Bm7',
        'C7M',
        'G6',
      ]) {
        expect(resultado.chordProSugerido, contains('[$acorde]'));
      }
    });

    test('não altera linha que já contém marcação ChordPro', () {
      const conteudo = '[E]Senhor, Tu és bom';

      final resultado = conversor.converter(conteudo);

      expect(resultado.chordProSugerido, conteudo);
      expect(
        resultado.trechos.single.tipo,
        TipoTrechoConversaoCifra.preservado,
      );
    });

    test('preserva rótulo conhecido de forma não destrutiva', () {
      final resultado = conversor.converter('[Pré-Refrão]');

      expect(resultado.chordProSugerido, '{comment: [Pré-Refrão]}');
      expect(
        resultado.trechos.single.tipo,
        TipoTrechoConversaoCifra.rotuloPreservado,
      );
    });

    test(
      'mantém conteúdo misto não transformado quando não é linha de acordes',
      () {
        const conteudo = 'Observação do ensaio\nE5 B11/D#\nLetra\n[Refrão]';

        final resultado = conversor.converter(conteudo);

        expect(resultado.chordProSugerido, contains('Observação do ensaio'));
        expect(resultado.chordProSugerido, contains('[E5][B11/D#]Letra'));
        expect(resultado.chordProSugerido, endsWith('{comment: [Refrão]}'));
      },
    );

    test('preserva integralmente o texto original no resultado', () {
      const conteudo = 'Tom: E\r\n\r\n\tE5\r\nSenhor, Tu és bom';

      final resultado = conversor.converter(conteudo);

      expect(resultado.conteudoOriginal, conteudo);
    });

    test(
      'caracteriza trecho real sem perder acordes ou rótulos relevantes',
      () {
        const conteudo =
            'Tom: E\n'
            '\n'
            '[Intro] E5 B11/D# D2(6) A9/C#\n'
            '\n'
            '[Primeira Parte]\n'
            '\n'
            '    E5\n'
            'Senhor, Tu és bom\n'
            '\n'
            '     B11/D#             D2(6) A9/C#\n'
            'Tua misericórdia é pra sempre\n'
            '\n'
            '[Pré-Refrão]\n'
            '\n'
            ' A2                 B4\n'
            'Todos os povos te exaltarão\n'
            '\n'
            ' C7M       D2(6)\n'
            'De geração em geração';

        final resultado = conversor.converter(conteudo);

        expect(resultado.conteudoOriginal, conteudo);
        expect(resultado.chordProSugerido, startsWith('{key: E}'));
        expect(resultado.chordProSugerido, contains('{comment: [Intro]}'));
        expect(resultado.chordProSugerido, contains('[E5]Senhor, Tu és bom'));
        expect(resultado.chordProSugerido, contains('[B11/D#]misericórdia'));
        expect(resultado.chordProSugerido, contains('[A2]Todos'));
        expect(resultado.chordProSugerido, contains('[C7M]De geração'));
      },
    );

    test('associa acorde isolado indentado ao início da letra', () {
      final resultado = conversor.converter('    C\nPalavra');

      expect(resultado.chordProSugerido, '[C]Palavra');
    });

    test('preserva a posição relativa do segundo acorde', () {
      final resultado = conversor.converter('C       G\nPalavra longa');

      expect(resultado.chordProSugerido, '[C]Palavra [G]longa');
    });

    test('não divide palavra quando o segundo acorde cai no seu interior', () {
      final resultado = conversor.converter('C   G\nPalavra');

      expect(resultado.chordProSugerido, '[C][G]Palavra');
      expect(resultado.chordProSugerido, isNot(contains('Pala[G]vra')));
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.acordesConvergentes),
        isTrue,
      );
    });

    test(
      'mantém acorde sobre whitespace entre palavras na coluna original',
      () {
        final resultado = conversor.converter('C      G\nPalavra longa');

        expect(resultado.chordProSugerido, '[C]Palavra[G] longa');
      },
    );

    test('converte Divino Companheiro sem inserir acordes nas palavras', () {
      final resultado = conversor.converter(
        'D              A                    D\n'
        'Divino companheiro do caminho',
      );

      expect(
        resultado.chordProSugerido,
        '[D]Divino [A]companheiro do caminho[D]',
      );
      expect(resultado.chordProSugerido, isNot(contains('companhe[A]iro')));
      expect(
        temAviso(resultado, TipoAvisoConversaoCifra.acordeAposLetra),
        isTrue,
      );
    });

    test('não separa palavras quando a coluna do acorde cai no interior', () {
      for (final palavra in ['Senhor', 'coração', 'transitar', 'permanente']) {
        final resultado = conversor.converter('D    A\n$palavra');

        expect(resultado.chordProSugerido, '[D][A]$palavra');
        expect(
          resultado.chordProSugerido,
          isNot(contains('${palavra.substring(0, 5)}[A]')),
        );
      }
    });

    test('não perde nenhum acorde de uma linha candidata', () {
      final resultado = conversor.converter('E5 B11/D# D2(6) A9/C#\nLetra');

      for (final acorde in ['E5', 'B11/D#', 'D2(6)', 'A9/C#']) {
        expect(resultado.chordProSugerido, contains('[$acorde]'));
      }
    });
  });
}
