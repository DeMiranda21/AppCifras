import '../chordpro/documento_chordpro.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/id_versao_musica.dart';
import '../objetos_de_valor/tom.dart';
import 'versao_musica.dart';

class Musica {
  Musica({
    required this.id,
    String? titulo,
    String? artista,
    VersaoMusica? versaoPrincipal,
    DocumentoChordPro? documento,
  }) : versaoPrincipal =
           versaoPrincipal ??
           _criarVersaoPrincipalLegada(id: id, documento: documento),
       titulo = _validarMetadado(titulo ?? _obterTitulo(documento), 'título'),
       artista = _validarMetadado(
         artista ?? _obterArtista(documento),
         'artista',
       ) {
    if (this.versaoPrincipal.idMusica != id ||
        !this.versaoPrincipal.principal) {
      throw ArgumentError(
        'A música exige uma versão principal pertencente à própria música.',
      );
    }
  }

  final IdMusica id;
  final VersaoMusica versaoPrincipal;
  final String titulo;
  final String artista;

  /// Compatibilidade temporária para os fluxos que leem a versão principal.
  DocumentoChordPro get documento => versaoPrincipal.documento;

  /// Compatibilidade temporária para os fluxos que leem a versão principal.
  Tom get tomOriginal => versaoPrincipal.tomOriginal;

  static VersaoMusica _criarVersaoPrincipalLegada({
    required IdMusica id,
    required DocumentoChordPro? documento,
  }) {
    if (documento == null) {
      throw ArgumentError('A música exige uma versão principal.');
    }
    return VersaoMusica(
      id: IdVersaoMusica(id.valor),
      idMusica: id,
      nome: 'Principal',
      documento: documento,
      principal: true,
      arquivada: false,
    );
  }

  static String _obterTitulo(DocumentoChordPro? documento) {
    if (documento == null) {
      throw ArgumentError('A música exige título válido.');
    }
    final diretivas = documento.elementos.whereType<DiretivaTituloChordPro>();
    if (diretivas.length != 1 || diretivas.single.titulo.isEmpty) {
      throw ArgumentError('A música exige exatamente um título válido.');
    }
    return diretivas.single.titulo;
  }

  static String _obterArtista(DocumentoChordPro? documento) {
    if (documento == null) {
      throw ArgumentError('A música exige artista válido.');
    }
    final diretivas = documento.elementos.whereType<DiretivaArtistaChordPro>();
    if (diretivas.length != 1 || diretivas.single.artista.isEmpty) {
      throw ArgumentError('A música exige exatamente um artista válido.');
    }
    return diretivas.single.artista;
  }

  static String _validarMetadado(String valor, String nome) {
    final normalizado = valor.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError('A música exige $nome válido.');
    }
    return normalizado;
  }

  @override
  bool operator ==(Object other) => other is Musica && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
