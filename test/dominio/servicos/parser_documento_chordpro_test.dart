import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  group('ParserDocumentoChordPro - linhas', () {
    test('preserva texto, acordes e suas posições', () {
      final documento = parser.interpretar('[G]Grande é o [D/F#]Senhor');
      final linha = documento.elementos.single as LinhaChordPro;

      expect(linha.conteudoOriginal, '[G]Grande é o [D/F#]Senhor');
      expect(linha.elementos.map((e) => e.conteudoOriginal), [
        'G',
        'Grande é o ',
        'D/F#',
        'Senhor',
      ]);
      expect(
        linha.elementos.whereType<AcordeLinhaChordPro>().every(
          (e) => e.resultado is AcordeInterpretado,
        ),
        isTrue,
      );
    });

    test('preserva espaços, acentos e pontuação', () {
      final linha =
          (parser.interpretar('[G]Grande   é o [D/F#]Senhor!').elementos.single
              as LinhaChordPro);
      expect(linha.elementos.map((e) => e.conteudoOriginal), [
        'G',
        'Grande   é o ',
        'D/F#',
        'Senhor!',
      ]);
    });

    test('aceita linhas sem acordes e somente acordes', () {
      final documento = parser.interpretar(
        'Santo, Santo é o Senhor\n[G] [D] [Em] [C]',
      );
      final texto = documento.elementos.first as LinhaChordPro;
      final acordes = documento.elementos.last as LinhaChordPro;

      expect(
        texto.elementos.single.conteudoOriginal,
        'Santo, Santo é o Senhor',
      );
      expect(acordes.elementos.map((e) => e.conteudoOriginal), [
        'G',
        ' ',
        'D',
        ' ',
        'Em',
        ' ',
        'C',
      ]);
    });

    test('mantém acorde não interpretável como elemento da linha', () {
      final linha =
          (parser.interpretar('[Cmaj9(#11)]Santo').elementos.single
              as LinhaChordPro);
      final acorde = linha.elementos.first as AcordeLinhaChordPro;

      expect(acorde.conteudoOriginal, 'Cmaj9(#11)');
      expect(acorde.resultado, isA<AcordeNaoInterpretavel>());
      expect(linha.elementos.last.conteudoOriginal, 'Santo');
    });

    test('preserva a grafia de alias do acorde', () {
      final acorde =
          ((parser.interpretar('[C7M]Santo').elementos.single as LinhaChordPro)
                  .elementos
                  .first
              as AcordeLinhaChordPro);
      expect(acorde.conteudoOriginal, 'C7M');
      expect(acorde.resultado, isA<AcordeInterpretado>());
    });
  });

  group('ParserDocumentoChordPro - diretivas', () {
    test('interpreta title, artist e key', () {
      final documento = parser.interpretar(
        '{title: Música}\n{artist: Artista}\n{key: Am}\n{key: Bb}',
      );
      expect(
        (documento.elementos[0] as DiretivaTituloChordPro).titulo,
        'Música',
      );
      expect(
        (documento.elementos[1] as DiretivaArtistaChordPro).artista,
        'Artista',
      );
      expect(
        (documento.elementos[2] as DiretivaTomChordPro).tom,
        const Tom(
          notaFundamental: Nota(nome: NomeNota.a),
          modo: ModoTom.menor,
        ),
      );
      expect(
        (documento.elementos[3] as DiretivaTomChordPro).tom,
        const Tom(
          notaFundamental: Nota(
            nome: NomeNota.b,
            alteracao: AlteracaoNota.bemol,
          ),
          modo: ModoTom.maior,
        ),
      );
    });

    test('preserva key não interpretável e diretiva desconhecida', () {
      final documento = parser.interpretar('{key: H}\n{tempo: 72}');
      expect((documento.elementos.first as DiretivaTomChordPro).tom, isNull);
      final tempo = documento.elementos.last as DiretivaDesconhecidaChordPro;
      expect(tempo.conteudoOriginal, '{tempo: 72}');
      expect(tempo.valorOriginal, ' 72');
    });

    test('reconhece marcadores explícitos de refrão e aliases', () {
      final documento = parser.interpretar(
        '{start_of_chorus}\n{end_of_chorus}\n{soc}\n{eoc}',
      );
      expect(documento.elementos[0], isA<InicioRefraoChordPro>());
      expect(documento.elementos[1], isA<FimRefraoChordPro>());
      expect(documento.elementos[2], isA<InicioRefraoChordPro>());
      expect(documento.elementos[3], isA<FimRefraoChordPro>());
    });
  });

  group('ParserDocumentoChordPro - preservação', () {
    test('preserva linhas vazias e ordem do documento completo', () {
      const fonte =
          '{title: Grande é o Senhor}\n{artist: Exemplo}\n{key: G}\n\n[G]Grande\n[Cmaj9(#11)]Santo\n{tempo: 72}';
      final documento = parser.interpretar(fonte);

      expect(documento.conteudoOriginal, fonte);
      expect(documento.elementos.length, 7);
      expect(documento.elementos[3], isA<LinhaChordPro>());
      expect(documento.elementos[3].conteudoOriginal, '');
      expect(documento.elementos[6], isA<DiretivaDesconhecidaChordPro>());
    });

    test('preserva entradas malformadas conservadoramente', () {
      final documento = parser.interpretar(
        '[ sem fechamento\n[]\n{title Música}',
      );
      expect(documento.elementos[0], isA<LinhaNaoInterpretadaChordPro>());
      expect(
        (documento.elementos[1] as LinhaChordPro)
            .elementos
            .single
            .conteudoOriginal,
        '[]',
      );
      expect(documento.elementos[2], isA<LinhaNaoInterpretadaChordPro>());
    });

    test('representa documento vazio e documento somente textual', () {
      expect(parser.interpretar('').elementos, isEmpty);
      final documento = parser.interpretar('Apenas texto');
      expect(
        (documento.elementos.single as LinhaChordPro)
            .elementos
            .single
            .conteudoOriginal,
        'Apenas texto',
      );
    });
  });
}
