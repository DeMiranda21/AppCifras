import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import '../portas/repositorio_classificacao_musica.dart';
import 'normalizacao_pesquisa.dart';

class ServicoPesquisaMusicas {
  const ServicoPesquisaMusicas();

  IndicePesquisaMusicas criarIndice(
    Iterable<Musica> musicas, {
    Map<IdMusica, ClassificacaoMusica> classificacoes = const {},
  }) => IndicePesquisaMusicas(
    musicas.map(
      (musica) => TextoPesquisaMusica(
        musica: musica,
        classificacao: classificacoes[musica.id] ?? const ClassificacaoMusica(),
        linhasVisiveis: _extrairLinhasVisiveis(musica.documento),
        textoNormalizado: normalizarPesquisa(
          '${musica.titulo}\n${musica.artista}\n'
          '${_extrairConteudoVisivel(musica.documento)}',
        ),
      ),
    ),
  );

  String _extrairConteudoVisivel(DocumentoChordPro documento) =>
      documento.elementos.map(_textoVisivel).join('\n');

  List<LinhaPesquisaMusica> _extrairLinhasVisiveis(
    DocumentoChordPro documento,
  ) {
    final linhas = <LinhaPesquisaMusica>[];
    for (final elemento in documento.elementos) {
      final texto = _textoVisivel(elemento);
      if (texto.isNotEmpty) {
        linhas.add(LinhaPesquisaMusica(texto));
      }
    }
    return linhas;
  }

  String _textoVisivel(ElementoDocumentoChordPro elemento) =>
      switch (elemento) {
        LinhaChordPro linha =>
          linha.elementos
              .whereType<TextoLinhaChordPro>()
              .map((texto) => texto.conteudoOriginal)
              .join(),
        LinhaNaoInterpretadaChordPro linha => linha.conteudoOriginal,
        _ => '',
      };
}

class IndicePesquisaMusicas {
  IndicePesquisaMusicas(Iterable<TextoPesquisaMusica> entradas)
    : _entradas = List.unmodifiable(entradas);

  final List<TextoPesquisaMusica> _entradas;

  List<TagMusica> get tagsDisponiveis {
    final tags = <String, TagMusica>{};
    for (final entrada in _entradas) {
      for (final tag in entrada.classificacao.tags) {
        tags.putIfAbsent(tag.chaveNormalizada, () => tag);
      }
    }
    final resultado = tags.values.toList()
      ..sort(
        (primeira, segunda) =>
            primeira.chaveNormalizada.compareTo(segunda.chaveNormalizada),
      );
    return List.unmodifiable(resultado);
  }

  List<Musica> filtrar(ConsultaPesquisaMusicas consulta) {
    return pesquisar(consulta).map((resultado) => resultado.musica).toList();
  }

  List<ResultadoPesquisaMusica> pesquisar(ConsultaPesquisaMusicas consulta) {
    final texto = normalizarPesquisa(consulta.texto);
    return _entradas
        .where(
          (entrada) =>
              (texto.isEmpty || entrada.textoNormalizado.contains(texto)) &&
              (consulta.energia == null ||
                  entrada.classificacao.energia == consulta.energia) &&
              consulta.tags.every(entrada.classificacao.tags.contains),
        )
        .map(
          (entrada) => ResultadoPesquisaMusica(
            musica: entrada.musica,
            trechoLetra: texto.isEmpty
                ? null
                : entrada.primeiraLinhaCorrespondente(texto),
          ),
        )
        .toList();
  }
}

class ResultadoPesquisaMusica {
  const ResultadoPesquisaMusica({
    required this.musica,
    required this.trechoLetra,
  });

  final Musica musica;
  final String? trechoLetra;
}

class ConsultaPesquisaMusicas {
  ConsultaPesquisaMusicas({
    this.texto = '',
    this.energia,
    Iterable<TagMusica> tags = const [],
  }) : tags = Set.unmodifiable(tags);

  final String texto;
  final EnergiaMusica? energia;
  final Set<TagMusica> tags;
}

class TextoPesquisaMusica {
  const TextoPesquisaMusica({
    required this.musica,
    required this.classificacao,
    required this.linhasVisiveis,
    required this.textoNormalizado,
  });

  final Musica musica;
  final ClassificacaoMusica classificacao;
  final List<LinhaPesquisaMusica> linhasVisiveis;
  final String textoNormalizado;

  String? primeiraLinhaCorrespondente(String textoNormalizado) {
    for (final linha in linhasVisiveis) {
      if (linha.textoNormalizado.contains(textoNormalizado)) {
        return linha.original;
      }
    }
    return null;
  }
}

class LinhaPesquisaMusica {
  LinhaPesquisaMusica(this.original)
    : textoNormalizado = normalizarPesquisa(original);

  final String original;
  final String textoNormalizado;
}
