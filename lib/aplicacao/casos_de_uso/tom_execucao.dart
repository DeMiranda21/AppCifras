import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../portas/repositorio_tom_execucao.dart';

class ObterUltimoTomExecucao {
  const ObterUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<Tom?> executar(IdMusica idMusica) =>
      _repositorio.obterUltimoTom(idMusica);
}

class SalvarUltimoTomExecucao {
  const SalvarUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<void> executar(IdMusica idMusica, Tom tom) =>
      _repositorio.salvarUltimoTom(idMusica, tom);
}

class RemoverUltimoTomExecucao {
  const RemoverUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<void> executar(IdMusica idMusica) =>
      _repositorio.removerUltimoTom(idMusica);
}
