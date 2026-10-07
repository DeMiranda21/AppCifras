import '../../aplicacao/portas/repositorio_classificacao_musica.dart';
import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import 'banco_biblioteca.dart';

class RepositorioClassificacaoMusicaLocal
    implements RepositorioClassificacaoMusica {
  const RepositorioClassificacaoMusicaLocal(this._banco);
  final BancoBiblioteca _banco;

  @override
  Future<ClassificacaoMusica> obter(IdMusica idMusica) async {
    final energia = await _banco.obterEnergiaMusica(idMusica.valor);
    final tags = await _banco.listarTagsMusica(idMusica.valor);
    return ClassificacaoMusica(
      energia: energia == null
          ? null
          : EnergiaMusica.values.byName(energia.energia),
      tags: [for (final tag in tags) TagMusica(tag.valor)],
    );
  }

  @override
  Future<Map<IdMusica, ClassificacaoMusica>> listar() async {
    final resultados = await Future.wait([
      _banco.listarEnergiasMusicas(),
      _banco.listarTodasTagsMusicas(),
    ]);
    final energias = resultados[0] as List<EnergiasMusica>;
    final tags = resultados[1] as List<TagsMusica>;
    final classificacoes = <IdMusica, ClassificacaoMusica>{
      for (final energia in energias)
        IdMusica(energia.idMusica): ClassificacaoMusica(
          energia: EnergiaMusica.values.byName(energia.energia),
        ),
    };
    for (final tag in tags) {
      final id = IdMusica(tag.idMusica);
      final atual = classificacoes[id] ?? const ClassificacaoMusica();
      classificacoes[id] = ClassificacaoMusica(
        energia: atual.energia,
        tags: [...atual.tags, TagMusica(tag.valor)],
      );
    }
    return Map.unmodifiable(classificacoes);
  }

  @override
  Future<void> definirEnergia(IdMusica idMusica, EnergiaMusica? energia) =>
      _banco.definirEnergiaMusica(idMusica.valor, energia?.name);

  @override
  Future<void> substituirTags(IdMusica idMusica, Iterable<TagMusica> tags) {
    final unicas = <String, TagMusica>{};
    for (final tag in tags) {
      unicas.putIfAbsent(tag.chaveNormalizada, () => tag);
    }
    return _banco.substituirTagsMusica(
      idMusica.valor,
      unicas.values.map(
        (tag) => (valor: tag.valor, chave: tag.chaveNormalizada),
      ),
    );
  }

  @override
  Future<void> removerPorMusica(IdMusica idMusica) =>
      _banco.removerClassificacaoMusica(idMusica.valor);
}
