import 'package:appcifras/aplicacao/edicao/duplicar_bloco_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/excluir_bloco_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/localizador_secao_chordpro.dart';
import 'package:appcifras/aplicacao/estrutura/estrutura_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  final estruturador = EstruturadorDocumentoChordPro();
  final localizador = LocalizadorSecaoChordPro();
  final duplicar = DuplicarBlocoChordPro();
  final excluir = ExcluirBlocoChordPro();

  FaixaBlocoChordPro faixaDoBloco(String conteudo, int indice) {
    final estrutura = estruturador.estruturar(parser.interpretar(conteudo));
    return localizador.localizarBlocoSeguro(
      conteudo: conteudo,
      secao: estrutura.secoes[indice],
    )!;
  }

  group('Operações de bloco ChordPro', () {
    test('duplica literalmente seção explícita', () {
      const conteudo =
          '{start_of_verse: label="Verso"}\n[C]Letra\n{end_of_verse}';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        faixa: faixaDoBloco(conteudo, 0),
      );

      expect(resultado.foiDuplicado, isTrue);
      expect(resultado.conteudo, '$conteudo\n$conteudo');
    });

    test('duplica e exclui rótulo textual sem normalizá-lo', () {
      const conteudo = '[Verso]\n[C]Linha 1\n[G]Linha 2\n[Refrão]\n[D]Fim';
      final faixa = faixaDoBloco(conteudo, 0);

      final duplicado = duplicar.duplicar(conteudo: conteudo, faixa: faixa);
      expect(
        duplicado.conteudo,
        '[Verso]\n[C]Linha 1\n[G]Linha 2\n'
        '[Verso]\n[C]Linha 1\n[G]Linha 2\n[Refrão]\n[D]Fim',
      );

      final excluido = excluir.excluir(conteudo: conteudo, faixa: faixa);
      expect(excluido.foiExcluido, isTrue);
      expect(excluido.conteudo, '[Refrão]\n[D]Fim');
    });

    test(
      'opera somente trecho não identificado e preserva metadados e seção',
      () {
        const conteudo =
            '{title: T}\n{artist: A}\n{key: C}\n'
            '[C]Intro livre\n[G]Outra linha\n'
            '{start_of_chorus: label="Refrão"}\n[D]Vizinha\n{end_of_chorus}';
        final faixa = faixaDoBloco(conteudo, 0);

        final duplicado = duplicar.duplicar(conteudo: conteudo, faixa: faixa);
        expect(
          duplicado.conteudo,
          contains(
            '[C]Intro livre\n[G]Outra linha\n[C]Intro livre\n[G]Outra linha',
          ),
        );
        expect(
          duplicado.conteudo,
          contains('{start_of_chorus: label="Refrão"}'),
        );

        final excluido = excluir.excluir(conteudo: conteudo, faixa: faixa);
        expect(excluido.foiExcluido, isTrue);
        expect(
          excluido.conteudo,
          startsWith('{title: T}\n{artist: A}\n{key: C}\n'),
        );
        expect(
          excluido.conteudo,
          contains('{start_of_chorus: label="Refrão"}'),
        );
        expect(excluido.conteudo, isNot(contains('Intro livre')));
      },
    );
  });
}
