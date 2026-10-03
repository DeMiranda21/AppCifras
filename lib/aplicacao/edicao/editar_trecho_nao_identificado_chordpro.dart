import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ContextoTrechoNaoIdentificadoChordPro {
  const ContextoTrechoNaoIdentificadoChordPro({
    required this.faixa,
    required this.conteudo,
  });

  final FaixaTrechoNaoIdentificadoChordPro faixa;
  final String conteudo;
}

class ResultadoEdicaoTrechoNaoIdentificadoChordPro {
  const ResultadoEdicaoTrechoNaoIdentificadoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiAlterado,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiAlterado;
}

/// Edita literalmente um range livre derivado, sem incluir diretivas vizinhas.
class EditarTrechoNaoIdentificadoChordPro {
  EditarTrechoNaoIdentificadoChordPro({LocalizadorSecaoChordPro? localizador})
    : _localizador = localizador ?? LocalizadorSecaoChordPro();

  final LocalizadorSecaoChordPro _localizador;

  ContextoTrechoNaoIdentificadoChordPro? contextoAtual({
    required String conteudo,
    required int inicioConteudo,
  }) {
    final faixa = _localizador.localizarTrechoNaoIdentificado(
      conteudo: conteudo,
      inicioConteudo: inicioConteudo,
    );
    if (faixa == null) return null;
    return ContextoTrechoNaoIdentificadoChordPro(
      faixa: faixa,
      conteudo: conteudo.substring(faixa.inicio, faixa.fim),
    );
  }

  ResultadoEdicaoTrechoNaoIdentificadoChordPro editar({
    required String conteudo,
    required int inicioConteudo,
    required String novoConteudo,
  }) {
    final contexto = contextoAtual(
      conteudo: conteudo,
      inicioConteudo: inicioConteudo,
    );
    if (contexto == null) {
      return ResultadoEdicaoTrechoNaoIdentificadoChordPro(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiAlterado: false,
      );
    }
    if (novoConteudo == contexto.conteudo) {
      return ResultadoEdicaoTrechoNaoIdentificadoChordPro(
        conteudo: conteudo,
        selecao: SelecaoTextoChordPro(
          inicio: contexto.faixa.inicio,
          fim: contexto.faixa.fim,
        ),
        foiAlterado: false,
      );
    }
    return ResultadoEdicaoTrechoNaoIdentificadoChordPro(
      conteudo:
          '${conteudo.substring(0, contexto.faixa.inicio)}$novoConteudo${conteudo.substring(contexto.faixa.fim)}',
      selecao: SelecaoTextoChordPro(
        inicio: contexto.faixa.inicio,
        fim: contexto.faixa.inicio + novoConteudo.length,
      ),
      foiAlterado: true,
    );
  }
}
