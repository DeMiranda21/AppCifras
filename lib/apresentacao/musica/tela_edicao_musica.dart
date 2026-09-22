import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/entrada/conteudo_chordpro_editavel.dart';
import '../../aplicacao/entrada/reanalisador_conteudo_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/tom.dart';

class TelaEdicaoMusica extends StatefulWidget {
  const TelaEdicaoMusica({
    super.key,
    required this.musica,
    required this.atualizarMusica,
  });

  final Musica musica;
  final AtualizarMusica atualizarMusica;

  @override
  State<TelaEdicaoMusica> createState() => _TelaEdicaoMusicaState();
}

class _TelaEdicaoMusicaState extends State<TelaEdicaoMusica> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _artista;
  late final TextEditingController _tom;
  late final TextEditingController _conteudo;
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
  }

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _tom.dispose();
    _conteudo.dispose();
    super.dispose();
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
    appBar: AppBar(title: const Text('Editar música')),
    body: SafeArea(
      child: Form(
        key: _formulario,
        child: SingleChildScrollView(
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
                controller: _conteudo,
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
