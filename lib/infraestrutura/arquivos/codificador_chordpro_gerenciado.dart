import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/musica.dart';

class CodificadorChordProGerenciado {
  const CodificadorChordProGerenciado({
    this._validadorSchema = const ValidadorSchemaAppCifras(),
  });

  final ValidadorSchemaAppCifras _validadorSchema;

  String codificar(Musica musica) {
    final documento = musica.documento;
    _validadorSchema.validarParaIncorporacao(documento);

    final cabecalho = <String>[];
    if (documento.elementos.whereType<DiretivaSchemaAppCifras>().isEmpty) {
      cabecalho.add('{appcifras_schema: 1}');
    }
    if (documento.elementos.whereType<DiretivaIdAppCifras>().isEmpty) {
      cabecalho.add('{appcifras_id: ${musica.id.valor}}');
    }

    if (cabecalho.isEmpty) {
      return documento.conteudoOriginal;
    }
    return '${cabecalho.join('\n')}\n${documento.conteudoOriginal}';
  }
}
