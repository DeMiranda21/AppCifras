import '../aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import '../aplicacao/casos_de_uso/classificacao_musica.dart';
import '../aplicacao/casos_de_uso/editar_versao_musica.dart';
import '../aplicacao/casos_de_uso/listas_culto.dart';
import '../aplicacao/casos_de_uso/musicas.dart';
import '../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../aplicacao/casos_de_uso/tom_execucao.dart';
import '../aplicacao/casos_de_uso/versoes_musicas.dart';
import '../aplicacao/biblioteca_oficial/preparar_atualizacao_biblioteca_oficial.dart';
import '../aplicacao/biblioteca_oficial/atualizar_biblioteca_oficial.dart';
import '../aplicacao/biblioteca_oficial/estado_biblioteca_oficial.dart';
import '../aplicacao/biblioteca/item_biblioteca.dart';
import '../aplicacao/entrada/preparar_entrada_musica.dart';
import '../aplicacao/portas/fonte_biblioteca_oficial.dart';
import '../aplicacao/portas/consulta_detalhe_lista_culto.dart';
import '../aplicacao/portas/aplicador_grupo_sincronizacao.dart';
import '../aplicacao/portas/gerador_id_item_lista_culto.dart';
import '../aplicacao/portas/gerador_id_lista_culto.dart';
import '../aplicacao/portas/gerador_id_musica.dart';
import '../aplicacao/portas/gerador_id_versao_musica.dart';
import '../aplicacao/portas/repositorio_classificacao_musica.dart';
import '../aplicacao/portas/repositorio_sincronizacao.dart';
import '../aplicacao/portas/repositorio_tom_execucao.dart';
import '../aplicacao/sincronizacao/aplicar_grupo_sincronizacao.dart';
import '../dominio/chordpro/validador_schema_appcifras.dart';
import '../dominio/entidades/versao_musica.dart';
import '../dominio/entidades/origem_sincronizada_versao.dart';
import '../dominio/objetos_de_valor/energia_musica.dart';
import '../dominio/objetos_de_valor/id_musica.dart';
import '../dominio/objetos_de_valor/id_versao_musica.dart';
import '../dominio/objetos_de_valor/tag_musica.dart';
import '../dominio/repositorios/repositorio_listas_culto.dart';
import '../dominio/repositorios/repositorio_musicas.dart';
import '../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../dominio/servicos/parser_documento_chordpro.dart';
import '../infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import '../infraestrutura/arquivos/codificador_chordpro_gerenciado.dart';
import '../infraestrutura/identidade/gerador_id_item_lista_culto_uuid.dart';
import '../infraestrutura/identidade/gerador_id_lista_culto_uuid.dart';
import '../infraestrutura/identidade/gerador_id_musica_uuid.dart';
import '../infraestrutura/identidade/gerador_id_versao_musica_uuid.dart';
import '../infraestrutura/http/fonte_biblioteca_oficial_http.dart';
import '../infraestrutura/persistencia/banco_biblioteca.dart';
import '../infraestrutura/persistencia/consulta_detalhe_lista_culto_local.dart';
import '../infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';
import '../infraestrutura/persistencia/repositorio_listas_culto_local.dart';
import '../infraestrutura/persistencia/repositorio_musicas_local.dart';
import '../infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import '../infraestrutura/persistencia/repositorio_tom_execucao_local.dart';

