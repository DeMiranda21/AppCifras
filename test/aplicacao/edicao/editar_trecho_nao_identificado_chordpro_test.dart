import 'package:appcifras/aplicacao/edicao/editar_trecho_nao_identificado_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final editar = EditarTrechoNaoIdentificadoChordPro();

  group('EditarTrechoNaoIdentificadoChordPro', () {
    test('altera somente o trecho musical livre localizado', () {
      const conteudo =
          '{title: T}\n{artist: A}\n{key: C}\n'
          '[C]Introdução\n\n'
          '{start_of_verse: label="Verso"}\n[D]Letra\n{end_of_verse}\n'
          '{comment: preservar}';

      final resultado = editar.editar(
        conteudo: conteudo,
        inicioConteudo: 3,
        novoConteudo: '[G]Nova introdução\n\nTexto',
      );

      expect(resultado.foiAlterado, isTrue);
      expect(
        resultado.conteudo,
        '{title: T}\n{artist: A}\n{key: C}\n'
        '[G]Nova introdução\n\nTexto\n\n'
        '{start_of_verse: label="Verso"}\n[D]Letra\n{end_of_verse}\n'
        '{comment: preservar}',
      );
    });

    test('não altera conteúdo se a faixa derivada não existe', () {
      const conteudo = '{title: T}\n{artist: A}\n{key: C}\n[C]Letra';

      final resultado = editar.editar(
        conteudo: conteudo,
        inicioConteudo: 0,
        novoConteudo: 'Não aplicar',
      );

      expect(resultado.foiAlterado, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
