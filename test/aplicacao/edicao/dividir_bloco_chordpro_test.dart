import 'package:appcifras/aplicacao/edicao/dividir_bloco_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/localizador_secao_chordpro.dart';
import 'package:appcifras/aplicacao/estrutura/estrutura_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  final estruturador = EstruturadorDocumentoChordPro();
  final localizador = LocalizadorSecaoChordPro();
  final dividir = DividirBlocoChordPro();

  FaixaBlocoChordPro faixa(String conteudo, int indice) {
    final estrutura = estruturador.estruturar(parser.interpretar(conteudo));
    return localizador.localizarBlocoSeguro(
      conteudo: conteudo,
      secao: estrutura.secoes[indice],
    )!;
  }

  group('DividirBlocoChordPro', () {
    test('divide trecho livre e mantém fronteira após nova derivação', () {
      const conteudo = '[C]Linha A\n[G]Linha B\n[D]Linha C';
      final resultado = dividir.dividir(
        conteudo: conteudo,
        faixa: faixa(conteudo, 0),
        posicao: conteudo.indexOf('[D]'),
      );

      expect(resultado.foiDividido, isTrue);
      expect(
        resultado.conteudo,
        '[C]Linha A\n[G]Linha B\n{appcifras_block_break}\n[D]Linha C',
      );
      final estrutura = estruturador.estruturar(
        parser.interpretar(resultado.conteudo),
      );
      expect(estrutura.secoes, hasLength(2));
      expect(estrutura.secoes.map((s) => s.elementos.length), [2, 1]);
    });

    test('mantém rótulo textual apenas na primeira metade', () {
      const conteudo = '[Verso]\nA\nB\nC';
      final resultado = dividir.dividir(
        conteudo: conteudo,
        faixa: faixa(conteudo, 0),
        posicao: conteudo.indexOf('C'),
      );

      expect(resultado.conteudo, '[Verso]\nA\nB\n{appcifras_block_break}\nC');
      final estrutura = estruturador.estruturar(
        parser.interpretar(resultado.conteudo),
      );
      expect(estrutura.secoes, hasLength(2));
      expect(estrutura.secoes.first.rotuloOriginal, '[Verso]');
      expect(estrutura.secoes.last.ehImplicita, isTrue);
      expect(estrutura.secoes.last.rotuloOriginal, isNull);
    });

    test('fecha seção explícita e deixa a segunda metade livre', () {
      const conteudo =
          '{start_of_verse: label="Verso 1"}\nA\nB\nC\n{end_of_verse}';
      final resultado = dividir.dividir(
        conteudo: conteudo,
        faixa: faixa(conteudo, 0),
        posicao: conteudo.indexOf('C'),
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="Verso 1"}\nA\nB\n{end_of_verse}\nC',
      );
      expect(resultado.conteudo, isNot(contains('appcifras_block_break')));
      final estrutura = estruturador.estruturar(
        parser.interpretar(resultado.conteudo),
      );
      expect(estrutura.secoes, hasLength(2));
      expect(estrutura.secoes.first.rotuloOriginal, 'Verso 1');
      expect(estrutura.secoes.last.ehImplicita, isTrue);
    });

    test('preserva CRLF, linhas vazias internas e metadados', () {
      const conteudo =
          '{title: T}\r\n{artist: A}\r\n{key: C}\r\nA\r\n\r\nB\r\nC';
      final resultado = dividir.dividir(
        conteudo: conteudo,
        faixa: faixa(conteudo, 0),
        posicao: conteudo.lastIndexOf('C'),
      );

      expect(resultado.foiDividido, isTrue);
      expect(resultado.conteudo, contains('{appcifras_block_break}\r\nC'));
      expect(
        resultado.conteudo,
        startsWith('{title: T}\r\n{artist: A}\r\n{key: C}\r\n'),
      );
      expect(resultado.conteudo, contains('A\r\n\r\nB'));
    });

    test('rejeita cursor na primeira linha e bloco de uma linha', () {
      const conteudo = 'A\nB';
      final faixaSegura = faixa(conteudo, 0);
      for (final posicao in [0]) {
        final resultado = dividir.dividir(
          conteudo: conteudo,
          faixa: faixaSegura,
          posicao: posicao,
        );
        expect(resultado.foiDividido, isFalse);
      }
      const umaLinha = 'A';
      final resultado = dividir.dividir(
        conteudo: umaLinha,
        faixa: faixa(umaLinha, 0),
        posicao: 0,
      );
      expect(resultado.foiDividido, isFalse);
    });
  });
}
