import 'dart:typed_data';

import '../portas/pasta_curada_externa.dart';
import '../portas/repositorio_sincronizacao.dart';
import 'configuracao_pasta_sincronizada.dart';

class PastaCuradaNaoConfigurada implements Exception {
  const PastaCuradaNaoConfigurada();

  @override
  String toString() => 'Nenhuma pasta da biblioteca foi configurada.';
}

class GerenciarPastaCurada {
  const GerenciarPastaCurada(this._pastaExterna, this._repositorioConfiguracao);

  final PastaCuradaExterna _pastaExterna;
  final RepositorioConfiguracaoPastaSincronizada _repositorioConfiguracao;

  Future<ConfiguracaoPastaSincronizada?> obterConfiguracao() =>
      _repositorioConfiguracao.obter();

  Future<ConfiguracaoPastaSincronizada?> selecionarPasta() async {
    final selecionada = await _pastaExterna.selecionarPasta();
    if (selecionada == null) return null;

    await _pastaExterna.verificarAcesso(selecionada.uriArvore);
    final anterior = await _repositorioConfiguracao.obter();
    final configuracao = ConfiguracaoPastaSincronizada(
      uriArvore: selecionada.uriArvore,
      autorizacaoPersistente: true,
      nomeLegivel: selecionada.nomeLegivel,
      ultimaSincronizacaoConcluida: anterior?.uriArvore == selecionada.uriArvore
          ? anterior?.ultimaSincronizacaoConcluida
          : null,
    );
    await _repositorioConfiguracao.salvarConfiguracao(configuracao);
    return configuracao;
  }

  Future<void> verificarAcesso() async {
    final configuracao = await _configuracaoObrigatoria();
    await _pastaExterna.verificarAcesso(configuracao.uriArvore);
  }

  Future<List<DocumentoPastaCurada>> listarArquivosCho() async {
    final configuracao = await _configuracaoObrigatoria();
    await _pastaExterna.verificarAcesso(configuracao.uriArvore);
    final enumeracao = await _pastaExterna.listarFilhosDiretos(
      configuracao.uriArvore,
    );
    if (!enumeracao.completa) {
      throw const FalhaPastaCurada(
        TipoFalhaPastaCurada.provedorIndisponivel,
        'O provedor não concluiu a leitura da pasta a tempo.',
      );
    }
    return enumeracao.documentos
        .where(
          (documento) =>
              !documento.ehDiretorio &&
              documento.nome.toLowerCase().endsWith('.cho'),
        )
        .toList(growable: false);
  }

  Future<Uint8List> lerBytes(DocumentoPastaCurada documento) =>
      _pastaExterna.lerBytes(documento);

  Future<ConfiguracaoPastaSincronizada> _configuracaoObrigatoria() async {
    final configuracao = await _repositorioConfiguracao.obter();
    if (configuracao == null) throw const PastaCuradaNaoConfigurada();
    if (!configuracao.autorizacaoPersistente) {
      throw const FalhaPastaCurada(
        TipoFalhaPastaCurada.autorizacaoRevogada,
        'A autorização de acesso à pasta não está disponível.',
      );
    }
    return configuracao;
  }
}
