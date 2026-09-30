import 'dart:async';

import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/tom_execucao.dart';
import '../../aplicacao/visualizacao/alterar_tom_execucao.dart';
import '../../aplicacao/visualizacao/projetar_musica_para_visualizacao.dart';
import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/parser_acorde.dart';
import 'contexto_navegacao_lista_culto.dart';
import 'controle_tela_ativa.dart';
import 'escala_visualizacao_cifra.dart';
import 'tela_edicao_musica.dart';

class TelaVisualizacaoMusica extends StatefulWidget {
  const TelaVisualizacaoMusica({
    super.key,
    required this.idMusica,
    required this.obterMusicaPorId,
    required this.atualizarMusica,
    required this.excluirMusica,
    this.projetarMusicaParaVisualizacao,
    this.alterarTomExecucao,
    this.obterUltimoTomExecucao,
    this.salvarUltimoTomExecucao,
    this.removerUltimoTomExecucao,
    this.contextoListaCulto,
    this.controleTelaAtiva = const ControleTelaAtivaWakelockPlus(),
  });

  final IdMusica idMusica;
  final ObterMusicaPorId obterMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;
  final ProjetarMusicaParaVisualizacao? projetarMusicaParaVisualizacao;
  final AlterarTomExecucao? alterarTomExecucao;
  final ObterUltimoTomExecucao? obterUltimoTomExecucao;
  final SalvarUltimoTomExecucao? salvarUltimoTomExecucao;
  final RemoverUltimoTomExecucao? removerUltimoTomExecucao;
  final ContextoNavegacaoListaCulto? contextoListaCulto;
  final ControleTelaAtiva controleTelaAtiva;

  @override
  State<TelaVisualizacaoMusica> createState() => _TelaVisualizacaoMusicaState();
}

class _TelaVisualizacaoMusicaState extends State<TelaVisualizacaoMusica> {
  static const _distanciaMinimaDoSwipe = 72.0;
  static const _proporcaoMinimaHorizontalDoSwipe = 1.5;

  late Future<_DadosVisualizacaoMusica?> _dadosVisualizacao;
  late final ProjetarMusicaParaVisualizacao _projetarMusica;
  late final AlterarTomExecucao _alterarTomExecucao;
  late IdMusica _idMusicaAtual;
  ContextoNavegacaoListaCulto? _contextoListaCulto;
  final _rolagem = ScrollController();
  final _ponteirosDoZoom = <int, Offset>{};
  Tom? _tomExecucao;
  ProjecaoMusicaVisualizacao? _projecaoEmCache;
  IdMusica? _idDaProjecaoEmCache;
  Tom? _tomDaProjecaoEmCache;
  List<AcordeNaoTransponivelVisualizacao>? _problemasEmCache;
  var _escalaCifra = EscalaVisualizacaoCifra.padrao;
  EscalaVisualizacaoCifra? _escalaNoInicioDoZoom;
  double? _distanciaInicialDoZoom;
  int? _ponteiroDoSwipe;
  Offset? _inicioDoSwipe;
  var _gestoPossuiMultiplosPonteiros = false;
  var _excluindo = false;
  String? _erroExclusao;

  @override
  void initState() {
    super.initState();
    _contextoListaCulto = widget.contextoListaCulto;
    _idMusicaAtual = _contextoListaCulto?.itemAtual.idMusica ?? widget.idMusica;
    _dadosVisualizacao = _carregarDadosVisualizacao();
    _projetarMusica =
        widget.projetarMusicaParaVisualizacao ??
        ProjetarMusicaParaVisualizacao();
    _alterarTomExecucao = widget.alterarTomExecucao ?? AlterarTomExecucao();
    unawaited(_ativarTelaAtiva());
  }

  @override
  void dispose() {
    unawaited(_desativarTelaAtiva());
    _rolagem.dispose();
    super.dispose();
  }

  Future<void> _ativarTelaAtiva() async {
    try {
      await widget.controleTelaAtiva.ativar();
    } catch (_) {
      // O wake lock é auxiliar e não pode impedir a leitura da cifra.
    }
  }

  Future<void> _desativarTelaAtiva() async {
    try {
      await widget.controleTelaAtiva.desativar();
    } catch (_) {
      // O wake lock é auxiliar e não pode impedir a leitura da cifra.
    }
  }

