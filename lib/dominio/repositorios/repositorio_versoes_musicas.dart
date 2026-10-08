import '../entidades/versao_musica.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/id_versao_musica.dart';

abstract interface class RepositorioVersoesMusicas {
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica);

  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id);

  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica);
}
