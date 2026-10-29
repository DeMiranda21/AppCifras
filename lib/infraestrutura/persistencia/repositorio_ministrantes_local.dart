import '../../dominio/entidades/ministrante.dart';
import '../../dominio/erros/ministrante_nao_encontrado.dart';
import '../../dominio/objetos_de_valor/id_ministrante.dart';
import '../../dominio/repositorios/repositorio_ministrantes.dart';
import 'banco_biblioteca.dart';

class RepositorioMinistrantesLocal implements RepositorioMinistrantes {
  const RepositorioMinistrantesLocal(this._banco);

  final BancoBiblioteca _banco;

  @override
  Future<void> salvar(Ministrante ministrante) => _banco.inserirMinistrante(
    id: ministrante.id.valor,
    nome: ministrante.nome,
    arquivado: ministrante.arquivado,
  );

  @override
  Future<Ministrante?> obterPorId(IdMinistrante id) async {
    final registro = await _banco.obterMinistrantePorId(id.valor);
    return registro == null ? null : _mapear(registro);
  }

  @override
  Future<List<Ministrante>> listar({bool incluirArquivados = true}) async =>
      (await _banco.listarMinistrantes(incluirArquivados: incluirArquivados))
          .map(_mapear)
          .toList(growable: false);

  @override
  Future<void> renomear(IdMinistrante id, String nome) async {
    final atual = await obterPorId(id);
    if (atual == null) throw MinistranteNaoEncontrado(id);
    final renomeado = atual.renomear(nome);
    final atualizados = await _banco.renomearMinistrante(
      id: id.valor,
      nome: renomeado.nome,
    );
    if (atualizados != 1) throw MinistranteNaoEncontrado(id);
  }

  @override
  Future<void> arquivar(IdMinistrante id) => _definirArquivado(id, true);

  @override
  Future<void> restaurar(IdMinistrante id) => _definirArquivado(id, false);

  Future<void> _definirArquivado(IdMinistrante id, bool arquivado) async {
    final atualizados = await _banco.definirMinistranteArquivado(
      id: id.valor,
      arquivado: arquivado,
    );
    if (atualizados != 1) throw MinistranteNaoEncontrado(id);
  }

  Ministrante _mapear(MinistranteRegistro registro) => Ministrante(
    id: IdMinistrante(registro.id),
    nome: registro.nome,
    arquivado: registro.arquivado,
  );
}
