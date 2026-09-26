import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/listas_culto.dart';
import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/entidades/lista_culto.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../compartilhado/normalizacao_pesquisa.dart';
import '../musica/contexto_navegacao_lista_culto.dart';
import '../musica/tela_visualizacao_musica.dart';

class TelaDetalheListaCulto extends StatefulWidget {
  const TelaDetalheListaCulto({
    super.key,
    required this.lista,
    required this.listarItensListaCulto,
    required this.adicionarMusicaAListaCulto,
    required this.removerItemListaCulto,
    required this.reordenarItensListaCulto,
    required this.listarMusicas,
    required this.obterMusicaPorId,
    required this.atualizarMusica,
    required this.excluirMusica,
    this.obterUltimoTomExecucao,
    this.salvarUltimoTomExecucao,
    this.removerUltimoTomExecucao,
  });

  final ListaCulto lista;
  final ListarItensListaCulto listarItensListaCulto;
  final AdicionarMusicaAListaCulto adicionarMusicaAListaCulto;
  final RemoverItemListaCulto removerItemListaCulto;
  final ReordenarItensListaCulto reordenarItensListaCulto;
  final ListarMusicas listarMusicas;
  final ObterMusicaPorId obterMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;
  final ObterUltimoTomExecucao? obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao? salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao? removerUltimoTomExecucao;

  @override
  State<TelaDetalheListaCulto> createState() => _TelaDetalheListaCultoState();
}

class _TelaDetalheListaCultoState extends State<TelaDetalheListaCulto> {
  late Future<List<_ItemComMusica>> _itens;
  var _reordenando = false;
  var _removendo = false;

  @override
  void initState() {
    super.initState();
    _itens = _carregarItens();
  }

  Future<List<_ItemComMusica>> _carregarItens() async {
    final itens = await widget.listarItensListaCulto.executar(widget.lista.id);
    final musicas = await widget.listarMusicas.executar();
    final porId = {for (final musica in musicas) musica.id: musica};
    return [
      for (final item in itens)
        if (porId[item.idMusica] case final musica?)
          _ItemComMusica(item: item, musica: musica),
    ];
  }

  void _recarregar() {
    setState(() {
      _itens = _carregarItens();
    });
  }

  Future<void> _adicionarMusicas() async {
    final itensAtuais = await _itens;
    if (!mounted) return;
    final selecionadas = await Navigator.of(context).push<List<IdMusica>>(
      MaterialPageRoute<List<IdMusica>>(
        builder: (context) => _TelaSelecionarMusicas(
          listarMusicas: widget.listarMusicas,
          idsMusicasJaAdicionadas: {
            for (final item in itensAtuais) item.item.idMusica,
          },
        ),
      ),
    );
    if (selecionadas == null || selecionadas.isEmpty) return;

    try {
      for (final idMusica in selecionadas) {
        await widget.adicionarMusicaAListaCulto.executar(
          widget.lista.id,
          idMusica,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível adicionar as músicas.'),
          ),
        );
      }
    } finally {
      if (mounted) _recarregar();
    }
  }

  Future<void> _removerItem(_ItemComMusica item) async {
    if (_removendo) return;
    setState(() {
      _removendo = true;
    });
    try {
      await widget.removerItemListaCulto.executar(
        widget.lista.id,
        item.item.id,
      );
      if (mounted) _recarregar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível remover a música.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _removendo = false;
        });
      }
    }
  }

  Future<void> _confirmarRemocao(_ItemComMusica item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover "${item.musica.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _removerItem(item);
    }
  }

  Future<void> _reordenar(
    List<_ItemComMusica> itens,
    int indiceAntigo,
    int indiceNovo,
  ) async {
    if (_reordenando) return;
    final ordemAnterior = List<_ItemComMusica>.from(itens);
    final novaOrdem = List<_ItemComMusica>.from(itens);
    final movido = novaOrdem.removeAt(indiceAntigo);
    novaOrdem.insert(indiceNovo, movido);

    setState(() {
      _reordenando = true;
      _itens = Future.value(novaOrdem);
    });
    try {
      await widget.reordenarItensListaCulto.executar(widget.lista.id, [
        for (final item in novaOrdem) item.item.id,
      ]);
      if (mounted) _recarregar();
    } catch (_) {
      if (mounted) {
        setState(() {
          _itens = Future.value(ordemAnterior);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível reordenar as músicas.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reordenando = false;
        });
      }
    }
  }

  Future<void> _abrirMusica(List<_ItemComMusica> itens, int indiceAtual) async {
    final contexto = ContextoNavegacaoListaCulto(
      idLista: widget.lista.id,
      itens: [for (final item in itens) item.item],
      indiceAtual: indiceAtual,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TelaVisualizacaoMusica(
          idMusica: contexto.itemAtual.idMusica,
          obterMusicaPorId: widget.obterMusicaPorId,
          atualizarMusica: widget.atualizarMusica,
          excluirMusica: widget.excluirMusica,
          obterUltimoTomExecucao: widget.obterUltimoTomExecucao,
          salvarUltimoTomExecucao: widget.salvarUltimoTomExecucao,
          removerUltimoTomExecucao: widget.removerUltimoTomExecucao,
          contextoListaCulto: contexto,
        ),
      ),
    );
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.lista.nome)),
    floatingActionButton: FloatingActionButton.extended(
      tooltip: 'Adicionar músicas',
      onPressed: _removendo || _reordenando ? null : _adicionarMusicas,
      icon: const Icon(Icons.add),
      label: const Text('Adicionar músicas'),
    ),
    body: FutureBuilder<List<_ItemComMusica>>(
      future: _itens,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resultado.hasError) {
          return const Center(
            child: Text('Não foi possível carregar a lista.'),
          );
        }
        final itens = resultado.requireData;
        if (itens.isEmpty) {
          return _EstadoItensVazio(onAdicionar: _adicionarMusicas);
        }
        return ReorderableListView.builder(
          itemCount: itens.length,
          onReorderItem: (antigo, novo) => _reordenar(itens, antigo, novo),
          itemBuilder: (context, indice) {
            final item = itens[indice];
            return ListTile(
              key: ValueKey('item-lista-${item.item.id.valor}'),
              onTap: () => _abrirMusica(itens, indice),
              title: Text(item.musica.titulo),
              subtitle: Text(item.musica.artista),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remover da lista',
                    onPressed: _removendo
                        ? null
                        : () => _confirmarRemocao(item),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  ReorderableDragStartListener(
                    index: indice,
                    child: const Icon(Icons.drag_handle),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _ItemComMusica {
  const _ItemComMusica({required this.item, required this.musica});

  final ItemListaCulto item;
  final Musica musica;
}

class _EstadoItensVazio extends StatelessWidget {
  const _EstadoItensVazio({required this.onAdicionar});

  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note_outlined, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma música nesta lista',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione músicas da Biblioteca para organizar esta lista.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdicionar,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar músicas'),
          ),
        ],
      ),
    ),
  );
}

