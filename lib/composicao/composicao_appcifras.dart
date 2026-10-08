import '../aplicacao/casos_de_uso/listas_culto.dart';
import '../aplicacao/casos_de_uso/classificacao_musica.dart';
import '../aplicacao/casos_de_uso/musicas.dart';
import '../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../aplicacao/casos_de_uso/tom_execucao.dart';
import '../aplicacao/casos_de_uso/versoes_musicas.dart';
import '../aplicacao/entrada/preparar_entrada_musica.dart';
import '../aplicacao/portas/gerador_id_musica.dart';
import '../aplicacao/portas/gerador_id_item_lista_culto.dart';
import '../aplicacao/portas/gerador_id_lista_culto.dart';
import '../aplicacao/portas/repositorio_tom_execucao.dart';
import '../aplicacao/portas/repositorio_classificacao_musica.dart';
import '../dominio/chordpro/validador_schema_appcifras.dart';
import '../dominio/entidades/versao_musica.dart';
import '../dominio/objetos_de_valor/energia_musica.dart';
import '../dominio/objetos_de_valor/id_musica.dart';
import '../dominio/objetos_de_valor/id_versao_musica.dart';
import '../dominio/objetos_de_valor/tag_musica.dart';
import '../dominio/repositorios/repositorio_musicas.dart';
import '../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../dominio/repositorios/repositorio_listas_culto.dart';
import '../dominio/servicos/parser_documento_chordpro.dart';
import '../infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import '../infraestrutura/arquivos/codificador_chordpro_gerenciado.dart';
import '../infraestrutura/identidade/gerador_id_musica_uuid.dart';
import '../infraestrutura/identidade/gerador_id_item_lista_culto_uuid.dart';
import '../infraestrutura/identidade/gerador_id_lista_culto_uuid.dart';
import '../infraestrutura/persistencia/banco_biblioteca.dart';
import '../infraestrutura/persistencia/repositorio_musicas_local.dart';
import '../infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import '../infraestrutura/persistencia/repositorio_tom_execucao_local.dart';
import '../infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';

