import 'documento_chordpro.dart';

class SchemaAppCifrasNaoSuportado implements Exception {
  const SchemaAppCifrasNaoSuportado();
}

class ValidadorSchemaAppCifras {
  const ValidadorSchemaAppCifras();

  static const versaoSuportada = 1;

  void validarParaIncorporacao(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaSchemaAppCifras>();
    if (diretivas.isEmpty) {
      return;
    }
    if (diretivas.length != 1 || diretivas.single.versao != versaoSuportada) {
      throw const SchemaAppCifrasNaoSuportado();
    }
  }
}
