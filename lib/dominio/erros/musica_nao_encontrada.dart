import '../objetos_de_valor/id_musica.dart';

class MusicaNaoEncontrada implements Exception {
  const MusicaNaoEncontrada(this.id);

  final IdMusica id;
}
