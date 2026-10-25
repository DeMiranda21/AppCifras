class InformacoesApp {
  const InformacoesApp({
    required this.versao,
    required this.numeroBuild,
    this.commitGit,
  });

  final String versao;
  final String numeroBuild;
  final String? commitGit;
}

abstract interface class ObterInformacoesApp {
  Future<InformacoesApp> executar();
}
