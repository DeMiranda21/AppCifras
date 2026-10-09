import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../versoes/politica_edicao_versao.dart';

class AvaliarPoliticaEdicaoVersao {
  const AvaliarPoliticaEdicaoVersao(
    this._repositorio, [
    this._politica = const PoliticaEdicaoVersao(),
  ]);
  final RepositorioVersoesMusicas _repositorio;
  final PoliticaEdicaoVersao _politica;
  Future<DecisaoEdicaoVersao> executar(VersaoMusica versao) async =>
      _politica.decidir(
        versao: versao,
        usadaEmLista: await _repositorio.estaUsadaEmLista(versao.id),
      );
}

class RenomearVersaoMusica {
  const RenomearVersaoMusica(this._repositorio);
  final RepositorioVersoesMusicas _repositorio;
  Future<void> executar(IdVersaoMusica id, String nome) =>
      _repositorio.renomear(id, nome);
}

class DefinirVersaoPrincipal {
  const DefinirVersaoPrincipal(this._repositorio);
  final RepositorioVersoesMusicas _repositorio;
  Future<void> executar(IdVersaoMusica id) =>
      _repositorio.definirComoPrincipal(id);
}

class ArquivarVersaoMusica {
  const ArquivarVersaoMusica(this._repositorio);
  final RepositorioVersoesMusicas _repositorio;
  Future<void> executar(IdVersaoMusica id) => _repositorio.arquivar(id);
}

class RestaurarVersaoMusica {
  const RestaurarVersaoMusica(this._repositorio);
  final RepositorioVersoesMusicas _repositorio;
  Future<void> executar(IdVersaoMusica id) => _repositorio.restaurar(id);
}

class ExcluirVersaoMusica {
  const ExcluirVersaoMusica(this._repositorio);
  final RepositorioVersoesMusicas _repositorio;
  Future<void> executar(IdVersaoMusica id) => _repositorio.excluirVersao(id);
}
