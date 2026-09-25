import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/formatador_acorde.dart';
import '../../dominio/servicos/parser_acorde.dart';
import '../../dominio/servicos/servico_transposicao.dart';

/// Resultado da preparação de uma música para leitura em um tom de execução.
sealed class ResultadoProjecaoMusicaVisualizacao {
  const ResultadoProjecaoMusicaVisualizacao();
}

/// Projeção pronta para o renderer, sem alterar a música persistida.
class ProjecaoMusicaVisualizacao extends ResultadoProjecaoMusicaVisualizacao {
  ProjecaoMusicaVisualizacao({
    required this.titulo,
    required this.artista,
    required this.tomOriginal,
    required this.tomExecucao,
    required Iterable<ElementoDocumentoChordPro> elementos,
  }) : elementos = List.unmodifiable(elementos);

  final String titulo;
  final String artista;
  final Tom tomOriginal;
  final Tom tomExecucao;
  final List<ElementoDocumentoChordPro> elementos;
}

/// Uma cifra não interpretável impede a transposição segura da música.
class AcordeNaoTransponivelVisualizacao {
  const AcordeNaoTransponivelVisualizacao({
    required this.numeroLinha,
    required this.textoOriginal,
  });

  /// Número físico da linha no conteúdo ChordPro, iniciado em um.
  final int numeroLinha;
  final String textoOriginal;
}

/// Resultado quando a música pode ser lida no tom original, mas não transposta.
class TransposicaoVisualizacaoIndisponivel
    extends ResultadoProjecaoMusicaVisualizacao {
  TransposicaoVisualizacaoIndisponivel({
    required this.projecaoNoTomOriginal,
    required this.tomExecucaoSolicitado,
    required Iterable<AcordeNaoTransponivelVisualizacao> problemas,
  }) : problemas = List.unmodifiable(problemas);

  final ProjecaoMusicaVisualizacao projecaoNoTomOriginal;
  final Tom tomExecucaoSolicitado;
  final List<AcordeNaoTransponivelVisualizacao> problemas;
}

/// Cria uma representação temporária da música para leitura em outro tom.
class ProjetarMusicaParaVisualizacao {
  ProjetarMusicaParaVisualizacao({
    ServicoTransposicao? servicoTransposicao,
    FormatadorAcorde? formatadorAcorde,
  }) : _servicoTransposicao = servicoTransposicao ?? ServicoTransposicao(),
       _formatadorAcorde = formatadorAcorde ?? FormatadorAcorde();

  final ServicoTransposicao _servicoTransposicao;
  final FormatadorAcorde _formatadorAcorde;

  ResultadoProjecaoMusicaVisualizacao executar(Musica musica, Tom tomExecucao) {
    final projecaoOriginal = _projecaoOriginal(musica);
    if (tomExecucao == musica.tomOriginal) {
      return projecaoOriginal;
    }

    final problemas = _acordesNaoInterpretaveis(musica.documento);
    if (problemas.isNotEmpty) {
      return TransposicaoVisualizacaoIndisponivel(
        projecaoNoTomOriginal: projecaoOriginal,
        tomExecucaoSolicitado: tomExecucao,
        problemas: problemas,
      );
    }

    final semitons = _calcularSemitons(musica.tomOriginal, tomExecucao);
    return ProjecaoMusicaVisualizacao(
      titulo: musica.titulo,
      artista: musica.artista,
      tomOriginal: musica.tomOriginal,
      tomExecucao: tomExecucao,
      elementos: musica.documento.elementos.map(
        (elemento) => elemento is LinhaChordPro
            ? _transporLinha(elemento, semitons, tomExecucao)
            : elemento,
      ),
    );
  }

  ProjecaoMusicaVisualizacao _projecaoOriginal(Musica musica) =>
      ProjecaoMusicaVisualizacao(
        titulo: musica.titulo,
        artista: musica.artista,
        tomOriginal: musica.tomOriginal,
        tomExecucao: musica.tomOriginal,
        elementos: musica.documento.elementos,
      );

  int _calcularSemitons(Tom origem, Tom destino) {
    final ascendente =
        (destino.notaFundamental.classeDeAltura -
            origem.notaFundamental.classeDeAltura) %
        12;
    return ascendente > 6 ? ascendente - 12 : ascendente;
  }

  List<AcordeNaoTransponivelVisualizacao> _acordesNaoInterpretaveis(
    DocumentoChordPro documento,
  ) {
    final problemas = <AcordeNaoTransponivelVisualizacao>[];
    for (var indice = 0; indice < documento.elementos.length; indice += 1) {
      final elemento = documento.elementos[indice];
      if (elemento is! LinhaChordPro) {
        continue;
      }
      for (final acorde
          in elemento.elementos.whereType<AcordeLinhaChordPro>()) {
        if (acorde.resultado is AcordeNaoInterpretavel) {
          problemas.add(
            AcordeNaoTransponivelVisualizacao(
              numeroLinha: indice + 1,
              textoOriginal: acorde.conteudoOriginal,
            ),
          );
        }
      }
    }
    return problemas;
  }

  LinhaChordPro _transporLinha(
    LinhaChordPro linha,
    int semitons,
    Tom tomExecucao,
  ) => LinhaChordPro(
    linha.conteudoOriginal,
    linha.elementos.map((elemento) {
      if (elemento is! AcordeLinhaChordPro) {
        return elemento;
      }
      final resultado = elemento.resultado;
      if (resultado is! AcordeInterpretado) {
        throw StateError(
          'Acorde não interpretável deveria bloquear a projeção.',
        );
      }
      final acordeTransposto = _servicoTransposicao.transporAcorde(
        resultado.acorde,
        semitons,
        tomDestino: tomExecucao,
      );
      return AcordeLinhaChordPro(
        _formatadorAcorde.formatar(acordeTransposto),
        AcordeInterpretado(acordeTransposto),
      );
    }),
  );
}
