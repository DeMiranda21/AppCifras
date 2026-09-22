import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import 'tela_revisao_entrada_musica.dart';

class TelaEntradaMusica extends StatefulWidget {
  const TelaEntradaMusica({
    super.key,
    required this.prepararEntradaMusica,
    required this.salvarRascunhoChordPro,
  });

  final PrepararEntradaMusica prepararEntradaMusica;
  final SalvarRascunhoChordPro salvarRascunhoChordPro;

  @override
  State<TelaEntradaMusica> createState() => _TelaEntradaMusicaState();
}

class _TelaEntradaMusicaState extends State<TelaEntradaMusica> {
  final _formulario = GlobalKey<FormState>();
  final _conteudo = TextEditingController();
  var _analisando = false;
  String? _erro;

  @override
  void dispose() {
    _conteudo.dispose();
    super.dispose();
  }

  Future<void> _analisar() async {
    if (_analisando || !(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _analisando = true;
      _erro = null;
    });
    await Future<void>.delayed(Duration.zero);
    final preparada = widget.prepararEntradaMusica.executar(_conteudo.text);
    if (!mounted) {
      return;
    }
    if (!preparada.possuiRascunhoParaRevisao) {
      setState(() {
        _analisando = false;
        _erro = 'Não foi possível reconhecer a estrutura da cifra automaticamente. Ajuste o texto e tente novamente.';
      });
      return;
    }
    final salva = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TelaRevisaoEntradaMusica(
          entrada: preparada,
          salvarRascunhoChordPro: widget.salvarRascunhoChordPro,
        ),
      ),
    );
    if (mounted) {
      if (salva == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _analisando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adicionar música')),
    body: SafeArea(
      child: Form(
        key: _formulario,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cole ou digite sua cifra.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conteudo,
                enabled: !_analisando,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Cifra',
                  hintText: 'Tom: E\n\n[E]Exemplo de letra',
                ),
                keyboardType: TextInputType.multiline,
                minLines: 14,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                validator: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Informe uma cifra para analisar.'
                    : null,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _analisando ? null : _analisar,
                child: _analisando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analisar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
