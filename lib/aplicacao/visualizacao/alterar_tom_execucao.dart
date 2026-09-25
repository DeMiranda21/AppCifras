import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/servico_transposicao.dart';

/// Altera temporariamente um tom de execução sem modificar a música.
class AlterarTomExecucao {
  AlterarTomExecucao({ServicoTransposicao? servicoTransposicao})
    : _servicoTransposicao = servicoTransposicao ?? ServicoTransposicao();

  final ServicoTransposicao _servicoTransposicao;

  /// Avança ou recua [semitons], preservando o modo tonal atual.
  Tom executar(Tom tomAtual, int semitons) => Tom(
    notaFundamental: _servicoTransposicao.transporNota(
      tomAtual.notaFundamental,
      semitons,
    ),
    modo: tomAtual.modo,
  );
}
