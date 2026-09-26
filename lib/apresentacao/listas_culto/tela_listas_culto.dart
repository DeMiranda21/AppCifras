import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/listas_culto.dart';
import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../dominio/entidades/lista_culto.dart';
import '../listas_culto/tela_detalhe_lista_culto.dart';

class TelaListasCulto extends StatefulWidget {
  const TelaListasCulto({
    super.key,
    required this.listarListasCulto,
    required this.criarListaCulto,
    required this.renomearListaCulto,
    required this.excluirListaCulto,
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

  final ListarListasCulto listarListasCulto;
  final CriarListaCulto criarListaCulto;
  final RenomearListaCulto renomearListaCulto;
  final ExcluirListaCulto excluirListaCulto;
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
  State<TelaListasCulto> createState() => _TelaListasCultoState();
}

class _TelaListasCultoState extends State<TelaListasCulto> {
  late Future<List<ListaCulto>> _listas;
  var _operacaoEmAndamento = false;

  @override
  void initState() {
    super.initState();
    _listas = widget.listarListasCulto.executar();
  }

  void _recarregar() {
    setState(() {
      _listas = widget.listarListasCulto.executar();
    });
  }

  Future<void> _criarLista() async {
    final nome = await _solicitarNomeLista(context, titulo: 'Criar lista');
    if (nome == null) return;
    await _executarOperacao(() => widget.criarListaCulto.executar(nome));
  }

  Future<void> _renomearLista(ListaCulto lista) async {
    final nome = await _solicitarNomeLista(
      context,
      titulo: 'Renomear lista',
      valorInicial: lista.nome,
    );
    if (nome == null) return;
    await _executarOperacao(
      () => widget.renomearListaCulto.executar(lista.id, nome),
    );
  }

  Future<void> _confirmarExclusao(ListaCulto lista) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir "${lista.nome}"?'),
        content: const Text('Esta ação removerá a lista e seus itens.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _executarOperacao(
        () => widget.excluirListaCulto.executar(lista.id),
      );
    }
  }

  Future<void> _executarOperacao(Future<void> Function() operacao) async {
    if (_operacaoEmAndamento) return;
    setState(() {
      _operacaoEmAndamento = true;
    });
    try {
      await operacao();
      if (mounted) _recarregar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar a lista.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _operacaoEmAndamento = false;
        });
      }
    }
  }

  Future<void> _abrirLista(ListaCulto lista) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TelaDetalheListaCulto(
          lista: lista,
          listarItensListaCulto: widget.listarItensListaCulto,
          adicionarMusicaAListaCulto: widget.adicionarMusicaAListaCulto,
          removerItemListaCulto: widget.removerItemListaCulto,
          reordenarItensListaCulto: widget.reordenarItensListaCulto,
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
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Listas de culto')),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Criar lista',
      onPressed: _operacaoEmAndamento ? null : _criarLista,
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<ListaCulto>>(
      future: _listas,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (resultado.hasError) return const _EstadoErroListasCulto();
        final listas = resultado.requireData;
        if (listas.isEmpty) {
          return _EstadoListasCultoVazia(onCriarLista: _criarLista);
        }
        return ListView.separated(
          itemCount: listas.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, indice) {
            final lista = listas[indice];
            return ListTile(
              key: ValueKey('lista-${lista.id.valor}'),
              title: Text(lista.nome),
              leading: const Icon(Icons.queue_music_outlined),
              onTap: () => _abrirLista(lista),
              trailing: PopupMenuButton<_AcaoLista>(
                tooltip: 'Ações da lista',
                enabled: !_operacaoEmAndamento,
                onSelected: (acao) {
                  switch (acao) {
                    case _AcaoLista.renomear:
                      _renomearLista(lista);
                    case _AcaoLista.excluir:
                      _confirmarExclusao(lista);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _AcaoLista.renomear,
                    child: Text('Renomear'),
                  ),
                  PopupMenuItem(
                    value: _AcaoLista.excluir,
                    child: Text('Excluir'),
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

enum _AcaoLista { renomear, excluir }

class _EstadoListasCultoVazia extends StatelessWidget {
  const _EstadoListasCultoVazia({required this.onCriarLista});

  final VoidCallback onCriarLista;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue_music_outlined, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma lista de culto criada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie uma lista para organizar as músicas de um culto.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCriarLista,
            icon: const Icon(Icons.add),
            label: const Text('Criar lista'),
          ),
        ],
      ),
    ),
  );
}

class _EstadoErroListasCulto extends StatelessWidget {
  const _EstadoErroListasCulto();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('Não foi possível carregar as listas de culto.'),
    ),
  );
}

Future<String?> _solicitarNomeLista(
  BuildContext context, {
  required String titulo,
  String valorInicial = '',
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _DialogoNomeLista(titulo: titulo, valorInicial: valorInicial),
);

class _DialogoNomeLista extends StatefulWidget {
  const _DialogoNomeLista({required this.titulo, required this.valorInicial});

  final String titulo;
  final String valorInicial;

  @override
  State<_DialogoNomeLista> createState() => _DialogoNomeListaState();
}

class _DialogoNomeListaState extends State<_DialogoNomeLista> {
  late final TextEditingController _controlador;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _controlador.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _erro = 'Informe o nome da lista.';
      });
      return;
    }
    Navigator.pop(context, nome);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.titulo),
    content: TextField(
      controller: _controlador,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _confirmar(),
      decoration: InputDecoration(labelText: 'Nome da lista', errorText: _erro),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _confirmar, child: const Text('Salvar')),
    ],
  );
}
