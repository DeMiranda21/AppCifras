import 'package:flutter/material.dart';

import '../../aplicacao/portas/pasta_curada_externa.dart';
import '../../aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import '../../aplicacao/sincronizacao/gerenciar_pasta_curada.dart';
import '../../aplicacao/sincronizacao/sincronizar_pasta_curada.dart';

class TelaPastaCurada extends StatefulWidget {
  const TelaPastaCurada({
    super.key,
    required this.gerenciarPastaCurada,
    this.sincronizarPastaCurada,
  });

  final GerenciarPastaCurada gerenciarPastaCurada;
  final Future<ResultadoSincronizacao> Function()? sincronizarPastaCurada;

  @override
  State<TelaPastaCurada> createState() => _TelaPastaCuradaState();
}

class _TelaPastaCuradaState extends State<TelaPastaCurada> {
  ConfiguracaoPastaSincronizada? _configuracao;
  String? _resultado;
  ResultadoSincronizacao? _resultadoSincronizacao;
  bool _leituraConfirmada = false;
  bool _acessoConfirmado = false;
  String? _erro;
  var _carregando = true;
  var _sincronizando = false;

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
      _resultadoSincronizacao = null;
      _leituraConfirmada = false;
    });
    try {
      final configuracao = await widget.gerenciarPastaCurada.selecionarPasta();
      if (!mounted) return;
      setState(() {
        if (configuracao != null) {
          _configuracao = configuracao;
          _resultado = 'Pasta selecionada. A autorização foi preservada.';
          _acessoConfirmado = true;
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
      _resultadoSincronizacao = null;
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
        _acessoConfirmado = true;
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

  Future<void> _sincronizar() async {
    final sincronizar = widget.sincronizarPastaCurada;
    if (sincronizar == null || _sincronizando || _configuracao == null) return;
    setState(() {
      _sincronizando = true;
      _erro = null;
      _resultado = null;
      _resultadoSincronizacao = null;
    });
    try {
      final resultado = await sincronizar();
      final configuracao = await widget.gerenciarPastaCurada
          .obterConfiguracao();
      if (!mounted) return;
      setState(() {
        _resultadoSincronizacao = resultado;
        _configuracao = configuracao ?? _configuracao;
        _acessoConfirmado = resultado.enumeracaoCompleta;
        _sincronizando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível concluir a sincronização. Tente novamente.';
        _acessoConfirmado = false;
        _sincronizando = false;
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

  String _formatarData(DateTime data) {
    final local = data.toLocal();
    final agora = DateTime.now();
    final hora =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    if (local.year == agora.year &&
        local.month == agora.month &&
        local.day == agora.day) {
      return 'hoje $hora';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} $hora';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pasta da biblioteca')),
    body: SingleChildScrollView(
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
          if (_configuracao?.ultimaSincronizacaoConcluida case final data?) ...[
            const SizedBox(height: 8),
            Text(
              'Última sincronização: ${_formatarData(data)}',
              key: const ValueKey('ultima-sincronizacao'),
            ),
          ],
          if (_acessoConfirmado) ...[
            const SizedBox(height: 8),
            const Text(
              'Status: acesso confirmado.',
              key: ValueKey('status-acesso-pasta-curada'),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('selecionar-pasta-curada'),
            onPressed: _carregando || _sincronizando ? null : _selecionarPasta,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Selecionar pasta da biblioteca'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('ler-pasta-curada'),
            onPressed: _carregando || _sincronizando || _configuracao == null
                ? null
                : _lerPasta,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Ler pasta'),
          ),
          if (widget.sincronizarPastaCurada != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('sincronizar-pasta-curada'),
              onPressed: _carregando || _sincronizando || _configuracao == null
                  ? null
                  : _sincronizar,
              icon: const Icon(Icons.sync),
              label: const Text('Sincronizar agora'),
            ),
          ],
          const SizedBox(height: 24),
          if (_carregando || _sincronizando)
            const Center(
              child: CircularProgressIndicator(
                key: ValueKey('carregando-pasta-curada'),
              ),
            ),
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
          if (_resultadoSincronizacao case final resultado?)
            _ResumoSincronizacao(resultado: resultado),
        ],
      ),
    ),
  );
}

class _ResumoSincronizacao extends StatelessWidget {
  const _ResumoSincronizacao({required this.resultado});

  final ResultadoSincronizacao resultado;

  @override
  Widget build(BuildContext context) {
    final concluida = resultado.enumeracaoCompleta;
    return Card(
      key: const ValueKey('resultado-sincronizacao'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              concluida
                  ? 'Sincronização concluída'
                  : 'Sincronização não concluída',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (concluida) ...[
              const SizedBox(height: 12),
              Text(_quantidade(resultado.adicionadas, 'adicionada')),
              Text(_quantidade(resultado.atualizadas, 'atualizada')),
              Text(_quantidade(resultado.inalteradas, 'inalterada')),
              Text(_quantidade(resultado.origensAusentes, 'ausente')),
              Text(_quantidade(resultado.erros.length, 'erro')),
            ],
            if (resultado.erros.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Erros', style: Theme.of(context).textTheme.titleSmall),
              ...resultado.erros.map(
                (erro) => Text(
                  _descricao(erro.localizador, erro.mensagem),
                  key: ValueKey('erro-sincronizacao-${erro.codigo.name}'),
                ),
              ),
            ],
            if (resultado.avisos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Avisos', style: Theme.of(context).textTheme.titleSmall),
              ...resultado.avisos.map(
                (aviso) => Text(
                  _descricao(aviso.localizador, aviso.mensagem),
                  key: ValueKey('aviso-sincronizacao-${aviso.codigo.name}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _descricao(String? localizador, String mensagem) {
    if (localizador == null || localizador.trim().isEmpty) return mensagem;
    final uri = Uri.tryParse(localizador);
    final segmentos = uri?.pathSegments ?? const <String>[];
    final ultimoSegmento = segmentos.isEmpty ? null : segmentos.last;
    final rotulo = ultimoSegmento == null || ultimoSegmento.isEmpty
        ? 'Arquivo'
        : Uri.decodeComponent(ultimoSegmento);
    return '$rotulo: $mensagem';
  }

  static String _quantidade(int valor, String singular) =>
      '$valor ${valor == 1 ? singular : '${singular}s'}';
}
