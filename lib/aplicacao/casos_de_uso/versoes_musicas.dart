import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../portas/gerador_id_versao_musica.dart';

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

class ListarVersoesMusica {
  const ListarVersoesMusica(this._repositorio);

  final RepositorioVersoesMusicas _repositorio;

  Future<List<VersaoMusica>> executar(IdMusica idMusica) async =>
      (await _repositorio.listarPorMusica(idMusica))
          .where((versao) => !versao.arquivada)
          .toList(growable: false);
}

class CriarVersaoMusica {
  const CriarVersaoMusica({
    required this._repositorio,
    required this._geradorId,
  });

  final RepositorioVersoesMusicas _repositorio;
  final GeradorIdVersaoMusica _geradorId;

  Future<VersaoMusica> executar({
    required VersaoMusica origem,
    required String nome,
  }) async {
    final versao = VersaoMusica(
      id: _geradorId.gerar(),
      idMusica: origem.idMusica,
      nome: nome,
      documento: origem.documento,
      principal: false,
      arquivada: false,
    );
    await _repositorio.salvarVersao(versao);
    return versao;
  }
}
