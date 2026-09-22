import 'conversor_cifra_textual.dart';

class ReanalisadorConteudoChordPro {
  ReanalisadorConteudoChordPro({ConversorCifraTextual? conversor})
    : _conversor = conversor ?? ConversorCifraTextual();
  final ConversorCifraTextual _conversor;

  ResultadoConversaoCifraTextual analisar(String conteudo) {
    final separador = conteudo.contains('\r\n') ? '\r\n' : '\n';
    final linhas = conteudo.split(RegExp(r'\r\n|\n|\r'));
    final saida = <String>[];
    final avisos = <AvisoConversaoCifra>[];
    var i = 0;
    while (i < linhas.length) {
      if (i + 1 < linhas.length &&
          !_marcada(linhas[i]) &&
          !_marcada(linhas[i + 1])) {
        final resultado = _conversor.converter(
          '${linhas[i]}\n${linhas[i + 1]}',
        );
        if (resultado.chordProSugerido != '${linhas[i]}\n${linhas[i + 1]}' &&
            resultado.avisos.isEmpty) {
          saida.addAll(resultado.chordProSugerido.split('\n'));
          i += 2;
          continue;
        }
      }
      saida.add(linhas[i]);
      i += 1;
    }
    return ResultadoConversaoCifraTextual(
      conteudoOriginal: conteudo,
      chordProSugerido: saida.join(separador),
      avisos: avisos,
    );
  }

  bool _marcada(String linha) =>
      linha.trim().startsWith('{') || RegExp(r'\[[^\]]+\]').hasMatch(linha);
}
