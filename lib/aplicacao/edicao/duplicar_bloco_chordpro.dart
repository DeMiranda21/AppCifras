import 'localizador_secao_chordpro.dart';
import 'transformar_selecao_chordpro.dart';

class ResultadoDuplicacaoBlocoChordPro {
  const ResultadoDuplicacaoBlocoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiDuplicado,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiDuplicado;
}

/// Duplica literalmente qualquer bloco com faixa segura.
class DuplicarBlocoChordPro {
  ResultadoDuplicacaoBlocoChordPro duplicar({
    required String conteudo,
    required FaixaBlocoChordPro faixa,
  }) {
    if (faixa.inicio < 0 ||
        faixa.fim < faixa.inicio ||
        faixa.fim > conteudo.length ||
        faixa.fimComSeparador < faixa.fim ||
        faixa.fimComSeparador > conteudo.length) {
      return _semDuplicacao(conteudo);
    }
    final bloco = conteudo.substring(faixa.inicio, faixa.fim);
    if (bloco.isEmpty) return _semDuplicacao(conteudo);
    final separador = conteudo.substring(faixa.fim, faixa.fimComSeparador);
    final separadorEfetivo = separador.isEmpty
        ? _separadorDoDocumento(conteudo)
        : separador;
    final inicioDaCopia = faixa.fim + separadorEfetivo.length;
    return ResultadoDuplicacaoBlocoChordPro(
      conteudo:
          '${conteudo.substring(0, faixa.fim)}$separadorEfetivo$bloco${conteudo.substring(faixa.fim)}',
      selecao: SelecaoTextoChordPro(inicio: inicioDaCopia, fim: inicioDaCopia),
      foiDuplicado: true,
    );
  }

  ResultadoDuplicacaoBlocoChordPro _semDuplicacao(String conteudo) =>
      ResultadoDuplicacaoBlocoChordPro(
        conteudo: conteudo,
        selecao: const SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiDuplicado: false,
      );

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';
}
