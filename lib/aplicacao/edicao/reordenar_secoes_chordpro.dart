import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../estrutura/estrutura_musica.dart';
import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoReordenacaoSecoesChordPro {
  const ResultadoReordenacaoSecoesChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiReordenada,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiReordenada;
}

/// Reordena literalmente blocos explícitos ou trechos musicais livres dentro
/// de uma mesma faixa segura.
///
/// Uma faixa segura é uma sequência contígua sem diretivas ou conteúdo não
/// musical entre os blocos. A operação preserva o conteúdo interno de cada
/// bloco e normaliza somente o separador criado entre eles.
class ReordenarSecoesChordPro {
  ReordenarSecoesChordPro({
    LocalizadorSecaoChordPro? localizador,
    EstruturadorDocumentoChordPro? estruturador,
    ParserDocumentoChordPro? parserDocumento,
  }) : _localizador = localizador ?? LocalizadorSecaoChordPro(),
       _estruturador = estruturador ?? EstruturadorDocumentoChordPro(),
       _parserDocumento = parserDocumento ?? ParserDocumentoChordPro();

  final LocalizadorSecaoChordPro _localizador;
  final EstruturadorDocumentoChordPro _estruturador;
  final ParserDocumentoChordPro _parserDocumento;

  ResultadoReordenacaoSecoesChordPro reordenar({
    required String conteudo,
    required int indiceOrigem,
    required int indiceDestino,
  }) {
    final estrutura = _estruturar(conteudo);
    final secoes = estrutura.secoes;
    if (indiceOrigem < 0 ||
        indiceDestino < 0 ||
        indiceOrigem >= secoes.length ||
        indiceDestino >= secoes.length ||
        indiceOrigem == indiceDestino) {
      return _semReordenacao(conteudo);
    }

    final faixas = [for (final secao in secoes) _faixaDo(conteudo, secao)];
    final faixaOrigem = faixas[indiceOrigem];
    if (faixaOrigem == null) {
      return _semReordenacao(conteudo);
    }
    final inicioDoGrupo = _inicioDoGrupo(conteudo, faixas, indiceOrigem);
    final fimDoGrupo = _fimDoGrupo(conteudo, faixas, indiceOrigem);
    if (indiceDestino < inicioDoGrupo || indiceDestino > fimDoGrupo) {
      return _semReordenacao(conteudo);
    }

    final grupo = faixas
        .sublist(inicioDoGrupo, fimDoGrupo + 1)
        .cast<_FaixaBlocoChordPro>();
    final origemNoGrupo = indiceOrigem - inicioDoGrupo;
    final destinoNoGrupo = indiceDestino - inicioDoGrupo;
    final novaOrdem = List<_FaixaBlocoChordPro>.from(grupo);
    final movida = novaOrdem.removeAt(origemNoGrupo);
    novaOrdem.insert(destinoNoGrupo, movida);

    final inicioDaFaixa = grupo.first.inicio;
    final fimDaFaixa = grupo.last.fimComSeparador;
    final trechos = {
      for (final faixa in grupo)
        faixa: conteudo.substring(faixa.inicio, faixa.fim),
    };
    final separador = _separadorDoGrupo(conteudo, grupo);
    final novoTrecho = novaOrdem
        .map((faixa) => trechos[faixa]!)
        .join(separador);
    final separadorFinal = conteudo.substring(grupo.last.fim, fimDaFaixa);
    final inicioDaMovida =
        inicioDaFaixa +
        novaOrdem
            .take(destinoNoGrupo)
            .fold<int>(
              0,
              (total, faixa) =>
                  total + trechos[faixa]!.length + separador.length,
            );
    return ResultadoReordenacaoSecoesChordPro(
      conteudo:
          '${conteudo.substring(0, inicioDaFaixa)}$novoTrecho$separadorFinal${conteudo.substring(fimDaFaixa)}',
      selecao: SelecaoTextoChordPro(
        inicio: inicioDaMovida,
        fim: inicioDaMovida,
      ),
      foiReordenada: true,
    );
  }

  EstruturaMusica _estruturar(String conteudo) =>
      _estruturador.estruturar(_parserDocumento.interpretar(conteudo));

  _FaixaBlocoChordPro? _faixaDo(String conteudo, SecaoMusica secao) {
    final indiceMarcador = secao.indiceMarcador;
    if (indiceMarcador != null) {
      final faixa = _localizador.localizar(
        conteudo: conteudo,
        indiceMarcador: indiceMarcador,
      );
      return faixa == null ? null : _FaixaBlocoChordPro.deSecao(faixa);
    }
    final faixa = _localizador.localizarTrechoNaoIdentificado(
      conteudo: conteudo,
      inicioConteudo: secao.inicioConteudo,
    );
    return faixa == null ? null : _FaixaBlocoChordPro.deTrecho(faixa);
  }

  int _inicioDoGrupo(
    String conteudo,
    List<_FaixaBlocoChordPro?> faixas,
    int indice,
  ) {
    var atual = indice;
    while (atual > 0 &&
        _faixasSaoVizinhasSeguras(conteudo, faixas[atual - 1], faixas[atual])) {
      atual -= 1;
    }
    return atual;
  }

  int _fimDoGrupo(
    String conteudo,
    List<_FaixaBlocoChordPro?> faixas,
    int indice,
  ) {
    var atual = indice;
    while (atual + 1 < faixas.length &&
        _faixasSaoVizinhasSeguras(conteudo, faixas[atual], faixas[atual + 1])) {
      atual += 1;
    }
    return atual;
  }

  bool _faixasSaoVizinhasSeguras(
    String conteudo,
    _FaixaBlocoChordPro? anterior,
    _FaixaBlocoChordPro? posterior,
  ) {
    if (anterior == null || posterior == null) return false;
    return conteudo
        .substring(anterior.fimComSeparador, posterior.inicio)
        .trim()
        .isEmpty;
  }

  String _separadorDoGrupo(String conteudo, List<_FaixaBlocoChordPro> grupo) {
    for (final faixa in grupo) {
      final separador = conteudo.substring(faixa.fim, faixa.fimComSeparador);
      if (separador.isNotEmpty) {
        return separador;
      }
    }
    return conteudo.contains('\r\n')
        ? '\r\n'
        : conteudo.contains('\r')
        ? '\r'
        : '\n';
  }

  ResultadoReordenacaoSecoesChordPro _semReordenacao(String conteudo) =>
      ResultadoReordenacaoSecoesChordPro(
        conteudo: conteudo,
        selecao: SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiReordenada: false,
      );
}

class _FaixaBlocoChordPro {
  const _FaixaBlocoChordPro({
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
  });

  factory _FaixaBlocoChordPro.deSecao(FaixaSecaoChordPro faixa) =>
      _FaixaBlocoChordPro(
        inicio: faixa.inicio,
        fim: faixa.fim,
        fimComSeparador: faixa.fimComSeparador,
      );

  factory _FaixaBlocoChordPro.deTrecho(
    FaixaTrechoNaoIdentificadoChordPro faixa,
  ) => _FaixaBlocoChordPro(
    inicio: faixa.inicio,
    fim: faixa.fim,
    fimComSeparador: faixa.fimComSeparador,
  );

  final int inicio;
  final int fim;
  final int fimComSeparador;
}