class _TelaSelecionarMusicas extends StatefulWidget {
  const _TelaSelecionarMusicas({
    required this.listarMusicas,
    required this.idsMusicasJaAdicionadas,
  });

  final ListarMusicas listarMusicas;
  final Set<IdMusica> idsMusicasJaAdicionadas;

  @override
  State<_TelaSelecionarMusicas> createState() => _TelaSelecionarMusicasState();
}

class _TelaSelecionarMusicasState extends State<_TelaSelecionarMusicas> {
  late Future<List<Musica>> _musicas;
  final _pesquisa = TextEditingController();
  final _selecionadas = <IdMusica>[];

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

  void _alterarSelecao(IdMusica idMusica, bool selecionar) {
    setState(() {
      if (selecionar) {
        _selecionadas.add(idMusica);
      } else {
        _selecionadas.remove(idMusica);
      }
    });
  }

  List<Musica> _filtrar(List<Musica> musicas) {
    final consulta = normalizarPesquisa(_pesquisa.text);
    if (consulta.isEmpty) return musicas;
    return musicas
        .where(
          (musica) =>
              normalizarPesquisa(musica.titulo).contains(consulta) ||
              normalizarPesquisa(musica.artista).contains(consulta),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adicionar músicas')),
    floatingActionButton: _selecionadas.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => Navigator.pop(context, _selecionadas),
            icon: const Icon(Icons.add),
            label: Text('Adicionar (${_selecionadas.length})'),
          ),
    body: FutureBuilder<List<Musica>>(
      future: _musicas,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resultado.hasError) {
          return const Center(
            child: Text('Não foi possível carregar a Biblioteca.'),
          );
        }
        final musicas = _filtrar(resultado.requireData);
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
                          onPressed: _pesquisa.clear,
                        ),
                ),
              ),
            ),
            Expanded(
              child: musicas.isEmpty
                  ? const Center(child: Text('Nenhuma música encontrada.'))
                  : ListView.builder(
                      itemCount: musicas.length,
                      itemBuilder: (context, indice) {
                        final musica = musicas[indice];
                        final jaAdicionada = widget.idsMusicasJaAdicionadas
                            .contains(musica.id);
                        final marcada = _selecionadas.contains(musica.id);
                        return CheckboxListTile(
                          key: ValueKey('selecionar-${musica.id.valor}'),
                          value: jaAdicionada || marcada,
                          onChanged: jaAdicionada
                              ? null
                              : (valor) =>
                                    _alterarSelecao(musica.id, valor ?? false),
                          title: Text(musica.titulo),
                          subtitle: Text(
                            jaAdicionada
                                ? '${musica.artista} · Já adicionada'
                                : musica.artista,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}
