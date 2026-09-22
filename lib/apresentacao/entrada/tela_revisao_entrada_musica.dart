import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'mensagens_entrada_musica.dart';

class TelaRevisaoEntradaMusica extends StatefulWidget {
  const TelaRevisaoEntradaMusica({
    super.key,
    required this.entrada,
    required this.salvarRascunhoChordPro,
  });

  final EntradaMusicaPreparada entrada;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;

  @override
  State<TelaRevisaoEntradaMusica> createState() =>
      _TelaRevisaoEntradaMusicaState();
}

class _TelaRevisaoEntradaMusicaState extends State<TelaRevisaoEntradaMusica> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _artista;
  late final TextEditingController _tom;
  var _salvando = false;
  String? _erroTom;
  String? _erroGeral;

  @override
  void initState() {
    super.initState();
    final rascunho = widget.entrada.rascunho!;
    _titulo = TextEditingController(text: rascunho.tituloDetectado ?? '');
    _artista = TextEditingController(text: rascunho.artistaDetectado ?? '');
    _tom = TextEditingController(text: rascunho.tomDetectado ?? '');
  }

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _tom.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor, String nome) =>
      valor == null || valor.trim().isEmpty ? '$nome é obrigatório.' : null;

  Future<void> _salvar() async {
    if (_salvando || widget.entrada.conflitos.isNotEmpty) {
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
    final rascunho = widget.entrada.rascunho!.comRevisao(
      RevisaoMetadadosChordPro(
        titulo: _titulo.text,
        artista: _artista.text,
        tom: _tom.text,
      ),
    );
    try {
      await widget.salvarRascunhoChordPro.executar(rascunho);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on RascunhoNaoPodeSerFinalizado catch (erro) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroGeral = MensagensEntradaMusica.conflito(erro);
        });
      }
    } on ArgumentError catch (erro) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroTom = erro.toString().contains('tom original')
              ? 'Tom original inválido.'
              : null;
          _erroGeral = _erroTom == null
              ? MensagensEntradaMusica.erroGeral()
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erroGeral = MensagensEntradaMusica.erroGeral();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avisos = MensagensEntradaMusica.avisos(widget.entrada);
    final detalhes = MensagensEntradaMusica.detalhesConversao(widget.entrada);
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar música')),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.entrada.houveConversaoTextual) ...[
                  const Text(
                    'A cifra foi convertida para o formato interno do AppCifras.',
                  ),
                  const SizedBox(height: 16),
                ],
                for (final aviso in avisos) ...[
                  Text(
                    aviso,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (detalhes.isNotEmpty) ...[
                  const Text('Alguns trechos precisam de revisão:'),
                  const SizedBox(height: 8),
                  for (final detalhe in detalhes) ...[
                    Text(detalhe),
                    const SizedBox(height: 12),
                  ],
                ],
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
                  validator: (valor) => _obrigatorio(valor, 'Tom original'),
                ),
                const SizedBox(height: 20),
                ExpansionTile(
                  title: const Text('Prévia do conteúdo'),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    SelectableText(widget.entrada.chordProSugerido ?? ''),
                  ],
                ),
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
                  onPressed: _salvando || widget.entrada.conflitos.isNotEmpty
                      ? null
                      : _salvar,
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
}
