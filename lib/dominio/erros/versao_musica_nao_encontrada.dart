import '../objetos_de_valor/id_versao_musica.dart';

class VersaoMusicaNaoEncontrada implements Exception {
  const VersaoMusicaNaoEncontrada(this.id);
  final IdVersaoMusica id;
}
