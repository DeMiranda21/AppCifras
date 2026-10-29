import 'dart:async';

enum OrigemAberturaVisualizacao { biblioteca, listaCulto }

class MedicaoDesempenhoVisualizacao {
  MedicaoDesempenhoVisualizacao._(this.origem, this._registrar)
    : _total = Stopwatch()..start();

  static final Object _chaveZona = Object();

  final OrigemAberturaVisualizacao origem;
  final void Function(String mensagem) _registrar;
  final Stopwatch _total;

  Duration _carregamentoCatalogo = Duration.zero;
  Duration _carregamentoVersao = Duration.zero;
  Duration _sqlite = Duration.zero;
  Duration _leituraArquivo = Duration.zero;
  Duration _interpretacaoChordPro = Duration.zero;
  Duration _processamentoMusical = Duration.zero;
  Duration _construcaoInterface = Duration.zero;
  Duration? _dadosProntos;
  var _consultasSqlite = 0;
  var _arquivosLidos = 0;
  var _documentosInterpretados = 0;
  var _concluida = false;

  static MedicaoDesempenhoVisualizacao? iniciar({
    required OrigemAberturaVisualizacao origem,
    required void Function(String mensagem) registrar,
  }) {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug ? MedicaoDesempenhoVisualizacao._(origem, registrar) : null;
  }

  static MedicaoDesempenhoVisualizacao? get atual =>
      Zone.current[_chaveZona] as MedicaoDesempenhoVisualizacao?;

  Future<T> executarNoContexto<T>(Future<T> Function() operacao) =>
      runZoned(operacao, zoneValues: {_chaveZona: this});

  Future<T> medirCarregamentoCatalogo<T>(Future<T> Function() operacao) =>
      _medirAssincrono(operacao, (duracao) => _carregamentoCatalogo += duracao);

  Future<T> medirCarregamentoVersao<T>(Future<T> Function() operacao) =>
      _medirAssincrono(operacao, (duracao) => _carregamentoVersao += duracao);

  Future<T> medirSqlite<T>(Future<T> Function() operacao) async {
    _consultasSqlite++;
    return _medirAssincrono(operacao, (duracao) => _sqlite += duracao);
  }

  Future<T> medirLeituraArquivo<T>(Future<T> Function() operacao) async {
    final resultado = await _medirAssincrono(
      operacao,
      (duracao) => _leituraArquivo += duracao,
    );
    _arquivosLidos++;
    return resultado;
  }

  T medirInterpretacaoChordPro<T>(T Function() operacao) {
    final resultado = _medirSincrono(
      operacao,
      (duracao) => _interpretacaoChordPro += duracao,
    );
    _documentosInterpretados++;
    return resultado;
  }

  T medirProcessamentoMusical<T>(T Function() operacao) =>
      _medirSincrono(operacao, (duracao) => _processamentoMusical += duracao);

  T medirConstrucaoInterface<T>(T Function() operacao) =>
      _medirSincrono(operacao, (duracao) => _construcaoInterface += duracao);

  void marcarDadosProntos() {
    _dadosProntos ??= _total.elapsed;
  }

  void concluirApresentacao({bool sucesso = true}) {
    if (_concluida) return;
    _concluida = true;
    _total.stop();
    final atePrimeiroFrame = _total.elapsed;
    final dadosProntos = _dadosProntos ?? atePrimeiroFrame;
    _registrar(
      '[QX-02][Visualizacao] '
      'origem=${origem.name} '
      'sucesso=$sucesso '
      'total_ate_cifra_ms=${atePrimeiroFrame.inMilliseconds} '
      'carregamento_catalogo_ms=${_carregamentoCatalogo.inMilliseconds} '
      'carregamento_versao_ms=${_carregamentoVersao.inMilliseconds} '
      'sqlite_acumulado_ms=${_sqlite.inMilliseconds} '
      'consultas_sqlite=$_consultasSqlite '
      'leitura_arquivo_ms=${_leituraArquivo.inMilliseconds} '
      'arquivos_lidos=$_arquivosLidos '
      'interpretacao_chordpro_ms=${_interpretacaoChordPro.inMilliseconds} '
      'documentos_interpretados=$_documentosInterpretados '
      'processamento_musical_ms=${_processamentoMusical.inMilliseconds} '
      'construcao_interface_ms=${_construcaoInterface.inMilliseconds} '
      'dados_prontos_ms=${dadosProntos.inMilliseconds} '
      'dados_prontos_ate_frame_ms='
      '${(atePrimeiroFrame - dadosProntos).inMilliseconds}',
    );
  }

  Future<T> _medirAssincrono<T>(
    Future<T> Function() operacao,
    void Function(Duration duracao) acumular,
  ) async {
    final cronometro = Stopwatch()..start();
    try {
      return await operacao();
    } finally {
      cronometro.stop();
      acumular(cronometro.elapsed);
    }
  }

  T _medirSincrono<T>(
    T Function() operacao,
    void Function(Duration duracao) acumular,
  ) {
    final cronometro = Stopwatch()..start();
    try {
      return operacao();
    } finally {
      cronometro.stop();
      acumular(cronometro.elapsed);
    }
  }
}
