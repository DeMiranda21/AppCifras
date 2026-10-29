import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../pesquisa/normalizacao_pesquisa.dart';

class ItemBiblioteca {
  const ItemBiblioteca({
    required this.idMusica,
    required this.idVersaoPrincipal,
    required this.titulo,
    required this.artista,
    required this.conteudoVisivel,
    required this.tituloNormalizado,
    required this.textoNormalizado,
  });

  final IdMusica idMusica;
  final IdVersaoMusica idVersaoPrincipal;
  final String titulo;
  final String artista;
  final String conteudoVisivel;
  final String tituloNormalizado;
  final String textoNormalizado;
}

abstract interface class RepositorioConsultaBiblioteca {
  Future<List<ItemBiblioteca>> listarItensBiblioteca();
}

class ListarItensBiblioteca {
  const ListarItensBiblioteca(this._repositorio);

  final RepositorioConsultaBiblioteca _repositorio;

  Future<List<ItemBiblioteca>> executar() =>
      _repositorio.listarItensBiblioteca();
}

class RepositorioConsultaBibliotecaLegada
    implements RepositorioConsultaBiblioteca {
  const RepositorioConsultaBibliotecaLegada(this._listarMusicas);

  final Future<List<Musica>> Function() _listarMusicas;

  @override
  Future<List<ItemBiblioteca>> listarItensBiblioteca() async => [
    for (final musica in await _listarMusicas()) _criarItemLegado(musica),
  ];

  ItemBiblioteca _criarItemLegado(Musica musica) {
    final conteudoVisivel = ExtratorConteudoVisivelChordPro.extrair(
      musica.documento,
    );
    return ItemBiblioteca(
      idMusica: musica.id,
      idVersaoPrincipal: musica.versaoPrincipal.id,
      titulo: musica.titulo,
      artista: musica.artista,
      conteudoVisivel: conteudoVisivel,
      tituloNormalizado: normalizarPesquisa(musica.titulo),
      textoNormalizado: normalizarPesquisa(
        '${musica.titulo}\n${musica.artista}\n$conteudoVisivel',
      ),
    );
  }
}

class ExtratorConteudoVisivelChordPro {
  const ExtratorConteudoVisivelChordPro._();

  static String extrair(DocumentoChordPro documento) =>
      documento.elementos.map(textoVisivel).join('\n');

  static List<String> extrairLinhas(String conteudoVisivel) =>
      conteudoVisivel.split('\n').where((linha) => linha.isNotEmpty).toList();

  static String textoVisivel(ElementoDocumentoChordPro elemento) =>
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