  Future<void> _abrirEdicao(
    Musica musica, {
    String? textoParaLocalizacao,
  }) async {
    unawaited(_desativarTelaAtiva());
    final alterada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => TelaEdicaoMusica(
          musica: musica,
          atualizarMusica: widget.atualizarMusica,
          textoParaLocalizacao: textoParaLocalizacao,
        ),
      ),
    );
    if (mounted) {
      unawaited(_ativarTelaAtiva());
    }
    if (alterada == true && mounted) {
      setState(() {
        _tomExecucao = null;
        _limparCacheDaVisualizacao();
        _dadosVisualizacao = _carregarDadosVisualizacao();
      });
    }
  }

  Future<void> _alterarTom(Musica musica, Tom tomInicial, int semitons) async {
    final tomAtual = _tomExecucao ?? tomInicial;
    final novoTom = _alterarTomExecucao.executar(tomAtual, semitons);
    final resultado = _projetarMusica.executar(musica, novoTom);
    if (resultado is TransposicaoVisualizacaoIndisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível alterar o tom. Revise os acordes destacados na cifra.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _tomExecucao = novoTom;
    });
    try {
      if (novoTom == musica.tomOriginal) {
        await widget.removerUltimoTomExecucao?.executar(musica.id);
      } else {
        await widget.salvarUltimoTomExecucao?.executar(musica.id, novoTom);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O tom foi alterado, mas não foi possível lembrá-lo para a próxima abertura.',
            ),
          ),
        );
      }
    }
  }

  void _navegarNaLista(int deslocamento) {
    final contexto = _contextoListaCulto;
    if (contexto == null) return;
    final novoIndice = contexto.indiceAtual + deslocamento;
    if (novoIndice < 0 || novoIndice >= contexto.itens.length) return;
    setState(() {
      _contextoListaCulto = contexto.comIndice(novoIndice);
      _idMusicaAtual = _contextoListaCulto!.itemAtual.idMusica;
      _tomExecucao = null;
      _limparCacheDaVisualizacao();
      _dadosVisualizacao = _carregarDadosVisualizacao();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.jumpTo(0);
      }
    });
  }

  void _iniciarPonteiroDoZoom(PointerDownEvent evento) {
    _ponteirosDoZoom[evento.pointer] = evento.position;
    if (_ponteirosDoZoom.length == 1) {
      _ponteiroDoSwipe = evento.pointer;
      _inicioDoSwipe = evento.position;
      _gestoPossuiMultiplosPonteiros = false;
    } else {
      _gestoPossuiMultiplosPonteiros = true;
      _ponteiroDoSwipe = null;
      _inicioDoSwipe = null;
    }
    if (_ponteirosDoZoom.length == 2) {
      _escalaNoInicioDoZoom = _escalaCifra;
      _distanciaInicialDoZoom = _distanciaEntrePonteiros;
    }
  }

  void _atualizarPonteiroDoZoom(PointerMoveEvent evento) {
    if (!_ponteirosDoZoom.containsKey(evento.pointer)) {
      return;
    }
    _ponteirosDoZoom[evento.pointer] = evento.position;
    final escalaInicial = _escalaNoInicioDoZoom;
    final distanciaInicial = _distanciaInicialDoZoom;
    final distanciaAtual = _distanciaEntrePonteiros;
    if (escalaInicial == null ||
        distanciaInicial == null ||
        distanciaAtual == null ||
        distanciaInicial == 0) {
      return;
    }
    final novaEscala = escalaInicial.aplicarFator(
      distanciaAtual / distanciaInicial,
    );
    if (novaEscala == _escalaCifra) {
      return;
    }
    setState(() => _escalaCifra = novaEscala);
  }

  void _encerrarPonteiroDoZoom(PointerEvent evento) {
    _ponteirosDoZoom.remove(evento.pointer);
    if (_ponteirosDoZoom.length < 2) {
      _escalaNoInicioDoZoom = null;
      _distanciaInicialDoZoom = null;
    }
    if (_ponteirosDoZoom.isEmpty) {
      _gestoPossuiMultiplosPonteiros = false;
    }
  }

  void _encerrarPonteiro(PointerUpEvent evento) {
    _reconhecerSwipe(evento);
    _encerrarPonteiroDoZoom(evento);
  }

  void _cancelarPonteiro(PointerCancelEvent evento) {
    _encerrarPonteiroDoZoom(evento);
  }

  void _reconhecerSwipe(PointerUpEvent evento) {
    final inicio = _inicioDoSwipe;
    if (_contextoListaCulto == null ||
        _gestoPossuiMultiplosPonteiros ||
        _ponteiroDoSwipe != evento.pointer ||
        inicio == null) {
      return;
    }
    final deslocamento = evento.position - inicio;
    final distanciaHorizontal = deslocamento.dx.abs();
    final distanciaVertical = deslocamento.dy.abs();
    if (distanciaHorizontal < _distanciaMinimaDoSwipe ||
        distanciaHorizontal <
            distanciaVertical * _proporcaoMinimaHorizontalDoSwipe) {
      return;
    }
    _navegarNaLista(deslocamento.dx < 0 ? 1 : -1);
  }

  double? get _distanciaEntrePonteiros {
    if (_ponteirosDoZoom.length != 2) {
      return null;
    }
    final posicoes = _ponteirosDoZoom.values.toList(growable: false);
    return (posicoes[0] - posicoes[1]).distance;
  }

  void _redefinirEscalaDaCifra() {
    if (_escalaCifra == EscalaVisualizacaoCifra.padrao) {
      return;
    }
    setState(() => _escalaCifra = EscalaVisualizacaoCifra.padrao);
  }

  void _limparCacheDaVisualizacao() {
    _projecaoEmCache = null;
    _idDaProjecaoEmCache = null;
    _tomDaProjecaoEmCache = null;
    _problemasEmCache = null;
  }

  Future<void> _excluir(Musica musica) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir "${musica.titulo}"?'),
        content: const Text('Esta ação removerá a música da biblioteca.'),
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
    if (confirmar != true || !mounted || _excluindo) return;
    setState(() {
      _excluindo = true;
      _erroExclusao = null;
    });
    try {
      await widget.excluirMusica.executar(musica.id, confirmada: true);
      if (mounted) Navigator.of(context).pop(true);
    } on MusicaNaoEncontrada {
      if (mounted) {
        setState(() {
          _excluindo = false;
          _erroExclusao = 'A música não foi encontrada na biblioteca.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _excluindo = false;
          _erroExclusao = 'Não foi possível excluir a música. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<_DadosVisualizacaoMusica?>(
        future: _dadosVisualizacao,
        builder: (context, resultado) {
          final dadosVisualizacao = resultado.data;
          final musica = dadosVisualizacao?.musica;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cifra'),
              actions: [
                if (resultado.connectionState == ConnectionState.done &&
                    musica != null)
                  IconButton(
                    tooltip: 'Redefinir tamanho da cifra',
                    icon: const Icon(Icons.restart_alt),
                    onPressed: _escalaCifra == EscalaVisualizacaoCifra.padrao
                        ? null
                        : _redefinirEscalaDaCifra,
                  ),
                if (resultado.connectionState == ConnectionState.done &&
                    !resultado.hasError &&
                    musica != null)
                  IconButton(
                    tooltip: 'Editar música',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _excluindo ? null : () => _abrirEdicao(musica),
                  ),
                if (resultado.connectionState == ConnectionState.done &&
                    musica != null)
                  PopupMenuButton<String>(
                    enabled: !_excluindo,
                    onSelected: (_) => _excluir(musica),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
              ],
            ),
            body: switch (resultado.connectionState) {
              ConnectionState.done when resultado.hasError || musica == null =>
                const _EstadoErroMusica(),
              ConnectionState.done => Column(
                children: [
                  if (_excluindo) const LinearProgressIndicator(),
                  if (_erroExclusao != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _erroExclusao!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _ConteudoMusica(
                      projecao: _projecaoAtual(
                        musica!,
                        dadosVisualizacao!.tomInicial,
                      ),
                      problemasTransposicao: _problemasTransposicaoAtuais(
                        musica,
                      ),
                      aoRevisarProblema: (problema) => _abrirEdicao(
                        musica,
                        textoParaLocalizacao: problema.textoOriginal,
                      ),
                      aoDiminuirTom: _excluindo
                          ? null
                          : () => _alterarTom(
                              musica,
                              dadosVisualizacao.tomInicial,
                              -1,
                            ),
                      aoAumentarTom: _excluindo
                          ? null
                          : () => _alterarTom(
                              musica,
                              dadosVisualizacao.tomInicial,
                              1,
                            ),
                      controladorRolagem: _rolagem,
                      escalaCifra: _escalaCifra,
                      aoIniciarPonteiroDoZoom: _iniciarPonteiroDoZoom,
                      aoAtualizarPonteiroDoZoom: _atualizarPonteiroDoZoom,
                      aoEncerrarPonteiro: _encerrarPonteiro,
                      aoCancelarPonteiro: _cancelarPonteiro,
                    ),
                  ),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
            bottomNavigationBar: _contextoListaCulto == null
                ? null
                : _BarraNavegacaoListaCulto(contexto: _contextoListaCulto!),
          );
        },
      );

  Future<_DadosVisualizacaoMusica?> _carregarDadosVisualizacao() async {
    final musica = await widget.obterMusicaPorId.executar(_idMusicaAtual);
    if (musica == null) {
      return null;
    }
    final ultimoTom = await widget.obterUltimoTomExecucao?.executar(musica.id);
    return _DadosVisualizacaoMusica(
      musica: musica,
      tomInicial: ultimoTom ?? musica.tomOriginal,
    );
  }

  ProjecaoMusicaVisualizacao _projecaoAtual(Musica musica, Tom tomInicial) {
    final tomExecucao = _tomExecucao ?? tomInicial;
    final projecaoEmCache = _projecaoEmCache;
    if (projecaoEmCache != null &&
        _idDaProjecaoEmCache == musica.id &&
        _tomDaProjecaoEmCache == tomExecucao) {
      return projecaoEmCache;
    }
    final resultado = _projetarMusica.executar(musica, tomExecucao);
    final projecao = resultado is ProjecaoMusicaVisualizacao
        ? resultado
        : (resultado as TransposicaoVisualizacaoIndisponivel)
              .projecaoNoTomOriginal;
    _projecaoEmCache = projecao;
    _idDaProjecaoEmCache = musica.id;
    _tomDaProjecaoEmCache = tomExecucao;
    return projecao;
  }

  List<AcordeNaoTransponivelVisualizacao> _problemasTransposicaoAtuais(
    Musica musica,
  ) {
    final problemasEmCache = _problemasEmCache;
    if (problemasEmCache != null && _idDaProjecaoEmCache == musica.id) {
      return problemasEmCache;
    }
    final problemas = _projetarMusica.problemasDeTransposicao(musica);
    _problemasEmCache = problemas;
    return problemas;
  }
}

class _DadosVisualizacaoMusica {
  const _DadosVisualizacaoMusica({
    required this.musica,
    required this.tomInicial,
  });

  final Musica musica;
  final Tom tomInicial;
}

class _ConteudoMusica extends StatelessWidget {
  const _ConteudoMusica({
    required this.projecao,
    required this.aoDiminuirTom,
    required this.aoAumentarTom,
    required this.controladorRolagem,
    required this.problemasTransposicao,
    required this.aoRevisarProblema,
    required this.escalaCifra,
    required this.aoIniciarPonteiroDoZoom,
    required this.aoAtualizarPonteiroDoZoom,
    required this.aoEncerrarPonteiro,
    required this.aoCancelarPonteiro,
  });

  final ProjecaoMusicaVisualizacao projecao;
  final VoidCallback? aoDiminuirTom;
  final VoidCallback? aoAumentarTom;
  final ScrollController controladorRolagem;
  final List<AcordeNaoTransponivelVisualizacao> problemasTransposicao;
  final ValueChanged<AcordeNaoTransponivelVisualizacao> aoRevisarProblema;
  final EscalaVisualizacaoCifra escalaCifra;
  final PointerDownEventListener aoIniciarPonteiroDoZoom;
  final PointerMoveEventListener aoAtualizarPonteiroDoZoom;
  final PointerUpEventListener aoEncerrarPonteiro;
  final PointerCancelEventListener aoCancelarPonteiro;

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[];
    var emRefrao = false;
    var indiceLinha = 0;

    for (final elemento in projecao.elementos) {
      if (elemento is InicioRefraoChordPro) {
        emRefrao = true;
        continue;
      }
      if (elemento is FimRefraoChordPro) {
        emRefrao = false;
        continue;
      }
      if (elemento is LinhaChordPro ||
          elemento is LinhaNaoInterpretadaChordPro) {
        linhas.add(
          _LinhaDaMusica(
            key: ValueKey('linha-$indiceLinha'),
            elemento: elemento,
            emRefrao: emRefrao,
            escalaCifra: escalaCifra,
          ),
        );
        indiceLinha += 1;
      }
    }

    return Listener(
      key: const ValueKey('conteudo-cifra'),
      onPointerDown: aoIniciarPonteiroDoZoom,
      onPointerMove: aoAtualizarPonteiroDoZoom,
      onPointerUp: aoEncerrarPonteiro,
      onPointerCancel: aoCancelarPonteiro,
      child: ListView(
        controller: controladorRolagem,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            projecao.titulo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            projecao.artista,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Diminuir tom',
                icon: const Icon(Icons.remove),
                onPressed: aoDiminuirTom,
              ),
              Text(
                'Tom: ${_formatarTom(projecao.tomExecucao)}',
                key: const ValueKey('tom-execucao'),
              ),
              IconButton(
                tooltip: 'Aumentar tom',
                icon: const Icon(Icons.add),
                onPressed: aoAumentarTom,
              ),
            ],
          ),
          if (projecao.tomExecucao != projecao.tomOriginal)
            Text('Original: ${_formatarTom(projecao.tomOriginal)}'),
          if (problemasTransposicao.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AvisoProblemasTransposicao(
              problemas: problemasTransposicao,
              aoRevisar: aoRevisarProblema,
            ),
          ],
          const SizedBox(height: 24),
          ...linhas,
        ],
      ),
    );
  }

  String _formatarTom(Tom tom) =>
      '${tom.notaFundamental}${tom.modo == ModoTom.menor ? ' menor' : ''}';
}

