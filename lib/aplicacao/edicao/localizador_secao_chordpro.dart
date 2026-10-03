import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../estrutura/estrutura_musica.dart';
import '../estrutura/reconhecedor_secao_musica.dart';
import 'transformar_selecao_chordpro.dart';

/// Localiza a faixa literal de uma seção explícita com delimitadores confiáveis.
///
/// A estrutura continua derivada do ChordPro. Esta classe não altera conteúdo e
/// não atribui faixa destrutiva a seções sem fechamento correspondente.
class LocalizadorSecaoChordPro {
  LocalizadorSecaoChordPro({
    ParserDocumentoChordPro? parserDocumento,
    EstruturadorDocumentoChordPro? estruturador,
    ReconhecedorSecaoMusica? reconhecedor,
  }) : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro(),
       _estruturador = estruturador ?? EstruturadorDocumentoChordPro(),
       _reconhecedor = reconhecedor ?? ReconhecedorSecaoMusica();

  final ParserDocumentoChordPro _parserDocumento;
  final EstruturadorDocumentoChordPro _estruturador;
  final ReconhecedorSecaoMusica _reconhecedor;

  FaixaSecaoChordPro? localizar({
    required String conteudo,
    required int indiceMarcador,
  }) {
    final documento = _parserDocumento.interpretar(conteudo);
    final estrutura = _estruturador.estruturar(documento);
    final linhas = _linhas(conteudo);
    if (indiceMarcador < 0 ||
        indiceMarcador >= documento.elementos.length ||
        indiceMarcador >= linhas.length) {
      return null;
    }
    final secao = estrutura.secoes.where(
      (secao) => secao.indiceMarcador == indiceMarcador,
    );
    if (secao.isEmpty) {
      return null;
    }
    final marcadorInicio = _reconhecedor.reconhecerDiretiva(
      documento.elementos[indiceMarcador].conteudoOriginal,
    );
    if (marcadorInicio == null || !marcadorInicio.ehInicio) {
      return null;
    }
    final indiceFim = secao.first.fimConteudoExclusivo;
    if (indiceFim >= documento.elementos.length || indiceFim >= linhas.length) {
      return null;
    }
    final marcadorFim = _reconhecedor.reconhecerDiretiva(
      documento.elementos[indiceFim].conteudoOriginal,
    );
    if (marcadorFim == null ||
        marcadorFim.ehInicio ||
        marcadorFim.ambiente != marcadorInicio.ambiente) {
      return null;
    }
    final linhaInicio = linhas[indiceMarcador];
    final linhaFim = linhas[indiceFim];
    return FaixaSecaoChordPro(
      secao: secao.first,
      inicio: linhaInicio.inicio,
      fim: linhaFim.fim,
      fimComSeparador: linhaFim.fimComSeparador,
      inicioConteudo: linhaInicio.fimComSeparador,
      fimConteudo: linhaFim.inicio,
      separadorAposInicio: conteudo.substring(
        linhaInicio.fim,
        linhaInicio.fimComSeparador,
      ),
      selecaoNoInicio: SelecaoTextoChordPro(
        inicio: linhaInicio.inicio,
        fim: linhaInicio.inicio,
      ),
    );
  }

  /// Localiza conteúdo derivado que não possui delimitadores ChordPro.
  ///
  /// Inclui tanto texto livre quanto o conteúdo posterior a um rótulo textual
  /// reconhecido, como `[Refrão]`. O rótulo permanece fora da faixa para ser
  /// preservado literalmente durante a edição.
  FaixaTrechoNaoIdentificadoChordPro? localizarTrechoNaoIdentificado({
    required String conteudo,
    required int inicioConteudo,
  }) {
    final documento = _parserDocumento.interpretar(conteudo);
    final estrutura = _estruturador.estruturar(documento);
    final secao = estrutura.secoes.where((secao) {
      if (secao.inicioConteudo != inicioConteudo) {
        return false;
      }
      final indiceMarcador = secao.indiceMarcador;
      if (indiceMarcador == null) {
        return true;
      }
      final marcador = indiceMarcador < documento.elementos.length
          ? _reconhecedor.reconhecerDiretiva(
              documento.elementos[indiceMarcador].conteudoOriginal,
            )
          : null;
      return marcador == null || !marcador.ehInicio;
    });
    if (secao.isEmpty) return null;
    final trecho = secao.first;
    if (trecho.fimConteudoExclusivo <= trecho.inicioConteudo) return null;
    final linhas = _linhas(conteudo);
    if (trecho.inicioConteudo >= linhas.length ||
        trecho.fimConteudoExclusivo > linhas.length) {
      return null;
    }
    final linhaInicio = linhas[trecho.inicioConteudo];
    final linhaFim = linhas[trecho.fimConteudoExclusivo - 1];
    return FaixaTrechoNaoIdentificadoChordPro(
      trecho: trecho,
      inicio: linhaInicio.inicio,
      fim: linhaFim.fim,
      fimComSeparador: linhaFim.fimComSeparador,
      selecaoNoInicio: SelecaoTextoChordPro(
        inicio: linhaInicio.inicio,
        fim: linhaInicio.inicio,
      ),
    );
  }

