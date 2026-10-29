import 'package:appcifras/dominio/entidades/ministrante.dart';
import 'package:appcifras/dominio/erros/ministrante_nao_encontrado.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_ministrante.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_ministrantes_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoBiblioteca banco;
  late RepositorioMinistrantesLocal repositorio;

  setUp(() async {
    banco = BancoBiblioteca(NativeDatabase.memory());
    await banco.inicializar();
    repositorio = RepositorioMinistrantesLocal(banco);
  });

  tearDown(() => banco.close());

  test('salva, obtém e permite nomes duplicados', () async {
    final primeiro = Ministrante(
      id: IdMinistrante('ministrante-1'),
      nome: 'Nome igual',
      arquivado: false,
    );
    final segundo = Ministrante(
      id: IdMinistrante('ministrante-2'),
      nome: 'Nome igual',
      arquivado: false,
    );

    await repositorio.salvar(primeiro);
    await repositorio.salvar(segundo);

    expect(await repositorio.obterPorId(primeiro.id), primeiro);
    expect(await repositorio.listar(), hasLength(2));
  });

  test('renomeia, arquiva, filtra ativos e restaura preservando ID', () async {
    final id = IdMinistrante('ministrante-1');
    await repositorio.salvar(
      Ministrante(id: id, nome: 'Original', arquivado: false),
    );

    await repositorio.renomear(id, ' Renomeado ');
    await repositorio.arquivar(id);

    final arquivado = await repositorio.obterPorId(id);
    expect(arquivado?.nome, 'Renomeado');
    expect(arquivado?.arquivado, isTrue);
    expect(await repositorio.listar(incluirArquivados: false), isEmpty);

    await repositorio.restaurar(id);
    final restaurado = await repositorio.obterPorId(id);
    expect(restaurado?.id, id);
    expect(restaurado?.arquivado, isFalse);
  });

  test('operações sobre ID inexistente falham explicitamente', () async {
    final id = IdMinistrante('inexistente');
    await expectLater(
      repositorio.renomear(id, 'Nome'),
      throwsA(isA<MinistranteNaoEncontrado>()),
    );
    await expectLater(
      repositorio.arquivar(id),
      throwsA(isA<MinistranteNaoEncontrado>()),
    );
  });
}
