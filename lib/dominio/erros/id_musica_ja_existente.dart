import '../objetos_de_valor/id_musica.dart';

class IdMusicaJaExistente implements Exception {
  const IdMusicaJaExistente(this.id);

  final IdMusica id;
}
