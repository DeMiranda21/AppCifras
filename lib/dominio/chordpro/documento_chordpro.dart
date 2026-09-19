import '../objetos_de_valor/tom.dart';
import '../servicos/parser_acorde.dart';

sealed class ElementoDocumentoChordPro {
  const ElementoDocumentoChordPro(this.conteudoOriginal);
  final String conteudoOriginal;
}

class DocumentoChordPro {
  DocumentoChordPro({
    required this.conteudoOriginal,
    required Iterable<ElementoDocumentoChordPro> elementos,
  }) : elementos = List.unmodifiable(elementos);
  final String conteudoOriginal;
  final List<ElementoDocumentoChordPro> elementos;
}

class LinhaChordPro extends ElementoDocumentoChordPro {
  LinhaChordPro(
    super.conteudoOriginal,
    Iterable<ElementoLinhaChordPro> elementos,
  ) : elementos = List.unmodifiable(elementos);
  final List<ElementoLinhaChordPro> elementos;
}

class LinhaNaoInterpretadaChordPro extends ElementoDocumentoChordPro {
  const LinhaNaoInterpretadaChordPro(super.conteudoOriginal);
}

sealed class ElementoLinhaChordPro {
  const ElementoLinhaChordPro(this.conteudoOriginal);
  final String conteudoOriginal;
}

class TextoLinhaChordPro extends ElementoLinhaChordPro {
  const TextoLinhaChordPro(super.conteudoOriginal);
}

class AcordeLinhaChordPro extends ElementoLinhaChordPro {
  const AcordeLinhaChordPro(super.conteudoOriginal, this.resultado);
  final ResultadoParserAcorde resultado;
}

sealed class DiretivaChordPro extends ElementoDocumentoChordPro {
  const DiretivaChordPro(super.conteudoOriginal, this.valorOriginal);
  final String valorOriginal;
}

class DiretivaTituloChordPro extends DiretivaChordPro {
  const DiretivaTituloChordPro(super.original, super.valor);
  String get titulo => valorOriginal.trim();
}

class DiretivaArtistaChordPro extends DiretivaChordPro {
  const DiretivaArtistaChordPro(super.original, super.valor);
  String get artista => valorOriginal.trim();
}

class DiretivaTomChordPro extends DiretivaChordPro {
  const DiretivaTomChordPro(super.original, super.valor, this.tom);
  final Tom? tom;
}

class DiretivaDesconhecidaChordPro extends DiretivaChordPro {
  const DiretivaDesconhecidaChordPro(super.original, super.valor, this.nome);
  final String nome;
}

class InicioRefraoChordPro extends ElementoDocumentoChordPro {
  const InicioRefraoChordPro(super.conteudoOriginal);
}

class FimRefraoChordPro extends ElementoDocumentoChordPro {
  const FimRefraoChordPro(super.conteudoOriginal);
}
