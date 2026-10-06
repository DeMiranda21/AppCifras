import '../../dominio/objetos_de_valor/energia_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tag_musica.dart';
import '../portas/repositorio_classificacao_musica.dart';

class ObterClassificacaoMusica {
  const ObterClassificacaoMusica(this._repositorio);
  final RepositorioClassificacaoMusica _repositorio;
  Future<ClassificacaoMusica> executar(IdMusica id) => _repositorio.obter(id);
}

class SalvarClassificacaoMusica {
  const SalvarClassificacaoMusica(this._repositorio);
  final RepositorioClassificacaoMusica _repositorio;

  Future<void> executar(
    IdMusica id, {
    required EnergiaMusica? energia,
    required Iterable<TagMusica> tags,
  }) async {
    await _repositorio.definirEnergia(id, energia);
    await _repositorio.substituirTags(id, tags);
  }
}
