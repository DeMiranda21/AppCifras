import '../entidades/versao_musica.dart';
import '../objetos_de_valor/id_musica.dart';
import '../objetos_de_valor/id_versao_musica.dart';

abstract interface class RepositorioVersoesMusicas {
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica);

  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id);

  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica);

  Future<void> salvarVersao(VersaoMusica versao);

  Future<bool> estaUsadaEmLista(IdVersaoMusica id);

  Future<void> renomear(IdVersaoMusica id, String nome);

  Future<void> definirComoPrincipal(IdVersaoMusica id);

  Future<void> arquivar(IdVersaoMusica id);

  Future<void> restaurar(IdVersaoMusica id);

  Future<void> excluirVersao(IdVersaoMusica id);
}
