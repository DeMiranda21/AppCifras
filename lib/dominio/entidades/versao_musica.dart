import '../chordpro/documento_chordpro.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/id_versao_musica.dart';
import '../objetos_de_valor/tom.dart';

class VersaoMusica {
  VersaoMusica({
    required this.id,
    required this.idMusica,
    required String nome,
    required this.documento,
    required this.principal,
    required this.arquivada,
  }) : nome = _validarNome(nome),
       tomOriginal = _obterTomOriginal(documento) {
    if (principal && arquivada) {
      throw ArgumentError('A versão principal precisa permanecer ativa.');
    }
    _validarIdentidadeDeclarada(documento, idMusica);
  }

  final IdVersaoMusica id;
  final IdMusica idMusica;
  final String nome;
  final DocumentoChordPro documento;
  final Tom tomOriginal;
  final bool principal;
  final bool arquivada;

  static String _validarNome(String nome) {
    final normalizado = nome.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError.value(
        nome,
        'nome',
        'O nome da versão é obrigatório.',
      );
    }
    return normalizado;
  }

  static Tom _obterTomOriginal(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaTomChordPro>();
    if (diretivas.length != 1 || diretivas.single.tom == null) {
      throw ArgumentError('A versão exige exatamente um tom original válido.');
    }
    return diretivas.single.tom!;
  }

  static void _validarIdentidadeDeclarada(
    DocumentoChordPro documento,
    IdMusica idMusica,
  ) {
    final diretivas = documento.elementos.whereType<DiretivaIdAppCifras>();
    if (diretivas.isEmpty) return;
    if (diretivas.length != 1 || diretivas.single.id == null) {
      throw ArgumentError(
        'A diretiva appcifras_id deve ocorrer uma única vez e ser válida.',
      );
    }
    if (IdMusica(diretivas.single.id!) != idMusica) {
      throw ArgumentError(
        'A diretiva appcifras_id deve corresponder ao ID da música.',
      );
    }
  }

  @override
  bool operator ==(Object other) => other is VersaoMusica && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
