import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../portas/repositorio_tom_execucao.dart';

class ObterUltimoTomExecucao {
  const ObterUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<Tom?> executar(IdVersaoMusica idVersaoMusica) =>
      _repositorio.obterUltimoTom(idVersaoMusica);
}

class SalvarUltimoTomExecucao {
  const SalvarUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<void> executar(IdVersaoMusica idVersaoMusica, Tom tom) =>
      _repositorio.salvarUltimoTom(idVersaoMusica, tom);
}

class RemoverUltimoTomExecucao {
  const RemoverUltimoTomExecucao(this._repositorio);

  final RepositorioTomExecucao _repositorio;

  Future<void> executar(IdVersaoMusica idVersaoMusica) =>
      _repositorio.removerUltimoTom(idVersaoMusica);
}