class ComposicaoAppCifras {
  ComposicaoAppCifras._({
    required this._banco,
    required RepositorioMusicas repositorio,
    required RepositorioConsultaBiblioteca repositorioConsultaBiblioteca,
    required RepositorioVersoesMusicas repositorioVersoes,
    required RepositorioListasCulto repositorioListasCulto,
    required ConsultaDetalheListaCulto consultaDetalheListaCulto,
    required RepositorioTomExecucao repositorioTomExecucao,
    required RepositorioClassificacaoMusica repositorioClassificacao,
    required RepositorioOrigensSincronizadas repositorioOrigens,
    required RepositorioEstadoBibliotecaOficial repositorioEstadoOficial,
    required AplicadorGrupoSincronizacao aplicadorSincronizacao,
    required GeradorIdMusica geradorId,
    required GeradorIdVersaoMusica geradorIdVersao,
    required GeradorIdListaCulto geradorIdListaCulto,
    required GeradorIdItemListaCulto geradorIdItemListaCulto,
    required ParserDocumentoChordPro parserDocumento,
    required FonteBibliotecaOficial fonteBibliotecaOficial,
  }) : _repositorioMusicasEdicao = repositorio,
       _repositorioVersoesEdicao = repositorioVersoes,
       _repositorioTomEdicao = repositorioTomExecucao,
       repositorioOrigensSincronizadas = repositorioOrigens,
       repositorioEstadoBibliotecaOficial = repositorioEstadoOficial,
       _fonteBibliotecaOficial = fonteBibliotecaOficial,
       prepararAtualizacaoBibliotecaOficial =
           PrepararAtualizacaoBibliotecaOficial(
             fonteBibliotecaOficial,
             repositorioOrigens,
           ),
       atualizarBibliotecaOficial = AtualizarBibliotecaOficial(
         preparar: PrepararAtualizacaoBibliotecaOficial(
           fonteBibliotecaOficial,
           repositorioOrigens,
         ),
         aplicarGrupo: AplicarGrupoSincronizacao(
           repositorioOrigens: repositorioOrigens,
           repositorioMusicas: repositorio,
           repositorioVersoes: repositorioVersoes,
           aplicador: aplicadorSincronizacao,
         ),
         repositorioOrigens: repositorioOrigens,
         repositorioEstado: repositorioEstadoOficial,
       ),
       salvarMusica = SalvarMusica(repositorio),
       obterMusicaPorId = ObterMusicaPorId(repositorio),
       listarMusicas = ListarMusicas(repositorio),
       listarItensBiblioteca = ListarItensBiblioteca(
         repositorioConsultaBiblioteca,
       ),
       obterVersaoPrincipalMusica = ObterVersaoPrincipalMusica(
         repositorioVersoes,
       ),
       obterVersaoMusicaPorId = ObterVersaoMusicaPorId(repositorioVersoes),
       listarVersoesMusica = ListarVersoesMusica(repositorioVersoes),
       criarVersaoMusica = CriarVersaoMusica(
         repositorio: repositorioVersoes,
         geradorId: geradorIdVersao,
       ),
       avaliarPoliticaEdicaoVersao = AvaliarPoliticaEdicaoVersao(
         repositorioVersoes,
         repositorioOrigens: repositorioOrigens,
       ),
       renomearVersaoMusica = RenomearVersaoMusica(repositorioVersoes),
       definirVersaoPrincipal = DefinirVersaoPrincipal(repositorioVersoes),
       arquivarVersaoMusica = ArquivarVersaoMusica(repositorioVersoes),
       restaurarVersaoMusica = RestaurarVersaoMusica(repositorioVersoes),
       excluirVersaoMusica = ExcluirVersaoMusica(repositorioVersoes),
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
       carregarDetalheListaCulto = CarregarDetalheListaCulto(
         consultaDetalheListaCulto,
       ),
       adicionarMusicaAListaCulto = AdicionarMusicaAListaCulto(
         repositorioListasCulto,
         geradorIdItemListaCulto,
         repositorioVersoes: repositorioVersoes,
       ),
       removerItemListaCulto = RemoverItemListaCulto(repositorioListasCulto),
       trocarVersaoItemListaCulto = TrocarVersaoItemListaCulto(
         repositorioListasCulto,
         repositorioVersoes,
       ),
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
  final ListarItensBiblioteca listarItensBiblioteca;
  final ObterVersaoPrincipalMusica obterVersaoPrincipalMusica;
  final ObterVersaoMusicaPorId obterVersaoMusicaPorId;
  final ListarVersoesMusica listarVersoesMusica;
  final CriarVersaoMusica criarVersaoMusica;
  final AvaliarPoliticaEdicaoVersao avaliarPoliticaEdicaoVersao;
  final RepositorioOrigensSincronizadas repositorioOrigensSincronizadas;
  final RepositorioEstadoBibliotecaOficial repositorioEstadoBibliotecaOficial;
  final FonteBibliotecaOficial _fonteBibliotecaOficial;
  final PrepararAtualizacaoBibliotecaOficial
  prepararAtualizacaoBibliotecaOficial;
  final AtualizarBibliotecaOficial atualizarBibliotecaOficial;
  final RenomearVersaoMusica renomearVersaoMusica;
  final DefinirVersaoPrincipal definirVersaoPrincipal;
  final ArquivarVersaoMusica arquivarVersaoMusica;
  final RestaurarVersaoMusica restaurarVersaoMusica;
  final ExcluirVersaoMusica excluirVersaoMusica;
  EditarVersaoMusica get editarVersaoMusica => EditarVersaoMusica(
    repositorio: _repositorioVersoesEdicao,
    repositorioMusicas: _repositorioMusicasEdicao,
    criarVersao: criarVersaoMusica,
    avaliarPolitica: avaliarPoliticaEdicaoVersao,
    repositorioTom: _repositorioTomEdicao,
    repositorioOrigens: repositorioOrigensSincronizadas,
  );
  final RepositorioMusicas _repositorioMusicasEdicao;
  final RepositorioVersoesMusicas _repositorioVersoesEdicao;
  final RepositorioTomExecucao _repositorioTomEdicao;
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
  final CarregarDetalheListaCulto carregarDetalheListaCulto;
  final AdicionarMusicaAListaCulto adicionarMusicaAListaCulto;
  final RemoverItemListaCulto removerItemListaCulto;
  final TrocarVersaoItemListaCulto trocarVersaoItemListaCulto;
  final ReordenarItensListaCulto reordenarItensListaCulto;

