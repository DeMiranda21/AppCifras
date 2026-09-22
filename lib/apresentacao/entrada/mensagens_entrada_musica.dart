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

  static List<String> detalhesConversao(EntradaMusicaPreparada entrada) {
    final conversao = entrada.conversao;
    if (conversao == null) return const [];
    return conversao.avisos.map((aviso) {
      final motivo = switch (aviso.tipo) {
        TipoAvisoConversaoCifra.acordesConvergentes =>
          'Dois acordes ficaram associados à mesma posição.',
        TipoAvisoConversaoCifra.acordeAposLetra =>
          'Um acorde ficou após o fim da letra.',
        TipoAvisoConversaoCifra.associacaoNaoSegura =>
          'Não foi possível associar os acordes à letra com segurança.',
        TipoAvisoConversaoCifra.linhaInstrumental =>
          'O trecho foi preservado como passagem instrumental.',
        TipoAvisoConversaoCifra.rotuloComConteudo =>
          'O rótulo possui conteúdo que precisa de revisão.',
        TipoAvisoConversaoCifra.tomExplicitoAmbiguo =>
          'Há mais de uma indicação de tom.',
        TipoAvisoConversaoCifra.tomExplicitoInvalido =>
          'A indicação de tom não pôde ser interpretada.',
      };
      return 'Linha ${aviso.linha + 1} — "${conversao.trechoOriginal(aviso)}"\n$motivo';
    }).toList();
  }
}
