import '../../aplicacao/entrada/conversor_cifra_textual.dart';
import '../../aplicacao/entrada/preparar_entrada_musica.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';

class MensagensEntradaMusica {
  const MensagensEntradaMusica._();

  static List<String> avisos(EntradaMusicaPreparada entrada) => [
    if (entrada.conflitos.isNotEmpty)
      'Há informações repetidas no documento que precisam ser corrigidas.',
    if (entrada.tomDetectado == null && entrada.possuiRascunhoParaRevisao)
      'O tom não pôde ser identificado.',
    if (entrada.avisosConversao.any(
      (aviso) =>
          aviso.tipo == TipoAvisoConversaoCifra.associacaoNaoSegura ||
          aviso.tipo == TipoAvisoConversaoCifra.linhaInstrumental,
    ))
      'Alguns trechos não puderam ser convertidos com segurança. Confira a prévia.',
  ];

  static String conflito(RascunhoNaoPodeSerFinalizado erro) =>
      erro.campos.isNotEmpty
      ? 'Há informações repetidas ou pendentes que precisam ser corrigidas.'
      : 'Não foi possível finalizar a revisão.';

  static String erroGeral() =>
      'Não foi possível salvar a música. Tente novamente.';
}
