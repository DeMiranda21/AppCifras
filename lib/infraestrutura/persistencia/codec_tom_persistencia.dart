import '../../dominio/objetos_de_valor/nota.dart';
import '../../dominio/objetos_de_valor/tom.dart';

class CodecTomPersistencia {
  const CodecTomPersistencia();

  static const _versao = '1';

  String codificar(Tom tom) => [
    _versao,
    tom.notaFundamental.nome.name,
    tom.notaFundamental.alteracao.name,
    tom.modo.name,
  ].join('|');

  Tom decodificar(String valor) {
    final partes = valor.split('|');
    if (partes.length != 4 || partes.first != _versao) {
      throw FormatException('Tom persistido inválido: $valor.');
    }
    try {
      return Tom(
        notaFundamental: Nota(
          nome: NomeNota.values.byName(partes[1]),
          alteracao: AlteracaoNota.values.byName(partes[2]),
        ),
        modo: ModoTom.values.byName(partes[3]),
      );
    } on ArgumentError {
      throw FormatException('Tom persistido inválido: $valor.');
    }
  }
}
