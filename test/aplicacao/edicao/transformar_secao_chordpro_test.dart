import 'package:appcifras/aplicacao/edicao/transformar_secao_chordpro.dart';
import 'package:appcifras/aplicacao/edicao/transformar_selecao_chordpro.dart';
import 'package:appcifras/aplicacao/estrutura/estrutura_musica.dart';
import 'package:appcifras/aplicacao/estrutura/reconhecedor_secao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transformador = TransformarSecaoChordPro();

  SelecaoTextoChordPro selecaoDaLinha(String texto, String linha) {
    final inicio = texto.indexOf(linha);
    return SelecaoTextoChordPro(inicio: inicio, fim: inicio + linha.length);
  }

  group('TransformarSecaoChordPro', () {
    for (final caso in [
      ('Verso 1', TipoSecaoMusica.verso, 'verse'),
      ('Refrão', TipoSecaoMusica.refrao, 'chorus'),
      ('Ponte', TipoSecaoMusica.ponte, 'bridge'),
      ('Pré-Refrão', TipoSecaoMusica.preRefrao, 'pre_chorus'),
      ('Intro', TipoSecaoMusica.intro, 'intro'),
      ('Instrumental', TipoSecaoMusica.instrumental, 'instrumental'),
      ('Solo', TipoSecaoMusica.solo, 'solo'),
      ('Final', TipoSecaoMusica.encerramento, 'final'),
      ('Ministração', TipoSecaoMusica.outro, 'section'),
    ]) {
      test('escreve $caso ambiente canônico preservando o rótulo', () {
        final (rotulo, tipo, ambiente) = caso;
        final conteudo = '$rotulo\n[C]Letra';

        final resultado = transformador.transformar(
          conteudo: conteudo,
          selecao: selecaoDaLinha(conteudo, rotulo),
          tipo: tipo,
        );

        expect(
          resultado.conteudo,
          '{start_of_$ambiente: label="$rotulo"}\n[C]Letra\n{end_of_$ambiente}',
        );
        expect(resultado.selecao.inicio, 0);
        expect(resultado.selecao.fim, greaterThan(0));
      });
    }

    test('fecha a seção antes do próximo marcador reconhecido', () {
      const conteudo = 'Verso 1\n[C]Linha 1\n[G]Linha 2\nRefrão\n[F]Linha 3';

      final resultado = transformador.transformar(
        conteudo: conteudo,
        selecao: selecaoDaLinha(conteudo, 'Verso 1'),
        tipo: TipoSecaoMusica.verso,
      );

      expect(
        resultado.conteudo,
        '{start_of_verse: label="Verso 1"}\n[C]Linha 1\n[G]Linha 2\n'
        '{end_of_verse}\nRefrão\n[F]Linha 3',
      );
    });

    test('cria seção vazia diante de marcador imediatamente seguinte', () {
      const conteudo = 'Intro\nRefrão\n[C]Letra';

      final resultado = transformador.transformar(
        conteudo: conteudo,
        selecao: selecaoDaLinha(conteudo, 'Intro'),
        tipo: TipoSecaoMusica.intro,
      );

      expect(
        resultado.conteudo,
        '{start_of_intro: label="Intro"}\n{end_of_intro}\nRefrão\n[C]Letra',
      );
    });

    test('preserva documento ao redor e escapa aspas do label', () {
      const conteudo =
          '{title: T}\n{tempo: 72}\nPonte "especial"\n[C]Letra\n{comment: fim}';

      final resultado = transformador.transformar(
        conteudo: conteudo,
        selecao: selecaoDaLinha(conteudo, 'Ponte "especial"'),
        tipo: TipoSecaoMusica.ponte,
      );

      expect(
        resultado.conteudo,
        '{title: T}\n{tempo: 72}\n'
        '{start_of_bridge: label="Ponte \\"especial\\""}\n[C]Letra\n{comment: fim}\n'
        '{end_of_bridge}',
      );
      final estrutura = EstruturadorDocumentoChordPro().estruturar(
        ParserDocumentoChordPro().interpretar(resultado.conteudo),
      );
      expect(
        estrutura.secoes
            .singleWhere((secao) => secao.tipo == TipoSecaoMusica.ponte)
            .rotuloOriginal,
        'Ponte "especial"',
      );
    });

    test('rejeita seleção parcial, multiline, vazia e diretiva', () {
      const conteudo = 'Verso 1\n[C]Letra\n{comment: fim}';
      final parcial = transformador.transformar(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 5),
        tipo: TipoSecaoMusica.verso,
      );
      final multilinha = transformador.transformar(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 16),
        tipo: TipoSecaoMusica.verso,
      );
      final vazia = transformador.transformar(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 0),
        tipo: TipoSecaoMusica.verso,
      );
      final diretiva = transformador.transformar(
        conteudo: conteudo,
        selecao: selecaoDaLinha(conteudo, '{comment: fim}'),
        tipo: TipoSecaoMusica.outro,
      );

      expect(parcial.foiTransformado, isFalse);
      expect(multilinha.foiTransformado, isFalse);
      expect(vazia.foiTransformado, isFalse);
      expect(diretiva.foiTransformado, isFalse);
      expect(diretiva.conteudo, conteudo);
    });

    test('rejeita linha já dentro de ambiente explícito', () {
      const conteudo =
          '{start_of_verse: label="Verso"}\nPonte\n[C]Letra\n{end_of_verse}';

      final resultado = transformador.transformar(
        conteudo: conteudo,
        selecao: selecaoDaLinha(conteudo, 'Ponte'),
        tipo: TipoSecaoMusica.ponte,
      );

      expect(resultado.foiTransformado, isFalse);
      expect(resultado.conteudo, conteudo);
    });
  });
}
