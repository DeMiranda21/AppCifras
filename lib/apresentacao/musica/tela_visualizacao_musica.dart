import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import 'tela_edicao_musica.dart';

class TelaVisualizacaoMusica extends StatefulWidget {
  const TelaVisualizacaoMusica({
    super.key,
    required this.idMusica,
    required this.obterMusicaPorId,
    required this.atualizarMusica,
    required this.excluirMusica,
  });

  final IdMusica idMusica;
  final ObterMusicaPorId obterMusicaPorId;
  final AtualizarMusica atualizarMusica;
  final ExcluirMusica excluirMusica;

  @override
  State<TelaVisualizacaoMusica> createState() => _TelaVisualizacaoMusicaState();
}

class _TelaVisualizacaoMusicaState extends State<TelaVisualizacaoMusica> {
  late Future<Musica?> _musica;
  var _excluindo = false;
  String? _erroExclusao;

  @override
  void initState() {
    super.initState();
    _musica = widget.obterMusicaPorId.executar(widget.idMusica);
  }

  Future<void> _abrirEdicao(Musica musica) async {
    final alterada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => TelaEdicaoMusica(
          musica: musica,
          atualizarMusica: widget.atualizarMusica,
        ),
      ),
    );
    if (alterada == true && mounted) {
      final musicaAtualizada = widget.obterMusicaPorId.executar(
        widget.idMusica,
      );
      setState(() {
        _musica = musicaAtualizada;
      });
    }
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
  Widget build(BuildContext context) => FutureBuilder<Musica?>(
    future: _musica,
    builder: (context, resultado) {
      final musica = resultado.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cifra'),
          actions: [
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
              Expanded(child: _ConteudoMusica(musica: musica!)),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      );
    },
  );
}

class _ConteudoMusica extends StatelessWidget {
  const _ConteudoMusica({required this.musica});

  final Musica musica;

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[];
    var emRefrao = false;
    var indiceLinha = 0;

    for (final elemento in musica.documento.elementos) {
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
          ),
        );
        indiceLinha += 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(musica.titulo, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(musica.artista, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tom original: ${_formatarTom(musica.tomOriginal)}'),
        const SizedBox(height: 24),
        ...linhas,
      ],
    );
  }

  String _formatarTom(Tom tom) =>
      '${tom.notaFundamental}${tom.modo == ModoTom.menor ? ' menor' : ''}';
}

class _LinhaDaMusica extends StatelessWidget {
  const _LinhaDaMusica({
    super.key,
    required this.elemento,
    required this.emRefrao,
  });

  final ElementoDocumentoChordPro elemento;
  final bool emRefrao;

  @override
  Widget build(BuildContext context) {
    final estiloLetra = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontFamily: 'monospace');
    final conteudo = switch (elemento) {
      LinhaChordPro linha when linha.elementos.isEmpty => SizedBox(
        key: const ValueKey('linha-vazia'),
        height: 16,
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
          unidades.add(_UnidadeDaLinha(acorde: acorde.conteudoOriginal));
      }
    }
    return unidades;
  }
}

class _UnidadeDaLinha {
  const _UnidadeDaLinha({this.acorde, this.texto = ''});

  final String? acorde;
  final String texto;

  _UnidadeDaLinha comTexto(String novoTexto) =>
      _UnidadeDaLinha(acorde: acorde, texto: novoTexto);
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (unidade.acorde != null)
        Text(unidade.acorde!, style: estiloAcorde, softWrap: false, maxLines: 1)
      else
        Text('', style: estiloLetra),
      Text(unidade.texto, style: estiloLetra),
    ],
  );
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
