import '../../dominio/entidades/origem_sincronizada_versao.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../biblioteca_oficial/estado_biblioteca_oficial.dart';

abstract interface class RepositorioOrigensSincronizadas {
  Future<OrigemSincronizadaVersao?> obterPorVersao(IdVersaoMusica id);

  Future<List<OrigemSincronizadaVersao>> listar();

  Future<void> salvarOrigem(OrigemSincronizadaVersao origem);

  Future<void> marcarAusente(IdVersaoMusica id);

  Future<void> marcarPresente(
    IdVersaoMusica id, {
    required String localizadorExterno,
    required String hashSha256,
  });

  Future<void> remover(IdVersaoMusica id);
}

abstract interface class RepositorioEstadoBibliotecaOficial {
  Future<EstadoBibliotecaOficial?> obterEstadoBibliotecaOficial();

  Future<void> salvarEstadoBibliotecaOficial(EstadoBibliotecaOficial estado);
}
