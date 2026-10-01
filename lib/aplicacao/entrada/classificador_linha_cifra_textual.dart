import '../../dominio/servicos/parser_acorde.dart';
import '../estrutura/reconhecedor_secao_musica.dart';

/// Classifica somente os casos inequívocos de uma linha colada pelo usuário.
///
/// A classificação é deliberadamente conservadora: uma linha só é musical
/// quando todos os seus tokens são acordes que o parser consegue interpretar.
/// Isso evita converter palavras parecidas com cifras em acordes inválidos.
class ClassificadorLinhaCifraTextual {
  ClassificadorLinhaCifraTextual({
    ParserAcorde? parserAcorde,
    ReconhecedorSecaoMusica? reconhecedorSecao,
  }) : _parserAcorde = parserAcorde ?? ParserAcorde(),
       _reconhecedorSecao = reconhecedorSecao ?? ReconhecedorSecaoMusica();

  final ParserAcorde _parserAcorde;
  final ReconhecedorSecaoMusica _reconhecedorSecao;

  bool ehRotuloDeSecao(String linha) =>
      _reconhecedorSecao.reconhecerRotulo(linha) != null;

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
}
