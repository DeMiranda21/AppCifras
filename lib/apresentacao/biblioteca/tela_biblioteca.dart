import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/classificacao_musica.dart';
import '../../aplicacao/casos_de_uso/editar_versao_musica.dart';
import '../../aplicacao/casos_de_uso/listas_culto.dart';
import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../aplicacao/casos_de_uso/versoes_musicas.dart';
import '../../aplicacao/biblioteca_oficial/atualizar_biblioteca_oficial.dart';
import '../../aplicacao/biblioteca_oficial/estado_biblioteca_oficial.dart';
import '../../aplicacao/biblioteca/item_biblioteca.dart';
import '../../aplicacao/diagnostico/medicao_desempenho_biblioteca.dart';
import '../../aplicacao/diagnostico/medicao_desempenho_visualizacao.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../aplicacao/pesquisa/servico_pesquisa_musicas.dart';
import '../../aplicacao/portas/obter_informacoes_app.dart';
import '../../aplicacao/portas/repositorio_classificacao_musica.dart';
import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import '../entrada/tela_entrada_musica.dart';
import '../listas_culto/tela_listas_culto.dart';
import '../musica/tela_visualizacao_musica.dart';

class TelaBiblioteca extends StatefulWidget {
  const TelaBiblioteca({
    super.key,
    required this.listarMusicas,
    this.listarItensBiblioteca,
    required this.prepararEntradaMusica,
    required this.salvarRascunhoChordPro,
    required this.obterMusicaPorId,
    required this.atualizarMusica,
    required this.editarVersaoMusica,
    required this.excluirMusica,
    this.obterUltimoTomExecucao,
    this.salvarUltimoTomExecucao,
    this.removerUltimoTomExecucao,
    this.obterVersaoMusicaPorId,
    this.listarVersoesMusica,
    this.criarVersaoMusica,
    this.obterClassificacaoMusica,
    this.listarClassificacoesMusicas,
    this.salvarClassificacaoMusica,
    this.listarListasCulto,
    this.criarListaCulto,
    this.renomearListaCulto,
    this.excluirListaCulto,
    this.carregarDetalheListaCulto,
    this.adicionarMusicaAListaCulto,
    this.removerItemListaCulto,
    this.trocarVersaoItemListaCulto,
    this.reordenarItensListaCulto,
    this.atualizarBibliotecaOficial,
    this.obterEstadoBibliotecaOficial,
    this.obterInformacoesApp,
  });

  final ListarMusicas listarMusicas;
  final ListarItensBiblioteca? listarItensBiblioteca;
  final PrepararEntradaMusica prepararEntradaMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;
  final ObterMusicaPorId obterMusicaPorId;
  final EditarVersaoMusica editarVersaoMusica;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;
  final ObterUltimoTomExecucao? obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao? salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao? removerUltimoTomExecucao;
  final ObterVersaoMusicaPorId? obterVersaoMusicaPorId;
  final ListarVersoesMusica? listarVersoesMusica;
  final CriarVersaoMusica? criarVersaoMusica;
  final ObterClassificacaoMusica? obterClassificacaoMusica;
  final ListarClassificacoesMusicas? listarClassificacoesMusicas;
  final SalvarClassificacaoMusica? salvarClassificacaoMusica;
  final ListarListasCulto? listarListasCulto;
  final CriarListaCulto? criarListaCulto;
  final RenomearListaCulto? renomearListaCulto;
  final ExcluirListaCulto? excluirListaCulto;
  final CarregarDetalheListaCulto? carregarDetalheListaCulto;
  final AdicionarMusicaAListaCulto? adicionarMusicaAListaCulto;
  final RemoverItemListaCulto? removerItemListaCulto;
  final TrocarVersaoItemListaCulto? trocarVersaoItemListaCulto;
  final ReordenarItensListaCulto? reordenarItensListaCulto;
  final Future<ResultadoAtualizacaoBibliotecaOficial> Function()?
  atualizarBibliotecaOficial;
  final Future<EstadoBibliotecaOficial?> Function()?
  obterEstadoBibliotecaOficial;
  final ObterInformacoesApp? obterInformacoesApp;

  @override
  State<TelaBiblioteca> createState() => _TelaBibliotecaState();
}

