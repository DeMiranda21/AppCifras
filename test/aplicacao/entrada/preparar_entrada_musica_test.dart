import 'package:appcifras/aplicacao/entrada/conversor_cifra_textual.dart';
import 'package:appcifras/aplicacao/entrada/preparar_entrada_musica.dart';
import 'package:appcifras/aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'package:appcifras/aplicacao/entrada/resultado_analise_entrada_musica.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final preparador = PrepararEntradaMusica();

  group('PrepararEntradaMusica', () {
    test(
      'prepara ChordPro completo sem conversão textual ou novos metadados',
      () {
        const conteudo =
            '{title: Senhor, Tu És Bom}\n'
            '{artist: Artista}\n'
            '{key: E}\n'
            '\n'
            '[E]Senhor, Tu és bom';

        final preparado = preparador.executar(conteudo);

        expect(
          preparado.classificacao,
          ClassificacaoEntradaMusica.chordProConfirmado,
        );
        expect(preparado.documentoJaEraChordPro, isTrue);
        expect(preparado.houveConversaoTextual, isFalse);
        expect(preparado.conversao, isNull);
        expect(preparado.conteudoOriginal, conteudo);
        expect(preparado.chordProSugerido, conteudo);
        expect(preparado.tituloDetectado, 'Senhor, Tu És Bom');
        expect(preparado.artistaDetectado, 'Artista');
        expect(preparado.tomDetectado?.notaFundamental.nome.simbolo, 'E');
        expect(preparado.camposObrigatoriosPendentes, isEmpty);
      },
    );

    test('mantém rascunho ChordPro com metadado obrigatório faltante', () {
      const conteudo = '{title: Título}\n{key: C}\n[C]Letra';

      final preparado = preparador.executar(conteudo);

      expect(preparado.possuiRascunhoParaRevisao, isTrue);
      expect(preparado.artistaDetectado, isNull);
      expect(preparado.camposObrigatoriosPendentes, [
        CampoMetadadoEntrada.artista,
      ]);
      expect(preparado.chordProSugerido, conteudo);
    });

    test(
      'expõe conflito de metadado ChordPro duplicado sem escolher precedência',
      () {
        const conteudo =
            '{title: Primeiro}\n'
            '{title: Segundo}\n'
            '{artist: Artista}\n'
            '{key: C}\n'
            '[C]Letra';

        final preparado = preparador.executar(conteudo);

        expect(preparado.possuiRascunhoParaRevisao, isTrue);
        expect(preparado.conflitos, {CampoMetadadoRascunho.titulo});
        expect(preparado.tituloDetectado, isNull);
      },
    );

    test('converte cifra textual com Tom explícito e mantém título e artista pendentes', () {
      const conteudo =
          'Tom: E\n\n'
          '[Primeira Parte]\n\n'
          '    E5\n'
          'Senhor, Tu és bom\n\n'
          '     B11/D#             D2(6) A9/C#\n'
          'Tua misericórdia é pra sempre';

      final preparado = preparador.executar(conteudo);

      expect(
        preparado.classificacao,
        ClassificacaoEntradaMusica.cifraTextualProvavel,
      );
      expect(preparado.houveConversaoTextual, isTrue);
      expect(preparado.documentoJaEraChordPro, isFalse);
      expect(preparado.conteudoOriginal, conteudo);
      expect(preparado.chordProSugerido, startsWith('{key: E}'));
      expect(preparado.chordProSugerido, contains('[B11/D#]misericórdia'));
      expect(preparado.tituloDetectado, isNull);
      expect(preparado.artistaDetectado, isNull);
      expect(preparado.tomDetectado?.notaFundamental.nome.simbolo, 'E');
      expect(preparado.camposObrigatoriosPendentes, [
        CampoMetadadoEntrada.titulo,
        CampoMetadadoEntrada.artista,
      ]);
    });

    test('mantém tom pendente quando a cifra textual não o informa', () {
      final preparado = preparador.executar('E5 B11/D#\nSenhor, Tu és bom');

      expect(
        preparado.classificacao,
        ClassificacaoEntradaMusica.cifraTextualProvavel,
      );
      expect(preparado.possuiRascunhoParaRevisao, isTrue);
      expect(preparado.tomDetectado, isNull);
      expect(preparado.camposObrigatoriosPendentes, [
        CampoMetadadoEntrada.titulo,
        CampoMetadadoEntrada.artista,
        CampoMetadadoEntrada.tom,
      ]);
    });

    test('não cria rascunho salvável para texto ambíguo', () {
      const conteudo = 'Senhor, Tu és bom\nTua misericórdia é pra sempre';

      final preparado = preparador.executar(conteudo);

      expect(preparado.classificacao, ClassificacaoEntradaMusica.ambigua);
      expect(preparado.conteudoOriginal, conteudo);
      expect(preparado.houveConversaoTextual, isFalse);
      expect(preparado.chordProSugerido, isNull);
      expect(preparado.rascunho, isNull);
      expect(preparado.requerRevisao, isTrue);
    });

    test('preserva avisos da análise em ChordPro confirmado', () {
      const conteudo =
          '{title: Título}\n'
          '{artist: Artista}\n'
          '{key: C}\n'
          '{comment: ensaio}\n'
          '[C]Letra';

      final preparado = preparador.executar(conteudo);

      expect(preparado.avisosAnalise, isNotEmpty);
      expect(preparado.avisosConversao, isEmpty);
    });

    test('preserva avisos da conversão textual', () {
      final preparado = preparador.executar('E5 B11/D#\n\n[Final]');

      expect(preparado.avisosConversao, isNotEmpty);
      expect(
        preparado.avisosConversao.any(
          (aviso) => aviso.tipo == TipoAvisoConversaoCifra.linhaInstrumental,
        ),
        isTrue,
      );
    });

    test('leva trecho representativo até rascunho revisável finalizável', () {
      const conteudo =
          'Tom: E\n\n'
          '[Intro] E5 B11/D# D2(6) A9/C#\n\n'
          '[Primeira Parte]\n\n'
          '    E5\n'
          'Senhor, Tu és bom\n\n'
          '     B11/D#             D2(6) A9/C#\n'
          'Tua misericórdia é pra sempre\n\n'
          '[Pré-Refrão]\n\n'
          ' A2                 B4\n'
          'Todos os povos te exaltarão\n\n'
          ' C7M       D2(6)\n'
          'De geração em geração';

      final preparado = preparador.executar(conteudo);
      final finalizado = preparado.rascunho!
          .comRevisao(
            const RevisaoMetadadosChordPro(
              titulo: 'Senhor, Tu És Bom',
              artista: 'Israel & New Breed',
            ),
          )
          .produzirConteudoFinal();
      final documento = ParserDocumentoChordPro().interpretar(finalizado);

      expect(preparado.conteudoOriginal, conteudo);
      expect(
        preparado.classificacao,
        ClassificacaoEntradaMusica.cifraTextualProvavel,
      );
      expect(preparado.chordProSugerido, isNotNull);
      expect(preparado.chordProSugerido, contains('[A2]'));
      expect(preparado.chordProSugerido, contains('[D2(6)]'));
      expect(preparado.tituloDetectado, isNull);
      expect(preparado.artistaDetectado, isNull);
      expect(
        documento.elementos.whereType<DiretivaTituloChordPro>(),
        hasLength(1),
      );
      expect(
        documento.elementos.whereType<DiretivaArtistaChordPro>(),
        hasLength(1),
      );
      expect(
        documento.elementos.whereType<DiretivaTomChordPro>(),
        hasLength(1),
      );
    });
  });
}