  /// Localiza a faixa literal completa de qualquer bloco que possa sofrer
  /// operações estruturais sem alcançar conteúdo vizinho.
  ///
  /// Para seções delimitadas, inclui os delimitadores. Para rótulos textuais,
  /// inclui o próprio rótulo e o conteúdo seguinte. Para texto livre, inclui
  /// somente o trecho musical derivado.
  FaixaBlocoChordPro? localizarBlocoSeguro({
    required String conteudo,
    required SecaoMusica secao,
  }) {
    final indiceMarcador = secao.indiceMarcador;
    if (indiceMarcador != null) {
      final faixaSecao = localizar(
        conteudo: conteudo,
        indiceMarcador: indiceMarcador,
      );
      if (faixaSecao != null) {
        return FaixaBlocoChordPro.deSecao(faixaSecao);
      }
    }
    final trecho = localizarTrechoNaoIdentificado(
      conteudo: conteudo,
      inicioConteudo: secao.inicioConteudo,
    );
    if (trecho == null) return null;
    final linhas = _linhas(conteudo);
    final inicio = indiceMarcador != null && indiceMarcador < linhas.length
        ? linhas[indiceMarcador].inicio
        : trecho.inicio;
    return FaixaBlocoChordPro(
      bloco: secao,
      inicio: inicio,
      fim: trecho.fim,
      fimComSeparador: trecho.fimComSeparador,
    );
  }

  List<_LinhaChordPro> _linhas(String conteudo) {
    final linhas = <_LinhaChordPro>[];
    var inicio = 0;
    for (final separador in RegExp(r'\r\n|\n|\r').allMatches(conteudo)) {
      linhas.add(
        _LinhaChordPro(
          inicio: inicio,
          fim: separador.start,
          fimComSeparador: separador.end,
        ),
      );
      inicio = separador.end;
    }
    linhas.add(
      _LinhaChordPro(
        inicio: inicio,
        fim: conteudo.length,
        fimComSeparador: conteudo.length,
      ),
    );
    return linhas;
  }
}

class FaixaSecaoChordPro {
  const FaixaSecaoChordPro({
    required this.secao,
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
    required this.inicioConteudo,
    required this.fimConteudo,
    required this.separadorAposInicio,
    required this.selecaoNoInicio,
  });

  final SecaoMusica secao;
  final int inicio;
  final int fim;
  final int fimComSeparador;
  final int inicioConteudo;
  final int fimConteudo;
  final String separadorAposInicio;
  final SelecaoTextoChordPro selecaoNoInicio;
}

class FaixaTrechoNaoIdentificadoChordPro {
  const FaixaTrechoNaoIdentificadoChordPro({
    required this.trecho,
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
    required this.selecaoNoInicio,
  });

  final SecaoMusica trecho;
  final int inicio;
  final int fim;
  final int fimComSeparador;
  final SelecaoTextoChordPro selecaoNoInicio;
}

/// Faixa literal segura para editar, mover, duplicar ou excluir um bloco.
class FaixaBlocoChordPro {
  const FaixaBlocoChordPro({
    required this.bloco,
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
  });

  factory FaixaBlocoChordPro.deSecao(FaixaSecaoChordPro faixa) =>
      FaixaBlocoChordPro(
        bloco: faixa.secao,
        inicio: faixa.inicio,
        fim: faixa.fim,
        fimComSeparador: faixa.fimComSeparador,
      );

  final SecaoMusica bloco;
  final int inicio;
  final int fim;
  final int fimComSeparador;
}

class _LinhaChordPro {
  const _LinhaChordPro({
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
  });

  final int inicio;
  final int fim;
  final int fimComSeparador;
}