  factory ComposicaoAppCifras.paraTeste({
    required BancoBiblioteca banco,
    required RepositorioMusicas repositorio,
    RepositorioConsultaBiblioteca? repositorioConsultaBiblioteca,
    RepositorioVersoesMusicas? repositorioVersoes,
    required RepositorioListasCulto repositorioListasCulto,
    ConsultaDetalheListaCulto? consultaDetalheListaCulto,
    required RepositorioTomExecucao repositorioTomExecucao,
    RepositorioClassificacaoMusica? repositorioClassificacao,
    RepositorioOrigensSincronizadas? repositorioOrigens,
    RepositorioEstadoBibliotecaOficial? repositorioEstadoOficial,
    AplicadorGrupoSincronizacao? aplicadorSincronizacao,
    required GeradorIdMusica geradorId,
    GeradorIdVersaoMusica? geradorIdVersao,
    required GeradorIdListaCulto geradorIdListaCulto,
    required GeradorIdItemListaCulto geradorIdItemListaCulto,
    required ParserDocumentoChordPro parserDocumento,
    FonteBibliotecaOficial? fonteBibliotecaOficial,
  }) => ComposicaoAppCifras._(
    banco: banco,
    repositorio: repositorio,
    repositorioConsultaBiblioteca:
        repositorioConsultaBiblioteca ??
        RepositorioConsultaBibliotecaLegada(repositorio.listar),
    repositorioVersoes:
        repositorioVersoes ?? _RepositorioVersoesVazio(repositorio),
    repositorioListasCulto: repositorioListasCulto,
    consultaDetalheListaCulto:
        consultaDetalheListaCulto ?? const _ConsultaDetalheListaCultoVazia(),
    repositorioTomExecucao: repositorioTomExecucao,
    repositorioClassificacao:
        repositorioClassificacao ?? _RepositorioClassificacaoVazio(),
    repositorioOrigens:
        repositorioOrigens ?? const _RepositorioSincronizacaoVazio(),
    repositorioEstadoOficial:
        repositorioEstadoOficial ?? const _RepositorioSincronizacaoVazio(),
    aplicadorSincronizacao:
        aplicadorSincronizacao ?? const _AplicadorSincronizacaoIndisponivel(),
    geradorId: geradorId,
    geradorIdVersao: geradorIdVersao ?? _GeradorIdVersaoLegado(),
    geradorIdListaCulto: geradorIdListaCulto,
    geradorIdItemListaCulto: geradorIdItemListaCulto,
    parserDocumento: parserDocumento,
    fonteBibliotecaOficial:
        fonteBibliotecaOficial ?? const FonteBibliotecaOficialIndisponivel(),
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
      final repositorioSincronizacao = RepositorioSincronizacaoLocal(banco);
      final consultaDetalheListaCulto = ConsultaDetalheListaCultoLocal(
        repositorioListas: repositorioListasCulto,
        banco: banco,
        armazenamentoArquivos: armazenamentoArquivos,
        parserDocumento: parserDocumento,
        validadorSchema: validadorSchema,
      );
      final fonteBibliotecaOficial = baseUrlBibliotecaOficialConfigurada.isEmpty
          ? const FonteBibliotecaOficialIndisponivel()
          : FonteBibliotecaOficialHttp(
              baseUrl: baseUrlBibliotecaOficialConfigurada,
            );

      return ComposicaoAppCifras._(
        banco: banco,
        repositorio: repositorio,
        repositorioConsultaBiblioteca: repositorio,
        repositorioVersoes: repositorio,
        repositorioListasCulto: repositorioListasCulto,
        consultaDetalheListaCulto: consultaDetalheListaCulto,
        repositorioTomExecucao: repositorioTomExecucao,
        repositorioClassificacao: repositorioClassificacao,
        repositorioOrigens: repositorioSincronizacao,
        repositorioEstadoOficial: repositorioSincronizacao,
        aplicadorSincronizacao: repositorio,
        geradorId: GeradorIdMusicaUuid(),
        geradorIdVersao: GeradorIdVersaoMusicaUuid(),
        geradorIdListaCulto: GeradorIdListaCultoUuid(),
        geradorIdItemListaCulto: GeradorIdItemListaCultoUuid(),
        parserDocumento: parserDocumento,
        fonteBibliotecaOficial: fonteBibliotecaOficial,
      );
    } catch (_) {
      await banco.close();
      rethrow;
    }
  }

  Future<void> encerrar() => _encerramento ??= _encerrarRecursos();

  Future<void> _encerrarRecursos() async {
    _fonteBibliotecaOficial.fechar();
    await _banco.close();
  }
}