class _TelaBibliotecaState extends State<TelaBiblioteca> {
  static const _pesquisaMusicas = ServicoPesquisaMusicas();
  late Future<_ResultadoCarregamentoBiblioteca> _indiceMusicas;
  final _pesquisa = TextEditingController();
  EnergiaMusica? _energia;
  Set<TagMusica> _tagsSelecionadas = {};
  EstadoBibliotecaOficial? _estadoBibliotecaOficial;
  var _atualizandoBiblioteca = false;

  @override
  void initState() {
    super.initState();
    _recarregarMusicas(MotivoCarregamentoBiblioteca.primeiraAbertura);
    _carregarEstadoBibliotecaOficial();
    _pesquisa.addListener(_atualizarPesquisa);
  }

  @override
  void dispose() {
    _pesquisa.removeListener(_atualizarPesquisa);
    _pesquisa.dispose();
    super.dispose();
  }

  void _atualizarPesquisa() => setState(() {});

  void _limparPesquisa() => _pesquisa.clear();

  @override
  void didUpdateWidget(covariant TelaBiblioteca oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listarMusicas != oldWidget.listarMusicas ||
        widget.listarItensBiblioteca != oldWidget.listarItensBiblioteca ||
        widget.listarClassificacoesMusicas !=
            oldWidget.listarClassificacoesMusicas) {
      _recarregarMusicas(MotivoCarregamentoBiblioteca.dependenciasAtualizadas);
    }
  }

  Future<void> _abrirCadastro() async {
    final cadastrada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TelaEntradaMusica(
          prepararEntradaMusica: widget.prepararEntradaMusica,
          salvarRascunhoChordPro: widget.salvarRascunhoChordPro,
        ),
      ),
    );
    if (cadastrada == true && mounted) {
      setState(
        () => _recarregarMusicas(MotivoCarregamentoBiblioteca.retornoCadastro),
      );
    }
  }

  Future<void> _abrirMusica(ItemBiblioteca musica) async {
    var alterada = false;
    final medicao = MedicaoDesempenhoVisualizacao.iniciar(
      origem: OrigemAberturaVisualizacao.biblioteca,
      registrar: debugPrint,
    );
    final excluida = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => TelaVisualizacaoMusica(
          idMusica: musica.idMusica,
          idVersaoMusica: musica.idVersaoPrincipal,
          obterVersaoMusicaPorId: widget.obterVersaoMusicaPorId,
          listarVersoesMusica: widget.listarVersoesMusica,
          criarVersaoMusica: widget.criarVersaoMusica,
          obterMusicaPorId: widget.obterMusicaPorId,
          atualizarMusica: widget.atualizarMusica,
          editarVersaoMusica: widget.editarVersaoMusica,
          excluirMusica: widget.excluirMusica,
          obterUltimoTomExecucao: widget.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: widget.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: widget.removerUltimoTomExecucao,
          obterClassificacaoMusica: widget.obterClassificacaoMusica,
          salvarClassificacaoMusica: widget.salvarClassificacaoMusica,
          aoAlterarBiblioteca: () => alterada = true,
          medicaoDesempenho: medicao,
        ),
      ),
    );
    if (mounted && (alterada || excluida == true)) {
      setState(
        () => _recarregarMusicas(MotivoCarregamentoBiblioteca.retornoMusica),
      );
    }
  }

  Future<void> _abrirListasCulto() async {
    final listarListasCulto = widget.listarListasCulto;
    final criarListaCulto = widget.criarListaCulto;
    final renomearListaCulto = widget.renomearListaCulto;
    final excluirListaCulto = widget.excluirListaCulto;
    final carregarDetalheListaCulto = widget.carregarDetalheListaCulto;
    final adicionarMusicaAListaCulto = widget.adicionarMusicaAListaCulto;
    final removerItemListaCulto = widget.removerItemListaCulto;
    final trocarVersaoItemListaCulto = widget.trocarVersaoItemListaCulto;
    final reordenarItensListaCulto = widget.reordenarItensListaCulto;
    if (listarListasCulto == null ||
        criarListaCulto == null ||
        renomearListaCulto == null ||
        excluirListaCulto == null ||
        carregarDetalheListaCulto == null ||
        adicionarMusicaAListaCulto == null ||
        removerItemListaCulto == null ||
        trocarVersaoItemListaCulto == null ||
        widget.listarVersoesMusica == null ||
        widget.obterVersaoMusicaPorId == null ||
        reordenarItensListaCulto == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TelaListasCulto(
          listarListasCulto: listarListasCulto,
          criarListaCulto: criarListaCulto,
          renomearListaCulto: renomearListaCulto,
          excluirListaCulto: excluirListaCulto,
          carregarDetalheListaCulto: carregarDetalheListaCulto,
          adicionarMusicaAListaCulto: adicionarMusicaAListaCulto,
          removerItemListaCulto: removerItemListaCulto,
          trocarVersaoItemListaCulto: trocarVersaoItemListaCulto,
          listarVersoesMusica: widget.listarVersoesMusica!,
          reordenarItensListaCulto: reordenarItensListaCulto,
          listarMusicas: widget.listarMusicas,
          obterMusicaPorId: widget.obterMusicaPorId,
          atualizarMusica: widget.atualizarMusica,
          editarVersaoMusica: widget.editarVersaoMusica,
          excluirMusica: widget.excluirMusica,
          obterUltimoTomExecucao: widget.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: widget.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: widget.removerUltimoTomExecucao,
          obterVersaoMusicaPorId: widget.obterVersaoMusicaPorId,
        ),
      ),
    );
    if (mounted) {
      setState(
        () =>
            _recarregarMusicas(MotivoCarregamentoBiblioteca.retornoListasCulto),
      );
    }
  }

  Future<void> _carregarEstadoBibliotecaOficial() async {
    final obterEstado = widget.obterEstadoBibliotecaOficial;
    if (obterEstado == null) return;
    try {
      final estado = await obterEstado();
      if (mounted) {
        setState(() => _estadoBibliotecaOficial = estado);
      }
    } catch (_) {
      // O estado é informativo e não deve impedir o uso offline da Biblioteca.
    }
  }

  Future<void> _atualizarBiblioteca() async {
    final atualizar = widget.atualizarBibliotecaOficial;
    if (atualizar == null || _atualizandoBiblioteca) return;
    setState(() => _atualizandoBiblioteca = true);

    ResultadoAtualizacaoBibliotecaOficial resultado;
    try {
      resultado = await atualizar();
    } catch (erro) {
      resultado = ResultadoAtualizacaoBibliotecaOficial(
        geracao: null,
        adicionadas: 0,
        atualizadas: 0,
        inalteradas: 0,
        origensAusentes: 0,
        geracaoRegistrada: false,
        erros: [
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.preparacao,
            mensagem: 'Não foi possível atualizar a biblioteca: $erro',
          ),
        ],
        avisos: const [],
      );
    }
    if (!mounted) return;

    final houveMudancas =
        resultado.adicionadas > 0 ||
        resultado.atualizadas > 0 ||
        resultado.origensAusentes > 0;
    if (houveMudancas) {
      _recarregarMusicas(MotivoCarregamentoBiblioteca.atualizacaoBiblioteca);
    }
    await _carregarEstadoBibliotecaOficial();
    if (!mounted) return;
    setState(() => _atualizandoBiblioteca = false);
    await _mostrarResultadoAtualizacao(resultado);
  }

  Future<void> _mostrarResultadoAtualizacao(
    ResultadoAtualizacaoBibliotecaOficial resultado,
  ) => showDialog<void>(
    context: context,
    builder: (context) => _DialogoResultadoAtualizacao(
      resultado: resultado,
      estado: _estadoBibliotecaOficial,
    ),
  );

  Future<void> _abrirSobre() async {
    final obterInformacoesApp = widget.obterInformacoesApp;
    if (obterInformacoesApp == null) return;
    final informacoes = obterInformacoesApp.executar();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o AppCifras'),
        content: FutureBuilder<InformacoesApp>(
          future: informacoes,
          builder: (context, resultado) {
            if (resultado.connectionState != ConnectionState.done) {
              return const SizedBox(
                width: 32,
                height: 32,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (resultado.hasError) {
              return const Text('Não foi possível obter a versão do app.');
            }
            final dados = resultado.requireData;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AppCifras ${dados.versao} (${dados.numeroBuild})'),
                const SizedBox(height: 8),
                Text('Build: ${dados.commitGit ?? 'não identificado'}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Biblioteca'),
      actions: [
        if (widget.obterInformacoesApp != null)
          IconButton(
            key: const ValueKey('abrir-sobre-app'),
            tooltip: 'Sobre o AppCifras',
            onPressed: _abrirSobre,
            icon: const Icon(Icons.info_outline),
          ),
        if (widget.atualizarBibliotecaOficial != null)
          Tooltip(
            message: 'Atualizar biblioteca',
            child: TextButton.icon(
              key: const ValueKey('atualizar-biblioteca'),
              onPressed: _atualizandoBiblioteca ? null : _atualizarBiblioteca,
              icon: _atualizandoBiblioteca
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_atualizandoBiblioteca ? 'Atualizando' : 'Atualizar'),
            ),
          ),
        if (widget.listarListasCulto != null)
          TextButton.icon(
            onPressed: _abrirListasCulto,
            icon: const Icon(Icons.queue_music_outlined),
            label: const Text('Listas'),
          ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _abrirCadastro,
      tooltip: 'Adicionar música',
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        if (_estadoBibliotecaOficial != null)
          _EstadoAtualizacaoBiblioteca(estado: _estadoBibliotecaOficial!),
        Expanded(
          child: FutureBuilder<_ResultadoCarregamentoBiblioteca>(
            future: _indiceMusicas,
            builder: (context, resultado) {
              if (resultado.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (resultado.hasError) {
                return const _EstadoErroBiblioteca();
              }
              final carregamento = resultado.requireData;
              final indice = carregamento.indice;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => carregamento.medicao?.concluirApresentacao(),
              );
              if (indice.isEmpty) {
                return const _EstadoBibliotecaVazia();
              }
              final resultados = indice.pesquisar(
                ConsultaPesquisaMusicas(
                  texto: _pesquisa.text,
                  energia: _energia,
                  tags: _tagsSelecionadas,
                ),
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pesquisa,
                            decoration: InputDecoration(
                              labelText: 'Pesquisar músicas',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _pesquisa.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar pesquisa',
                                      icon: const Icon(Icons.clear),
                                      onPressed: _limparPesquisa,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _BotaoFiltrosBiblioteca(
                          quantidadeAtiva: _quantidadeFiltrosAtivos,
                          aoAbrir: () => _abrirFiltros(indice),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: resultados.isEmpty
                        ? const _EstadoPesquisaVazia()
                        : ListView.separated(
                            itemCount: resultados.length,
                            itemBuilder: (context, indice) {
                              final resultadoPesquisa = resultados[indice];
                              final musica = resultadoPesquisa.musica;
                              return ListTile(
                                key: ValueKey(musica.idMusica.valor),
                                onTap: () => _abrirMusica(musica),
                                title: Text(musica.titulo),
                                subtitle: _SubtituloResultadoPesquisa(
                                  artista: musica.artista,
                                  trechoLetra: resultadoPesquisa.trechoLetra,
                                ),
                              );
                            },
                            separatorBuilder: (context, indice) =>
                                const Divider(height: 1),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  int get _quantidadeFiltrosAtivos =>
      (_energia == null ? 0 : 1) + _tagsSelecionadas.length;

  Future<void> _abrirFiltros(
    IndicePesquisaMusicas<ItemBiblioteca> indice,
  ) async {
    final consulta = await showModalBottomSheet<ConsultaPesquisaMusicas>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FolhaFiltrosBiblioteca(
        energiaInicial: _energia,
        tagsDisponiveis: indice.tagsDisponiveis,
        tagsSelecionadasIniciais: _tagsSelecionadas,
      ),
    );
    if (consulta != null && mounted) {
      setState(() {
        _energia = consulta.energia;
        _tagsSelecionadas = consulta.tags;
      });
    }
  }

  void _recarregarMusicas(MotivoCarregamentoBiblioteca motivo) {
    final medicao = MedicaoDesempenhoBiblioteca.iniciar(
      motivo: motivo,
      registrar: debugPrint,
    );
    _indiceMusicas = _carregarIndice(medicao).then((carregamento) {
      final indice = carregamento.indice;
      _tagsSelecionadas = _tagsSelecionadas
          .where(indice.tagsDisponiveis.contains)
          .toSet();
      return carregamento;
    });
  }

  Future<_ResultadoCarregamentoBiblioteca> _carregarIndice(
    MedicaoDesempenhoBiblioteca? medicao,
  ) async {
    Future<IndicePesquisaMusicas<ItemBiblioteca>> carregar() async {
      final itens =
          await (widget.listarItensBiblioteca?.executar() ??
              RepositorioConsultaBibliotecaLegada(widget.listarMusicas.executar)
                  .listarItensBiblioteca());
      final listarClassificacoes = widget.listarClassificacoesMusicas;
      final Map<IdMusica, ClassificacaoMusica> classificacoes =
          listarClassificacoes == null
          ? const {}
          : await listarClassificacoes.executar();
      return medicao == null
          ? _pesquisaMusicas.criarIndiceBiblioteca(
              itens,
              classificacoes: classificacoes,
            )
          : medicao.medirCriacaoIndice(
              () => _pesquisaMusicas.criarIndiceBiblioteca(
                itens,
                classificacoes: classificacoes,
              ),
            );
    }

    try {
      final indice = medicao == null
          ? await carregar()
          : await medicao.executarNoContexto(carregar);
      medicao?.concluirCarregamento();
      return _ResultadoCarregamentoBiblioteca(indice: indice, medicao: medicao);
    } catch (_) {
      medicao?.concluirCarregamento();
      medicao?.concluirApresentacao(sucesso: false);
      rethrow;
    }
  }
}

class _ResultadoCarregamentoBiblioteca {
  const _ResultadoCarregamentoBiblioteca({
    required this.indice,
    required this.medicao,
  });

  final IndicePesquisaMusicas<ItemBiblioteca> indice;
  final MedicaoDesempenhoBiblioteca? medicao;
}

class _EstadoAtualizacaoBiblioteca extends StatelessWidget {
  const _EstadoAtualizacaoBiblioteca({required this.estado});

  final EstadoBibliotecaOficial estado;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Última atualização: ${_formatarDataAtualizacao(estado.ultimaAtualizacao)}',
        key: const ValueKey('ultima-atualizacao-biblioteca'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class _DialogoResultadoAtualizacao extends StatelessWidget {
  const _DialogoResultadoAtualizacao({
    required this.resultado,
    required this.estado,
  });

  final ResultadoAtualizacaoBibliotecaOficial resultado;
  final EstadoBibliotecaOficial? estado;

  @override
  Widget build(BuildContext context) {
    final falhaGlobal = resultado.geracao == null;
    final titulo = resultado.concluida
        ? 'Biblioteca atualizada'
        : falhaGlobal
        ? 'Atualização não concluída'
        : 'Atualização incompleta';
    final estadoDaGeracao = estado?.ultimaGeracao == resultado.geracao
        ? estado
        : null;

    return AlertDialog(
      title: Text(titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!falhaGlobal) ...[
              Text(
                _quantidade(resultado.inalteradas, 'inalterada', 'inalteradas'),
              ),
              Text(
                _quantidade(resultado.adicionadas, 'adicionada', 'adicionadas'),
              ),
              Text(
                _quantidade(resultado.atualizadas, 'atualizada', 'atualizadas'),
              ),
              Text(
                _quantidade(resultado.origensAusentes, 'ausente', 'ausentes'),
              ),
              Text(_quantidade(resultado.erros.length, 'erro', 'erros')),
              const SizedBox(height: 12),
              Text('Geração: ${resultado.geracao}'),
              if (estadoDaGeracao != null)
                Text(
                  'Última atualização: '
                  '${_formatarDataAtualizacao(estadoDaGeracao.ultimaAtualizacao)}',
                ),
            ],
            if (resultado.erros.isNotEmpty) ...[
              if (!falhaGlobal) const SizedBox(height: 12),
              Text('Erros', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final erro in resultado.erros)
                Text(
                  '• ${_mensagemComLocalizador(erro.mensagem, erro.localizador)}',
                ),
            ],
            if (resultado.avisos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Avisos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final aviso in resultado.avisos)
                Text(
                  '• ${_mensagemComLocalizador(aviso.mensagem, aviso.localizador)}',
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

String _quantidade(int quantidade, String singular, String plural) =>
    '$quantidade ${quantidade == 1 ? singular : plural}';

String _mensagemComLocalizador(String mensagem, String? localizador) {
  if (localizador == null || localizador.trim().isEmpty) return mensagem;
  final partes = localizador.split(RegExp(r'[/\\]'));
  return '$mensagem (${partes.last})';
}

String _formatarDataAtualizacao(DateTime data) {
  final local = data.toLocal();
  final agora = DateTime.now();
  final hora =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  if (local.year == agora.year &&
      local.month == agora.month &&
      local.day == agora.day) {
    return 'hoje $hora';
  }
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year} $hora';
}

class _SubtituloResultadoPesquisa extends StatelessWidget {
  const _SubtituloResultadoPesquisa({
    required this.artista,
    required this.trechoLetra,
  });

  final String artista;
  final String? trechoLetra;

  @override
  Widget build(BuildContext context) {
    if (trechoLetra == null) {
      return Text(artista);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(artista),
        Text(
          trechoLetra!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BotaoFiltrosBiblioteca extends StatelessWidget {
  const _BotaoFiltrosBiblioteca({
    required this.quantidadeAtiva,
    required this.aoAbrir,
  });

  final int quantidadeAtiva;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    final botao = IconButton(
      key: const ValueKey('abrir-filtros-biblioteca'),
      tooltip: quantidadeAtiva == 0
          ? 'Filtros'
          : '$quantidadeAtiva filtros ativos',
      icon: const Icon(Icons.tune),
      onPressed: aoAbrir,
    );
    if (quantidadeAtiva == 0) return botao;
    return Badge.count(
      key: const ValueKey('indicador-filtros-ativos'),
      count: quantidadeAtiva,
      child: botao,
    );
  }
}

class _FolhaFiltrosBiblioteca extends StatefulWidget {
  const _FolhaFiltrosBiblioteca({
    required this.energiaInicial,
    required this.tagsDisponiveis,
    required this.tagsSelecionadasIniciais,
  });

  final EnergiaMusica? energiaInicial;
  final List<TagMusica> tagsDisponiveis;
  final Set<TagMusica> tagsSelecionadasIniciais;

  @override
  State<_FolhaFiltrosBiblioteca> createState() =>
      _FolhaFiltrosBibliotecaState();
}

class _FolhaFiltrosBibliotecaState extends State<_FolhaFiltrosBiblioteca> {
  late EnergiaMusica? _energia = widget.energiaInicial;
  late Set<TagMusica> _tags = {...widget.tagsSelecionadasIniciais};

  void _limpar() => setState(() {
    _energia = null;
    _tags = {};
  });

  void _alternarTag(TagMusica tag, bool selecionada) => setState(() {
    if (selecionada) {
      _tags.add(tag);
    } else {
      _tags.remove(tag);
    }
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtros', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            const Text('ENERGIA'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('filtro-energia-todas'),
                  label: const Text('Todas'),
                  selected: _energia == null,
                  onSelected: (_) => setState(() => _energia = null),
                ),
                for (final energia in EnergiaMusica.values)
                  ChoiceChip(
                    key: ValueKey('filtro-energia-${energia.name}'),
                    label: Text(energia.titulo),
                    selected: _energia == energia,
                    onSelected: (_) => setState(() => _energia = energia),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('TAGS'),
            const SizedBox(height: 8),
            if (widget.tagsDisponiveis.isEmpty)
              const Text('Nenhuma tag disponível.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.tagsDisponiveis)
                    FilterChip(
                      key: ValueKey('filtro-tag-${tag.chaveNormalizada}'),
                      label: Text(tag.valor),
                      selected: _tags.contains(tag),
                      onSelected: (selecionada) =>
                          _alternarTag(tag, selecionada),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('limpar-filtros-biblioteca'),
                  onPressed: _limpar,
                  child: const Text('Limpar filtros'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('aplicar-filtros-biblioteca'),
                  onPressed: () => Navigator.of(context).pop(
                    ConsultaPesquisaMusicas(energia: _energia, tags: _tags),
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EstadoBibliotecaVazia extends StatelessWidget {
  const _EstadoBibliotecaVazia();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music_outlined, size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhuma música na biblioteca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'As músicas adicionadas aparecerão aqui.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _EstadoErroBiblioteca extends StatelessWidget {
  const _EstadoErroBiblioteca();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48),
          SizedBox(height: 16),
          Text(
            'Não foi possível carregar a biblioteca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text('Tente novamente mais tarde.', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _EstadoPesquisaVazia extends StatelessWidget {
  const _EstadoPesquisaVazia();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Nenhuma música encontrada para esta pesquisa.'),
    ),
  );
}
