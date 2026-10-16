import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../portas/repositorio_sincronizacao.dart';
import '../versoes/politica_edicao_versao.dart';

class AvaliarPoliticaEdicaoVersao {
  const AvaliarPoliticaEdicaoVersao(
    this._repositorio, {
    this.repositorioOrigens,
    this.politica = const PoliticaEdicaoVersao(),
  });
  final RepositorioVersoesMusicas _repositorio;
  final RepositorioOrigensSincronizadas? repositorioOrigens;
  final PoliticaEdicaoVersao politica;
  Future<DecisaoEdicaoVersao> executar(VersaoMusica versao) async {
    final origem = await repositorioOrigens?.obterPorVersao(versao.id);
    return politica.decidir(
      versao: versao,
      usadaEmLista: await _repositorio.estaUsadaEmLista(versao.id),
      sincronizada: origem != null,
    );
  }
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
