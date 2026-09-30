import '../../dominio/servicos/parser_acorde.dart';

/// Classifica somente os casos inequívocos de uma linha colada pelo usuário.
///
/// A classificação é deliberadamente conservadora: uma linha só é musical
/// quando todos os seus tokens são acordes que o parser consegue interpretar.
/// Isso evita converter palavras parecidas com cifras em acordes inválidos.
class ClassificadorLinhaCifraTextual {
  ClassificadorLinhaCifraTextual({ParserAcorde? parserAcorde})
    : _parserAcorde = parserAcorde ?? ParserAcorde();

  final ParserAcorde _parserAcorde;

  bool ehRotuloDeSecao(String linha) {
    var texto = linha.trim();
    if (texto.startsWith('[') && texto.endsWith(']')) {
      texto = texto.substring(1, texto.length - 1).trim();
    }
    if (texto.endsWith(':')) {
      texto = texto.substring(0, texto.length - 1).trim();
    }
    final normalizado = _normalizar(texto);
    return normalizado == 'intro' ||
        normalizado == 'introducao' ||
        normalizado == 'primeira parte' ||
        normalizado == 'segunda parte' ||
        normalizado == 'pre-refrao' ||
        normalizado == 'refrao' ||
        normalizado == 'coro' ||
        normalizado == 'ponte' ||
        normalizado == 'instrumental' ||
        normalizado == 'solo' ||
        normalizado == 'final' ||
        RegExp(r'^verso\s+\d+$').hasMatch(normalizado) ||
        normalizado == 'verso';
  }

  bool ehNomeDeSecao(String texto) => ehRotuloDeSecao(texto);

  bool ehLinhaDeAcordes(String linha) {
    if (ehRotuloDeSecao(linha)) {
      return false;
    }
    final tokens = linha.trim().split(RegExp(r'\s+'));
    if (tokens.length == 1 && tokens.single.isEmpty) {
      return false;
    }
    return tokens.isNotEmpty &&
        tokens.every(
          (token) => _parserAcorde.interpretar(token) is AcordeInterpretado,
        );
  }

  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ç', 'c')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'\s+'), ' ');
}
