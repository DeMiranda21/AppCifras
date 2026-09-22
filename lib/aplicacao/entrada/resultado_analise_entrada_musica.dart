import '../../dominio/objetos_de_valor/tom.dart';

enum ClassificacaoEntradaMusica {
  chordProConfirmado,
  cifraTextualProvavel,
  ambigua,
}

enum CampoMetadadoEntrada { titulo, artista, tom }

enum TipoAvisoAnaliseEntrada {
  entradaVazia,
  formatoAmbiguo,
  metadadoAusente,
  metadadoDuplicado,
  metadadoInvalido,
  diretivaDesconhecida,
  acordeNaoInterpretavel,
}

class AvisoAnaliseEntrada {
  const AvisoAnaliseEntrada({required this.tipo, this.campo, this.detalhe});

  final TipoAvisoAnaliseEntrada tipo;
  final CampoMetadadoEntrada? campo;
  final String? detalhe;
}

class ResultadoAnaliseEntradaMusica {
  ResultadoAnaliseEntradaMusica({
    required this.conteudoOriginal,
    required this.classificacao,
    this.titulo,
    this.artista,
    this.tom,
    Iterable<AvisoAnaliseEntrada> avisos = const [],
    required this.possuiRotulosDeSecao,
    required this.possuiLinhaDeAcordesProvavel,
  }) : avisos = List.unmodifiable(avisos);

  final String conteudoOriginal;
  final ClassificacaoEntradaMusica classificacao;
  final String? titulo;
  final String? artista;
  final Tom? tom;
  final List<AvisoAnaliseEntrada> avisos;
  final bool possuiRotulosDeSecao;
  final bool possuiLinhaDeAcordesProvavel;

  bool get requerConversao =>
      classificacao != ClassificacaoEntradaMusica.chordProConfirmado;

  bool get requerRevisao =>
      camposObrigatoriosPendentes.isNotEmpty ||
      avisos.isNotEmpty ||
      requerConversao;

  List<CampoMetadadoEntrada> get camposObrigatoriosPendentes => [
    if (titulo == null) CampoMetadadoEntrada.titulo,
    if (artista == null) CampoMetadadoEntrada.artista,
    if (tom == null) CampoMetadadoEntrada.tom,
  ];
}
