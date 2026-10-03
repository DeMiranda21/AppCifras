import 'package:appcifras/aplicacao/edicao/reordenar_secoes_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reordenar = ReordenarSecoesChordPro();

  group('ReordenarSecoesChordPro', () {
    test('move primeira seção para a última', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}\n'
          '{start_of_bridge: label="P"}\n[E]Ponte\n{end_of_bridge}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 2,
      );

      expect(resultado.foiReordenada, isTrue);
      expect(
        resultado.conteudo,
        '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}\n'
        '{start_of_bridge: label="P"}\n[E]Ponte\n{end_of_bridge}\n'
        '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}',
      );
    });

    test('move última seção para a primeira', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 1,
        indiceDestino: 0,
      );

      expect(
        resultado.conteudo,
        '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}\n'
        '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}',
      );
    });

    test('move seção intermediária para cima e preserva conteúdo literal', () {
      const conteudo =
          '{start_of_intro: label="I"}\n[C]I\n{end_of_intro}\n'
          '{start_of_verse: label="V"}\n\n{comment: manter}\n[D]V\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[E]R\n{end_of_chorus}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 1,
        indiceDestino: 0,
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="V"}\n\n{comment: manter}\n[D]V\n{end_of_verse}\n'
        '{start_of_intro: label="I"}\n[C]I\n{end_of_intro}\n'
        '{start_of_chorus: label="R"}\n[E]R\n{end_of_chorus}',
      );
    });

    test('aceita movimento adjacente entre duas seções', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]V\n{end_of_verse}\n'
          '{start_of_chorus: label="R"}\n[D]R\n{end_of_chorus}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 1,
      );

      expect(resultado.foiReordenada, isTrue);
      expect(resultado.conteudo, contains('{start_of_chorus'));
      expect(
        resultado.conteudo.indexOf('{start_of_chorus'),
        lessThan(resultado.conteudo.indexOf('{start_of_verse')),
      );
    });

    test('preserva alias e ambiente externo byte a byte', () {
      const conteudo =
          '{sov: label="V"}\r\n[C]Verso\r\n{eov}\r\n'
          '{start_of_spontaneous: label="Livre"}\r\n[D]Texto\r\n{end_of_spontaneous}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 1,
      );

      expect(
        resultado.conteudo,
        '{start_of_spontaneous: label="Livre"}\r\n[D]Texto\r\n{end_of_spontaneous}\r\n'
        '{sov: label="V"}\r\n[C]Verso\r\n{eov}',
      );
    });

    test('rejeita seção sem fechamento confiável', () {
      const conteudo =
          '{start_of_verse: label="V"}\n[C]Verso\n'
          '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 1,
      );

      expect(resultado.foiReordenada, isFalse);
      expect(resultado.conteudo, conteudo);
    });

    test('reordena trecho não identificado entre seções contíguas', () {
      const conteudo =
          'Observação\n'
          '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}\n'
          '\n'
          '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 2,
      );

      expect(resultado.foiReordenada, isTrue);
      expect(
        resultado.conteudo,
        '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}\n'
        '{start_of_chorus: label="R"}\n[D]Refrão\n{end_of_chorus}\n'
        'Observação',
      );
    });

    test('não move trecho através de diretiva não estrutural', () {
      const conteudo =
          'Antes\n{tempo: 72}\nDepois\n'
          '{start_of_verse: label="V"}\n[C]Verso\n{end_of_verse}';

      final resultado = reordenar.reordenar(
        conteudo: conteudo,
        indiceOrigem: 0,
        indiceDestino: 1,
      );

      expect(resultado.foiReordenada, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
