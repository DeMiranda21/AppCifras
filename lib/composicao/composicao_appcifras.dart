import '../aplicacao/casos_de_uso/musicas.dart';
import '../aplicacao/portas/gerador_id_musica.dart';
import '../dominio/chordpro/validador_schema_appcifras.dart';
import '../dominio/repositorios/repositorio_musicas.dart';
import '../dominio/servicos/parser_documento_chordpro.dart';
import '../infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import '../infraestrutura/arquivos/codificador_chordpro_gerenciado.dart';
import '../infraestrutura/identidade/gerador_id_musica_uuid.dart';
import '../infraestrutura/persistencia/banco_biblioteca.dart';
import '../infraestrutura/persistencia/repositorio_musicas_local.dart';

class ComposicaoAppCifras {
  ComposicaoAppCifras._({
    required this._banco,
    required RepositorioMusicas repositorio,
    required GeradorIdMusica geradorId,
    required ParserDocumentoChordPro parserDocumento,
  }) : salvarMusica = SalvarMusica(repositorio),
       obterMusicaPorId = ObterMusicaPorId(repositorio),
       listarMusicas = ListarMusicas(repositorio),
       cadastrarMusica = CadastrarMusica(
         repositorio: repositorio,
         parserDocumento: parserDocumento,
         geradorId: geradorId,
       ),
       excluirMusica = ExcluirMusica(repositorio),
       importarMusica = ImportarMusica(
         repositorio: repositorio,
         parserDocumento: parserDocumento,
         geradorId: geradorId,
       );

  final BancoBiblioteca _banco;
  Future<void>? _encerramento;

  final SalvarMusica salvarMusica;
  final ObterMusicaPorId obterMusicaPorId;
  final ListarMusicas listarMusicas;
  final CadastrarMusica cadastrarMusica;
  final ExcluirMusica excluirMusica;
  final ImportarMusica importarMusica;

  static Future<ComposicaoAppCifras> inicializar() async {
    final banco = BancoBiblioteca.local();
    try {
      await banco.inicializar();
      final armazenamentoArquivos =
          await const FabricaArmazenamentoArquivosChordPro().criar();
      final parserDocumento = ParserDocumentoChordPro();
      const validadorSchema = ValidadorSchemaAppCifras();
      final repositorio = RepositorioMusicasLocal(
        banco: banco,
        armazenamentoArquivos: armazenamentoArquivos,
        parserDocumento: parserDocumento,
        codificador: const CodificadorChordProGerenciado(
          validadorSchema: validadorSchema,
        ),
        validadorSchema: validadorSchema,
      );

      return ComposicaoAppCifras._(
        banco: banco,
        repositorio: repositorio,
        geradorId: GeradorIdMusicaUuid(),
        parserDocumento: parserDocumento,
      );
    } catch (_) {
      await banco.close();
      rethrow;
    }
  }

  Future<void> encerrar() => _encerramento ??= _banco.close();
}
