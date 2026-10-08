import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';

class ObterVersaoPrincipalMusica {
  const ObterVersaoPrincipalMusica(this._repositorio);

  final RepositorioVersoesMusicas _repositorio;

  Future<VersaoMusica?> executar(IdMusica idMusica) =>
      _repositorio.obterPrincipalPorMusica(idMusica);
}

class ObterVersaoMusicaPorId {
  const ObterVersaoMusicaPorId(this._repositorio);

  final RepositorioVersoesMusicas _repositorio;

  Future<VersaoMusica?> executar(IdVersaoMusica idVersaoMusica) =>
      _repositorio.obterVersaoPorId(idVersaoMusica);
}