class ComposicaoAppCifras {
  ComposicaoAppCifras._({
    required this._banco,
    required RepositorioMusicas repositorio,
    required RepositorioVersoesMusicas repositorioVersoes,
    required RepositorioListasCulto repositorioListasCulto,
    required RepositorioTomExecucao repositorioTomExecucao,
    required RepositorioClassificacaoMusica repositorioClassificacao,
    required GeradorIdMusica geradorId,
    required GeradorIdListaCulto geradorIdListaCulto,
    required GeradorIdItemListaCulto geradorIdItemListaCulto,
    required ParserDocumentoChordPro parserDocumento,
  }) : salvarMusica = SalvarMusica(repositorio),
       obterMusicaPorId = ObterMusicaPorId(repositorio),
       listarMusicas = ListarMusicas(repositorio),
       obterVersaoPrincipalMusica = ObterVersaoPrincipalMusica(
         repositorioVersoes,
       ),
       obterVersaoMusicaPorId = ObterVersaoMusicaPorId(repositorioVersoes),
       excluirMusica = ExcluirMusica(
         repositorio,
         repositorioTomExecucao: repositorioTomExecucao,
         repositorioClassificacao: repositorioClassificacao,
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
       obterClassificacaoMusica = ObterClassificacaoMusica(
         repositorioClassificacao,
       ),
       listarClassificacoesMusicas = ListarClassificacoesMusicas(
         repositorioClassificacao,
       ),
       salvarClassificacaoMusica = SalvarClassificacaoMusica(
         repositorioClassificacao,
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
       criarListaCulto = CriarListaCulto(
         repositorioListasCulto,
         geradorIdListaCulto,
       ),
       listarListasCulto = ListarListasCulto(repositorioListasCulto),
       obterListaCulto = ObterListaCulto(repositorioListasCulto),
       renomearListaCulto = RenomearListaCulto(repositorioListasCulto),
       excluirListaCulto = ExcluirListaCulto(repositorioListasCulto),
       listarItensListaCulto = ListarItensListaCulto(repositorioListasCulto),
       adicionarMusicaAListaCulto = AdicionarMusicaAListaCulto(
         repositorioListasCulto,
         geradorIdItemListaCulto,
         repositorioVersoes: repositorioVersoes,
       ),
       removerItemListaCulto = RemoverItemListaCulto(repositorioListasCulto),
       reordenarItensListaCulto = ReordenarItensListaCulto(
         repositorioListasCulto,
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
  final ObterVersaoPrincipalMusica obterVersaoPrincipalMusica;
  final ObterVersaoMusicaPorId obterVersaoMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final CadastrarMusica cadastrarMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;
  final PrepararEntradaMusica prepararEntradaMusica;
  final ExcluirMusica excluirMusica;
  final ImportarMusica importarMusica;
  final ObterUltimoTomExecucao obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao removerUltimoTomExecucao;
  final ObterClassificacaoMusica obterClassificacaoMusica;
  final ListarClassificacoesMusicas listarClassificacoesMusicas;
  final SalvarClassificacaoMusica salvarClassificacaoMusica;
  final CriarListaCulto criarListaCulto;
  final ListarListasCulto listarListasCulto;
  final ObterListaCulto obterListaCulto;
  final RenomearListaCulto renomearListaCulto;
  final ExcluirListaCulto excluirListaCulto;
  final ListarItensListaCulto listarItensListaCulto;
  final AdicionarMusicaAListaCulto adicionarMusicaAListaCulto;
  final RemoverItemListaCulto removerItemListaCulto;
  final ReordenarItensListaCulto reordenarItensListaCulto;

  factory ComposicaoAppCifras.paraTeste({
    required BancoBiblioteca banco,
    required RepositorioMusicas repositorio,
    RepositorioVersoesMusicas? repositorioVersoes,
    required RepositorioListasCulto repositorioListasCulto,
    required RepositorioTomExecucao repositorioTomExecucao,
    RepositorioClassificacaoMusica? repositorioClassificacao,
    required GeradorIdMusica geradorId,
    required GeradorIdListaCulto geradorIdListaCulto,
    required GeradorIdItemListaCulto geradorIdItemListaCulto,
    required ParserDocumentoChordPro parserDocumento,
  }) => ComposicaoAppCifras._(
    banco: banco,
    repositorio: repositorio,
    repositorioVersoes:
        repositorioVersoes ?? _RepositorioVersoesVazio(repositorio),
    repositorioListasCulto: repositorioListasCulto,
    repositorioTomExecucao: repositorioTomExecucao,
    repositorioClassificacao:
        repositorioClassificacao ?? _RepositorioClassificacaoVazio(),
    geradorId: geradorId,
    geradorIdListaCulto: geradorIdListaCulto,
    geradorIdItemListaCulto: geradorIdItemListaCulto,
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
      final repositorioClassificacao = RepositorioClassificacaoMusicaLocal(
        banco,
      );
      final repositorioListasCulto = RepositorioListasCultoLocal(banco);

      return ComposicaoAppCifras._(
        banco: banco,
        repositorio: repositorio,
        repositorioVersoes: repositorio,
        repositorioListasCulto: repositorioListasCulto,
        repositorioTomExecucao: repositorioTomExecucao,
        repositorioClassificacao: repositorioClassificacao,
        geradorId: GeradorIdMusicaUuid(),
        geradorIdListaCulto: GeradorIdListaCultoUuid(),
        geradorIdItemListaCulto: GeradorIdItemListaCultoUuid(),
        parserDocumento: parserDocumento,
      );
    } catch (_) {
      await banco.close();
      rethrow;
    }
  }

  Future<void> encerrar() => _encerramento ??= _banco.close();
}

class _RepositorioVersoesVazio implements RepositorioVersoesMusicas {
  const _RepositorioVersoesVazio(this._repositorioMusicas);

  final RepositorioMusicas _repositorioMusicas;

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async {
    final musica = await _repositorioMusicas.obterPorId(IdMusica(id.valor));
    return musica?.versaoPrincipal;
  }

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async =>
      (await _repositorioMusicas.obterPorId(idMusica))?.versaoPrincipal;

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async {
    final versao = await obterPrincipalPorMusica(idMusica);
    return versao == null ? const [] : [versao];
  }
}

class _RepositorioClassificacaoVazio implements RepositorioClassificacaoMusica {
  @override
  Future<ClassificacaoMusica> obter(IdMusica idMusica) async =>
      const ClassificacaoMusica();

  @override
  Future<Map<IdMusica, ClassificacaoMusica>> listar() async => const {};

  @override
  Future<void> definirEnergia(
    IdMusica idMusica,
    EnergiaMusica? energia,
  ) async {}

  @override
  Future<void> substituirTags(
    IdMusica idMusica,
    Iterable<TagMusica> tags,
  ) async {}

  @override
  Future<void> removerPorMusica(IdMusica idMusica) async {}
}
