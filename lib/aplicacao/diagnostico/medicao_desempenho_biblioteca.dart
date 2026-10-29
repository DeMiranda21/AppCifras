import 'dart:async';

enum MotivoCarregamentoBiblioteca {
  primeiraAbertura,
  retornoCadastro,
  retornoMusica,
  retornoListasCulto,
  atualizacaoBiblioteca,
  dependenciasAtualizadas,
}

class MedicaoDesempenhoBiblioteca {
  MedicaoDesempenhoBiblioteca._(this.motivo, this._registrar)
    : _total = Stopwatch()..start();

  static final Object _chaveZona = Object();

  final MotivoCarregamentoBiblioteca motivo;
  final void Function(String mensagem) _registrar;
  final Stopwatch _total;

  Duration _sqlite = Duration.zero;
  Duration _leituraArquivos = Duration.zero;
  Duration _interpretacaoChordPro = Duration.zero;
  Duration _criacaoIndice = Duration.zero;
  Duration? _carregamento;
  var _quantidadeMusicas = 0;
  var _arquivosLidos = 0;
  var _documentosInterpretados = 0;
  var _concluida = false;

  static MedicaoDesempenhoBiblioteca? iniciar({
    required MotivoCarregamentoBiblioteca motivo,
    required void Function(String mensagem) registrar,
  }) {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug ? MedicaoDesempenhoBiblioteca._(motivo, registrar) : null;
  }

  static MedicaoDesempenhoBiblioteca? get atual =>
      Zone.current[_chaveZona] as MedicaoDesempenhoBiblioteca?;

  Future<T> executarNoContexto<T>(Future<T> Function() operacao) =>
      runZoned(operacao, zoneValues: {_chaveZona: this});

  Future<T> medirSqlite<T>(Future<T> Function() operacao) =>
      _medirAssincrono(operacao, (duracao) => _sqlite += duracao);

  Future<T> medirLeituraArquivo<T>(Future<T> Function() operacao) async {
    final resultado = await _medirAssincrono(
      operacao,
      (duracao) => _leituraArquivos += duracao,
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

  T medirCriacaoIndice<T>(T Function() operacao) =>
      _medirSincrono(operacao, (duracao) => _criacaoIndice += duracao);

  void registrarQuantidadeMusicas(int quantidade) {
    _quantidadeMusicas = quantidade;
  }

  void concluirCarregamento() {
    _carregamento ??= _total.elapsed;
  }

  void concluirApresentacao({bool sucesso = true}) {
    if (_concluida) return;
    _concluida = true;
    _total.stop();
    final carregamento = _carregamento ?? _total.elapsed;
    final ateApresentacao = _total.elapsed;
    final aposCarregamento = ateApresentacao - carregamento;
    _registrar(
      '[QX-02][Biblioteca] '
      'motivo=${motivo.name} '
      'sucesso=$sucesso '
      'carregamento_total_ms=${carregamento.inMilliseconds} '
      'sqlite_acumulado_ms=${_sqlite.inMilliseconds} '
      'leitura_arquivos_acumulada_ms=${_leituraArquivos.inMilliseconds} '
      'interpretacao_chordpro_acumulada_ms='
      '${_interpretacaoChordPro.inMilliseconds} '
      'criacao_indice_ms=${_criacaoIndice.inMilliseconds} '
      'ate_primeiro_frame_ms=${ateApresentacao.inMilliseconds} '
      'indice_pronto_ate_frame_ms=${aposCarregamento.inMilliseconds} '
      'musicas=$_quantidadeMusicas '
      'arquivos_lidos=$_arquivosLidos '
      'documentos_interpretados=$_documentosInterpretados',
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
