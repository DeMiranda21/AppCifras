import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import 'normalizacao_pesquisa.dart';

class ServicoPesquisaMusicas {
  const ServicoPesquisaMusicas();

  IndicePesquisaMusicas criarIndice(Iterable<Musica> musicas) =>
      IndicePesquisaMusicas(
        musicas.map(
          (musica) => TextoPesquisaMusica(
            musica: musica,
            textoNormalizado: normalizarPesquisa(
              '${musica.titulo}\n${musica.artista}\n'
              '${_extrairConteudoVisivel(musica.documento)}',
            ),
          ),
        ),
      );

  String _extrairConteudoVisivel(DocumentoChordPro documento) => documento
      .elementos
      .map(
        (elemento) => switch (elemento) {
          LinhaChordPro linha =>
            linha.elementos
                .whereType<TextoLinhaChordPro>()
                .map((texto) => texto.conteudoOriginal)
                .join(),
          LinhaNaoInterpretadaChordPro linha => linha.conteudoOriginal,
          _ => '',
        },
      )
      .join('\n');
}

class IndicePesquisaMusicas {
  IndicePesquisaMusicas(Iterable<TextoPesquisaMusica> entradas)
    : _entradas = List.unmodifiable(entradas);

  final List<TextoPesquisaMusica> _entradas;

  List<Musica> filtrar(String consulta) {
    final normalizada = normalizarPesquisa(consulta);
    if (normalizada.isEmpty) {
      return _entradas.map((entrada) => entrada.musica).toList();
    }
    return _entradas
        .where((entrada) => entrada.textoNormalizado.contains(normalizada))
        .map((entrada) => entrada.musica)
        .toList();
  }
}

class TextoPesquisaMusica {
  const TextoPesquisaMusica({
    required this.musica,
    required this.textoNormalizado,
  });

  final Musica musica;
  final String textoNormalizado;
}
