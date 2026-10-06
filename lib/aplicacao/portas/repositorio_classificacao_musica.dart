import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';

class ClassificacaoMusica {
  const ClassificacaoMusica({this.energia, this.tags = const []});
  final EnergiaMusica? energia;
  final List<TagMusica> tags;
}

abstract interface class RepositorioClassificacaoMusica {
  Future<ClassificacaoMusica> obter(IdMusica idMusica);
  Future<void> definirEnergia(IdMusica idMusica, EnergiaMusica? energia);
  Future<void> substituirTags(IdMusica idMusica, Iterable<TagMusica> tags);
  Future<void> removerPorMusica(IdMusica idMusica);
}
