import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/listas_culto.dart';
import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../dominio/entidades/musica.dart';
import '../compartilhado/normalizacao_pesquisa.dart';
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
  late Future<List<Musica>> _musicas;
  final _pesquisa = TextEditingController();

  @override
  void initState() {
    super.initState();
    _musicas = widget.listarMusicas.executar();
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
    if (widget.listarMusicas != oldWidget.listarMusicas) {
      _musicas = widget.listarMusicas.executar();
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
      final musicas = widget.listarMusicas.executar();
      setState(() {
        _musicas = musicas;
      });
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
        ),
      ),
    );
    if (mounted) {
      final musicas = widget.listarMusicas.executar();
      setState(() {
        _musicas = musicas;
      });
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
      final musicas = widget.listarMusicas.executar();
      setState(() {
        _musicas = musicas;
      });
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
    body: FutureBuilder<List<Musica>>(
      future: _musicas,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resultado.hasError) {
          return const _EstadoErroBiblioteca();
        }
        final musicas = resultado.requireData;
        if (musicas.isEmpty) {
          return const _EstadoBibliotecaVazia();
        }
        final filtradas = _filtrar(musicas, _pesquisa.text);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            Expanded(
              child: filtradas.isEmpty
                  ? const _EstadoPesquisaVazia()
                  : ListView.separated(
                      itemCount: filtradas.length,
                      itemBuilder: (context, indice) {
                        final musica = filtradas[indice];
                        return ListTile(
                          key: ValueKey(musica.id.valor),
                          onTap: () => _abrirMusica(musica),
                          title: Text(musica.titulo),
                          subtitle: Text(musica.artista),
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

  List<Musica> _filtrar(List<Musica> musicas, String consulta) {
    final normalizada = normalizarPesquisa(consulta);
    if (normalizada.isEmpty) return musicas;
    return musicas.where((musica) {
      return normalizarPesquisa(musica.titulo).contains(normalizada) ||
          normalizarPesquisa(musica.artista).contains(normalizada);
    }).toList();
  }
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
