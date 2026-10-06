import 'package:appcifras/aplicacao/casos_de_uso/classificacao_musica.dart';
import 'package:appcifras/aplicacao/portas/repositorio_classificacao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salva e obtém classificação por música', () async {
    final repositorio = _RepositorioClassificacaoFake();
    final id = IdMusica('musica-1');
    await SalvarClassificacaoMusica(repositorio).executar(
      id,
      energia: EnergiaMusica.animada,
      tags: [TagMusica('Ceia'), TagMusica('Congregacional')],
    );

    final classificacao = await ObterClassificacaoMusica(repositorio)
        .executar(id);
    expect(classificacao.energia, EnergiaMusica.animada);
    expect(classificacao.tags, [
      TagMusica('Ceia'),
      TagMusica('Congregacional'),
    ]);
  });
}

class _RepositorioClassificacaoFake implements RepositorioClassificacaoMusica {
  final Map<IdMusica, ClassificacaoMusica> _dados = {};

  @override
  Future<void> definirEnergia(IdMusica id, EnergiaMusica? energia) async {
    final atual = await obter(id);
    _dados[id] = ClassificacaoMusica(energia: energia, tags: atual.tags);
  }

  @override
  Future<ClassificacaoMusica> obter(IdMusica id) async =>
      _dados[id] ?? const ClassificacaoMusica();

  @override
  Future<void> removerPorMusica(IdMusica id) async => _dados.remove(id);

  @override
  Future<void> substituirTags(IdMusica id, Iterable<TagMusica> tags) async {
    final atual = await obter(id);
    _dados[id] = ClassificacaoMusica(
      energia: atual.energia,
      tags: tags.toList(),
    );
  }
}
