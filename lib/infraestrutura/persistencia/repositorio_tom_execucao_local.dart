import '../../aplicacao/portas/repositorio_tom_execucao.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/nota.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import 'banco_biblioteca.dart';

class RepositorioTomExecucaoLocal implements RepositorioTomExecucao {
  const RepositorioTomExecucaoLocal(this._banco);

  final BancoBiblioteca _banco;

  @override
  Future<Tom?> obterUltimoTom(IdMusica idMusica) async {
    final preferencia = await _banco.obterTomExecucaoPorMusica(idMusica.valor);
    if (preferencia == null) {
      return null;
    }
    try {
      return Tom(
        notaFundamental: Nota(
          nome: NomeNota.values.byName(preferencia.nomeNota),
          alteracao: AlteracaoNota.values.byName(preferencia.alteracao),
        ),
        modo: ModoTom.values.byName(preferencia.modo),
      );
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> salvarUltimoTom(IdMusica idMusica, Tom tom) =>
      _banco.salvarTomExecucao(
        idMusica: idMusica.valor,
        nomeNota: tom.notaFundamental.nome.name,
        alteracao: tom.notaFundamental.alteracao.name,
        modo: tom.modo.name,
      );

  @override
  Future<void> removerUltimoTom(IdMusica idMusica) =>
      _banco.removerTomExecucao(idMusica.valor);
}
