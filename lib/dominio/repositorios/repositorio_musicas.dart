import '../entidades/musica.dart';
import '../objetos_de_valor/id_musica.dart';

abstract interface class RepositorioMusicas {
  Future<void> salvar(Musica musica);

  Future<Musica?> obterPorId(IdMusica id);

  Future<List<Musica>> listar();

  Future<void> excluir(IdMusica id);
}
