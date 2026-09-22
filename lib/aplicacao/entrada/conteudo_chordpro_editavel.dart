/// Separa do ChordPro canônico as diretivas técnicas gerenciadas pelo app.
class ConteudoChordProEditavel {
  const ConteudoChordProEditavel._();

  static final _diretivaInterna = RegExp(
    r'^\s*\{\s*appcifras_(?:schema|id)\s*:[^}]*\}\s*$',
    caseSensitive: false,
  );

  static String extrair(String conteudoCanonico) =>
      _removerInternas(conteudoCanonico);

  /// Ignora diretivas reservadas inseridas manualmente na área editável.
  static String prepararParaSalvar(String conteudoEditavel) =>
      _removerInternas(conteudoEditavel);

  /// Reaplica somente diretivas internas do documento canônico confiável.
  static String recomporCanonico({
    required String conteudoCanonicoAnterior,
    required String conteudoEditavel,
  }) {
    final separador = conteudoCanonicoAnterior.contains('\r\n') ? '\r\n' : '\n';
    final internas = conteudoCanonicoAnterior
        .split(RegExp(r'\r\n|\n|\r'))
        .where(_diretivaInterna.hasMatch)
        .toList();
    final conteudo = prepararParaSalvar(conteudoEditavel);
    if (internas.isEmpty) return conteudo;
    return conteudo.isEmpty
        ? internas.join(separador)
        : '${internas.join(separador)}$separador$conteudo';
  }

  static String _removerInternas(String conteudo) {
    final separador = conteudo.contains('\r\n') ? '\r\n' : '\n';
    return conteudo
        .split(RegExp(r'\r\n|\n|\r'))
        .where((linha) => !_diretivaInterna.hasMatch(linha))
        .join(separador);
  }
}
