import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/edicao/transformar_selecao_chordpro.dart';
import '../../aplicacao/edicao/transformar_secao_chordpro.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/entrada/conteudo_chordpro_editavel.dart';
import '../../aplicacao/entrada/reanalisador_conteudo_chordpro.dart';
import '../../aplicacao/estrutura/reconhecedor_secao_musica.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/tom.dart';

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
  late final String _tomInicial;
  var _salvando = false;
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

  void _atualizarConteudo(String conteudo, SelecaoTextoChordPro selecao) {
    _conteudo.value = TextEditingValue(
      text: conteudo,
      selection: TextSelection(
        baseOffset: selecao.inicio,
        extentOffset: selecao.fim,
      ),
    );
    _focoConteudo.requestFocus();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Editar música'),
      actions: [
        if (_acaoAssistidaDisponivel case final acao?)
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
        if (_podeMarcarComoSecao)
          IconButton(
            key: const ValueKey('acao-assistida-secao'),
            onPressed: _salvando ? null : _escolherTipoDeSecao,
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: 'Marcar como seção',
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
                validator: (valor) => _obrigatorio(valor, 'Conteúdo ChordPro'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _salvando ? null : _analisarAlteracoes,
                child: const Text('Analisar alterações'),
              ),
              if (_erroGeral != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erroGeral!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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

class _OpcaoDeSecao {
  const _OpcaoDeSecao(this.tipo, this.titulo);

  final TipoSecaoMusica tipo;
  final String titulo;
}
