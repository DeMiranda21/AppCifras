import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/formatador_acorde.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';
import 'package:appcifras/dominio/servicos/servico_transposicao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserAcorde();
  final formatador = FormatadorAcorde();
  final transposicao = ServicoTransposicao();

  String transporEFormatar(String texto, int semitons) => formatador.formatar(
    transposicao.transporAcorde(_interpretar(parser, texto), semitons),
  );

  group('FormatadorAcorde - formato canônico e round-trip estrutural', () {
    const casos = <String, String>{
      'E': 'E',
      'Cm': 'Cm',
      'C#': 'C#',
      'Bb': 'Bb',
      'F#m': 'F#m',
      'E5': 'E5',
      'B11/D#': 'B11/D#',
      'A9/C#': 'A9/C#',
      'E/G#': 'E/G#',
      'B4': 'B4',
      'C7M': 'C7M',
      'Bm7': 'Bm7',
      'G6': 'G6',
      'Cm6': 'Cm6',
      'A2': 'A2',
      'D2(6)': 'D2(6)',
      'F#2': 'F#2',
      'Bb2(6)': 'Bb2(6)',
      'A2/C#': 'A2/C#',
      'C7': 'C7',
      'Cadd9': 'Cadd9',
      'Cadd11': 'Cadd11',
      'Csus2': 'Csus2',
      'Csus4': 'C4',
      'C4': 'C4',
      'Cdim': 'Cdim',
      'Caug': 'Caug',
      'Cm7(b5)': 'Cm7(b5)',
      'C7(b9)': 'C7(b9)',
      'C7(#9)': 'C7(#9)',
      'C7(b9)(#5)': 'C7(#5)(b9)',
      'C7(#9)(b5)': 'C7(b5)(#9)',
      'C7(9)': 'C9',
      'Cm7(9)': 'Cm9',
      'C7M(9)': 'C7M(9)',
      'C7(13)': 'C7(13)',
      'C(9)(13)': 'C(9)(13)',
      'C6(9)(13)': 'C6(9)(13)',
      'Cm6(9)(13)': 'Cm6(9)(13)',
      'C7M(9)(13)': 'C7M(9)(13)',
      'Cadd11(9)(13)': 'Cadd11(9)(13)',
      'Csus2(9)(13)': 'Csus2(9)(13)',
      'C5(9)(13)': 'C5(9)(13)',
      'Cdim(9)(13)': 'Cdim(9)(13)',
      'C11': 'C11',
      'C13': 'C13',
      'Cmaj7': 'C7M',
      'CM7': 'C7M',
      'CΔ7': 'C7M',
      'C°': 'Cdim',
      'C+': 'Caug',
      'Cø': 'Cm7(b5)',
      'G/B': 'G/B',
      'D/F#': 'D/F#',
      'C7/E': 'C7/E',
      'Cadd9/G': 'Cadd9/G',
    };

    for (final caso in casos.entries) {
      test('${caso.key} gera ${caso.value}', () {
        final acordeOriginal = _interpretar(parser, caso.key);

        final textoFormatado = formatador.formatar(acordeOriginal);

        expect(textoFormatado, caso.value);
        expect(_interpretar(parser, textoFormatado), acordeOriginal);
      });
    }
  });

  group('FormatadorAcorde - transposição e formatação', () {
    test('transpõe A2 para B2', () {
      expect(transporEFormatar('A2', 2), 'B2');
    });

    test('transpõe D2(6) para E2(6)', () {
      expect(transporEFormatar('D2(6)', 2), 'E2(6)');
    });

    test('transpõe A2/C# para B2/D#', () {
      expect(transporEFormatar('A2/C#', 2), 'B2/D#');
    });

    test('preserva acorde menor', () {
      expect(transporEFormatar('Cm7', 2), 'Dm7');
    });

    test('preserva acorde de quinta', () {
      expect(transporEFormatar('C5', 2), 'D5');
    });

    test('preserva extensão e inversão', () {
      expect(transporEFormatar('B11/D#', 2), 'C#11/F');
    });

    test('mantém bemol escolhido pelo contexto tonal', () {
      final resultado = transposicao.transporAcorde(
        _interpretar(parser, 'C7'),
        3,
        tomDestino: const Tom(
          notaFundamental: Nota(
            nome: NomeNota.e,
            alteracao: AlteracaoNota.bemol,
          ),
          modo: ModoTom.maior,
        ),
      );

      expect(formatador.formatar(resultado), 'Eb7');
    });

    test('mantém sustenido escolhido sem contexto tonal', () {
      expect(transporEFormatar('C7', 1), 'C#7');
    });
  });

  group('FormatadorAcorde - estados fora da gramática', () {
    test('não inventa sintaxe para adições não produzidas pelo parser', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        adicoes: {AdicaoAcorde.segunda, AdicaoAcorde.nona},
      );

      expect(() => formatador.formatar(acorde), throwsUnsupportedError);
    });
  });
}

Acorde _interpretar(ParserAcorde parser, String texto) {
  final resultado = parser.interpretar(texto);

  expect(resultado, isA<AcordeInterpretado>());
  return (resultado as AcordeInterpretado).acorde;
}
