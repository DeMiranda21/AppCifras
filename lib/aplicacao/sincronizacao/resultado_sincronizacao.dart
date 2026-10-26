enum CodigoErroSincronizacao {
  configuracaoAusente,
  acessoPasta,
  enumeracaoPasta,
  leituraArquivo,
  arquivoInvalido,
  grupoInvalido,
  grupoNovoSemPrincipal,
  colisaoVersaoLocal,
  alternativaUsadaEmLista,
  falhaAplicacao,
  falhaAoAvaliarAusencias,
  falhaAoMarcarAusencia,
  falhaAoAtualizarConfiguracao,
}

class ErroSincronizacao {
  const ErroSincronizacao({
    required this.codigo,
    required this.mensagem,
    this.localizador,
  });

  final CodigoErroSincronizacao codigo;
  final String mensagem;
  final String? localizador;
}

enum CodigoAvisoSincronizacao {
  principalExternaDivergente,
  alternativaUsadaEmLista,
}

class AvisoSincronizacao {
  const AvisoSincronizacao({
    required this.codigo,
    required this.mensagem,
    this.localizador,
  });

  final CodigoAvisoSincronizacao codigo;
  final String mensagem;
  final String? localizador;
}

class ResultadoSincronizacao {
  ResultadoSincronizacao({
    required this.adicionadas,
    required this.atualizadas,
    required this.inalteradas,
    required this.origensAusentes,
    required Iterable<ErroSincronizacao> erros,
    required Iterable<AvisoSincronizacao> avisos,
    required this.enumeracaoCompleta,
  }) : erros = List.unmodifiable(erros),
       avisos = List.unmodifiable(avisos);

  final int adicionadas;
  final int atualizadas;
  final int inalteradas;
  final int origensAusentes;
  final List<ErroSincronizacao> erros;
  final List<AvisoSincronizacao> avisos;
  final bool enumeracaoCompleta;
}
