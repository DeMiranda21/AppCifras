enum TipoFalhaBibliotecaOficial {
  configuracaoAusente,
  semConexao,
  timeout,
  manifestoNaoEncontrado,
  arquivoNaoEncontrado,
  httpServidor,
  httpInesperado,
  manifestoInvalido,
  schemaNaoSuportado,
  caminhoInseguro,
  limiteExcedido,
  tamanhoDivergente,
  sha256Divergente,
}

class FalhaBibliotecaOficial implements Exception {
  const FalhaBibliotecaOficial(this.tipo, this.mensagem, {this.statusHttp});

  final TipoFalhaBibliotecaOficial tipo;
  final String mensagem;
  final int? statusHttp;

  @override
  String toString() => mensagem;
}
