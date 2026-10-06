import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoDivisaoBlocoChordPro {
  const ResultadoDivisaoBlocoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiDividido,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiDividido;
}

/// Divide um bloco antes da linha onde está o cursor.
///
/// Seções explícitas são fechadas antes da segunda metade. Blocos livres usam
/// a diretiva interna canônica para preservar a fronteira após nova derivação.
class DividirBlocoChordPro {
  DividirBlocoChordPro({
    LocalizadorSecaoChordPro? localizador,
    ParserDocumentoChordPro? parserDocumento,
  }) : _localizador = localizador ?? LocalizadorSecaoChordPro(),
       _parserDocumento = parserDocumento ?? ParserDocumentoChordPro();

  static const diretivaQuebra = '{appcifras_block_break}';

  final LocalizadorSecaoChordPro _localizador;
  final ParserDocumentoChordPro _parserDocumento;

  ResultadoDivisaoBlocoChordPro dividir({
    required String conteudo,
    required FaixaBlocoChordPro faixa,
    required int posicao,
  }) {
    if (!_faixaValida(conteudo, faixa)) return _semDivisao(conteudo);
    final inicioDaLinha = _inicioDaLinha(conteudo, posicao);
    final indiceMarcador = faixa.bloco.indiceMarcador;
    final secao = indiceMarcador == null
        ? null
        : _localizador.localizar(
            conteudo: conteudo,
            indiceMarcador: indiceMarcador,
          );

    if (secao != null) {
      return _dividirSecaoExplicita(conteudo, secao, inicioDaLinha);
    }

    final trecho = _localizador.localizarTrechoNaoIdentificado(
      conteudo: conteudo,
      inicioConteudo: faixa.bloco.inicioConteudo,
    );
    if (trecho == null) return _semDivisao(conteudo);
    return _dividirTrechoLivre(
      conteudo,
      inicio: trecho.inicio,
      fim: trecho.fim,
      inicioDaLinha: inicioDaLinha,
    );
  }

  ResultadoDivisaoBlocoChordPro _dividirSecaoExplicita(
    String conteudo,
    FaixaSecaoChordPro secao,
    int inicioDaLinha,
  ) {
    if (!_podeDividir(
      conteudo,
      inicio: secao.inicioConteudo,
      fim: secao.fimConteudo,
      inicioDaLinha: inicioDaLinha,
    )) {
      return _semDivisao(conteudo);
    }
    final fimOriginal = conteudo.substring(secao.fimConteudo, secao.fim);
    final separador = secao.separadorAposInicio.isEmpty
        ? _separadorDoDocumento(conteudo)
        : secao.separadorAposInicio;
    final segundaMetade = secao.fimComSeparador == secao.fim
        ? _semSeparadorFinal(
            conteudo.substring(inicioDaLinha, secao.fimConteudo),
          )
        : conteudo.substring(inicioDaLinha, secao.fimConteudo);
    final novoConteudo =
        '${conteudo.substring(0, inicioDaLinha)}$fimOriginal$separador'
        '$segundaMetade'
        '${conteudo.substring(secao.fimComSeparador)}';
    final inicioSegundaMetade =
        inicioDaLinha + fimOriginal.length + separador.length;
    return ResultadoDivisaoBlocoChordPro(
      conteudo: novoConteudo,
      selecao: SelecaoTextoChordPro(
        inicio: inicioSegundaMetade,
        fim: inicioSegundaMetade,
      ),
      foiDividido: true,
    );
  }

  ResultadoDivisaoBlocoChordPro _dividirTrechoLivre(
    String conteudo, {
    required int inicio,
    required int fim,
    required int inicioDaLinha,
  }) {
    if (!_podeDividir(
      conteudo,
      inicio: inicio,
      fim: fim,
      inicioDaLinha: inicioDaLinha,
    )) {
      return _semDivisao(conteudo);
    }
    final separador = _separadorDoDocumento(conteudo);
    final insercao = '$diretivaQuebra$separador';
    final novoConteudo =
        '${conteudo.substring(0, inicioDaLinha)}$insercao'
        '${conteudo.substring(inicioDaLinha)}';
    return ResultadoDivisaoBlocoChordPro(
      conteudo: novoConteudo,
      selecao: SelecaoTextoChordPro(
        inicio: inicioDaLinha + insercao.length,
        fim: inicioDaLinha + insercao.length,
      ),
      foiDividido: true,
    );
  }

  bool podeDividir({
    required String conteudo,
    required FaixaBlocoChordPro faixa,
    required int posicao,
  }) {
    if (!_faixaValida(conteudo, faixa)) return false;
    final inicioDaLinha = _inicioDaLinha(conteudo, posicao);
    final indiceMarcador = faixa.bloco.indiceMarcador;
    final secao = indiceMarcador == null
        ? null
        : _localizador.localizar(
            conteudo: conteudo,
            indiceMarcador: indiceMarcador,
          );
    if (secao != null) {
      return _podeDividir(
        conteudo,
        inicio: secao.inicioConteudo,
        fim: secao.fimConteudo,
        inicioDaLinha: inicioDaLinha,
      );
    }
    final trecho = _localizador.localizarTrechoNaoIdentificado(
      conteudo: conteudo,
      inicioConteudo: faixa.bloco.inicioConteudo,
    );
    return trecho != null &&
        _podeDividir(
          conteudo,
          inicio: trecho.inicio,
          fim: trecho.fim,
          inicioDaLinha: inicioDaLinha,
        );
  }

  bool _podeDividir(
    String conteudo, {
    required int inicio,
    required int fim,
    required int inicioDaLinha,
  }) =>
      inicioDaLinha > inicio &&
      inicioDaLinha < fim &&
      _temConteudoMusical(conteudo.substring(inicio, inicioDaLinha)) &&
      _temConteudoMusical(conteudo.substring(inicioDaLinha, fim));

  bool _temConteudoMusical(String texto) => _parserDocumento
      .interpretar(texto)
      .elementos
      .any(
        (elemento) =>
            (elemento is LinhaChordPro ||
                elemento is LinhaNaoInterpretadaChordPro) &&
            elemento.conteudoOriginal.trim().isNotEmpty,
      );

  bool _faixaValida(String conteudo, FaixaBlocoChordPro faixa) =>
      faixa.inicio >= 0 &&
      faixa.fim >= faixa.inicio &&
      faixa.fim <= conteudo.length;

  int _inicioDaLinha(String conteudo, int posicao) {
    final cursor = posicao.clamp(0, conteudo.length);
    var indice = cursor;
    while (indice > 0) {
      final anterior = conteudo.codeUnitAt(indice - 1);
      if (anterior == 10 || anterior == 13) break;
      indice -= 1;
    }
    return indice;
  }

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';

  String _semSeparadorFinal(String texto) => texto.endsWith('\r\n')
      ? texto.substring(0, texto.length - 2)
      : texto.endsWith('\n') || texto.endsWith('\r')
      ? texto.substring(0, texto.length - 1)
      : texto;

  ResultadoDivisaoBlocoChordPro _semDivisao(String conteudo) =>
      ResultadoDivisaoBlocoChordPro(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiDividido: false,
      );
}
