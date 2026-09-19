import '../chordpro/documento_chordpro.dart';
import '../objetos_de_valor/nota.dart';
import '../objetos_de_valor/tom.dart';
import 'parser_acorde.dart';

class ParserDocumentoChordPro {
  ParserDocumentoChordPro({ParserAcorde? parserAcorde})
    : _parserAcorde = parserAcorde ?? ParserAcorde();
  final ParserAcorde _parserAcorde;
  static final _diretiva = RegExp(r'^\{([A-Za-z_]+)(?::(.*))?\}$');
  static final _tom = RegExp(r'^([A-G])([#b]?)(m?)$');

  DocumentoChordPro interpretar(String conteudo) => DocumentoChordPro(
    conteudoOriginal: conteudo,
    elementos: conteudo.isEmpty
        ? const []
        : _linhas(conteudo).map(_interpretarLinha),
  );

  Iterable<String> _linhas(String texto) => texto.split(RegExp(r'\r\n|\n|\r'));

  ElementoDocumentoChordPro _interpretarLinha(String linha) {
    final diretiva = _diretiva.firstMatch(linha);
    if (diretiva != null) {
      return _interpretarDiretiva(
        linha,
        diretiva.group(1)!,
        diretiva.group(2) ?? '',
      );
    }
    if ((linha.startsWith('{') || linha.endsWith('}')) ||
        (linha.contains('[') && !linha.contains(']'))) {
      return LinhaNaoInterpretadaChordPro(linha);
    }
    return _interpretarConteudo(linha);
  }

  ElementoDocumentoChordPro _interpretarDiretiva(
    String original,
    String nome,
    String valor,
  ) => switch (nome) {
    'title' => DiretivaTituloChordPro(original, valor),
    'artist' => DiretivaArtistaChordPro(original, valor),
    'key' => DiretivaTomChordPro(
      original,
      valor,
      _interpretarTom(valor.trim()),
    ),
    'start_of_chorus' || 'soc' => InicioRefraoChordPro(original),
    'end_of_chorus' || 'eoc' => FimRefraoChordPro(original),
    _ => DiretivaDesconhecidaChordPro(original, valor, nome),
  };

  LinhaChordPro _interpretarConteudo(String linha) {
    final elementos = <ElementoLinhaChordPro>[];
    var cursor = 0;
    while (cursor < linha.length) {
      final inicio = linha.indexOf('[', cursor);
      if (inicio == -1) {
        elementos.add(TextoLinhaChordPro(linha.substring(cursor)));
        break;
      }
      if (inicio > cursor) {
        elementos.add(TextoLinhaChordPro(linha.substring(cursor, inicio)));
      }
      final fim = linha.indexOf(']', inicio + 1);
      if (fim == -1 || fim == inicio + 1) {
        return LinhaChordPro(linha, [TextoLinhaChordPro(linha)]);
      }
      final acorde = linha.substring(inicio + 1, fim);
      elementos.add(
        AcordeLinhaChordPro(acorde, _parserAcorde.interpretar(acorde)),
      );
      cursor = fim + 1;
    }
    return LinhaChordPro(linha, elementos);
  }

  Tom? _interpretarTom(String valor) {
    final match = _tom.firstMatch(valor);
    if (match == null) return null;
    final nome = match.group(1)!;
    final acidente = match.group(2)!;
    return Tom(
      notaFundamental: Nota(
        nome: switch (nome) {
          'A' => NomeNota.a,
          'B' => NomeNota.b,
          'C' => NomeNota.c,
          'D' => NomeNota.d,
          'E' => NomeNota.e,
          'F' => NomeNota.f,
          'G' => NomeNota.g,
          _ => throw StateError('Nome de nota inválido.'),
        },
        alteracao: switch (acidente) {
          '#' => AlteracaoNota.sustenido,
          'b' => AlteracaoNota.bemol,
          _ => AlteracaoNota.natural,
        },
      ),
      modo: match.group(3) == 'm' ? ModoTom.menor : ModoTom.maior,
    );
  }
}
