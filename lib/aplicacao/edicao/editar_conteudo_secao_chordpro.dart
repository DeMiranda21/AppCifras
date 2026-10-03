import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

enum EstadoEdicaoConteudoSecaoChordPro { alterado, semAlteracao, invalido }

class ContextoConteudoSecaoChordPro {
  const ContextoConteudoSecaoChordPro({
    required this.faixa,
    required this.conteudoInterno,
  });

  final FaixaSecaoChordPro faixa;
  final String conteudoInterno;
}

class ResultadoEdicaoConteudoSecaoChordPro {
  const ResultadoEdicaoConteudoSecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.estado,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final EstadoEdicaoConteudoSecaoChordPro estado;

  bool get foiAlterado => estado == EstadoEdicaoConteudoSecaoChordPro.alterado;
}

/// Substitui somente o conteúdo interno de uma seção com limites confiáveis.
///
/// Os delimitadores são encontrados pelo [LocalizadorSecaoChordPro] e não são
/// reescritos. Isso preserva aliases e ambientes externos literalmente.
class EditarConteudoSecaoChordPro {
  EditarConteudoSecaoChordPro({LocalizadorSecaoChordPro? localizador})
    : _localizador = localizador ?? LocalizadorSecaoChordPro();

  final LocalizadorSecaoChordPro _localizador;

  ContextoConteudoSecaoChordPro? contextoAtual({
    required String conteudo,
    required int indiceMarcador,
  }) {
    final faixa = _localizador.localizar(
      conteudo: conteudo,
      indiceMarcador: indiceMarcador,
    );
    if (faixa == null) {
      return null;
    }
    return ContextoConteudoSecaoChordPro(
      faixa: faixa,
      conteudoInterno: conteudo.substring(
        faixa.inicioConteudo,
        faixa.fimConteudo,
      ),
    );
  }

  ResultadoEdicaoConteudoSecaoChordPro editar({
    required String conteudo,
    required int indiceMarcador,
    required String novoConteudoInterno,
  }) {
    final contexto = contextoAtual(
      conteudo: conteudo,
      indiceMarcador: indiceMarcador,
    );
    if (contexto == null) {
      return _resultado(
        conteudo,
        const SelecaoTextoChordPro(inicio: 0, fim: 0),
        EstadoEdicaoConteudoSecaoChordPro.invalido,
      );
    }

    if (novoConteudoInterno == contexto.conteudoInterno) {
      return _resultado(
        conteudo,
        SelecaoTextoChordPro(
          inicio: contexto.faixa.inicioConteudo,
          fim: contexto.faixa.fimConteudo,
        ),
        EstadoEdicaoConteudoSecaoChordPro.semAlteracao,
      );
    }

    final precisaSeparadorAntesDoFim =
        novoConteudoInterno.isNotEmpty &&
        !_terminaComQuebraDeLinha(novoConteudoInterno);
    final conteudoSubstituto =
        '$novoConteudoInterno'
        '${precisaSeparadorAntesDoFim ? contexto.faixa.separadorAposInicio : ''}';
    final novoConteudo =
        '${conteudo.substring(0, contexto.faixa.inicioConteudo)}'
        '$conteudoSubstituto'
        '${conteudo.substring(contexto.faixa.fimConteudo)}';

    return _resultado(
      novoConteudo,
      SelecaoTextoChordPro(
        inicio: contexto.faixa.inicioConteudo,
        fim: contexto.faixa.inicioConteudo + novoConteudoInterno.length,
      ),
      EstadoEdicaoConteudoSecaoChordPro.alterado,
    );
  }

  ResultadoEdicaoConteudoSecaoChordPro _resultado(
    String conteudo,
    SelecaoTextoChordPro selecao,
    EstadoEdicaoConteudoSecaoChordPro estado,
  ) => ResultadoEdicaoConteudoSecaoChordPro(
    conteudo: conteudo,
    selecao: selecao,
    estado: estado,
  );

  bool _terminaComQuebraDeLinha(String texto) =>
      texto.endsWith('\n') || texto.endsWith('\r');
}
