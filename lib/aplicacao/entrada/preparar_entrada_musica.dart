import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import 'analisador_entrada_musica.dart';
import 'conversor_cifra_textual.dart';
import 'rascunho_documento_chordpro.dart';
import 'resultado_analise_entrada_musica.dart';

/// Orquestra a preparação de texto recebido para a etapa transitória de revisão.
///
/// Não persiste o conteúdo nem cria Música. Para entradas ambíguas, não produz
/// rascunho ChordPro: a revisão futura deverá pedir uma ação explícita do usuário.
class PrepararEntradaMusica {
  factory PrepararEntradaMusica({
    AnalisadorEntradaMusica? analisador,
    ConversorCifraTextual? conversor,
    ParserDocumentoChordPro? parserDocumento,
  }) {
    final parser = parserDocumento ?? ParserDocumentoChordPro();
    return PrepararEntradaMusica._(
      analisador:
          analisador ?? AnalisadorEntradaMusica(parserDocumento: parser),
      conversor: conversor ?? ConversorCifraTextual(),
      parserDocumento: parser,
    );
  }

  PrepararEntradaMusica._({
    required this._analisador,
    required this._conversor,
    required this._parserDocumento,
  });

  final AnalisadorEntradaMusica _analisador;
  final ConversorCifraTextual _conversor;
  final ParserDocumentoChordPro _parserDocumento;

  EntradaMusicaPreparada executar(String conteudoOriginal) {
    final analise = _analisador.analisar(conteudoOriginal);

    return switch (analise.classificacao) {
      ClassificacaoEntradaMusica.chordProConfirmado => EntradaMusicaPreparada(
        analise: analise,
        rascunho: RascunhoDocumentoChordPro.aPartirDaAnalise(
          analise: analise,
          parserDocumento: _parserDocumento,
        ),
      ),
      ClassificacaoEntradaMusica.cifraTextualProvavel => _prepararCifraTextual(
        analise,
      ),
      ClassificacaoEntradaMusica.ambigua => EntradaMusicaPreparada(
        analise: analise,
      ),
    };
  }

  EntradaMusicaPreparada _prepararCifraTextual(
    ResultadoAnaliseEntradaMusica analise,
  ) {
    final conversao = _conversor.converter(analise.conteudoOriginal);
    return EntradaMusicaPreparada(
      analise: analise,
      conversao: conversao,
      rascunho: RascunhoDocumentoChordPro.criar(
        conteudoChordPro: conversao.chordProSugerido,
        parserDocumento: _parserDocumento,
      ),
    );
  }
}

/// Estado transitório consumível pela futura revisão de entrada de músicas.
///
/// Os valores de metadados são derivados da análise e do rascunho; não são uma
/// fonte de verdade independente do conteúdo ChordPro que será salvo.
class EntradaMusicaPreparada {
  const EntradaMusicaPreparada({
    required this.analise,
    this.conversao,
    this.rascunho,
  });

  final ResultadoAnaliseEntradaMusica analise;
  final ResultadoConversaoCifraTextual? conversao;
  final RascunhoDocumentoChordPro? rascunho;

  String get conteudoOriginal => analise.conteudoOriginal;
  ClassificacaoEntradaMusica get classificacao => analise.classificacao;
  bool get houveConversaoTextual => conversao != null;
  bool get documentoJaEraChordPro =>
      classificacao == ClassificacaoEntradaMusica.chordProConfirmado;
  bool get possuiRascunhoParaRevisao => rascunho != null;

  /// Conteúdo ChordPro que a revisão poderá alterar por meio do rascunho.
  /// É nulo para entrada ambígua, que ainda não tem conversão segura.
  String? get chordProSugerido => rascunho?.conteudoRecebido;

  String? get tituloDetectado => rascunho?.tituloDetectado ?? analise.titulo;
  String? get artistaDetectado => rascunho?.artistaDetectado ?? analise.artista;
  Tom? get tomDetectado => analise.tom;

  List<CampoMetadadoEntrada> get camposObrigatoriosPendentes => [
    if (tituloDetectado == null) CampoMetadadoEntrada.titulo,
    if (artistaDetectado == null) CampoMetadadoEntrada.artista,
    if (tomDetectado == null) CampoMetadadoEntrada.tom,
  ];

  Set<CampoMetadadoRascunho> get conflitos => rascunho?.conflitos ?? const {};
  List<AvisoAnaliseEntrada> get avisosAnalise => analise.avisos;
  List<AvisoConversaoCifra> get avisosConversao =>
      conversao?.avisos ?? const [];

  bool get requerRevisao =>
      !possuiRascunhoParaRevisao ||
      camposObrigatoriosPendentes.isNotEmpty ||
      conflitos.isNotEmpty ||
      avisosAnalise.isNotEmpty ||
      avisosConversao.isNotEmpty;
}
