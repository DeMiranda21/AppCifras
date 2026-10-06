/// Localiza o token útil tocado em um campo de texto musical.
///
/// Tokens são delimitados apenas por espaço, tabulação e quebras de linha. A
/// pontuação periférica simples é excluída; acordes entre colchetes são
/// tratados como uma unidade para que a ação assistida existente possa operar
/// sobre eles de modo previsível.
class SelecionarTokenTexto {
  const SelecionarTokenTexto();

  FaixaTokenTexto? localizar({required String texto, required int offset}) {
    if (offset < 0 || offset >= texto.length || _ehDelimitador(texto[offset])) {
      return null;
    }

    final intervaloDeAcorde = _intervaloDeAcordeEntreColchetes(texto, offset);
    if (intervaloDeAcorde != null) {
      return intervaloDeAcorde;
    }

    var inicio = offset;
    while (inicio > 0 && !_ehDelimitador(texto[inicio - 1])) {
      inicio -= 1;
    }
    var fim = offset + 1;
    while (fim < texto.length && !_ehDelimitador(texto[fim])) {
      fim += 1;
    }

    final ultimoFechamentoDeAcorde = offset == 0
        ? -1
        : texto.lastIndexOf(']', offset - 1);
    final ultimaAberturaDeAcorde = ultimoFechamentoDeAcorde < 0
        ? -1
        : texto.lastIndexOf('[', ultimoFechamentoDeAcorde);
    if (ultimoFechamentoDeAcorde >= inicio &&
        ultimaAberturaDeAcorde >= inicio) {
      inicio = ultimoFechamentoDeAcorde + 1;
    }

    while (inicio < fim && _ehPontuacaoPeriferica(texto[inicio])) {
      inicio += 1;
    }
    while (fim > inicio && _ehPontuacaoPerifericaNoFim(texto, inicio, fim)) {
      fim -= 1;
    }
    if (inicio == fim || offset < inicio || offset >= fim) {
      return null;
    }
    return FaixaTokenTexto(inicio: inicio, fim: fim);
  }

  FaixaTokenTexto? _intervaloDeAcordeEntreColchetes(String texto, int offset) {
    var abertura = offset;
    while (abertura >= 0 && !_ehDelimitador(texto[abertura])) {
      if (texto[abertura] == '[') {
        break;
      }
      abertura -= 1;
    }
    if (abertura < 0 || texto[abertura] != '[') {
      return null;
    }
    var fechamento = abertura + 1;
    while (fechamento < texto.length && !_ehDelimitador(texto[fechamento])) {
      if (texto[fechamento] == ']') {
        break;
      }
      fechamento += 1;
    }
    if (fechamento >= texto.length ||
        texto[fechamento] != ']' ||
        fechamento == abertura + 1 ||
        offset > fechamento) {
      return null;
    }
    return FaixaTokenTexto(inicio: abertura, fim: fechamento + 1);
  }

  bool _ehDelimitador(String caractere) =>
      caractere == ' ' ||
      caractere == '\t' ||
      caractere == '\n' ||
      caractere == '\r';

  bool _ehPontuacaoPeriferica(String caractere) =>
      const {',', '.', ';', ':', '!', '?', '(', ')'}.contains(caractere);

  bool _ehPontuacaoPerifericaNoFim(String texto, int inicio, int fim) {
    final caractere = texto[fim - 1];
    if (!_ehPontuacaoPeriferica(caractere)) {
      return false;
    }
    return caractere != ')' || texto.indexOf('(', inicio) < inicio;
  }
}

class FaixaTokenTexto {
  const FaixaTokenTexto({required this.inicio, required this.fim});

  final int inicio;
  final int fim;
}