class _AvisoProblemasTransposicao extends StatelessWidget {
  const _AvisoProblemasTransposicao({
    required this.problemas,
    required this.aoRevisar,
  });

  final List<AcordeNaoTransponivelVisualizacao> problemas;
  final ValueChanged<AcordeNaoTransponivelVisualizacao> aoRevisar;

  @override
  Widget build(BuildContext context) {
    final quantidade = problemas.length;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$quantidade ${quantidade == 1 ? 'trecho impede' : 'trechos impedem'} a transposição.',
              ),
            ),
            TextButton(
              key: const ValueKey('revisar-problema-transposicao'),
              onPressed: () => aoRevisar(problemas.first),
              child: const Text('Revisar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraNavegacaoListaCulto extends StatelessWidget {
  const _BarraNavegacaoListaCulto({required this.contexto});

  final ContextoNavegacaoListaCulto contexto;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Center(
          heightFactor: 1,
          child: Text(
            '${contexto.indiceAtual + 1} de ${contexto.itens.length}',
            key: const ValueKey('navegacao-lista-posicao'),
          ),
        ),
      ),
    ),
  );
}

class _LinhaDaMusica extends StatelessWidget {
  const _LinhaDaMusica({
    super.key,
    required this.elemento,
    required this.emRefrao,
    required this.escalaCifra,
  });

