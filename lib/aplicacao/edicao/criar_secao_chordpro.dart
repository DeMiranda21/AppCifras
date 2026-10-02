import '../estrutura/reconhecedor_secao_musica.dart';
import 'transformar_selecao_chordpro.dart';

enum PosicaoCriacaoSecaoChordPro { finalDoDocumento }

class ResultadoCriacaoSecaoChordPro {
  const ResultadoCriacaoSecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.foiCriada,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiCriada;
}

/// Insere uma seção canônica e vazia, sem alterar o documento já existente.
class CriarSecaoChordPro {
  CriarSecaoChordPro({ReconhecedorSecaoMusica? reconhecedor})
    : _reconhecedor = reconhecedor ?? ReconhecedorSecaoMusica();

  final ReconhecedorSecaoMusica _reconhecedor;

  ResultadoCriacaoSecaoChordPro criar({
    required String conteudo,
    required TipoSecaoMusica tipo,
    required String label,
    PosicaoCriacaoSecaoChordPro posicao =
        PosicaoCriacaoSecaoChordPro.finalDoDocumento,
  }) {
    if (label.trim().isEmpty) {
      return ResultadoCriacaoSecaoChordPro(
        conteudo: conteudo,
        selecao: SelecaoTextoChordPro(inicio: 0, fim: 0),
        foiCriada: false,
      );
    }
    switch (posicao) {
      case PosicaoCriacaoSecaoChordPro.finalDoDocumento:
        final separador = _separadorDoDocumento(conteudo);
        final prefixo = conteudo.isEmpty || _terminaComQuebraDeLinha(conteudo)
            ? conteudo
            : '$conteudo$separador';
        final abertura = _reconhecedor.escreverInicioCanonico(tipo, label);
        final fechamento = _reconhecedor.escreverFimCanonico(tipo);
        return ResultadoCriacaoSecaoChordPro(
          conteudo: '$prefixo$abertura$separador$fechamento',
          selecao: SelecaoTextoChordPro(
            inicio: prefixo.length,
            fim: prefixo.length + abertura.length,
          ),
          foiCriada: true,
        );
    }
  }

  bool _terminaComQuebraDeLinha(String conteudo) =>
      conteudo.endsWith('\n') || conteudo.endsWith('\r');

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';
}
