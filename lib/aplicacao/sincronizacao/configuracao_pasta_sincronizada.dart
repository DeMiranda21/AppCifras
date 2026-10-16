class ConfiguracaoPastaSincronizada {
  ConfiguracaoPastaSincronizada({
    required this.uriArvore,
    required this.autorizacaoPersistente,
    String? nomeLegivel,
    this.ultimaSincronizacaoConcluida,
  }) : nomeLegivel = _normalizarNome(nomeLegivel) {
    if (uriArvore.trim().isEmpty) {
      throw ArgumentError.value(
        uriArvore,
        'uriArvore',
        'A URI da árvore é obrigatória.',
      );
    }
  }

  /// Identificador opaco da árvore. A interpretação pertence à integração SAF.
  final String uriArvore;
  final bool autorizacaoPersistente;
  final String? nomeLegivel;
  final DateTime? ultimaSincronizacaoConcluida;

  static String? _normalizarNome(String? nome) {
    final normalizado = nome?.trim();
    return normalizado == null || normalizado.isEmpty ? null : normalizado;
  }
}
