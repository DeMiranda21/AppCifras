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

/// Reordena literalmente seções explícitas dentro de uma mesma faixa segura.
///
/// Uma faixa segura é uma sequência contígua de blocos com abertura e
/// fechamento correspondentes. Conteúdo implícito e seções malformadas formam
/// limites: uma seção nunca é movida através deles nesta primeira versão.
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
    final inicioDoGrupo = _inicioDoGrupo(faixas, indiceOrigem);
    final fimDoGrupo = _fimDoGrupo(faixas, indiceOrigem);
    if (indiceDestino < inicioDoGrupo || indiceDestino > fimDoGrupo) {
      return _semReordenacao(conteudo);
    }

    final grupo = faixas
        .sublist(inicioDoGrupo, fimDoGrupo + 1)
        .cast<FaixaSecaoChordPro>();
    final origemNoGrupo = indiceOrigem - inicioDoGrupo;
    final destinoNoGrupo = indiceDestino - inicioDoGrupo;
    final novaOrdem = List<FaixaSecaoChordPro>.from(grupo);
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

  FaixaSecaoChordPro? _faixaDo(String conteudo, SecaoMusica secao) {
    final indiceMarcador = secao.indiceMarcador;
    return indiceMarcador == null
        ? null
        : _localizador.localizar(
            conteudo: conteudo,
            indiceMarcador: indiceMarcador,
          );
  }

  int _inicioDoGrupo(List<FaixaSecaoChordPro?> faixas, int indice) {
    var atual = indice;
    while (atual > 0 && faixas[atual - 1] != null) {
      atual -= 1;
    }
    return atual;
  }

  int _fimDoGrupo(List<FaixaSecaoChordPro?> faixas, int indice) {
    var atual = indice;
    while (atual + 1 < faixas.length && faixas[atual + 1] != null) {
      atual += 1;
    }
    return atual;
  }

  String _separadorDoGrupo(String conteudo, List<FaixaSecaoChordPro> grupo) {
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
