import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/edicao/duplicar_secao_chordpro.dart';
import '../../aplicacao/edicao/editar_secao_chordpro.dart';
import '../../aplicacao/edicao/excluir_secao_chordpro.dart';
import '../../aplicacao/edicao/localizador_secao_chordpro.dart';
import '../../aplicacao/edicao/reordenar_secoes_chordpro.dart';
import '../../aplicacao/edicao/transformar_selecao_chordpro.dart';
import '../../aplicacao/edicao/transformar_secao_chordpro.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/entrada/conteudo_chordpro_editavel.dart';
import '../../aplicacao/entrada/reanalisador_conteudo_chordpro.dart';
import '../../aplicacao/estrutura/estrutura_musica.dart';
import '../../aplicacao/estrutura/reconhecedor_secao_musica.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';

class TelaEdicaoMusica extends StatefulWidget {
  const TelaEdicaoMusica({
    super.key,
    required this.musica,
    required this.atualizarMusica,
    this.textoParaLocalizacao,
  });

  final Musica musica;
  final AtualizarMusica atualizarMusica;
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
  final _editarSecaoChordPro = EditarSecaoChordPro();
  final _duplicarSecaoChordPro = DuplicarSecaoChordPro();
  final _excluirSecaoChordPro = ExcluirSecaoChordPro();
  final _localizadorSecaoChordPro = LocalizadorSecaoChordPro();
  final _reordenarSecoesChordPro = ReordenarSecoesChordPro();
  final _parserDocumento = ParserDocumentoChordPro();
  final _estruturadorDocumento = EstruturadorDocumentoChordPro();
  late final String _tomInicial;
  var _salvando = false;
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
    _conteudo.addListener(_atualizarAcaoAssistida);
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

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _tom.dispose();
    _conteudo.removeListener(_atualizarAcaoAssistida);
    _conteudo.dispose();
    _focoConteudo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _atualizarAcaoAssistida() {
    if (mounted) {
      setState(() {});
    }
  }

  SelecaoTextoChordPro get _selecaoDoConteudo {
    final selecao = _conteudo.selection;
    return SelecaoTextoChordPro(inicio: selecao.start, fim: selecao.end);
  }

  AcaoSelecaoChordPro? get _acaoAssistidaDisponivel =>
      _transformarSelecaoChordPro.acaoDisponivel(
        _conteudo.text,
        _selecaoDoConteudo,
      );

  bool get _podeMarcarComoSecao => _transformarSecaoChordPro.podeTransformar(
    _conteudo.text,
    _selecaoDoConteudo,
  );

  ContextoEdicaoSecaoChordPro? get _secaoEditavelAtual => _editarSecaoChordPro
      .contextoAtual(conteudo: _conteudo.text, selecao: _selecaoDoConteudo);

  EstruturaMusica get _estruturaAtual => _estruturadorDocumento.estruturar(
    _parserDocumento.interpretar(_conteudo.text),
  );

  void _aplicarAcaoAssistida(AcaoSelecaoChordPro acao) {
    final resultado = switch (acao) {
      AcaoSelecaoChordPro.marcarComoAcorde =>
        _transformarSelecaoChordPro.marcarComoAcorde(
          _conteudo.text,
          _selecaoDoConteudo,
        ),
      AcaoSelecaoChordPro.tratarComoTexto =>
        _transformarSelecaoChordPro.tratarComoTexto(
          _conteudo.text,
          _selecaoDoConteudo,
        ),
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

  void _duplicarSecao(FaixaSecaoChordPro faixa) {
    final resultado = _duplicarSecaoChordPro.duplicar(
      conteudo: _conteudo.text,
      indiceMarcador: faixa.secao.indiceMarcador!,
    );
    if (resultado.foiDuplicada) {
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

  Future<void> _confirmarExclusaoSecao(FaixaSecaoChordPro faixa) async {
    final titulo = _tituloDaSecao(faixa.secao);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir "$titulo"?'),
        content: const Text('A seção e todo o seu conteúdo serão removidos.'),
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
    final resultado = _excluirSecaoChordPro.excluir(
      conteudo: _conteudo.text,
      indiceMarcador: faixa.secao.indiceMarcador!,
    );
    if (resultado.foiExcluida) {
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

  String _tituloDoTipo(TipoSecaoMusica tipo) =>
      _opcoesDeSecao.firstWhere((opcao) => opcao.tipo == tipo).titulo;

  String _previaDaSecao(SecaoMusica secao) {
    final linhas = secao.elementos
        .map((elemento) => elemento.conteudoOriginal.trim())
        .where((linha) => linha.isNotEmpty)
        .take(2)
        .toList();
    final previa = linhas.join(' · ');
    return previa.length <= 96 ? previa : '${previa.substring(0, 93)}...';
  }

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
      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
    final titulo = ehExplicita ? _tituloDaSecao(secao) : 'Sem seção';
    final previa = _previaDaSecao(secao);
    return Card(
      key: ValueKey(
        ehExplicita ? 'bloco-secao-$indiceMarcador' : 'bloco-implicito-$indice',
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _salvando || !ehExplicita
            ? null
            : () => _editarSecao(
                selecao:
                    faixa?.selecaoNoInicio ??
                    _selecaoDoMarcador(indiceMarcador),
              ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (faixa != null)
                ReorderableDragStartListener(
                  key: ValueKey('arrastar-bloco-$indiceMarcador'),
                  index: indice,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: 'Arrastar seção',
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 16)),
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
              if (faixa != null)
                PopupMenuButton<_AcaoBloco>(
                  key: ValueKey('acoes-bloco-$indiceMarcador'),
                  tooltip: 'Ações da seção',
                  onSelected: (acao) {
                    switch (acao) {
                      case _AcaoBloco.duplicar:
                        _duplicarSecao(faixa);
                      case _AcaoBloco.excluir:
                        _confirmarExclusaoSecao(faixa);
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
    final acaoAssistida = _modoEditor == _ModoEditor.textual
        ? _acaoAssistidaDisponivel
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar música'),
        actions: [
          if (acaoAssistida case final acao?)
            IconButton(
              key: const ValueKey('acao-assistida-acorde'),
              onPressed: _salvando ? null : () => _aplicarAcaoAssistida(acao),
              icon: Icon(
                acao == AcaoSelecaoChordPro.marcarComoAcorde
                    ? Icons.music_note_outlined
                    : Icons.text_fields,
              ),
              tooltip: acao == AcaoSelecaoChordPro.marcarComoAcorde
                  ? 'Marcar como acorde'
                  : 'Tratar como texto',
            ),
          if (_modoEditor == _ModoEditor.textual && _podeMarcarComoSecao)
            IconButton(
              key: const ValueKey('acao-assistida-secao'),
              onPressed: _salvando ? null : _escolherTipoDeSecao,
              icon: const Icon(Icons.view_agenda_outlined),
              tooltip: 'Marcar como seção',
            ),
          if (_modoEditor == _ModoEditor.textual && _secaoEditavelAtual != null)
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
                      label: Text('ChordPro'),
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
                  TextFormField(
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
                    validator: (valor) =>
                        _obrigatorio(valor, 'Conteúdo ChordPro'),
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
    );
  }
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

class _OpcaoDeSecao {
  const _OpcaoDeSecao(this.tipo, this.titulo);

  final TipoSecaoMusica tipo;
  final String titulo;
}
