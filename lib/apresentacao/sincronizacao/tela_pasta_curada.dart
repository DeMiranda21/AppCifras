import 'package:flutter/material.dart';

import '../../aplicacao/portas/pasta_curada_externa.dart';
import '../../aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import '../../aplicacao/sincronizacao/gerenciar_pasta_curada.dart';

class TelaPastaCurada extends StatefulWidget {
  const TelaPastaCurada({super.key, required this.gerenciarPastaCurada});

  final GerenciarPastaCurada gerenciarPastaCurada;

  @override
  State<TelaPastaCurada> createState() => _TelaPastaCuradaState();
}

class _TelaPastaCuradaState extends State<TelaPastaCurada> {
  ConfiguracaoPastaSincronizada? _configuracao;
  String? _resultado;
  bool _leituraConfirmada = false;
  String? _erro;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final configuracao = await widget.gerenciarPastaCurada
          .obterConfiguracao();
      if (!mounted) return;
      setState(() {
        _configuracao = configuracao;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemErro(erro);
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarPasta() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _resultado = null;
      _leituraConfirmada = false;
    });
    try {
      final configuracao = await widget.gerenciarPastaCurada.selecionarPasta();
      if (!mounted) return;
      setState(() {
        if (configuracao != null) {
          _configuracao = configuracao;
          _resultado = 'Pasta selecionada. A autorização foi preservada.';
        }
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemErro(erro);
        _carregando = false;
      });
    }
  }

  Future<void> _lerPasta() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _resultado = null;
      _leituraConfirmada = false;
    });
    try {
      final arquivos = await widget.gerenciarPastaCurada.listarArquivosCho();
      if (arquivos.isNotEmpty) {
        await widget.gerenciarPastaCurada.lerBytes(arquivos.first);
      }
      if (!mounted) return;
      setState(() {
        _resultado = arquivos.length == 1
            ? '1 arquivo .cho encontrado.'
            : '${arquivos.length} arquivos .cho encontrados.';
        _leituraConfirmada = arquivos.isNotEmpty;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemErro(erro);
        _carregando = false;
      });
    }
  }

  String _mensagemErro(Object erro) {
    if (erro is PastaCuradaNaoConfigurada) {
      return 'Selecione uma pasta antes de verificar o acesso.';
    }
    if (erro is FalhaPastaCurada) {
      return switch (erro.tipo) {
        TipoFalhaPastaCurada.autorizacaoRevogada => 'A autorização da pasta foi perdida ou revogada. Selecione-a novamente.',
        TipoFalhaPastaCurada.provedorIndisponivel =>
          'O provedor da pasta está indisponível. Tente novamente mais tarde.',
        TipoFalhaPastaCurada.autorizacaoNaoPersistida =>
          'O provedor não permitiu preservar o acesso à pasta.',
        TipoFalhaPastaCurada.leitura =>
          'Não foi possível ler a pasta selecionada.',
      };
    }
    return 'Não foi possível acessar a pasta selecionada.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pasta da biblioteca')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _configuracao?.nomeLegivel ??
                (_configuracao == null
                    ? 'Nenhuma pasta selecionada'
                    : 'Pasta selecionada'),
            key: const ValueKey('nome-pasta-curada'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('selecionar-pasta-curada'),
            onPressed: _carregando ? null : _selecionarPasta,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Selecionar pasta da biblioteca'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('ler-pasta-curada'),
            onPressed: _carregando || _configuracao == null ? null : _lerPasta,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Ler pasta'),
          ),
          const SizedBox(height: 24),
          if (_carregando) const Center(child: CircularProgressIndicator()),
          if (_resultado != null)
            Text(_resultado!, key: const ValueKey('resultado-pasta-curada')),
          if (_leituraConfirmada) ...[
            const SizedBox(height: 8),
            const Text(
              'Leitura do primeiro arquivo confirmada.',
              key: ValueKey('leitura-pasta-curada-confirmada'),
            ),
          ],
          if (_erro != null)
            Text(
              _erro!,
              key: const ValueKey('erro-pasta-curada'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
