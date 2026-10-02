import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoDuplicacaoSecaoChordPro {
  const ResultadoDuplicacaoSecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiDuplicada,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiDuplicada;
}

/// Duplica literalmente uma seção explícita com começo e fim confiáveis.
class DuplicarSecaoChordPro {
  DuplicarSecaoChordPro({LocalizadorSecaoChordPro? localizador})
    : _localizador = localizador ?? LocalizadorSecaoChordPro();

  final LocalizadorSecaoChordPro _localizador;

  ResultadoDuplicacaoSecaoChordPro duplicar({
    required String conteudo,
    required int indiceMarcador,
  }) {
    final faixa = _localizador.localizar(
      conteudo: conteudo,
      indiceMarcador: indiceMarcador,
    );
    if (faixa == null) {
      return ResultadoDuplicacaoSecaoChordPro(
        conteudo: conteudo,
        selecao: SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiDuplicada: false,
      );
    }
    final trecho = conteudo.substring(faixa.inicio, faixa.fim);
    final separador =
        _separadorDepoisDaFaixa(conteudo, faixa) ??
        _separadorDoDocumento(conteudo);
    final inicioDaCopia = faixa.fim + separador.length;
    return ResultadoDuplicacaoSecaoChordPro(
      conteudo:
          '${conteudo.substring(0, faixa.fim)}$separador$trecho${conteudo.substring(faixa.fim)}',
      selecao: SelecaoTextoChordPro(inicio: inicioDaCopia, fim: inicioDaCopia),
      foiDuplicada: true,
    );
  }

  String? _separadorDepoisDaFaixa(String conteudo, FaixaSecaoChordPro faixa) {
    final depois = conteudo.substring(faixa.fim, faixa.fimComSeparador);
    return depois.isEmpty ? null : depois;
  }

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';
}