  final ElementoDocumentoChordPro elemento;
  final bool emRefrao;
  final EscalaVisualizacaoCifra escalaCifra;

  @override
  Widget build(BuildContext context) {
    final estiloBase = Theme.of(context).textTheme.bodyLarge;
    final estiloLetra = estiloBase?.copyWith(
      fontFamily: 'monospace',
      fontSize: (estiloBase.fontSize ?? 16) * escalaCifra.valor,
    );
    final conteudo = switch (elemento) {
      LinhaChordPro linha when linha.elementos.isEmpty => SizedBox(
        key: const ValueKey('linha-vazia'),
        height: 16 * escalaCifra.valor,
      ),
      LinhaChordPro linha => _LinhaInterpretada(
        linha: linha,
        estiloLetra: estiloLetra,
      ),
      LinhaNaoInterpretadaChordPro linha => Text(
        linha.conteudoOriginal,
        style: estiloLetra,
      ),
      _ => const SizedBox.shrink(),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: emRefrao ? const EdgeInsets.symmetric(horizontal: 8) : null,
      color: emRefrao
          ? Theme.of(context).colorScheme.secondaryContainer
                .withValues(alpha: 0.35)
          : null,
      child: conteudo,
    );
  }
}

class _LinhaInterpretada extends StatelessWidget {
  const _LinhaInterpretada({required this.linha, required this.estiloLetra});

