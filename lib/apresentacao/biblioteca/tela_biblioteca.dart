import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../dominio/entidades/musica.dart';
import '../entrada/tela_entrada_musica.dart';
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
  });

  final ListarMusicas listarMusicas;
  final PrepararEntradaMusica prepararEntradaMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;
  final ObterMusicaPorId obterMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;

  @override
  State<TelaBiblioteca> createState() => _TelaBibliotecaState();
}

class _TelaBibliotecaState extends State<TelaBiblioteca> {
  late Future<List<Musica>> _musicas;

  @override
  void initState() {
    super.initState();
    _musicas = widget.listarMusicas.executar();
  }

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
    appBar: AppBar(title: const Text('Biblioteca')),
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
        return ListView.separated(
          itemCount: musicas.length,
          itemBuilder: (context, indice) {
            final musica = musicas[indice];
            return ListTile(
              key: ValueKey(musica.id.valor),
              onTap: () => _abrirMusica(musica),
              title: Text(musica.titulo),
              subtitle: Text(musica.artista),
            );
          },
          separatorBuilder: (context, indice) => const Divider(height: 1),
        );
      },
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
