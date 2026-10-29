import '../entidades/ministrante.dart';
import '../objetos_de_valor/id_ministrante.dart';

abstract interface class RepositorioMinistrantes {
  Future<void> salvar(Ministrante ministrante);

  Future<Ministrante?> obterPorId(IdMinistrante id);

  Future<List<Ministrante>> listar({bool incluirArquivados = true});

  Future<void> renomear(IdMinistrante id, String nome);

  Future<void> arquivar(IdMinistrante id);

  Future<void> restaurar(IdMinistrante id);
}