  final LinhaChordPro linha;
  final TextStyle? estiloLetra;

  @override
  Widget build(BuildContext context) {
    final unidades = _criarUnidades(linha);
    return LayoutBuilder(
      builder: (context, constraints) {
        final estiloAcorde = estiloLetra?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        );
        final segmentos = _CompositorLinhaMusical(
          estiloLetra: estiloLetra,
          estiloAcorde: estiloAcorde,
          direcaoTexto: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        ).compor(unidades, constraints.maxWidth);
        return Column(
          key: const ValueKey('linha-musical-responsiva'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var indice = 0; indice < segmentos.length; indice += 1)
              _SegmentoLinhaMusical(
                key: ValueKey('fragmento-$indice'),
                unidades: segmentos[indice],
                estiloLetra: estiloLetra,
                estiloAcorde: estiloAcorde,
              ),
          ],
        );
      },
    );
  }

  List<_UnidadeDaLinha> _criarUnidades(LinhaChordPro linha) {
    final unidades = <_UnidadeDaLinha>[];
    for (final elemento in linha.elementos) {
      switch (elemento) {
        case TextoLinhaChordPro texto:
          if (unidades.isNotEmpty && unidades.last.acorde != null) {
            unidades.last = unidades.last.comTexto(
              '${unidades.last.texto}${texto.conteudoOriginal}',
            );
          } else {
            unidades.add(_UnidadeDaLinha(texto: texto.conteudoOriginal));
          }
        case AcordeLinhaChordPro acorde:
          unidades.add(
            _UnidadeDaLinha(
              acorde: acorde.conteudoOriginal,
              acordeNaoInterpretavel:
                  acorde.resultado is AcordeNaoInterpretavel,
            ),
          );
      }
    }
    return unidades;
  }
}

