import 'package:appcifras/aplicacao/edicao/editar_conteudo_secao_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final editor = EditarConteudoSecaoChordPro();

  group('EditarConteudoSecaoChordPro', () {
    test(
      'edita verso sem alterar metadados, delimitadores ou seção vizinha',
      () {
        const conteudo =
            '{title: T}\n{artist: A}\n{key: C}\n'
            '{start_of_verse: label="Verso 1"}\n[C]Antiga\n{end_of_verse}\n'
            '{start_of_chorus: label="Refrão"}\n[G]Coro\n{end_of_chorus}';

        final resultado = editor.editar(
          conteudo: conteudo,
          indiceMarcador: 3,
          novoConteudoInterno: '[D]Nova',
        );

        expect(resultado.foiAlterado, isTrue);
        expect(
          resultado.conteudo,
          '{title: T}\n{artist: A}\n{key: C}\n'
          '{start_of_verse: label="Verso 1"}\n[D]Nova\n{end_of_verse}\n'
          '{start_of_chorus: label="Refrão"}\n[G]Coro\n{end_of_chorus}',
        );
      },
    );

    test('preenche conteúdo vazio e permite apagá-lo novamente', () {
      const vazio = '{start_of_chorus: label="Refrão"}\n{end_of_chorus}';
      final preenchido = editor.editar(
        conteudo: vazio,
        indiceMarcador: 0,
        novoConteudoInterno: '[C]Letra',
      );
      final apagado = editor.editar(
        conteudo: preenchido.conteudo,
        indiceMarcador: 0,
        novoConteudoInterno: '',
      );

      expect(
        preenchido.conteudo,
        '{start_of_chorus: label="Refrão"}\n[C]Letra\n{end_of_chorus}',
      );
      expect(apagado.conteudo, vazio);
    });

    test('preserva linhas vazias internas e quebra final fornecida', () {
      const conteudo =
          '{start_of_verse: label="V"}\r\n[A]Antes\r\n{end_of_verse}';

      final resultado = editor.editar(
        conteudo: conteudo,
        indiceMarcador: 0,
        novoConteudoInterno: '[C]Primeira\r\n\r\n[G]Última\r\n',
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="V"}\r\n[C]Primeira\r\n\r\n[G]Última\r\n'
        '{end_of_verse}',
      );
    });

    test('preserva aliases e ambiente externo byte a byte', () {
      const alias = '{sov: label="V"}\n[C]Antes\n{eov}';
      const externo =
          '{start_of_spontaneous: label="Livre"}\n[A]Antes\n{end_of_spontaneous}';

      final aliasEditado = editor.editar(
        conteudo: alias,
        indiceMarcador: 0,
        novoConteudoInterno: '[D]Depois',
      );
      final externoEditado = editor.editar(
        conteudo: externo,
        indiceMarcador: 0,
        novoConteudoInterno: '[B]Depois',
      );

      expect(aliasEditado.conteudo, '{sov: label="V"}\n[D]Depois\n{eov}');
      expect(
        externoEditado.conteudo,
        '{start_of_spontaneous: label="Livre"}\n[B]Depois\n{end_of_spontaneous}',
      );
    });

    test('rejeita seção sem fechamento confiável', () {
      const conteudo = '{start_of_verse: label="V"}\n[C]Letra';

      final resultado = editor.editar(
        conteudo: conteudo,
        indiceMarcador: 0,
        novoConteudoInterno: '[D]Outra',
      );

      expect(resultado.foiAlterado, isFalse);
      expect(resultado.conteudo, conteudo);
    });

    test('não altera bytes quando o conteúdo interno é igual', () {
      const conteudo = '{sov: label="V"}\r\n[C]Letra\r\n{eov}';
      final contexto = editor.contextoAtual(
        conteudo: conteudo,
        indiceMarcador: 0,
      )!;

      final resultado = editor.editar(
        conteudo: conteudo,
        indiceMarcador: 0,
        novoConteudoInterno: contexto.conteudoInterno,
      );

      expect(resultado.foiAlterado, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
