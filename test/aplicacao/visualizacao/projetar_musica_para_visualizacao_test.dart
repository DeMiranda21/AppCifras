import 'package:appcifras/aplicacao/visualizacao/projetar_musica_para_visualizacao.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parserDocumento = ParserDocumentoChordPro();
  final projetor = ProjetarMusicaParaVisualizacao();

  group('ProjetarMusicaParaVisualizacao', () {
    test('mantém os acordes originais no próprio tom, inclusive aliases', () {
      final musica = _musica(
        parserDocumento,
        tom: 'C',
        conteudo: '[Cmaj7]Letra [C4]',
      );

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, musica.tomOriginal),
      );

      expect(projecao.tomExecucao, musica.tomOriginal);
      expect(_acordes(projecao), ['Cmaj7', 'C4']);
      expect(projecao.elementos, orderedEquals(musica.documento.elementos));
    });

    test(
      'transpõe D para F usando o tom de destino como contexto enarmônico',
      () {
        final musica = _musica(
          parserDocumento,
          tom: 'D',
          conteudo: '[D]Um [G]dois [A]três',
        );

        final projecao = _projecaoDisponivel(
          projetor.executar(musica, _tom('F')),
        );

        expect(_acordes(projecao), ['F', 'Bb', 'C']);
        expect(projecao.tomOriginal, musica.tomOriginal);
        expect(projecao.tomExecucao, _tom('F'));
      },
    );

    test('transpõe E para F', () {
      final musica = _musica(parserDocumento, tom: 'E', conteudo: '[E]Letra');

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('F')),
      );

      expect(_acordes(projecao), ['F']);
    });

    test('usa deslocamento descendente no ciclo cromático de C para B', () {
      final musica = _musica(parserDocumento, tom: 'C', conteudo: '[C]Letra');

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('B')),
      );

      expect(_acordes(projecao), ['B']);
    });

    test('preserva as estruturas de acordes durante a transposição', () {
      final musica = _musica(
        parserDocumento,
        tom: 'C',
        conteudo: '[C]a [Cm]b [C5]c [C9]d [A2]e [D2(6)]f [A2/C#]g',
      );

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('D')),
      );

      expect(_acordes(projecao), [
        'D',
        'Dm',
        'D5',
        'D9',
        'B2',
        'E2(6)',
        'B2/D#',
      ]);
    });

    test('mantém a grafia de sustenido definida pelo tom de destino', () {
      final musica = _musica(parserDocumento, tom: 'C', conteudo: '[B]Letra');

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('D')),
      );

      expect(_acordes(projecao), ['C#']);
    });

    test('preserva linhas, espaços, seções e diretivas durante a projeção', () {
      const conteudo =
          '{comment: observação}\n'
          '{start_of_chorus}\n'
          '[D]Texto  com espaços [A]\n'
          '\n'
          '{end_of_chorus}\n'
          '{diretiva_desconhecida: valor}';
      final musica = _musica(parserDocumento, tom: 'D', conteudo: conteudo);

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('F')),
      );

      expect(
        projecao.elementos.map((elemento) => elemento.conteudoOriginal),
        orderedEquals(
          musica.documento.elementos.map(
            (elemento) => elemento.conteudoOriginal,
          ),
        ),
      );
      expect(_acordes(projecao), ['F', 'C']);
      expect(_textos(projecao), ['Texto  com espaços ']);
    });

    test('preserva acorde terminal na linha projetada', () {
      final musica = _musica(
        parserDocumento,
        tom: 'D',
        conteudo: '[D]Letra [A]',
      );

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, _tom('F')),
      );

      expect(_acordes(projecao), ['F', 'C']);
      expect(_textos(projecao), ['Letra ']);
    });

    test('não altera Música nem ChordPro canônico ao projetar', () {
      const conteudo = '[D]Letra [G]';
      final musica = _musica(parserDocumento, tom: 'D', conteudo: conteudo);
      final conteudoCanonico = musica.documento.conteudoOriginal;
      final acordesOriginais = _acordesDoDocumento(musica.documento);

      _projecaoDisponivel(projetor.executar(musica, _tom('F')));

      expect(musica.documento.conteudoOriginal, conteudoCanonico);
      expect(_acordesDoDocumento(musica.documento), acordesOriginais);
      expect(musica.tomOriginal, _tom('D'));
      expect(musica.titulo, 'Título');
      expect(musica.artista, 'Artista');
    });

    test(
      'bloqueia transposição em outro tom quando há acorde não interpretável',
      () {
        final musica = _musica(
          parserDocumento,
          tom: 'C',
          conteudo: '[C]Interpretável [H7]Preservado',
        );

        final resultado = projetor.executar(musica, _tom('D'));

        expect(resultado, isA<TransposicaoVisualizacaoIndisponivel>());
        final indisponivel = resultado as TransposicaoVisualizacaoIndisponivel;
        expect(indisponivel.tomExecucaoSolicitado, _tom('D'));
        expect(indisponivel.problemas, hasLength(1));
        expect(indisponivel.problemas.single.numeroLinha, 4);
        expect(indisponivel.problemas.single.textoOriginal, 'H7');
        expect(_acordes(indisponivel.projecaoNoTomOriginal), ['C', 'H7']);
      },
    );

    test('permite visualização original com acorde não interpretável', () {
      final musica = _musica(
        parserDocumento,
        tom: 'C',
        conteudo: '[C]Interpretável [H7]Preservado',
      );

      final projecao = _projecaoDisponivel(
        projetor.executar(musica, musica.tomOriginal),
      );

      expect(_acordes(projecao), ['C', 'H7']);
    });
  });
}

