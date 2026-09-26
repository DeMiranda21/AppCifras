import '../objetos_de_valor/id_lista_culto.dart';

class ListaCultoNaoEncontrada implements Exception {
  const ListaCultoNaoEncontrada(this.id);

  final IdListaCulto id;
}
