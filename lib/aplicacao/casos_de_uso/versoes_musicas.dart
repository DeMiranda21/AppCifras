import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../portas/repositorio_tom_execucao.dart';
import 'ciclo_vida_versoes_musicas.dart';
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

/// Atualiza explicitamente uma versão quando a política permite sobrescrita.
class AtualizarConteudoVersaoMusica {
  const AtualizarConteudoVersaoMusica(this._repositorio, {this.repositorioTom});
  final RepositorioVersoesMusicas _repositorio;
  final RepositorioTomExecucao? repositorioTom;

  Future<void> executar(VersaoMusica versao) async {
    final atual = await _repositorio.obterVersaoPorId(versao.id);
    if (atual == null) throw VersaoMusicaNaoEncontrada(versao.id);
    if (atual.idMusica != versao.idMusica) {
      throw ArgumentError('A edição deve preservar a música da versão.');
    }
    final decisao = await AvaliarPoliticaEdicaoVersao(_repositorio)
        .executar(atual);
    if (!decisao.podeSobrescreverConteudo) {
      throw StateError('Esta versão exige salvar como nova versão.');
    }
    await _repositorio.atualizarConteudoVersao(versao);
    if (!atual.principal && atual.tomOriginal != versao.tomOriginal) {
      await repositorioTom?.removerUltimoTom(atual.id);
    }
  }
}
