import 'package:appcifras/aplicacao/edicao/criar_secao_chordpro.dart';
import 'package:appcifras/aplicacao/estrutura/reconhecedor_secao_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final criar = CriarSecaoChordPro();

  ResultadoCriacaoSecaoChordPro criarSecao(
    String conteudo,
    TipoSecaoMusica tipo,
    String label,
  ) => criar.criar(conteudo: conteudo, tipo: tipo, label: label);

  group('CriarSecaoChordPro', () {
    test('cria verso em documento vazio', () {
      final resultado = criarSecao('', TipoSecaoMusica.verso, 'Verso 2');

      expect(resultado.foiCriada, isTrue);
      expect(
        resultado.conteudo,
        '{start_of_verse: label="Verso 2"}\n{end_of_verse}',
      );
    });

    test('cria tipos canônicos no fim do documento', () {
      const conteudo = '{title: T}\n{artist: A}\n{key: C}\n[C]Existente';
      final casos = {
        TipoSecaoMusica.intro: ('Intro', 'intro'),
        TipoSecaoMusica.refrao: ('Refrão', 'chorus'),
        TipoSecaoMusica.ponte: ('Ponte', 'bridge'),
        TipoSecaoMusica.encerramento: ('Final', 'final'),
      };

      for (final entrada in casos.entries) {
        final resultado = criarSecao(conteudo, entrada.key, entrada.value.$1);
        expect(
          resultado.conteudo,
          '$conteudo\n{start_of_${entrada.value.$2}: label="${entrada.value.$1}"}\n'
          '{end_of_${entrada.value.$2}}',
        );
      }
    });

    test('cria Outro com ambiente section e escapa o label', () {
      final resultado = criarSecao(
        '',
        TipoSecaoMusica.outro,
        'Seção "Livre" \\',
      );

      expect(
        resultado.conteudo,
        '{start_of_section: label="Seção \\"Livre\\" \\\\"}\n{end_of_section}',
      );
    });

    test('preserva literalmente documento existente e suas seções', () {
      const conteudo =
          '{sov: label="V"}\r\n[C]Verso\r\n{eov}\r\n'
          '{start_of_spontaneous: label="Livre"}\r\n[D]Texto\r\n{end_of_spontaneous}\r\n';

      final resultado = criarSecao(conteudo, TipoSecaoMusica.solo, 'Solo');

      expect(
        resultado.conteudo,
        '$conteudo{start_of_solo: label="Solo"}\r\n{end_of_solo}',
      );
    });

    test('rejeita label vazio sem alterar o documento', () {
      const conteudo = '[C]Existente';

      final resultado = criarSecao(conteudo, TipoSecaoMusica.verso, '   ');

      expect(resultado.foiCriada, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
