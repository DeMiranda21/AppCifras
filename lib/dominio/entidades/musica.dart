import '../chordpro/documento_chordpro.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/tom.dart';

class Musica {
  Musica({required this.id, required this.documento})
    : titulo = _obterTitulo(documento),
      artista = _obterArtista(documento),
      tomOriginal = _obterTomOriginal(documento) {
    _validarIdentidadeDeclarada(documento, id);
  }

  final IdMusica id;
  final DocumentoChordPro documento;
  final String titulo;
  final String artista;
  final Tom tomOriginal;

  static String _obterTitulo(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaTituloChordPro>();
    if (diretivas.length != 1 || diretivas.single.titulo.isEmpty) {
      throw ArgumentError('A música exige exatamente um título válido.');
    }
    return diretivas.single.titulo;
  }

  static String _obterArtista(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaArtistaChordPro>();
    if (diretivas.length != 1 || diretivas.single.artista.isEmpty) {
      throw ArgumentError('A música exige exatamente um artista válido.');
    }
    return diretivas.single.artista;
  }

  static Tom _obterTomOriginal(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaTomChordPro>();
    if (diretivas.length != 1 || diretivas.single.tom == null) {
      throw ArgumentError('A música exige exatamente um tom original válido.');
    }
    return diretivas.single.tom!;
  }

  static void _validarIdentidadeDeclarada(
    DocumentoChordPro documento,
    IdMusica id,
  ) {
    final diretivas = documento.elementos.whereType<DiretivaIdAppCifras>();
    if (diretivas.isEmpty) {
      return;
    }
    if (diretivas.length != 1 || diretivas.single.id == null) {
      throw ArgumentError(
        'A diretiva appcifras_id deve ocorrer uma única vez e ser válida.',
      );
    }
    if (IdMusica(diretivas.single.id!) != id) {
      throw ArgumentError(
        'A diretiva appcifras_id deve corresponder ao ID da música.',
      );
    }
  }

  @override
  bool operator ==(Object other) => other is Musica && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
