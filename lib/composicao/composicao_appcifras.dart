import '../aplicacao/casos_de_uso/musicas.dart';
import '../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../aplicacao/casos_de_uso/tom_execucao.dart';
import '../aplicacao/entrada/preparar_entrada_musica.dart';
import '../aplicacao/portas/gerador_id_musica.dart';
import '../aplicacao/portas/repositorio_tom_execucao.dart';
import '../dominio/chordpro/validador_schema_appcifras.dart';
import '../dominio/repositorios/repositorio_musicas.dart';
import '../dominio/servicos/parser_documento_chordpro.dart';
import '../infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import '../infraestrutura/arquivos/codificador_chordpro_gerenciado.dart';
import '../infraestrutura/identidade/gerador_id_musica_uuid.dart';
import '../infraestrutura/persistencia/banco_biblioteca.dart';
import '../infraestrutura/persistencia/repositorio_musicas_local.dart';
import '../infraestrutura/persistencia/repositorio_tom_execucao_local.dart';

class ComposicaoAppCifras {
  ComposicaoAppCifras._({
    required this._banco,
    required RepositorioMusicas repositorio,
    required RepositorioTomExecucao repositorioTomExecucao,
    required GeradorIdMusica geradorId,
    required ParserDocumentoChordPro parserDocumento,
  }) : salvarMusica = SalvarMusica(repositorio),
       obterMusicaPorId = ObterMusicaPorId(repositorio),
       listarMusicas = ListarMusicas(repositorio),
       excluirMusica = ExcluirMusica(
         repositorio,
         repositorioTomExecucao: repositorioTomExecucao,
       ),
       atualizarMusica = AtualizarMusica(
         repositorio: repositorio,
         parserDocumento: parserDocumento,
         repositorioTomExecucao: repositorioTomExecucao,
       ),
       obterUltimoTomExecucao = ObterUltimoTomExecucao(repositorioTomExecucao),
       salvarUltimoTomExecucao = SalvarUltimoTomExecucao(
         repositorioTomExecucao,
       ),
       removerUltimoTomExecucao = RemoverUltimoTomExecucao(
         repositorioTomExecucao,
       ),
       cadastrarMusica = CadastrarMusica(
         repositorio: repositorio,
         parserDocumento: parserDocumento,
         geradorId: geradorId,
       ),
       salvarRascunhoChordPro = SalvarRascunhoChordPro(
         repositorio: repositorio,
         parserDocumento: parserDocumento,
         geradorId: geradorId,
       ),
       prepararEntradaMusica = PrepararEntradaMusica(
         parserDocumento: parserDocumento,
       ),
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
  final AtualizarMusica atualizarMusica;
  final CadastrarMusica cadastrarMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;
  final PrepararEntradaMusica prepararEntradaMusica;
  final ExcluirMusica excluirMusica;
  final ImportarMusica importarMusica;
  final ObterUltimoTomExecucao obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao removerUltimoTomExecucao;

  factory ComposicaoAppCifras.paraTeste({
    required BancoBiblioteca banco,
    required RepositorioMusicas repositorio,
    required RepositorioTomExecucao repositorioTomExecucao,
    required GeradorIdMusica geradorId,
    required ParserDocumentoChordPro parserDocumento,
  }) => ComposicaoAppCifras._(
    banco: banco,
    repositorio: repositorio,
    repositorioTomExecucao: repositorioTomExecucao,
    geradorId: geradorId,
    parserDocumento: parserDocumento,
  );

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
      final repositorioTomExecucao = RepositorioTomExecucaoLocal(banco);

      return ComposicaoAppCifras._(
        banco: banco,
        repositorio: repositorio,
        repositorioTomExecucao: repositorioTomExecucao,
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
