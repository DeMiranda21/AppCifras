import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoExclusaoBlocoChordPro {
  const ResultadoExclusaoBlocoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiExcluido,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiExcluido;
}

/// Exclui somente uma faixa de bloco previamente considerada segura.
class ExcluirBlocoChordPro {
  ResultadoExclusaoBlocoChordPro excluir({
    required String conteudo,
    required FaixaBlocoChordPro faixa,
  }) {
    if (faixa.inicio < 0 ||
        faixa.fim < faixa.inicio ||
        faixa.fimComSeparador < faixa.fim ||
        faixa.fimComSeparador > conteudo.length) {
      return ResultadoExclusaoBlocoChordPro(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiExcluido: false,
      );
    }
    return ResultadoExclusaoBlocoChordPro(
      conteudo:
          '${conteudo.substring(0, faixa.inicio)}${conteudo.substring(faixa.fimComSeparador)}',
      selecao: SelecaoTextoChordPro(inicio: faixa.inicio, fim: faixa.inicio),
      foiExcluido: true,
    );
  }
}
