import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';

/// Preferências locais de execução, sem vínculo com o ChordPro canônico.
abstract interface class RepositorioTomExecucao {
  Future<Tom?> obterUltimoTom(IdMusica idMusica);

  Future<void> salvarUltimoTom(IdMusica idMusica, Tom tom);

  Future<void> removerUltimoTom(IdMusica idMusica);
}
