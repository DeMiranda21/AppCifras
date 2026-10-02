import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoExclusaoSecaoChordPro {
  const ResultadoExclusaoSecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiExcluida,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiExcluida;
}

/// Remove somente uma seção explícita cujo fechamento correspondente existe.
class ExcluirSecaoChordPro {
  ExcluirSecaoChordPro({LocalizadorSecaoChordPro? localizador})
    : _localizador = localizador ?? LocalizadorSecaoChordPro();

  final LocalizadorSecaoChordPro _localizador;

  ResultadoExclusaoSecaoChordPro excluir({
    required String conteudo,
    required int indiceMarcador,
  }) {
    final faixa = _localizador.localizar(
      conteudo: conteudo,
      indiceMarcador: indiceMarcador,
    );
    if (faixa == null) {
      return ResultadoExclusaoSecaoChordPro(
        conteudo: conteudo,
        selecao: SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiExcluida: false,
      );
    }
    return ResultadoExclusaoSecaoChordPro(
      conteudo:
          '${conteudo.substring(0, faixa.inicio)}${conteudo.substring(faixa.fimComSeparador)}',
      selecao: SelecaoTextoChordPro(inicio: faixa.inicio, fim: faixa.inicio),
      foiExcluida: true,
    );
  }
}
