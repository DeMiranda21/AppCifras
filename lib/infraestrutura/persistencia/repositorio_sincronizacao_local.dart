import '../../aplicacao/portas/repositorio_sincronizacao.dart';
import '../../aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import '../../aplicacao/biblioteca_oficial/estado_biblioteca_oficial.dart';
import '../../dominio/entidades/origem_sincronizada_versao.dart';
import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import 'banco_biblioteca.dart';

class RepositorioSincronizacaoLocal
    implements
        RepositorioOrigensSincronizadas,
        RepositorioConfiguracaoPastaSincronizada,
        RepositorioEstadoBibliotecaOficial {
  const RepositorioSincronizacaoLocal(this._banco);

  final BancoBiblioteca _banco;

  @override
  Future<OrigemSincronizadaVersao?> obterPorVersao(IdVersaoMusica id) async {
    final registro = await _banco.obterOrigemSincronizadaVersao(id.valor);
    if (registro == null) return null;
    return OrigemSincronizadaVersao(
      idVersaoMusica: id,
      localizadorExterno: registro.localizadorExterno,
      hashSha256: registro.hashSha256,
      estado: registro.presente
          ? EstadoOrigemSincronizada.presente
          : EstadoOrigemSincronizada.ausente,
    );
  }

  @override
  Future<List<OrigemSincronizadaVersao>> listar() async {
    final registros = await _banco.listarOrigensSincronizadasVersoes();
    return registros
        .map(
          (registro) => OrigemSincronizadaVersao(
            idVersaoMusica: IdVersaoMusica(registro.idVersaoMusica),
            localizadorExterno: registro.localizadorExterno,
            hashSha256: registro.hashSha256,
            estado: registro.presente
                ? EstadoOrigemSincronizada.presente
                : EstadoOrigemSincronizada.ausente,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> salvarOrigem(OrigemSincronizadaVersao origem) async {
    if (await _banco.obterVersaoPorId(origem.idVersaoMusica.valor) == null) {
      throw VersaoMusicaNaoEncontrada(origem.idVersaoMusica);
    }
    await _banco.salvarOrigemSincronizadaVersao(
      idVersaoMusica: origem.idVersaoMusica.valor,
      localizadorExterno: origem.localizadorExterno,
      hashSha256: origem.hashSha256,
      presente: origem.presente,
    );
  }

  @override
  Future<void> marcarAusente(IdVersaoMusica id) async {
    if (await _banco.marcarOrigemSincronizadaAusente(id.valor) != 1) {
      throw StateError('A versão não possui origem sincronizada.');
    }
  }

  @override
  Future<void> marcarPresente(
    IdVersaoMusica id, {
    required String localizadorExterno,
    required String hashSha256,
  }) async {
    if (await _banco.marcarOrigemSincronizadaPresente(
          idVersaoMusica: id.valor,
          localizadorExterno: localizadorExterno,
          hashSha256: hashSha256,
        ) !=
        1) {
      throw StateError('A versão não possui origem sincronizada.');
    }
  }

  @override
  Future<void> remover(IdVersaoMusica id) =>
      _banco.removerOrigemSincronizadaVersao(id.valor);

  @override
  Future<ConfiguracaoPastaSincronizada?> obter() async {
    final registro = await _banco.obterConfiguracaoPasta();
    if (registro == null) return null;
    return ConfiguracaoPastaSincronizada(
      uriArvore: registro.uriArvore,
      autorizacaoPersistente: registro.autorizacaoPersistente,
      nomeLegivel: registro.nomeLegivel,
      ultimaSincronizacaoConcluida: registro.ultimaSincronizacaoConcluida,
    );
  }

  @override
  Future<void> salvarConfiguracao(ConfiguracaoPastaSincronizada configuracao) =>
      _banco.salvarConfiguracaoPasta(
        uriArvore: configuracao.uriArvore,
        autorizacaoPersistente: configuracao.autorizacaoPersistente,
        nomeLegivel: configuracao.nomeLegivel,
        ultimaSincronizacaoConcluida: configuracao.ultimaSincronizacaoConcluida,
      );

  @override
  Future<void> limpar() => _banco.limparConfiguracaoPasta();

  @override
  Future<EstadoBibliotecaOficial?> obterEstadoBibliotecaOficial() async {
    final registro = await _banco.obterEstadoBibliotecaOficial();
    if (registro == null) return null;
    return EstadoBibliotecaOficial(
      ultimaGeracao: registro.ultimaGeracao,
      ultimaAtualizacao: registro.ultimaAtualizacao,
    );
  }

  @override
  Future<void> salvarEstadoBibliotecaOficial(EstadoBibliotecaOficial estado) =>
      _banco.salvarEstadoBibliotecaOficial(
        ultimaGeracao: estado.ultimaGeracao,
        ultimaAtualizacao: estado.ultimaAtualizacao,
      );
}
