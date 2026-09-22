import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/id_musica_ja_existente.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../entrada/rascunho_documento_chordpro.dart';
import '../portas/gerador_id_musica.dart';

class SalvarRascunhoChordPro {
  const SalvarRascunhoChordPro({
    required this.repositorio,
    required this.parserDocumento,
    required this.geradorId,
    this.validadorSchema = const ValidadorSchemaAppCifras(),
  });

  final RepositorioMusicas repositorio;
  final ParserDocumentoChordPro parserDocumento;
  final GeradorIdMusica geradorId;
  final ValidadorSchemaAppCifras validadorSchema;

  Future<Musica> executar(RascunhoDocumentoChordPro rascunho) async {
    final documento = parserDocumento.interpretar(
      rascunho.produzirConteudoFinal(),
    );
    validadorSchema.validarParaIncorporacao(documento);
    final id = _obterId(documento);
    if (await repositorio.obterPorId(id) != null) {
      throw IdMusicaJaExistente(id);
    }
    final musica = Musica(id: id, documento: documento);
    await repositorio.salvar(musica);
    return musica;
  }

  IdMusica _obterId(DocumentoChordPro documento) {
    final diretivas = documento.elementos.whereType<DiretivaIdAppCifras>();
    if (diretivas.isEmpty) {
      return geradorId.gerar();
    }
    if (diretivas.length != 1 || diretivas.single.id == null) {
      throw ArgumentError(
        'A diretiva appcifras_id deve ocorrer uma única vez e ser válida.',
      );
    }
    return IdMusica(diretivas.single.id!);
  }
}
