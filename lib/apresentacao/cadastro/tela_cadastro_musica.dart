import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/musicas.dart';

class TelaCadastroMusica extends StatefulWidget {
  const TelaCadastroMusica({super.key, required this.cadastrarMusica});

  final CadastrarMusica cadastrarMusica;

  @override
  State<TelaCadastroMusica> createState() => _TelaCadastroMusicaState();
}

class _TelaCadastroMusicaState extends State<TelaCadastroMusica> {
  final _formulario = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _artista = TextEditingController();
  final _tom = TextEditingController();
  final _conteudo = TextEditingController();
  var _salvando = false;
  String? _erroTom;
  String? _erroGeral;

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _tom.dispose();
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _erroTom = null;
      _erroGeral = null;
    });
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.cadastrarMusica.executar(
        DadosCadastroMusica(
          titulo: _titulo.text,
          artista: _artista.text,
          tomOriginal: _tom.text,
          conteudoChordPro: _conteudo.text,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on CadastroMusicaInvalido catch (erro) {
      if (!mounted) {
        return;
      }
      setState(() {
        _salvando = false;
        if (erro.campo == CampoCadastroMusica.tomOriginal) {
          _erroTom = 'Tom original inválido.';
        } else if (erro.campo == CampoCadastroMusica.conteudo) {
          _erroGeral = 'O conteúdo não formou uma música válida.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroGeral = 'Não foi possível salvar a música. Tente novamente.';
        });
      }
    }
  }

  String? _obrigatorio(String? valor, String nome) =>
      valor == null || valor.trim().isEmpty ? '$nome é obrigatório.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova música')),
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
                  hintText: '[G]Grande é o [D]Senhor',
                ),
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                validator: (valor) => _obrigatorio(valor, 'Conteúdo ChordPro'),
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
                    : const Text('Salvar música'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