class _UnidadeDaLinha {
  const _UnidadeDaLinha({
    this.acorde,
    this.texto = '',
    this.acordeNaoInterpretavel = false,
  });

  final String? acorde;
  final String texto;
  final bool acordeNaoInterpretavel;

  _UnidadeDaLinha comTexto(String novoTexto) => _UnidadeDaLinha(
    acorde: acorde,
    texto: novoTexto,
    acordeNaoInterpretavel: acordeNaoInterpretavel,
  );
}

class _UnidadeMusical extends StatelessWidget {
  const _UnidadeMusical({
    required this.unidade,
    required this.estiloLetra,
    required this.estiloAcorde,
  });

  final _UnidadeDaLinha unidade;
  final TextStyle? estiloLetra;
  final TextStyle? estiloAcorde;

  @override
  Widget build(BuildContext context) {
    final estiloDoAcorde = unidade.acordeNaoInterpretavel
        ? estiloAcorde?.copyWith(color: Theme.of(context).colorScheme.error)
        : estiloAcorde;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unidade.acorde != null)
          Text(
            unidade.acorde!,
            style: estiloDoAcorde,
            softWrap: false,
            maxLines: 1,
          )
        else
          Text('', style: estiloLetra),
        Text(unidade.texto, style: estiloLetra),
      ],
    );
  }
}

class _SegmentoLinhaMusical extends StatelessWidget {
  const _SegmentoLinhaMusical({
    super.key,
    required this.unidades,
    required this.estiloLetra,
    required this.estiloAcorde,
  });

