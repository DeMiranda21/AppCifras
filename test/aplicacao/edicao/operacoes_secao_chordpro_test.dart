import 'package:appcifras/aplicacao/edicao/duplicar_secao_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/excluir_secao_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final duplicar = DuplicarSecaoChordPro();
  final excluir = ExcluirSecaoChordPro();

  group('DuplicarSecaoChordPro', () {
    test('duplica verso imediatamente após o original', () {
      const conteudo =
          '{start_of_verse: label="Verso 1"}\n[C]Letra\n{end_of_verse}';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(resultado.foiDuplicada, isTrue);
      expect(resultado.conteudo, '$conteudo\n$conteudo');
    });

    test('preserva linhas vazias e diretivas internas da seção', () {
      const conteudo =
          '{start_of_chorus: label="Refrão"}\n[C]A\n\n{comment: volta}\n[D]B\n{end_of_chorus}\nDepois';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(
        resultado.conteudo,
        '{start_of_chorus: label="Refrão"}\n[C]A\n\n{comment: volta}\n[D]B\n{end_of_chorus}\n'
        '{start_of_chorus: label="Refrão"}\n[C]A\n\n{comment: volta}\n[D]B\n{end_of_chorus}\nDepois',
      );
    });

    test('copia ambiente externo e alias byte a byte', () {
      const conteudo =
          '{start_of_spontaneous: label="Espontâneo"}\r\n[C]Livre\r\n{end_of_spontaneous}';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(resultado.conteudo, '$conteudo\r\n$conteudo');
    });

    test('copia alias reconhecido byte a byte', () {
      const conteudo = '{sov: label="V"}\n[C]Letra\n{eov}';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(resultado.conteudo, '$conteudo\n$conteudo');
    });

    test('preserva seção vizinha', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[D]B\n{end_of_chorus}';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\n'
        '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\n'
        '{start_of_chorus: label="R"}\n[D]B\n{end_of_chorus}',
      );
    });

    test('rejeita seção sem fechamento confiável', () {
      const conteudo = '{start_of_verse: label="V"}\n[C]Letra';

      final resultado = duplicar.duplicar(
        conteudo: conteudo,
        indiceMarcador: 0,
      );

      expect(resultado.foiDuplicada, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });

  group('ExcluirSecaoChordPro', () {
    test('remove primeira seção e preserva conteúdo implícito', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]A\n{end_of_verse}\nTexto livre';

      final resultado = excluir.excluir(conteudo: conteudo, indiceMarcador: 0);

      expect(resultado.foiExcluida, isTrue);
      expect(resultado.conteudo, 'Texto livre');
    });

    test('remove seção intermediária sem tocar nas vizinhas', () {
      const conteudo =
          '{start_of_intro: label="I"}\n[C]I\n{end_of_intro}\n'
          '{start_of_verse: label="V"}\n[D]V\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[E]R\n{end_of_chorus}';

      final resultado = excluir.excluir(conteudo: conteudo, indiceMarcador: 3);

      expect(
        resultado.conteudo,
        '{start_of_intro: label="I"}\n[C]I\n{end_of_intro}\n'
        '{start_of_chorus: label="R"}\n[E]R\n{end_of_chorus}',
      );
    });

    test('remove última seção vazia', () {
      const conteudo = 'Antes\n{start_of_chorus: label="R"}\n{end_of_chorus}';

      final resultado = excluir.excluir(conteudo: conteudo, indiceMarcador: 1);

      expect(resultado.conteudo, 'Antes\n');
    });

    test('remove ambiente externo sem normalizá-lo', () {
      const conteudo =
          'Antes\n{start_of_spontaneous: label="Livre"}\n[C]Texto\n{end_of_spontaneous}\nDepois';

      final resultado = excluir.excluir(conteudo: conteudo, indiceMarcador: 1);

      expect(resultado.conteudo, 'Antes\nDepois');
    });

    test('rejeita start sem end e preserva conteúdo implícito', () {
      const conteudo = 'Antes\n{start_of_verse: label="V"}\n[C]Letra';

      final resultado = excluir.excluir(conteudo: conteudo, indiceMarcador: 1);

      expect(resultado.foiExcluida, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
