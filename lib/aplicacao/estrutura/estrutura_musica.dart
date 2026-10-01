import '../../dominio/chordpro/documento_chordpro.dart';
import 'reconhecedor_secao_musica.dart';

class EstruturaMusica {
  EstruturaMusica({
    required this.documento,
    required Iterable<SecaoMusica> secoes,
  }) : secoes = List.unmodifiable(secoes);

  final DocumentoChordPro documento;
  final List<SecaoMusica> secoes;
}

/// Faixa derivada do documento canônico que prepara futuras operações de bloco.
///
/// Os índices usam a lista ordenada de [DocumentoChordPro.elementos]. A seção
/// nunca é persistida nem reescreve o ChordPro de origem.
class SecaoMusica {
  SecaoMusica({
    required this.tipo,
    required this.rotuloOriginal,
    required this.indiceMarcador,
    required this.inicioConteudo,
    required this.fimConteudoExclusivo,
    required Iterable<ElementoDocumentoChordPro> elementos,
  }) : elementos = List.unmodifiable(elementos);

  final TipoSecaoMusica tipo;
  final String? rotuloOriginal;
  final int? indiceMarcador;
  final int inicioConteudo;
  final int fimConteudoExclusivo;
  final List<ElementoDocumentoChordPro> elementos;

  bool get ehImplicita => indiceMarcador == null;
}

/// Deriva seções por marcadores ChordPro e rótulos textuais inequívocos.
class EstruturadorDocumentoChordPro {
  EstruturadorDocumentoChordPro({ReconhecedorSecaoMusica? reconhecedor})
    : _reconhecedor = reconhecedor ?? ReconhecedorSecaoMusica();

  final ReconhecedorSecaoMusica _reconhecedor;

  EstruturaMusica estruturar(DocumentoChordPro documento) {
    final secoes = <SecaoMusica>[];
    _SecaoAberta? aberta;
    var inicioLivre = 0;

    void concluirAberta(int fimExclusivo) {
      final atual = aberta;
      if (atual == null) {
        return;
      }
      secoes.add(
        SecaoMusica(
          tipo: atual.tipo,
          rotuloOriginal: atual.rotuloOriginal,
          indiceMarcador: atual.indiceMarcador,
          inicioConteudo: atual.inicioConteudo,
          fimConteudoExclusivo: fimExclusivo,
          elementos: documento.elementos.sublist(
            atual.inicioConteudo,
            fimExclusivo,
          ),
        ),
      );
      aberta = null;
    }

    void concluirLivre(int fimExclusivo) {
      if (inicioLivre >= fimExclusivo) {
        return;
      }
      secoes.add(
        SecaoMusica(
          tipo: TipoSecaoMusica.outro,
          rotuloOriginal: null,
          indiceMarcador: null,
          inicioConteudo: inicioLivre,
          fimConteudoExclusivo: fimExclusivo,
          elementos: documento.elementos.sublist(inicioLivre, fimExclusivo),
        ),
      );
    }

    for (var indice = 0; indice < documento.elementos.length; indice += 1) {
      final elemento = documento.elementos[indice];
      final marcador = _marcadorDoElemento(elemento);
      if (marcador == null) {
        continue;
      }
      if (marcador.ehInicio) {
        if (aberta != null) {
          concluirAberta(indice);
        } else {
          concluirLivre(indice);
        }
        aberta = _SecaoAberta(
          tipo: marcador.tipo,
          rotuloOriginal: marcador.rotuloOriginal!,
          indiceMarcador: indice,
          inicioConteudo: indice + 1,
        );
        inicioLivre = indice + 1;
      } else if (aberta != null) {
        concluirAberta(indice);
        inicioLivre = indice + 1;
      }
    }

    if (aberta != null) {
      concluirAberta(documento.elementos.length);
    } else {
      concluirLivre(documento.elementos.length);
    }
    return EstruturaMusica(documento: documento, secoes: secoes);
  }

  MarcadorSecaoChordPro? _marcadorDoElemento(
    ElementoDocumentoChordPro elemento,
  ) {
    final diretiva = _reconhecedor.reconhecerDiretiva(
      elemento.conteudoOriginal,
    );
    if (diretiva != null) {
      return diretiva;
    }
    if (elemento is DiretivaDesconhecidaChordPro &&
        elemento.nome == 'comment') {
      final rotulo = _reconhecedor.reconhecerRotulo(elemento.valorOriginal);
      return rotulo == null
          ? null
          : MarcadorSecaoChordPro.inicio(
              tipo: rotulo.tipo,
              rotuloOriginal: rotulo.rotuloOriginal,
            );
    }
    if (elemento is LinhaChordPro || elemento is LinhaNaoInterpretadaChordPro) {
      final rotulo = _reconhecedor.reconhecerRotulo(elemento.conteudoOriginal);
      return rotulo == null
          ? null
          : MarcadorSecaoChordPro.inicio(
              tipo: rotulo.tipo,
              rotuloOriginal: rotulo.rotuloOriginal,
            );
    }
    return null;
  }
}

class _SecaoAberta {
  const _SecaoAberta({
    required this.tipo,
    required this.rotuloOriginal,
    required this.indiceMarcador,
    required this.inicioConteudo,
  });

  final TipoSecaoMusica tipo;
  final String rotuloOriginal;
  final int indiceMarcador;
  final int inicioConteudo;
}