  final List<_UnidadeComLargura> unidades;
  final TextStyle? estiloLetra;
  final TextStyle? estiloAcorde;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var indice = 0; indice < unidades.length; indice += 1) ...[
        if (indice > 0) const SizedBox(width: _CompositorLinhaMusical.espaco),
        SizedBox(
          width: unidades[indice].largura,
          child: _UnidadeMusical(
            unidade: unidades[indice].unidade,
            estiloLetra: estiloLetra,
            estiloAcorde: estiloAcorde,
          ),
        ),
      ],
    ],
  );
}

class _UnidadeComLargura {
  const _UnidadeComLargura({
    required this.unidade,
    required this.larguraDesejada,
    required this.largura,
  });

  final _UnidadeDaLinha unidade;
  final double larguraDesejada;
  final double largura;
}

class _CompositorLinhaMusical {
  const _CompositorLinhaMusical({
    required this.estiloLetra,
    required this.estiloAcorde,
    required this.direcaoTexto,
    required this.textScaler,
  });

  static const espaco = 8.0;
  final TextStyle? estiloLetra;
  final TextStyle? estiloAcorde;
  final TextDirection direcaoTexto;
  final TextScaler textScaler;

  List<List<_UnidadeComLargura>> compor(
    List<_UnidadeDaLinha> unidades,
    double larguraDisponivel,
  ) {
    final medidas = unidades.map((unidade) {
      final larguras = _medir(unidade);
      final desejada = larguras.desejada;
      return _UnidadeComLargura(
        unidade: unidade,
        larguraDesejada: desejada,
        largura: desejada <= larguraDisponivel
            ? desejada
            : larguras.minima <= larguraDisponivel
            ? larguraDisponivel
            // Conteúdo atômico maior que a viewport: mantém o limite físico
            // do segmento; o renderer não fragmenta acorde ou palavra.
            : larguraDisponivel,
      );
    }).toList();
    final segmentos = <List<_UnidadeComLargura>>[];
    var atual = <_UnidadeComLargura>[];
    var larguraAtual = 0.0;

    for (final medida in medidas) {
      final larguraComEspaco = atual.isEmpty
          ? medida.larguraDesejada
          : larguraAtual + espaco + medida.larguraDesejada;
      if (atual.isNotEmpty && larguraComEspaco > larguraDisponivel) {
        if (medida.unidade.texto.isEmpty && atual.length > 1) {
          final ultima = atual.last;
          if (ultima.larguraDesejada + espaco + medida.larguraDesejada <=
              larguraDisponivel) {
            atual.removeLast();
            segmentos.add(atual);
            atual = [ultima, medida];
            larguraAtual =
                ultima.larguraDesejada + espaco + medida.larguraDesejada;
            continue;
          }
        }
        segmentos.add(atual);
        atual = [];
        larguraAtual = 0;
      }
      larguraAtual = atual.isEmpty
          ? medida.larguraDesejada
          : larguraAtual + espaco + medida.larguraDesejada;
      atual.add(medida);
    }
    if (atual.isNotEmpty) {
      segmentos.add(atual);
    }
    return segmentos;
  }

  _LargurasUnidade _medir(_UnidadeDaLinha unidade) {
    final larguraAcorde = unidade.acorde == null
        ? 0.0
        : _medirTexto(unidade.acorde!, estiloAcorde);
    final larguraTexto = _medirTexto(unidade.texto, estiloLetra);
    final larguraMaiorPalavra = unidade.texto
        .split(RegExp(r'\s+'))
        .map((palavra) => _medirTexto(palavra, estiloLetra))
        .fold(0.0, (maior, largura) => maior > largura ? maior : largura);
    return _LargurasUnidade(
      minima: larguraAcorde > larguraMaiorPalavra
          ? larguraAcorde
          : larguraMaiorPalavra,
      desejada: larguraAcorde > larguraTexto ? larguraAcorde : larguraTexto,
    );
  }

  double _medirTexto(String texto, TextStyle? estilo) {
    if (texto.isEmpty) {
      return 0;
    }
    final painter = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: direcaoTexto,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }
}

class _LargurasUnidade {
  const _LargurasUnidade({required this.minima, required this.desejada});

  final double minima;
  final double desejada;
}

class _EstadoErroMusica extends StatelessWidget {
  const _EstadoErroMusica();

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
            'Não foi possível carregar a música',
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
