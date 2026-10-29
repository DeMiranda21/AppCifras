import '../objetos_de_valor/id_ministrante.dart';

class MinistranteNaoEncontrado implements Exception {
  const MinistranteNaoEncontrado(this.id);

  final IdMinistrante id;
}
