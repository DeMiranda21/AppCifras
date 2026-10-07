import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/classificacao_musica.dart';
import '../../aplicacao/casos_de_uso/listas_culto.dart';
import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../aplicacao/portas/repositorio_classificacao_musica.dart';
import '../../aplicacao/pesquisa/servico_pesquisa_musicas.dart';
import '../../dominio/entidades/musica.dart';
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
    required this.prepararEntradaMusica,
    required this.salvarRascunhoChordPro,
    required this.obterMusicaPorId,
    required this.atualizarMusica,
    required this.excluirMusica,
    this.obterUltimoTomExecucao,
    this.salvarUltimoTomExecucao,
    this.removerUltimoTomExecucao,
    this.obterClassificacaoMusica,
    this.listarClassificacoesMusicas,
    this.salvarClassificacaoMusica,
    this.listarListasCulto,
    this.criarListaCulto,
    this.renomearListaCulto,
    this.excluirListaCulto,
    this.listarItensListaCulto,
    this.adicionarMusicaAListaCulto,
    this.removerItemListaCulto,
    this.reordenarItensListaCulto,
  });

  final ListarMusicas listarMusicas;
  final PrepararEntradaMusica prepararEntradaMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;
  final ObterMusicaPorId obterMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;
  final ObterUltimoTomExecucao? obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao? salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao? removerUltimoTomExecucao;
  final ObterClassificacaoMusica? obterClassificacaoMusica;
  final ListarClassificacoesMusicas? listarClassificacoesMusicas;
  final SalvarClassificacaoMusica? salvarClassificacaoMusica;
  final ListarListasCulto? listarListasCulto;
  final CriarListaCulto? criarListaCulto;
  final RenomearListaCulto? renomearListaCulto;
  final ExcluirListaCulto? excluirListaCulto;
  final ListarItensListaCulto? listarItensListaCulto;
  final AdicionarMusicaAListaCulto? adicionarMusicaAListaCulto;
  final RemoverItemListaCulto? removerItemListaCulto;
  final ReordenarItensListaCulto? reordenarItensListaCulto;

  @override
  State<TelaBiblioteca> createState() => _TelaBibliotecaState();
}

class _TelaBibliotecaState extends State<TelaBiblioteca> {
  static const _pesquisaMusicas = ServicoPesquisaMusicas();
  late Future<IndicePesquisaMusicas> _indiceMusicas;
  final _pesquisa = TextEditingController();
  EnergiaMusica? _energia;
  Set<TagMusica> _tagsSelecionadas = {};

  @override
  void initState() {
    super.initState();
    _recarregarMusicas();
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
        widget.listarClassificacoesMusicas !=
            oldWidget.listarClassificacoesMusicas) {
      _recarregarMusicas();
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
      setState(_recarregarMusicas);
    }
  }

  Future<void> _abrirMusica(Musica musica) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TelaVisualizacaoMusica(
          idMusica: musica.id,
          obterMusicaPorId: widget.obterMusicaPorId,
          atualizarMusica: widget.atualizarMusica,
          excluirMusica: widget.excluirMusica,
          obterUltimoTomExecucao: widget.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: widget.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: widget.removerUltimoTomExecucao,
          obterClassificacaoMusica: widget.obterClassificacaoMusica,
          salvarClassificacaoMusica: widget.salvarClassificacaoMusica,
        ),
      ),
    );
    if (mounted) {
      setState(_recarregarMusicas);
    }
  }

  Future<void> _abrirListasCulto() async {
    final listarListasCulto = widget.listarListasCulto;
    final criarListaCulto = widget.criarListaCulto;
    final renomearListaCulto = widget.renomearListaCulto;
    final excluirListaCulto = widget.excluirListaCulto;
    final listarItensListaCulto = widget.listarItensListaCulto;
    final adicionarMusicaAListaCulto = widget.adicionarMusicaAListaCulto;
    final removerItemListaCulto = widget.removerItemListaCulto;
    final reordenarItensListaCulto = widget.reordenarItensListaCulto;
    if (listarListasCulto == null ||
        criarListaCulto == null ||
        renomearListaCulto == null ||
        excluirListaCulto == null ||
        listarItensListaCulto == null ||
        adicionarMusicaAListaCulto == null ||
        removerItemListaCulto == null ||
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
          listarItensListaCulto: listarItensListaCulto,
          adicionarMusicaAListaCulto: adicionarMusicaAListaCulto,
          removerItemListaCulto: removerItemListaCulto,
          reordenarItensListaCulto: reordenarItensListaCulto,
          listarMusicas: widget.listarMusicas,
          obterMusicaPorId: widget.obterMusicaPorId,
          atualizarMusica: widget.atualizarMusica,
          excluirMusica: widget.excluirMusica,
          obterUltimoTomExecucao: widget.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: widget.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: widget.removerUltimoTomExecucao,
        ),
      ),
    );
    if (mounted) {
      setState(_recarregarMusicas);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Biblioteca'),
      actions: [
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
    body: FutureBuilder<IndicePesquisaMusicas>(
      future: _indiceMusicas,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resultado.hasError) {
          return const _EstadoErroBiblioteca();
        }
        final indice = resultado.requireData;
        final resultadosSemFiltros = indice.pesquisar(
          ConsultaPesquisaMusicas(),
        );
        if (resultadosSemFiltros.isEmpty) {
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
                          key: ValueKey(musica.id.valor),
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
  );

  int get _quantidadeFiltrosAtivos =>
      (_energia == null ? 0 : 1) + _tagsSelecionadas.length;

  Future<void> _abrirFiltros(IndicePesquisaMusicas indice) async {
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

  void _recarregarMusicas() {
    _indiceMusicas = _carregarIndice().then((indice) {
      _tagsSelecionadas = _tagsSelecionadas
          .where(indice.tagsDisponiveis.contains)
          .toSet();
      return indice;
    });
  }

  Future<IndicePesquisaMusicas> _carregarIndice() async {
    final musicas = await widget.listarMusicas.executar();
    final listarClassificacoes = widget.listarClassificacoesMusicas;
    final Map<IdMusica, ClassificacaoMusica> classificacoes =
        listarClassificacoes == null
        ? const {}
        : await listarClassificacoes.executar();
    return _pesquisaMusicas.criarIndice(
      musicas,
      classificacoes: classificacoes,
    );
  }
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