class _ConsultaDetalheListaCultoVazia implements ConsultaDetalheListaCulto {
  const _ConsultaDetalheListaCultoVazia();

  @override
  Future<List<ItemDetalheListaCulto>> carregar(idLista) async => const [];
}

class _RepositorioVersoesVazio implements RepositorioVersoesMusicas {
  const _RepositorioVersoesVazio(this._repositorioMusicas);

  final RepositorioMusicas _repositorioMusicas;

  @override
  Future<void> atualizarConteudoVersao(VersaoMusica versao) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');

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

  @override
  Future<void> salvarVersao(VersaoMusica versao) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');

  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) async => false;

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');
  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');
  @override
  Future<void> arquivar(IdVersaoMusica id) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');
  @override
  Future<void> restaurar(IdVersaoMusica id) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');
  @override
  Future<void> excluirVersao(IdVersaoMusica id) =>
      throw UnsupportedError('Versões não estão disponíveis nesta composição.');
}

class _GeradorIdVersaoLegado implements GeradorIdVersaoMusica {
  @override
  IdVersaoMusica gerar() =>
      throw UnsupportedError('Geração de versões não está disponível.');
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

class _RepositorioSincronizacaoVazio
    implements
        RepositorioOrigensSincronizadas,
        RepositorioEstadoBibliotecaOficial {
  const _RepositorioSincronizacaoVazio();

  @override
  Future<OrigemSincronizadaVersao?> obterPorVersao(IdVersaoMusica id) async =>
      null;

  @override
  Future<List<OrigemSincronizadaVersao>> listar() async => const [];

  @override
  Future<void> salvarOrigem(OrigemSincronizadaVersao origem) async {}

  @override
  Future<void> marcarAusente(IdVersaoMusica id) async {}

  @override
  Future<void> marcarPresente(
    IdVersaoMusica id, {
    required String localizadorExterno,
    required String hashSha256,
  }) async {}

  @override
  Future<void> remover(IdVersaoMusica id) async {}

  @override
  Future<EstadoBibliotecaOficial?> obterEstadoBibliotecaOficial() async => null;

  @override
  Future<void> salvarEstadoBibliotecaOficial(
    EstadoBibliotecaOficial estado,
  ) async {}
}

class _AplicadorSincronizacaoIndisponivel
    implements AplicadorGrupoSincronizacao {
  const _AplicadorSincronizacaoIndisponivel();

  @override
  Future<void> aplicar(PlanoAplicacaoGrupoSincronizacao plano) =>
      throw UnsupportedError('Sincronização não disponível nesta composição.');
}
