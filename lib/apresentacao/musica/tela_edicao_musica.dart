import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/casos_de_uso/classificacao_musica.dart';
import '../../aplicacao/edicao/criar_secao_chordpro.dart';
import '../../aplicacao/edicao/dividir_bloco_chordpro.dart';
import '../../aplicacao/edicao/duplicar_bloco_chordpro.dart';
import '../../aplicacao/edicao/editar_conteudo_secao_chordpro.dart';
import '../../aplicacao/edicao/editar_trecho_nao_identificado_chordpro.dart';
import '../../aplicacao/edicao/editar_secao_chordpro.dart';
import '../../aplicacao/edicao/excluir_bloco_chordpro.dart';
import '../../aplicacao/edicao/localizador_secao_chordpro.dart';
import '../../aplicacao/edicao/reordenar_secoes_chordpro.dart';
import '../../aplicacao/edicao/selecionar_token_texto.dart';
import '../../aplicacao/edicao/transformar_selecao_chordpro.dart';
import '../../aplicacao/edicao/transformar_secao_chordpro.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/entrada/conteudo_chordpro_editavel.dart';
import '../../aplicacao/entrada/reanalisador_conteudo_chordpro.dart';
import '../../aplicacao/estrutura/estrutura_musica.dart';
import '../../aplicacao/estrutura/reconhecedor_secao_musica.dart';
import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';

class TelaEdicaoMusica extends StatefulWidget {
  const TelaEdicaoMusica({
    super.key,
    required this.musica,
    required this.atualizarMusica,
    this.obterClassificacaoMusica,
    this.salvarClassificacaoMusica,
    this.textoParaLocalizacao,
  });

  final Musica musica;
  final AtualizarMusica atualizarMusica;
  final ObterClassificacaoMusica? obterClassificacaoMusica;
  final SalvarClassificacaoMusica? salvarClassificacaoMusica;
  final String? textoParaLocalizacao;

  @override
  State<TelaEdicaoMusica> createState() => _TelaEdicaoMusicaState();
}