Musica _musica(
  ParserDocumentoChordPro parser, {
  required String tom,
  required String conteudo,
}) => Musica(
  id: IdMusica('musica-projecao'),
  documento: parser.interpretar(
    '{title: Título}\n{artist: Artista}\n{key: $tom}\n$conteudo',
  ),
);

Tom _tom(String valor) {
  final nome = valor[0];
  final acidente = valor.length > 1 && valor[1] != 'm' ? valor[1] : '';
  final menor = valor.endsWith('m');
  return Tom(
    notaFundamental: Nota(
      nome: switch (nome) {
        'A' => NomeNota.a,
        'B' => NomeNota.b,
        'C' => NomeNota.c,
        'D' => NomeNota.d,
        'E' => NomeNota.e,
        'F' => NomeNota.f,
        'G' => NomeNota.g,
        _ => throw ArgumentError.value(valor, 'valor'),
      },
      alteracao: switch (acidente) {
        '#' => AlteracaoNota.sustenido,
        'b' => AlteracaoNota.bemol,
        _ => AlteracaoNota.natural,
      },
    ),
    modo: menor ? ModoTom.menor : ModoTom.maior,
  );
}

ProjecaoMusicaVisualizacao _projecaoDisponivel(
  ResultadoProjecaoMusicaVisualizacao resultado,
) {
  expect(resultado, isA<ProjecaoMusicaVisualizacao>());
  return resultado as ProjecaoMusicaVisualizacao;
}

List<String> _acordes(ProjecaoMusicaVisualizacao projecao) => projecao.elementos
    .whereType<LinhaChordPro>()
    .expand((linha) => linha.elementos)
    .whereType<AcordeLinhaChordPro>()
    .map((acorde) => acorde.conteudoOriginal)
    .toList();

List<String> _textos(ProjecaoMusicaVisualizacao projecao) => projecao.elementos
    .whereType<LinhaChordPro>()
    .expand((linha) => linha.elementos)
    .whereType<TextoLinhaChordPro>()
    .map((texto) => texto.conteudoOriginal)
    .toList();

List<String> _acordesDoDocumento(DocumentoChordPro documento) => documento
    .elementos
    .whereType<LinhaChordPro>()
    .expand((linha) => linha.elementos)
    .whereType<AcordeLinhaChordPro>()
    .map((acorde) => acorde.conteudoOriginal)
    .toList();
