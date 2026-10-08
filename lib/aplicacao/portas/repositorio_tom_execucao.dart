import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';

/// Preferências locais de execução, sem vínculo com o ChordPro canônico.
abstract interface class RepositorioTomExecucao {
  Future<Tom?> obterUltimoTom(IdVersaoMusica idVersaoMusica);

  Future<void> salvarUltimoTom(IdVersaoMusica idVersaoMusica, Tom tom);

  Future<void> removerUltimoTom(IdVersaoMusica idVersaoMusica);
}
