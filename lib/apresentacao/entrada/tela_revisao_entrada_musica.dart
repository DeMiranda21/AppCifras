import 'package:flutter/material.dart';

import '../../aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/entrada/revisao_contextual_entrada_musica.dart';
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
  final _aplicador = AplicarAcaoProblemaDeCifra();
  late final TextEditingController _titulo;
  late final TextEditingController _artista;
  late final TextEditingController _tom;
  late RevisaoContextualEntradaMusica? _revisao;
  var _indiceProblema = 0;
  var _salvando = false;
  String? _erroTom;
  String? _erroGeral;
  String? _erroProblema;

  static final _acordeMarcado = RegExp(r'\[([^\]\r\n]+)\]');
  static final _diretivaChordPro = RegExp(r'\{[^\}\r\n]+\}');

  @override
  void initState() {
    super.initState();
    final rascunho = widget.entrada.rascunho!;
    _titulo = TextEditingController(text: rascunho.tituloDetectado ?? '');
    _artista = TextEditingController(text: rascunho.artistaDetectado ?? '');
    _tom = TextEditingController(text: rascunho.tomDetectado ?? '');
    _revisao = widget.entrada.revisaoContextual;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _artista.dispose();
    _tom.dispose();
    super.dispose();
  }

  List<ProblemaDeCifra> get _problemas => _revisao?.problemas ?? const [];

  ProblemaDeCifra? get _problemaAtual => _problemas.isEmpty
      ? null
      : _problemas[_indiceProblema.clamp(0, _problemas.length - 1)];

  bool get _temProblemaBloqueante => _problemas.any(
    (problema) => problema.gravidade == GravidadeProblemaDeCifra.bloqueia,
  );

  String? _obrigatorio(String? valor, String nome) =>
      valor == null || valor.trim().isEmpty ? '$nome é obrigatório.' : null;

  String _textoHumano(String texto) {
    var humano = texto
        .replaceAllMapped(_acordeMarcado, (acorde) => acorde.group(1)!)
        .replaceAll(_diretivaChordPro, '');
    final primeiraAbertura = humano.indexOf('{');
    final primeiroFechamento = humano.indexOf('}');
    if (primeiroFechamento >= 0 &&
        (primeiraAbertura < 0 || primeiroFechamento < primeiraAbertura)) {
      humano = humano.substring(primeiroFechamento + 1);
    }
    final ultimaAbertura = humano.lastIndexOf('{');
    final ultimoFechamento = humano.lastIndexOf('}');
    if (ultimaAbertura > ultimoFechamento) {
      humano = humano.substring(0, ultimaAbertura);
    }
    return humano;
  }

  String _mensagemErroAcao(Object erro) => switch (erro) {
    ProblemaDeCifraObsoleto() => 'O trecho mudou durante a revisão. Confira o problema atual e tente novamente.',
    AcaoProblemaDeCifraNaoPermitida() =>
      'Esta ação não está disponível para o trecho atual.',
    CorrecaoDeAcordeInvalida() =>
      'Acorde inválido. Use notas de A a G, como C, F#m ou G/B.',
    _ => 'Não foi possível aplicar a decisão. Tente novamente.',
  };

  void _adotarResultado(
    ResultadoAcaoProblemaDeCifra resultado,
    int indiceAnterior,
  ) {
    final quantidade = resultado.revisao.problemas.length;
    setState(() {
      _revisao = resultado.revisao;
      _indiceProblema = quantidade == 0
          ? 0
          : indiceAnterior.clamp(0, quantidade - 1);
      _erroProblema = null;
      _erroGeral = null;
    });
  }

  void _aplicarAcaoDireta(AcaoProblemaDeCifra acao) {
    final revisao = _revisao;
    final problema = _problemaAtual;
    if (revisao == null || problema == null) return;
    final indiceAnterior = _indiceProblema;
    try {
      final resultado = _aplicador.executar(
        estado: revisao,
        problema: problema,
        acao: acao,
      );
      _adotarResultado(resultado, indiceAnterior);
    } catch (erro) {
      setState(() => _erroProblema = _mensagemErroAcao(erro));
    }
  }

  Future<void> _corrigirAcorde() async {
    final revisao = _revisao;
    final problema = _problemaAtual;
    if (revisao == null || problema == null) return;
    final indiceAnterior = _indiceProblema;
    var correcao = _textoHumano(problema.textoEncontrado).trim();
    await showDialog<void>(
      context: context,
      builder: (contextoDialogo) {
        String? erro;
        return StatefulBuilder(
          builder: (context, atualizarDialogo) => AlertDialog(
            title: const Text('Corrigir acorde'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Valor atual: ${_textoHumano(problema.textoEncontrado)}'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('correcao-acorde-campo'),
                  initialValue: correcao,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (valor) => correcao = valor,
                  decoration: InputDecoration(
                    labelText: 'Novo acorde',
                    hintText: 'Ex.: C, F#m ou G/B',
                    errorText: erro,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                key: const ValueKey('correcao-acorde-cancelar'),
                onPressed: () => Navigator.of(contextoDialogo).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const ValueKey('correcao-acorde-confirmar'),
                onPressed: () {
                  try {
                    final resultado = _aplicador.executar(
                      estado: revisao,
                      problema: problema,
                      acao: AcaoProblemaDeCifra.corrigirAcorde,
                      correcao: correcao,
                    );
                    _adotarResultado(resultado, indiceAnterior);
                    Navigator.of(contextoDialogo).pop();
                  } catch (falha) {
                    atualizarDialogo(() => erro = _mensagemErroAcao(falha));
                  }
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _salvar() async {
    if (_salvando ||
        widget.entrada.conflitos.isNotEmpty ||
        _temProblemaBloqueante) {
      return;
    }
    setState(() {
      _erroTom = null;
      _erroGeral = null;
    });
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    final conteudoAtual =
        _revisao?.conteudoChordPro ?? widget.entrada.rascunho!.conteudoRecebido;
    final rascunho = widget.entrada.rascunho!
        .comConteudo(conteudoAtual)
        .comRevisao(
          RevisaoMetadadosChordPro(
            titulo: _titulo.text,
            artista: _artista.text,
            tom: _tom.text,
          ),
        );
    try {
      await widget.salvarRascunhoChordPro.executar(rascunho);
      if (mounted) Navigator.of(context).pop(true);
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
    final avisosNaoAcionaveis = _revisao?.avisosNaoAcionaveis ?? const [];
    final problema = _problemaAtual;
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
                    'A cifra foi analisada e preparada para o AppCifras.',
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
                if (problema != null)
                  _CartaoProblema(
                    problema: problema,
                    indice: _indiceProblema,
                    quantidade: _problemas.length,
                    textoHumano: _textoHumano,
                    erro: _erroProblema,
                    podeVoltar: _indiceProblema > 0,
                    podeAvancar: _indiceProblema < _problemas.length - 1,
                    aoVoltar: () => setState(() {
                      _indiceProblema -= 1;
                      _erroProblema = null;
                    }),
                    aoAvancar: () => setState(() {
                      _indiceProblema += 1;
                      _erroProblema = null;
                    }),
                    aoMarcarAcorde: () =>
                        _aplicarAcaoDireta(AcaoProblemaDeCifra.ehAcorde),
                    aoMarcarTexto: () =>
                        _aplicarAcaoDireta(AcaoProblemaDeCifra.ehTexto),
                    aoCorrigirAcorde: _corrigirAcorde,
                  )
                else
                  Card(
                    key: const ValueKey('estado-revisao-pronto'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('A cifra está pronta para salvar.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (avisosNaoAcionaveis.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    key: const ValueKey('avisos-nao-acionaveis'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Observações (${avisosNaoAcionaveis.length})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          for (final aviso in avisosNaoAcionaveis)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('• ${aviso.motivo}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_temProblemaBloqueante) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Resolva os problemas obrigatórios antes de salvar.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                  onPressed:
                      _salvando ||
                          widget.entrada.conflitos.isNotEmpty ||
                          _temProblemaBloqueante
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

class _CartaoProblema extends StatelessWidget {
  const _CartaoProblema({
    required this.problema,
    required this.indice,
    required this.quantidade,
    required this.textoHumano,
    required this.erro,
    required this.podeVoltar,
    required this.podeAvancar,
    required this.aoVoltar,
    required this.aoAvancar,
    required this.aoMarcarAcorde,
    required this.aoMarcarTexto,
    required this.aoCorrigirAcorde,
  });

  final ProblemaDeCifra problema;
  final int indice;
  final int quantidade;
  final String Function(String) textoHumano;
  final String? erro;
  final bool podeVoltar;
  final bool podeAvancar;
  final VoidCallback aoVoltar;
  final VoidCallback aoAvancar;
  final VoidCallback aoMarcarAcorde;
  final VoidCallback aoMarcarTexto;
  final VoidCallback aoCorrigirAcorde;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('problema-cifra'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Problema ${indice + 1} de $quantidade',
                  key: const ValueKey('problema-contador'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const ValueKey('problema-anterior'),
                tooltip: 'Problema anterior',
                onPressed: podeVoltar ? aoVoltar : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('problema-proximo'),
                tooltip: 'Próximo problema',
                onPressed: podeAvancar ? aoAvancar : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('problema-contexto'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: textoHumano(problema.contexto.antes)),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      key: const ValueKey('problema-alvo'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        textoHumano(problema.textoEncontrado),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TextSpan(text: textoHumano(problema.contexto.depois)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(problema.motivo),
          if (erro != null) ...[
            const SizedBox(height: 8),
            Text(
              erro!,
              key: const ValueKey('problema-erro'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (problema.acoesPermitidas.contains(
                AcaoProblemaDeCifra.ehAcorde,
              ))
                FilledButton.tonal(
                  key: const ValueKey('acao-eh-acorde'),
                  onPressed: aoMarcarAcorde,
                  child: const Text('É acorde'),
                ),
              if (problema.acoesPermitidas.contains(
                AcaoProblemaDeCifra.ehTexto,
              ))
                FilledButton.tonal(
                  key: const ValueKey('acao-eh-texto'),
                  onPressed: aoMarcarTexto,
                  child: const Text('É texto'),
                ),
              if (problema.acoesPermitidas.contains(
                AcaoProblemaDeCifra.corrigirAcorde,
              ))
                FilledButton.tonal(
                  key: const ValueKey('acao-corrigir-acorde'),
                  onPressed: aoCorrigirAcorde,
                  child: const Text('Corrigir acorde'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