class _TelaEdicaoMusicaState extends State<TelaEdicaoMusica> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _artista;
  late final TextEditingController _tom;
  late final TextEditingController _conteudo;
  final _focoConteudo = FocusNode();
  final _rolagem = ScrollController();
  final _transformarSelecaoChordPro = TransformarSelecaoChordPro();
  final _transformarSecaoChordPro = TransformarSecaoChordPro();
  final _criarSecaoChordPro = CriarSecaoChordPro();
  final _editarConteudoSecaoChordPro = EditarConteudoSecaoChordPro();
  final _editarTrechoNaoIdentificadoChordPro =
      EditarTrechoNaoIdentificadoChordPro();
  final _dividirBlocoChordPro = DividirBlocoChordPro();
  final _editarSecaoChordPro = EditarSecaoChordPro();
  final _duplicarBlocoChordPro = DuplicarBlocoChordPro();
  final _excluirBlocoChordPro = ExcluirBlocoChordPro();
  final _localizadorSecaoChordPro = LocalizadorSecaoChordPro();
  final _reordenarSecoesChordPro = ReordenarSecoesChordPro();
  final _parserDocumento = ParserDocumentoChordPro();
  final _estruturadorDocumento = EstruturadorDocumentoChordPro();
  late final String _tomInicial;
  late _SnapshotEdicaoMusica _snapshotInicial;
  EnergiaMusica? _energia;
  List<TagMusica> _tags = [];
  var _salvando = false;
  var _saidaPermitida = false;
  var _modoEditor = _ModoEditor.estrutural;
  String? _erroTom;
  String? _erroGeral;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.musica.titulo);
    _artista = TextEditingController(text: widget.musica.artista);
    final tom = widget.musica.tomOriginal;
    _tomInicial =
        '${tom.notaFundamental}${tom.modo == ModoTom.menor ? 'm' : ''}';
    _tom = TextEditingController(text: _tomInicial);
    _conteudo = TextEditingController(
      text: ConteudoChordProEditavel.extrair(
        widget.musica.documento.conteudoOriginal,
      ),
    );
    _snapshotInicial = _SnapshotEdicaoMusica(
      titulo: _titulo.text,
      artista: _artista.text,
      tom: _tom.text,
      conteudo: _conteudo.text,
      energia: null,
      tags: const [],
    );
    _titulo.addListener(_atualizarEstadoDoEditor);
    _artista.addListener(_atualizarEstadoDoEditor);
    _tom.addListener(_atualizarEstadoDoEditor);
    _conteudo.addListener(_atualizarEstadoDoEditor);
    _carregarClassificacao();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final texto = widget.textoParaLocalizacao;
      if (texto == null || texto.isEmpty || !mounted) {
        return;
      }
      final indice = _conteudo.text.indexOf('[$texto]');
      if (indice < 0) {
        return;
      }
      _conteudo.selection = TextSelection.collapsed(offset: indice);
      _focoConteudo.requestFocus();
      final linhasAntesDoTrecho = RegExp(r'\r\n|\n|\r')
          .allMatches(_conteudo.text.substring(0, indice))
          .length;
      if (_rolagem.hasClients) {
        final alvo = (224 + linhasAntesDoTrecho * 24.0)
            .clamp(0.0, _rolagem.position.maxScrollExtent)
            .toDouble();
        _rolagem.jumpTo(alvo);
      }
    });
  }

  Future<void> _carregarClassificacao() async {
    final obter = widget.obterClassificacaoMusica;
    if (obter == null) return;
    final classificacao = await obter.executar(widget.musica.id);
    if (!mounted) return;
    setState(() {
      _energia = classificacao.energia;
      _tags = List.of(classificacao.tags);
      final snapshotAnterior = _snapshotInicial;
      _snapshotInicial = _SnapshotEdicaoMusica(
        titulo: snapshotAnterior.titulo,
        artista: snapshotAnterior.artista,
        tom: snapshotAnterior.tom,
        conteudo: snapshotAnterior.conteudo,
        energia: _energia,
        tags: _tags,
      );
    });
  }

  @override
  void dispose() {
    _titulo.removeListener(_atualizarEstadoDoEditor);
    _titulo.dispose();
    _artista.removeListener(_atualizarEstadoDoEditor);
    _artista.dispose();
    _tom.removeListener(_atualizarEstadoDoEditor);
    _tom.dispose();
    _conteudo.removeListener(_atualizarEstadoDoEditor);
    _conteudo.dispose();
    _focoConteudo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _atualizarEstadoDoEditor() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _temAlteracoesPendentes =>
      _titulo.text != _snapshotInicial.titulo ||
      _artista.text != _snapshotInicial.artista ||
      _tom.text != _snapshotInicial.tom ||
      _conteudo.text != _snapshotInicial.conteudo ||
      _energia != _snapshotInicial.energia ||
      !_tagsIguais(_tags, _snapshotInicial.tags);

  bool _tagsIguais(List<TagMusica> atual, List<TagMusica> inicial) =>
      atual.length == inicial.length &&
      atual.every((tag) => inicial.contains(tag));

  Future<void> _adicionarTag() async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogAdicionarTag(),
    );
    if (!mounted || texto == null) return;
    try {
      final tag = TagMusica(texto);
      if (_tags.contains(tag)) return;
      setState(() => _tags = [..._tags, tag]);
    } on ArgumentError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe uma tag válida.')),
        );
      }
    }
  }

  Future<void> _aoTentarSair(bool didPop, Object? _) async {
    if (didPop || _saidaPermitida || _salvando || !_temAlteracoesPendentes) {
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'As alterações feitas nesta música não foram salvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      _sairPermitindoPop();
    }
  }

  void _sairPermitindoPop([bool? resultado]) {
    setState(() => _saidaPermitida = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(resultado);
      }
    });
  }

  SelecaoTextoChordPro get _selecaoDoConteudo {
    final selecao = _conteudo.selection;
    return SelecaoTextoChordPro(inicio: selecao.start, fim: selecao.end);
  }

  bool get _podeMarcarComoSecao => _transformarSecaoChordPro.podeTransformar(
    _conteudo.text,
    _selecaoDoConteudo,
  );

  ContextoEdicaoSecaoChordPro? get _secaoEditavelAtual => _editarSecaoChordPro
      .contextoAtual(conteudo: _conteudo.text, selecao: _selecaoDoConteudo);

  EstruturaMusica get _estruturaAtual => _estruturadorDocumento.estruturar(
    _parserDocumento.interpretar(_conteudo.text),
  );

  void _aplicarAcaoAssistida(
    AcaoSelecaoChordPro acao,
    SelecaoTextoChordPro selecao,
  ) {
    final resultado = switch (acao) {
      AcaoSelecaoChordPro.marcarComoAcorde =>
        _transformarSelecaoChordPro.marcarComoAcorde(_conteudo.text, selecao),
      AcaoSelecaoChordPro.tratarComoTexto =>
        _transformarSelecaoChordPro.tratarComoTexto(_conteudo.text, selecao),
    };
    if (!resultado.foiTransformado) {
      return;
    }
    _atualizarConteudo(resultado.conteudo, resultado.selecao);
  }

  Future<void> _escolherTipoDeSecao() async {
    final tipo = await showModalBottomSheet<TipoSecaoMusica>(
      context: context,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final opcao in _opcoesDeSecao)
                ListTile(
                  title: Text(opcao.titulo),
                  onTap: () => Navigator.pop(context, opcao.tipo),
                ),
            ],
          ),
        ),
      ),
    );
    if (tipo == null || !mounted) {
      return;
    }
    final resultado = _transformarSecaoChordPro.transformar(
      conteudo: _conteudo.text,
      selecao: _selecaoDoConteudo,
      tipo: tipo,
    );
    if (resultado.foiTransformado) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
  }

  Future<void> _editarSecao({SelecaoTextoChordPro? selecao}) async {
    final selecaoAtual = selecao ?? _selecaoDoConteudo;
    final contexto = _editarSecaoChordPro.contextoAtual(
      conteudo: _conteudo.text,
      selecao: selecaoAtual,
    );
    if (contexto == null) {
      return;
    }
    var tipo = contexto.tipo;
    var label = contexto.label ?? '';
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Editar seção', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoSecaoMusica>(
                  key: const ValueKey('tipo-edicao-secao'),
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final opcao in _opcoesDeSecao)
                      DropdownMenuItem(
                        value: opcao.tipo,
                        child: Text(opcao.titulo),
                      ),
                  ],
                  onChanged: (novoTipo) {
                    if (novoTipo != null) {
                      atualizar(() => tipo = novoTipo);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('rotulo-edicao-secao'),
                  initialValue: label,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Rótulo'),
                  onChanged: (novoLabel) => atualizar(() => label = novoLabel),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: label.trim().isEmpty
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (aplicar == true) {
      final resultado = _editarSecaoChordPro.editar(
        conteudo: _conteudo.text,
        selecao: selecaoAtual,
        novoTipo: tipo,
        novoLabel: label,
      );
      if (resultado.foiAlterado) {
        _atualizarConteudo(resultado.conteudo, resultado.selecao);
      }
    }
  }

  Future<void> _editarConteudoSecao(FaixaSecaoChordPro faixa) async {
    final indiceMarcador = faixa.secao.indiceMarcador;
    if (indiceMarcador == null) {
      return;
    }
    final contexto = _editarConteudoSecaoChordPro.contextoAtual(
      conteudo: _conteudo.text,
      indiceMarcador: indiceMarcador,
    );
    if (contexto == null) {
      return;
    }
    final resultadoDaFolha =
        await showModalBottomSheet<_ResultadoFolhaEdicaoConteudoSecao>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FolhaEdicaoConteudoSecao(
            titulo: _tituloDaSecao(faixa.secao),
            conteudoInicial: contexto.conteudoInterno,
            transformarSelecao: _transformarSelecaoChordPro,
          ),
        );
    if (resultadoDaFolha == null || !mounted) {
      return;
    }
    final resultado = _editarConteudoSecaoChordPro.editar(
      conteudo: _conteudo.text,
      indiceMarcador: indiceMarcador,
      novoConteudoInterno: resultadoDaFolha.conteudo,
    );
    if (resultado.foiAlterado) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
    if (resultadoDaFolha.acao == _AcaoEdicaoConteudoSecao.dividir) {
      final faixaAtual = _localizadorSecaoChordPro.localizar(
        conteudo: _conteudo.text,
        indiceMarcador: indiceMarcador,
      );
      if (faixaAtual != null) {
        final divisao = _dividirBlocoChordPro.dividir(
          conteudo: _conteudo.text,
          faixa: FaixaBlocoChordPro.deSecao(faixaAtual),
          posicao: faixaAtual.inicioConteudo + resultadoDaFolha.posicaoCursor,
        );
        if (divisao.foiDividido) {
          _atualizarConteudo(divisao.conteudo, divisao.selecao);
        }
      }
      return;
    }
    if (resultadoDaFolha.acao == _AcaoEdicaoConteudoSecao.editarSecao &&
        mounted) {
      await _editarSecao(selecao: resultado.selecao);
    }
  }

  Future<void> _editarTrechoNaoIdentificado(SecaoMusica trecho) async {
    final contexto = _editarTrechoNaoIdentificadoChordPro.contextoAtual(
      conteudo: _conteudo.text,
      inicioConteudo: trecho.inicioConteudo,
    );
    if (contexto == null) {
      return;
    }
    final resultadoDaFolha =
        await showModalBottomSheet<_ResultadoFolhaEdicaoConteudoSecao>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FolhaEdicaoConteudoSecao(
            titulo: 'Trecho não identificado',
            conteudoInicial: contexto.conteudo,
            transformarSelecao: _transformarSelecaoChordPro,
            podeEditarSecao: false,
          ),
        );
    if (resultadoDaFolha == null || !mounted) {
      return;
    }
    final resultado = _editarTrechoNaoIdentificadoChordPro.editar(
      conteudo: _conteudo.text,
      inicioConteudo: trecho.inicioConteudo,
      novoConteudo: resultadoDaFolha.conteudo,
    );
    if (resultado.foiAlterado) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
    if (resultadoDaFolha.acao == _AcaoEdicaoConteudoSecao.dividir) {
      final contextoAtual = _editarTrechoNaoIdentificadoChordPro.contextoAtual(
        conteudo: _conteudo.text,
        inicioConteudo: trecho.inicioConteudo,
      );
      if (contextoAtual != null) {
        final divisao = _dividirBlocoChordPro.dividir(
          conteudo: _conteudo.text,
          faixa: FaixaBlocoChordPro(
            bloco: trecho,
            inicio: contextoAtual.faixa.inicio,
            fim: contextoAtual.faixa.fim,
            fimComSeparador: contextoAtual.faixa.fimComSeparador,
          ),
          posicao: contextoAtual.faixa.inicio + resultadoDaFolha.posicaoCursor,
        );
        if (divisao.foiDividido) {
          _atualizarConteudo(divisao.conteudo, divisao.selecao);
        }
      }
    }
  }

  void _atualizarConteudo(String conteudo, SelecaoTextoChordPro selecao) {
    _conteudo.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection(
        baseOffset: selecao.inicio,
        extentOffset: selecao.fim,
      ),
    );
    if (_modoEditor == _ModoEditor.textual) {
      _focoConteudo.requestFocus();
    }
  }

  void _duplicarBloco(FaixaBlocoChordPro faixa) {
    final resultado = _duplicarBlocoChordPro.duplicar(
      conteudo: _conteudo.text,
      faixa: faixa,
    );
    if (resultado.foiDuplicado) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
  }

  Future<void> _adicionarSecao() async {
    var tipo = TipoSecaoMusica.verso;
    var label = _labelSugeridoParaNovoTipo(tipo);
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Adicionar seção', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                DropdownButtonFormField<TipoSecaoMusica>(
                  key: const ValueKey('tipo-nova-secao'),
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final opcao in _opcoesDeSecao)
                      DropdownMenuItem(
                        value: opcao.tipo,
                        child: Text(opcao.titulo),
                      ),
                  ],
                  onChanged: (novoTipo) {
                    if (novoTipo == null) {
                      return;
                    }
                    final labelEraSugestao =
                        label == _labelSugeridoParaNovoTipo(tipo);
                    atualizar(() {
                      tipo = novoTipo;
                      if (labelEraSugestao) {
                        label = _labelSugeridoParaNovoTipo(tipo);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey('rotulo-nova-secao-$tipo'),
                  initialValue: label,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Rótulo'),
                  onChanged: (novoLabel) => atualizar(() => label = novoLabel),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: label.trim().isEmpty
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (aplicar != true || !mounted) {
      return;
    }
    final resultado = _criarSecaoChordPro.criar(
      conteudo: _conteudo.text,
      tipo: tipo,
      label: label,
    );
    if (resultado.foiCriada) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
  }

  void _reordenarSecoes(int indiceOrigem, int indiceDestino) {
    final resultado = _reordenarSecoesChordPro.reordenar(
      conteudo: _conteudo.text,
      indiceOrigem: indiceOrigem,
      indiceDestino: indiceDestino,
    );
    if (resultado.foiReordenada) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
  }

  Future<void> _confirmarExclusaoBloco(
    FaixaBlocoChordPro faixa, {
    required String titulo,
    required bool ehTrechoNaoIdentificado,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ehTrechoNaoIdentificado
              ? 'Excluir trecho não identificado?'
              : 'Excluir "$titulo"?',
        ),
        content: const Text('O bloco e todo o seu conteúdo serão removidos.'),
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
    if (confirmar != true || !mounted) {
      return;
    }
    final resultado = _excluirBlocoChordPro.excluir(
      conteudo: _conteudo.text,
      faixa: faixa,
    );
    if (resultado.foiExcluido) {
      _atualizarConteudo(resultado.conteudo, resultado.selecao);
    }
  }

  SelecaoTextoChordPro _selecaoDoMarcador(int indiceMarcador) {
    var inicio = 0;
    var indice = 0;
    for (final separador in RegExp(r'\r\n|\n|\r').allMatches(_conteudo.text)) {
      if (indice == indiceMarcador) {
        return SelecaoTextoChordPro(inicio: inicio, fim: inicio);
      }
      inicio = separador.end;
      indice += 1;
    }
    return SelecaoTextoChordPro(inicio: inicio, fim: inicio);
  }

  String _tituloDaSecao(SecaoMusica secao) {
    final rotulo = secao.rotuloOriginal;
    if (rotulo != null && !rotulo.startsWith('{')) {
      return rotulo;
    }
    return _tituloDoTipo(secao.tipo);
  }

  String _tituloParaExclusao(SecaoMusica secao) {
    final titulo = _tituloDaSecao(secao);
    if (titulo.startsWith('[') && titulo.endsWith(']')) {
      return titulo.substring(1, titulo.length - 1).trim();
    }
    return titulo;
  }

  String _tituloDoTipo(TipoSecaoMusica tipo) =>
      _opcoesDeSecao.firstWhere((opcao) => opcao.tipo == tipo).titulo;

  String _labelSugeridoParaNovoTipo(TipoSecaoMusica tipo) =>
      tipo == TipoSecaoMusica.outro ? 'Seção' : _tituloDoTipo(tipo);

  String _previaDaSecao(SecaoMusica secao) {
    final linhas = secao.elementos
        .where(_ehConteudoRelevanteNaPrevia)
        .map((elemento) => elemento.conteudoOriginal.trim())
        .where((linha) => linha.isNotEmpty)
        .take(2)
        .toList();
    final previa = linhas.join(' · ');
    return previa.length <= 96 ? previa : '${previa.substring(0, 93)}...';
  }

  bool _ehConteudoRelevanteNaPrevia(ElementoDocumentoChordPro elemento) =>
      elemento is LinhaChordPro || elemento is LinhaNaoInterpretadaChordPro;

  String? _obrigatorio(String? valor, String nome) =>
      valor == null || valor.trim().isEmpty ? '$nome é obrigatório.' : null;

  Future<void> _salvar() async {
    if (_salvando) {
      return;
    }
    setState(() {
      _erroTom = null;
      _erroGeral = null;
    });
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.atualizarMusica.executar(
        DadosAtualizacaoMusica(
          id: widget.musica.id,
          conteudoChordPro: _conteudo.text,
          revisaoMetadados: RevisaoMetadadosChordPro(
            titulo: _titulo.text == widget.musica.titulo ? null : _titulo.text,
            artista: _artista.text == widget.musica.artista
                ? null
                : _artista.text,
            tom: _tom.text == _tomInicial ? null : _tom.text,
          ),
        ),
      );
      await widget.salvarClassificacaoMusica?.executar(
        widget.musica.id,
        energia: _energia,
        tags: _tags,
      );
      if (mounted) _sairPermitindoPop(true);
    } on RascunhoNaoPodeSerFinalizado catch (erro) {
      if (!mounted) {
        return;
      }
      setState(() {
        _salvando = false;
        _erroTom = erro.campos.contains(CampoMetadadoRascunho.tom)
            ? 'Tom original inválido.'
            : null;
        _erroGeral = _erroTom == null
            ? 'Corrija os metadados obrigatórios do documento.'
            : null;
      });
    } on ArgumentError catch (erro) {
      if (!mounted) {
        return;
      }
      setState(() {
        _salvando = false;
        _erroTom = erro.toString().contains('tom original')
            ? 'Tom original inválido.'
            : null;
        _erroGeral = _erroTom == null
            ? 'O conteúdo não formou uma música válida.'
            : null;
      });
    } on MusicaNaoEncontrada {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroGeral = 'A música não foi encontrada na biblioteca.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroGeral =
              'Não foi possível salvar as alterações. Tente novamente.';
        });
      }
    }
  }

  Future<void> _analisarAlteracoes() async {
    final resultado = ReanalisadorConteudoChordPro().analisar(_conteudo.text);
    if (resultado.chordProSugerido == _conteudo.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma conversão necessária.')),
      );
      return;
    }
    final aplicar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aplicar conversão?'),
        content: SingleChildScrollView(
          child: SelectableText(resultado.chordProSugerido),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar alterações'),
          ),
        ],
      ),
    );
    if (aplicar == true && mounted) {
      setState(() => _conteudo.text = resultado.chordProSugerido);
    }
  }

  Widget _editorEstrutural() {
    final secoes = _estruturaAtual.secoes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Seções da música',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _reordenarSecoes,
          children: [
            for (var indice = 0; indice < secoes.length; indice += 1)
              _blocoDaSecao(secoes[indice], indice),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('adicionar-secao'),
          onPressed: _salvando ? null : _adicionarSecao,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar seção'),
        ),
      ],
    );
  }

  Widget _blocoDaSecao(SecaoMusica secao, int indice) {
    final indiceMarcador = secao.indiceMarcador;
    final faixa = indiceMarcador == null
        ? null
        : _localizadorSecaoChordPro.localizar(
            conteudo: _conteudo.text,
            indiceMarcador: indiceMarcador,
          );
    final ehExplicita = indiceMarcador != null;
    final trechoNaoIdentificado = faixa == null
        ? _localizadorSecaoChordPro.localizarTrechoNaoIdentificado(
            conteudo: _conteudo.text,
            inicioConteudo: secao.inicioConteudo,
          )
        : null;
    final faixaSegura = _localizadorSecaoChordPro.localizarBlocoSeguro(
      conteudo: _conteudo.text,
      secao: secao,
    );
    final podeMover = faixaSegura != null;
    final titulo = ehExplicita
        ? _tituloDaSecao(secao)
        : 'Trecho não identificado';
    final previa = _previaDaSecao(secao);
    return Card(
      key: ValueKey(
        ehExplicita
            ? 'bloco-secao-$indiceMarcador'
            : 'bloco-trecho-${secao.inicioConteudo}',
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _salvando
            ? null
            : faixa != null
            ? () => _editarConteudoSecao(faixa)
            : trechoNaoIdentificado != null
            ? () => _editarTrechoNaoIdentificado(secao)
            : ehExplicita
            ? () => _editarSecao(selecao: _selecaoDoMarcador(indiceMarcador))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (podeMover)
                ReorderableDragStartListener(
                  key: ValueKey(
                    'arrastar-bloco-${indiceMarcador ?? secao.inicioConteudo}',
                  ),
                  index: indice,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: 'Arrastar bloco',
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 16)),
                    if (!ehExplicita)
                      Text(
                        'Parte ainda não classificada.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (ehExplicita && titulo != _tituloDoTipo(secao.tipo))
                      Text(
                        _tituloDoTipo(secao.tipo),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (previa.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        previa,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (faixaSegura != null)
                PopupMenuButton<_AcaoBloco>(
                  key: ValueKey(
                    'acoes-bloco-${indiceMarcador ?? secao.inicioConteudo}',
                  ),
                  tooltip: 'Ações do bloco',
                  onSelected: (acao) {
                    switch (acao) {
                      case _AcaoBloco.duplicar:
                        _duplicarBloco(faixaSegura);
                      case _AcaoBloco.excluir:
                        _confirmarExclusaoBloco(
                          faixaSegura,
                          titulo: _tituloParaExclusao(secao),
                          ehTrechoNaoIdentificado: !ehExplicita,
                        );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _AcaoBloco.duplicar,
                      child: Text('Duplicar'),
                    ),
                    PopupMenuItem(
                      value: _AcaoBloco.excluir,
                      child: Text('Excluir'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _saidaPermitida || !_temAlteracoesPendentes,
      onPopInvokedWithResult: _aoTentarSair,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar música'),
          actions: [
            if (_modoEditor == _ModoEditor.textual && _podeMarcarComoSecao)
              IconButton(
                key: const ValueKey('acao-assistida-secao'),
                onPressed: _salvando ? null : _escolherTipoDeSecao,
                icon: const Icon(Icons.view_agenda_outlined),
                tooltip: 'Marcar como seção',
              ),
            if (_modoEditor == _ModoEditor.textual &&
                _secaoEditavelAtual != null)
              IconButton(
                key: const ValueKey('acao-assistida-editar-secao'),
                onPressed: _salvando ? null : _editarSecao,
                icon: const Icon(Icons.edit_note_outlined),
                tooltip: 'Editar seção',
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formulario,
            child: SingleChildScrollView(
              controller: _rolagem,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titulo,
                    enabled: !_salvando,
                    decoration: const InputDecoration(labelText: 'Título'),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => _obrigatorio(valor, 'Título'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _artista,
                    enabled: !_salvando,
                    decoration: const InputDecoration(labelText: 'Artista'),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => _obrigatorio(valor, 'Artista'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tom,
                    enabled: !_salvando,
                    decoration: InputDecoration(
                      labelText: 'Tom original',
                      hintText: 'Ex.: C, Eb, F# ou Am',
                      errorText: _erroTom,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => _obrigatorio(valor, 'Tom original'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Energia',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<EnergiaMusica>(
                    key: const ValueKey('energia-musica'),
                    emptySelectionAllowed: true,
                    segments: [
                      for (final energia in EnergiaMusica.values)
                        ButtonSegment(
                          value: energia,
                          label: Text(energia.titulo),
                        ),
                    ],
                    selected: _energia == null ? {} : {_energia!},
                    onSelectionChanged: _salvando
                        ? null
                        : (selecionadas) => setState(
                            () => _energia = selecionadas.isEmpty
                                ? null
                                : selecionadas.single,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _tags)
                        InputChip(
                          label: Text(tag.valor),
                          onDeleted: _salvando
                              ? null
                              : () => setState(() => _tags.remove(tag)),
                        ),
                      ActionChip(
                        label: const Text('Adicionar tag'),
                        onPressed: _salvando ? null : _adicionarTag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_ModoEditor>(
                    key: const ValueKey('modo-editor-musica'),
                    segments: const [
                      ButtonSegment(
                        value: _ModoEditor.estrutural,
                        icon: Icon(Icons.view_agenda_outlined),
                        label: Text('Blocos'),
                      ),
                      ButtonSegment(
                        value: _ModoEditor.textual,
                        icon: Icon(Icons.code_outlined),
                        label: Text('ChordPro avançado'),
                      ),
                    ],
                    selected: {_modoEditor},
                    onSelectionChanged: _salvando
                        ? null
                        : (selecionados) {
                            setState(() => _modoEditor = selecionados.first);
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_modoEditor == _ModoEditor.estrutural)
                    _editorEstrutural()
                  else ...[
                    _CampoComSelecaoAutomatica(
                      controlador: _conteudo,
                      child: TextFormField(
                        key: const ValueKey('conteudo-edicao'),
                        controller: _conteudo,
                        focusNode: _focoConteudo,
                        enabled: !_salvando,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          labelText: 'Conteúdo ChordPro',
                        ),
                        keyboardType: TextInputType.multiline,
                        minLines: 12,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        contextMenuBuilder: (context, editableTextState) =>
                            _menuContextualComAcaoChordPro(
                              editableTextState: editableTextState,
                              transformarSelecao: _transformarSelecaoChordPro,
                              aoAplicar: _aplicarAcaoAssistida,
                            ),
                        validator: (valor) =>
                            _obrigatorio(valor, 'Conteúdo ChordPro'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _salvando ? null : _analisarAlteracoes,
                      child: const Text('Analisar alterações'),
                    ),
                  ],
                  if (_erroGeral != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erroGeral!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar alterações'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAdicionarTag extends StatefulWidget {
  const _DialogAdicionarTag();

  @override
  State<_DialogAdicionarTag> createState() => _DialogAdicionarTagState();
}

class _DialogAdicionarTagState extends State<_DialogAdicionarTag> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar tag'),
    content: TextField(
      key: const ValueKey('nova-tag-musica'),
      controller: _controlador,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _confirmar(),
      decoration: const InputDecoration(hintText: 'Ex.: congregacional'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _confirmar, child: const Text('Adicionar')),
    ],
  );

  void _confirmar() => Navigator.pop(context, _controlador.text);
}

class _SnapshotEdicaoMusica {
  const _SnapshotEdicaoMusica({
    required this.titulo,
    required this.artista,
    required this.tom,
    required this.conteudo,
    required this.energia,
    required this.tags,
  });

  final String titulo;
  final String artista;
  final String tom;
  final String conteudo;
  final EnergiaMusica? energia;
  final List<TagMusica> tags;
}

const _opcoesDeSecao = [
  _OpcaoDeSecao(TipoSecaoMusica.intro, 'Intro'),
  _OpcaoDeSecao(TipoSecaoMusica.verso, 'Verso'),
  _OpcaoDeSecao(TipoSecaoMusica.preRefrao, 'Pré-Refrão'),
  _OpcaoDeSecao(TipoSecaoMusica.refrao, 'Refrão'),
  _OpcaoDeSecao(TipoSecaoMusica.ponte, 'Ponte'),
  _OpcaoDeSecao(TipoSecaoMusica.instrumental, 'Instrumental'),
  _OpcaoDeSecao(TipoSecaoMusica.solo, 'Solo'),
  _OpcaoDeSecao(TipoSecaoMusica.encerramento, 'Final'),
  _OpcaoDeSecao(TipoSecaoMusica.outro, 'Outro'),
];

enum _ModoEditor { estrutural, textual }

enum _AcaoBloco { duplicar, excluir }

enum _AcaoEdicaoConteudoSecao { aplicar, editarSecao, dividir }

class _ResultadoFolhaEdicaoConteudoSecao {
  const _ResultadoFolhaEdicaoConteudoSecao({
    required this.acao,
    required this.conteudo,
    required this.posicaoCursor,
  });

  final _AcaoEdicaoConteudoSecao acao;
  final String conteudo;
  final int posicaoCursor;
}

class _FolhaEdicaoConteudoSecao extends StatefulWidget {
  const _FolhaEdicaoConteudoSecao({
    required this.titulo,
    required this.conteudoInicial,
    required this.transformarSelecao,
    this.podeEditarSecao = true,
  });

  final String titulo;
  final String conteudoInicial;
  final TransformarSelecaoChordPro transformarSelecao;
  final bool podeEditarSecao;

  @override
  State<_FolhaEdicaoConteudoSecao> createState() =>
      _FolhaEdicaoConteudoSecaoState();
}

class _FolhaEdicaoConteudoSecaoState extends State<_FolhaEdicaoConteudoSecao> {
  late final TextEditingController _conteudo;
  var _saidaPermitida = false;

  bool get _temAlteracoesPendentes => _conteudo.text != widget.conteudoInicial;

  @override
  void initState() {
    super.initState();
    _conteudo = TextEditingController(text: widget.conteudoInicial);
    _conteudo.addListener(_atualizarAcoes);
  }

  @override
  void dispose() {
    _conteudo.removeListener(_atualizarAcoes);
    _conteudo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PopScope<_ResultadoFolhaEdicaoConteudoSecao>(
        canPop: _saidaPermitida || !_temAlteracoesPendentes,
        onPopInvokedWithResult: _aoTentarSair,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.titulo, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                _CampoComSelecaoAutomatica(
                  controlador: _conteudo,
                  child: TextFormField(
                    key: const ValueKey('conteudo-edicao-secao'),
                    controller: _conteudo,
                    minLines: 8,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    contextMenuBuilder: (context, editableTextState) =>
                        _menuContextualComAcaoChordPro(
                          editableTextState: editableTextState,
                          transformarSelecao: widget.transformarSelecao,
                          aoAplicar: _aplicarAcaoAssistida,
                        ),
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo da seção',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _cancelar,
                      child: const Text('Cancelar'),
                    ),
                    if (widget.podeEditarSecao) ...[
                      OutlinedButton(
                        onPressed: () =>
                            _concluir(_AcaoEdicaoConteudoSecao.editarSecao),
                        child: const Text('Editar seção'),
                      ),
                    ],
                    if (_podeDividir) ...[
                      OutlinedButton(
                        onPressed: () =>
                            _concluir(_AcaoEdicaoConteudoSecao.dividir),
                        child: const Text('Dividir bloco aqui'),
                      ),
                    ],
                    FilledButton(
                      onPressed: () =>
                          _concluir(_AcaoEdicaoConteudoSecao.aplicar),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _aoTentarSair(
    bool didPop,
    _ResultadoFolhaEdicaoConteudoSecao? _,
  ) async {
    if (didPop || _saidaPermitida || !_temAlteracoesPendentes) {
      return;
    }
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'As alterações feitas neste bloco não foram aplicadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      _fecharPermitindoPop();
    }
  }

  void _cancelar() {
    if (_temAlteracoesPendentes) {
      _aoTentarSair(false, null);
      return;
    }
    Navigator.pop(context);
  }

  void _concluir(_AcaoEdicaoConteudoSecao acao) {
    _fecharPermitindoPop(
      _ResultadoFolhaEdicaoConteudoSecao(
        acao: acao,
        conteudo: _conteudo.text,
        posicaoCursor: _conteudo.selection.extentOffset,
      ),
    );
  }

  bool get _podeDividir {
    final posicao = _conteudo.selection.extentOffset;
    if (posicao <= 0 || posicao >= _conteudo.text.length) return false;
    var inicioDaLinha = posicao;
    while (inicioDaLinha > 0) {
      final anterior = _conteudo.text.codeUnitAt(inicioDaLinha - 1);
      if (anterior == 10 || anterior == 13) break;
      inicioDaLinha -= 1;
    }
    return inicioDaLinha > 0 &&
        _conteudo.text.substring(0, inicioDaLinha).trim().isNotEmpty &&
        _conteudo.text.substring(inicioDaLinha).trim().isNotEmpty;
  }

  void _fecharPermitindoPop([_ResultadoFolhaEdicaoConteudoSecao? resultado]) {
    setState(() => _saidaPermitida = true);
    Navigator.pop(context, resultado);
  }

  void _atualizarAcoes() {
    if (mounted) {
      setState(() {});
    }
  }

  void _aplicarAcaoAssistida(
    AcaoSelecaoChordPro acao,
    SelecaoTextoChordPro selecao,
  ) {
    final resultado = switch (acao) {
      AcaoSelecaoChordPro.marcarComoAcorde =>
        widget.transformarSelecao.marcarComoAcorde(_conteudo.text, selecao),
      AcaoSelecaoChordPro.tratarComoTexto =>
        widget.transformarSelecao.tratarComoTexto(_conteudo.text, selecao),
    };
    if (!resultado.foiTransformado) {
      return;
    }
    _conteudo.value = TextEditingValue(
      text: resultado.conteudo,
      selection: TextSelection(
        baseOffset: resultado.selecao.inicio,
        extentOffset: resultado.selecao.fim,
      ),
    );
  }
}

class _CampoComSelecaoAutomatica extends StatefulWidget {
  const _CampoComSelecaoAutomatica({
    required this.controlador,
    required this.child,
  });

  final TextEditingController controlador;
  final Widget child;

  @override
  State<_CampoComSelecaoAutomatica> createState() =>
      _CampoComSelecaoAutomaticaState();
}

class _CampoComSelecaoAutomaticaState
    extends State<_CampoComSelecaoAutomatica> {
  static const _duracaoMaximaDoToque = Duration(milliseconds: 300);
  static const _deslocamentoMaximoDoToque = 12.0;

  final _seletor = SelecionarTokenTexto();
  final Map<int, _ToquePendente> _toques = {};

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _registrarToque,
    onPointerMove: _registrarMovimento,
    onPointerUp: _concluirToque,
    onPointerCancel: (evento) => _toques.remove(evento.pointer),
    child: widget.child,
  );

  void _registrarToque(PointerDownEvent evento) {
    _toques[evento.pointer] = _ToquePendente(
      posicaoInicial: evento.position,
      instanteInicial: evento.timeStamp,
    );
  }

  void _registrarMovimento(PointerMoveEvent evento) {
    final toque = _toques[evento.pointer];
    if (toque == null) {
      return;
    }
    if ((evento.position - toque.posicaoInicial).distance >
        _deslocamentoMaximoDoToque) {
      toque.moveu = true;
    }
  }

  void _concluirToque(PointerUpEvent evento) {
    final toque = _toques.remove(evento.pointer);
    if (toque == null ||
        toque.moveu ||
        evento.timeStamp - toque.instanteInicial > _duracaoMaximaDoToque) {
      return;
    }
    final render = _encontrarRenderEditable();
    if (render == null) {
      return;
    }
    final offset = _offsetDoCaractereTocado(render, evento.position);
    if (offset == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final faixa = _seletor.localizar(
        texto: widget.controlador.text,
        offset: offset,
      );
      if (faixa == null) {
        return;
      }
      widget.controlador.selection = TextSelection(
        baseOffset: faixa.inicio,
        extentOffset: faixa.fim,
      );
      _encontrarEstadoEditable()?.showToolbar();
    });
  }

  EditableTextState? _encontrarEstadoEditable() {
    EditableTextState? encontrado;

    void visitar(Element elemento) {
      if (encontrado != null) {
        return;
      }
      if (elemento is StatefulElement && elemento.state is EditableTextState) {
        encontrado = elemento.state as EditableTextState;
        return;
      }
      elemento.visitChildren(visitar);
    }

    context.visitChildElements(visitar);
    return encontrado;
  }

  RenderEditable? _encontrarRenderEditable() {
    RenderEditable? encontrado;

    void visitar(RenderObject objeto) {
      if (encontrado != null) {
        return;
      }
      if (objeto is RenderEditable) {
        encontrado = objeto;
        return;
      }
      objeto.visitChildren(visitar);
    }

    final raiz = context.findRenderObject();
    if (raiz != null) {
      visitar(raiz);
    }
    return encontrado;
  }

  int? _offsetDoCaractereTocado(RenderEditable render, Offset posicaoGlobal) {
    final texto = widget.controlador.text;
    final posicaoDoTexto = render.getPositionForPoint(posicaoGlobal);
    final posicaoLocal = render.globalToLocal(posicaoGlobal);
    for (final candidato in [
      posicaoDoTexto.offset,
      posicaoDoTexto.offset - 1,
    ]) {
      if (candidato < 0 || candidato >= texto.length) {
        continue;
      }
      final caixas = render.getBoxesForSelection(
        TextSelection(baseOffset: candidato, extentOffset: candidato + 1),
      );
      if (caixas.any((caixa) => caixa.toRect().contains(posicaoLocal))) {
        return candidato;
      }
    }
    return null;
  }
}

class _ToquePendente {
  _ToquePendente({required this.posicaoInicial, required this.instanteInicial});

  final Offset posicaoInicial;
  final Duration instanteInicial;
  var moveu = false;
}

Widget _menuContextualComAcaoChordPro({
  required EditableTextState editableTextState,
  required TransformarSelecaoChordPro transformarSelecao,
  required void Function(AcaoSelecaoChordPro, SelecaoTextoChordPro) aoAplicar,
}) {
  final valor = editableTextState.textEditingValue;
  final selecao = SelecaoTextoChordPro(
    inicio: valor.selection.start,
    fim: valor.selection.end,
  );
  final acao = transformarSelecao.acaoDisponivel(valor.text, selecao);
  final itens = <ContextMenuButtonItem>[
    ...editableTextState.contextMenuButtonItems,
    if (acao != null)
      ContextMenuButtonItem(
        label: acao == AcaoSelecaoChordPro.marcarComoAcorde
            ? 'Marcar como acorde'
            : 'Tratar como texto',
        onPressed: () {
          aoAplicar(acao, selecao);
          ContextMenuController.removeAny();
        },
      ),
  ];
  return AdaptiveTextSelectionToolbar.buttonItems(
    buttonItems: itens,
    anchors: editableTextState.contextMenuAnchors,
  );
}

class _OpcaoDeSecao {
  const _OpcaoDeSecao(this.tipo, this.titulo);

  final TipoSecaoMusica tipo;
  final String titulo;
}
