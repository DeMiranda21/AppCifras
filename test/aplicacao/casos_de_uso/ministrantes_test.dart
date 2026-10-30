import 'package:appcifras/aplicacao/casos_de_uso/ministrantes.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_ministrante.dart';
import 'package:appcifras/dominio/entidades/ministrante.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_ministrante.dart';
import 'package:appcifras/dominio/repositorios/repositorio_ministrantes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria, obtém e permite nomes duplicados com IDs distintos', () async {
    final repositorio = _RepositorioMinistrantesMemoria();
    final criar = CriarMinistrante(
      repositorio,
      _GeradorIdMinistranteSequencial([
        IdMinistrante('ministrante-1'),
        IdMinistrante('ministrante-2'),
      ]),
    );

    final primeiro = await criar.executar(' Nome igual ');
    final segundo = await criar.executar('Nome igual');

    expect(primeiro.id, isNot(segundo.id));
    expect(primeiro.nome, 'Nome igual');
    expect(await ObterMinistrante(repositorio).executar(primeiro.id), primeiro);
    expect(await ListarMinistrantesAtivos(repositorio).executar(), [
      primeiro,
      segundo,
    ]);
  });

  test('renomeia, arquiva, filtra ativos e restaura preservando ID', () async {
    final repositorio = _RepositorioMinistrantesMemoria();
    final id = IdMinistrante('ministrante-1');
    await repositorio.salvar(
      Ministrante(id: id, nome: 'Original', arquivado: false),
    );

    await RenomearMinistrante(repositorio).executar(id, ' Renomeado ');
    await ArquivarMinistrante(repositorio).executar(id);

    final arquivado = await ObterMinistrante(repositorio).executar(id);
    expect(arquivado?.id, id);
    expect(arquivado?.nome, 'Renomeado');
    expect(arquivado?.arquivado, isTrue);
    expect(await ListarMinistrantesAtivos(repositorio).executar(), isEmpty);

    await RestaurarMinistrante(repositorio).executar(id);
    final restaurado = await ObterMinistrante(repositorio).executar(id);
    expect(restaurado?.id, id);
    expect(restaurado?.arquivado, isFalse);
  });
}

class _GeradorIdMinistranteSequencial implements GeradorIdMinistrante {
  _GeradorIdMinistranteSequencial(this._ids);

  final List<IdMinistrante> _ids;

  @override
  IdMinistrante gerar() => _ids.removeAt(0);
}

class _RepositorioMinistrantesMemoria implements RepositorioMinistrantes {
  final Map<IdMinistrante, Ministrante> _ministrantes = {};

  @override
  Future<void> salvar(Ministrante ministrante) async {
    _ministrantes[ministrante.id] = ministrante;
  }

  @override
  Future<Ministrante?> obterPorId(IdMinistrante id) async => _ministrantes[id];

  @override
  Future<List<Ministrante>> listar({bool incluirArquivados = true}) async =>
      _ministrantes.values
          .where((ministrante) => incluirArquivados || !ministrante.arquivado)
          .toList();

  @override
  Future<void> renomear(IdMinistrante id, String nome) async {
    _ministrantes[id] = _ministrantes[id]!.renomear(nome);
  }

  @override
  Future<void> arquivar(IdMinistrante id) async {
    _ministrantes[id] = _ministrantes[id]!.arquivar();
  }

  @override
  Future<void> restaurar(IdMinistrante id) async {
    _ministrantes[id] = _ministrantes[id]!.restaurar();
  }
}
