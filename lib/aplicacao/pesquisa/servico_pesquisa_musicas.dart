import '../../dominio/entidades/musica.dart';
import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import '../portas/repositorio_classificacao_musica.dart';
import '../biblioteca/item_biblioteca.dart';
import 'normalizacao_pesquisa.dart';

class ServicoPesquisaMusicas {
  const ServicoPesquisaMusicas();

  IndicePesquisaMusicas<Musica> criarIndice(
    Iterable<Musica> musicas, {
    Map<IdMusica, ClassificacaoMusica> classificacoes = const {},
  }) => IndicePesquisaMusicas(
    musicas.map((musica) {
      final conteudoVisivel = ExtratorConteudoVisivelChordPro.extrair(
        musica.documento,
      );
      return TextoPesquisaMusica(
        musica: musica,
        idMusica: musica.id,
        titulo: musica.titulo,
        classificacao: classificacoes[musica.id] ?? const ClassificacaoMusica(),
        conteudoVisivel: conteudoVisivel,
        tituloNormalizado: normalizarPesquisa(musica.titulo),
        artistaNormalizado: normalizarPesquisa(musica.artista),
        textoNormalizado: normalizarPesquisa(
          '${musica.titulo}\n${musica.artista}\n$conteudoVisivel',
        ),
      );
    }),
  );

  IndicePesquisaMusicas<ItemBiblioteca> criarIndiceBiblioteca(
    Iterable<ItemBiblioteca> itens, {
    Map<IdMusica, ClassificacaoMusica> classificacoes = const {},
  }) => IndicePesquisaMusicas(
    itens.map(
      (item) => TextoPesquisaMusica(
        musica: item,
        idMusica: item.idMusica,
        titulo: item.titulo,
        classificacao:
            classificacoes[item.idMusica] ?? const ClassificacaoMusica(),
        conteudoVisivel: item.conteudoVisivel,
        tituloNormalizado: item.tituloNormalizado,
        artistaNormalizado: normalizarPesquisa(item.artista),
        textoNormalizado: item.textoNormalizado,
      ),
    ),
  );
}

class IndicePesquisaMusicas<T> {
  IndicePesquisaMusicas(Iterable<TextoPesquisaMusica<T>> entradas)
    : _entradas = List.unmodifiable(
        List<TextoPesquisaMusica<T>>.of(entradas)..sort(_compararPorTitulo),
      ) {
    _tagsDisponiveis = _coletarTags();
    _resultadosSemConsulta = List.unmodifiable([
      for (final entrada in _entradas)
        ResultadoPesquisaMusica(musica: entrada.musica, trechoLetra: null),
    ]);
  }

  final List<TextoPesquisaMusica<T>> _entradas;
  late final List<TagMusica> _tagsDisponiveis;
  late final List<ResultadoPesquisaMusica<T>> _resultadosSemConsulta;

  bool get isEmpty => _entradas.isEmpty;

  static int _compararPorTitulo(
    TextoPesquisaMusica<dynamic> primeira,
    TextoPesquisaMusica<dynamic> segunda,
  ) {
    final tituloNormalizado = primeira.tituloNormalizado.compareTo(
      segunda.tituloNormalizado,
    );
    if (tituloNormalizado != 0) return tituloNormalizado;

    final tituloOriginal = primeira.titulo.compareTo(segunda.titulo);
    if (tituloOriginal != 0) return tituloOriginal;

    return primeira.idMusica.valor.compareTo(segunda.idMusica.valor);
  }

  List<TagMusica> get tagsDisponiveis => _tagsDisponiveis;

  List<TagMusica> _coletarTags() {
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

  List<T> filtrar(ConsultaPesquisaMusicas consulta) {
    return pesquisar(consulta).map((resultado) => resultado.musica).toList();
  }

  List<ResultadoPesquisaMusica<T>> pesquisar(ConsultaPesquisaMusicas consulta) {
    final texto = normalizarPesquisa(consulta.texto);
    if (texto.isEmpty && consulta.energia == null && consulta.tags.isEmpty) {
      return _resultadosSemConsulta;
    }
    final entradas = _entradas
        .where(
          (entrada) =>
              (texto.isEmpty || entrada.textoNormalizado.contains(texto)) &&
              (consulta.energia == null ||
                  entrada.classificacao.energia == consulta.energia) &&
              consulta.tags.every(entrada.classificacao.tags.contains),
        )
        .toList();
    if (texto.isNotEmpty) {
      entradas.sort((primeira, segunda) {
        final prioridade = primeira
            .prioridadePara(texto)
            .compareTo(segunda.prioridadePara(texto));
        return prioridade != 0
            ? prioridade
            : _compararPorTitulo(primeira, segunda);
      });
    }
    return entradas
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

class ResultadoPesquisaMusica<T> {
  const ResultadoPesquisaMusica({
    required this.musica,
    required this.trechoLetra,
  });

  final T musica;
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

class TextoPesquisaMusica<T> {
  const TextoPesquisaMusica({
    required this.musica,
    required this.idMusica,
    required this.titulo,
    required this.classificacao,
    required this.conteudoVisivel,
    required this.tituloNormalizado,
    required this.artistaNormalizado,
    required this.textoNormalizado,
  });

  final T musica;
  final IdMusica idMusica;
  final String titulo;
  final ClassificacaoMusica classificacao;
  final String conteudoVisivel;
  final String tituloNormalizado;
  final String artistaNormalizado;
  final String textoNormalizado;

  int prioridadePara(String consultaNormalizada) {
    if (tituloNormalizado == consultaNormalizada) return 0;
    if (tituloNormalizado.startsWith(consultaNormalizada)) return 1;
    if (tituloNormalizado.contains(consultaNormalizada)) return 2;
    if (artistaNormalizado.contains(consultaNormalizada)) return 3;
    return 4;
  }

  String? primeiraLinhaCorrespondente(String textoNormalizado) {
    for (final linha in ExtratorConteudoVisivelChordPro.extrairLinhas(
      conteudoVisivel,
    )) {
      if (normalizarPesquisa(linha).contains(textoNormalizado)) {
        return linha;
      }
    }
    return null;
  }
}
