import '../../dominio/servicos/parser_acorde.dart';

/// Intervalo de texto selecionado no conteúdo editável de uma música.
///
/// Não depende de [TextSelection] para que a transformação permaneça em Dart
/// puro, fora da apresentação Flutter.
class SelecaoTextoChordPro {
  const SelecaoTextoChordPro({required this.inicio, required this.fim});

  final int inicio;
  final int fim;

  bool get temConteudo => fim > inicio;
}

enum AcaoSelecaoChordPro { marcarComoAcorde, tratarComoTexto }

/// Resultado de uma transformação pontual no texto ChordPro editável.
class ResultadoTransformacaoSelecaoChordPro {
  const ResultadoTransformacaoSelecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiTransformado,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiTransformado;
}

/// Aplica ações assistidas a uma seleção textual, sem persistir a música.
class TransformarSelecaoChordPro {
  TransformarSelecaoChordPro({ParserAcorde? parserAcorde})
    : _parserAcorde = parserAcorde ?? ParserAcorde();

  final ParserAcorde _parserAcorde;

  AcaoSelecaoChordPro? acaoDisponivel(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (!_selecaoValida(conteudo, selecao)) {
      return null;
    }
    if (_selecaoEhAcordeEntreColchetes(conteudo, selecao) ||
        _selecaoIncluiAcordeEntreColchetes(conteudo, selecao)) {
      return AcaoSelecaoChordPro.tratarComoTexto;
    }
    if (!_ehTokenIsolado(conteudo, selecao)) {
      return null;
    }
    final textoSelecionado = conteudo.substring(selecao.inicio, selecao.fim);
    return _parserAcorde.interpretar(textoSelecionado) is AcordeInterpretado
        ? AcaoSelecaoChordPro.marcarComoAcorde
        : null;
  }

  ResultadoTransformacaoSelecaoChordPro marcarComoAcorde(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (acaoDisponivel(conteudo, selecao) !=
        AcaoSelecaoChordPro.marcarComoAcorde) {
      return _semTransformacao(conteudo, selecao);
    }
    final acorde = conteudo.substring(selecao.inicio, selecao.fim);
    final substituto = '[$acorde]';
    return _substituir(conteudo, selecao, substituto);
  }

  ResultadoTransformacaoSelecaoChordPro tratarComoTexto(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (acaoDisponivel(conteudo, selecao) !=
        AcaoSelecaoChordPro.tratarComoTexto) {
      return _semTransformacao(conteudo, selecao);
    }

    final intervalo = _intervaloDoAcordeEntreColchetes(conteudo, selecao)!;
    final texto = conteudo.substring(intervalo.inicio + 1, intervalo.fim - 1);
    return _substituir(conteudo, intervalo, texto);
  }

  ResultadoTransformacaoSelecaoChordPro _substituir(
    String conteudo,
    SelecaoTextoChordPro selecao,
    String substituto,
  ) => ResultadoTransformacaoSelecaoChordPro(
    conteudo:
        '${conteudo.substring(0, selecao.inicio)}$substituto${conteudo.substring(selecao.fim)}',
    selecao: SelecaoTextoChordPro(
      inicio: selecao.inicio,
      fim: selecao.inicio + substituto.length,
    ),
    foiTransformado: true,
  );

  ResultadoTransformacaoSelecaoChordPro _semTransformacao(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) => ResultadoTransformacaoSelecaoChordPro(
    conteudo: conteudo,
    selecao: selecao,
    foiTransformado: false,
  );

  bool _selecaoValida(String conteudo, SelecaoTextoChordPro selecao) =>
      selecao.temConteudo &&
      selecao.inicio >= 0 &&
      selecao.fim <= conteudo.length;

  bool _ehTokenIsolado(String conteudo, SelecaoTextoChordPro selecao) {
    final antes = selecao.inicio == 0 ? null : conteudo[selecao.inicio - 1];
    final depois = selecao.fim == conteudo.length
        ? null
        : conteudo[selecao.fim];
    return (antes == null || _ehDelimitadorDeToken(antes)) &&
        (depois == null || _ehDelimitadorDeToken(depois));
  }

  bool _ehDelimitadorDeToken(String caractere) =>
      RegExp(r'\s').hasMatch(caractere);

  bool _selecaoEhAcordeEntreColchetes(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) =>
      selecao.inicio > 0 &&
      selecao.fim < conteudo.length &&
      conteudo[selecao.inicio - 1] == '[' &&
      conteudo[selecao.fim] == ']';

  bool _selecaoIncluiAcordeEntreColchetes(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) => conteudo[selecao.inicio] == '[' && conteudo[selecao.fim - 1] == ']';

  SelecaoTextoChordPro? _intervaloDoAcordeEntreColchetes(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (_selecaoEhAcordeEntreColchetes(conteudo, selecao)) {
      return SelecaoTextoChordPro(
        inicio: selecao.inicio - 1,
        fim: selecao.fim + 1,
      );
    }
    if (_selecaoIncluiAcordeEntreColchetes(conteudo, selecao)) {
      return selecao;
    }
    return null;
  }
}
