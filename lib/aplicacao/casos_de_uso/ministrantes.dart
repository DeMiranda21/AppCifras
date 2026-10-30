import '../../dominio/entidades/ministrante.dart';
import '../../dominio/objetos_de_valor/id_ministrante.dart';
import '../../dominio/repositorios/repositorio_ministrantes.dart';
import '../portas/gerador_id_ministrante.dart';

class CriarMinistrante {
  const CriarMinistrante(this._repositorio, this._geradorId);

  final RepositorioMinistrantes _repositorio;
  final GeradorIdMinistrante _geradorId;

  Future<Ministrante> executar(String nome) async {
    final ministrante = Ministrante(
      id: _geradorId.gerar(),
      nome: nome,
      arquivado: false,
    );
    await _repositorio.salvar(ministrante);
    return ministrante;
  }
}

class ListarMinistrantesAtivos {
  const ListarMinistrantesAtivos(this._repositorio);

  final RepositorioMinistrantes _repositorio;

  Future<List<Ministrante>> executar() =>
      _repositorio.listar(incluirArquivados: false);
}

class ObterMinistrante {
  const ObterMinistrante(this._repositorio);

  final RepositorioMinistrantes _repositorio;

  Future<Ministrante?> executar(IdMinistrante id) =>
      _repositorio.obterPorId(id);
}

class RenomearMinistrante {
  const RenomearMinistrante(this._repositorio);

  final RepositorioMinistrantes _repositorio;

  Future<void> executar(IdMinistrante id, String nome) =>
      _repositorio.renomear(id, nome);
}

class ArquivarMinistrante {
  const ArquivarMinistrante(this._repositorio);

  final RepositorioMinistrantes _repositorio;

  Future<void> executar(IdMinistrante id) => _repositorio.arquivar(id);
}

class RestaurarMinistrante {
  const RestaurarMinistrante(this._repositorio);

  final RepositorioMinistrantes _repositorio;

  Future<void> executar(IdMinistrante id) => _repositorio.restaurar(id);
}
