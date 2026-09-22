import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/objetos_de_valor/tom.dart';
import '../../dominio/servicos/parser_acorde.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import 'resultado_analise_entrada_musica.dart';

class AnalisadorEntradaMusica {
  AnalisadorEntradaMusica({ParserDocumentoChordPro? parserDocumento})
    : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro();

  final ParserDocumentoChordPro _parserDocumento;

  static final _linhaTom = RegExp(
    r'^\s*(?:tom|key)\s*:\s*(.+?)\s*$',
    caseSensitive: false,
  );
  static final _rotuloSecao = RegExp(r'^\s*\[(.+)\]\s*$');
  static final _candidatoAcorde = RegExp(
    r'^[A-G](?:[#b])?(?:[A-Za-z0-9#b()+/°Δø-]*)$',
  );
  static const _nomesSecao = {
    'intro',
    'primeira parte',
    'verso',
    'pré-refrão',
    'refrão',
    'ponte',
    'final',
  };

  ResultadoAnaliseEntradaMusica analisar(String conteudo) {
    final documento = _parserDocumento.interpretar(conteudo);
    final avisos = <AvisoAnaliseEntrada>[];
    final temConteudo = conteudo.trim().isNotEmpty;
    final chordProConfirmado = _temEvidenciaChordProConfirmada(documento);
    final rotulosDeSecao = _possuiRotulosDeSecao(conteudo);
    final linhaDeAcordes = _possuiLinhaDeAcordesProvavel(conteudo);
    final tomTexto = _extrairTomTexto(conteudo);

    _adicionarAvisosDeDiretivasEDosAcordes(documento, avisos);

    if (!temConteudo) {
      avisos.add(
        const AvisoAnaliseEntrada(tipo: TipoAvisoAnaliseEntrada.entradaVazia),
      );
    }

    final classificacao = _classificar(
      temConteudo: temConteudo,
      chordProConfirmado: chordProConfirmado,
      possuiSinalTextual:
          rotulosDeSecao || linhaDeAcordes || tomTexto.encontrado,
    );
    if (classificacao == ClassificacaoEntradaMusica.ambigua && temConteudo) {
      avisos.add(
        const AvisoAnaliseEntrada(tipo: TipoAvisoAnaliseEntrada.formatoAmbiguo),
      );
    }

    if (chordProConfirmado) {
      final metadados = _extrairMetadadosChordPro(documento, avisos);
      return ResultadoAnaliseEntradaMusica(
        conteudoOriginal: conteudo,
        classificacao: classificacao,
        titulo: metadados.titulo,
        artista: metadados.artista,
        tom: metadados.tom,
        avisos: avisos,
        possuiRotulosDeSecao: rotulosDeSecao,
        possuiLinhaDeAcordesProvavel: linhaDeAcordes,
      );
    }

    if (tomTexto.encontrado && tomTexto.tom == null) {
      avisos.add(
        const AvisoAnaliseEntrada(
          tipo: TipoAvisoAnaliseEntrada.metadadoInvalido,
          campo: CampoMetadadoEntrada.tom,
        ),
      );
    }
    return ResultadoAnaliseEntradaMusica(
      conteudoOriginal: conteudo,
      classificacao: classificacao,
      tom: tomTexto.tom,
      avisos: avisos,
      possuiRotulosDeSecao: rotulosDeSecao,
      possuiLinhaDeAcordesProvavel: linhaDeAcordes,
    );
  }

  ClassificacaoEntradaMusica _classificar({
    required bool temConteudo,
    required bool chordProConfirmado,
    required bool possuiSinalTextual,
  }) {
    if (chordProConfirmado) {
      return ClassificacaoEntradaMusica.chordProConfirmado;
    }
    if (temConteudo && possuiSinalTextual) {
      return ClassificacaoEntradaMusica.cifraTextualProvavel;
    }
    return ClassificacaoEntradaMusica.ambigua;
  }

  bool _temEvidenciaChordProConfirmada(DocumentoChordPro documento) =>
      documento.elementos.any(
        (elemento) =>
            elemento is DiretivaTituloChordPro ||
            elemento is DiretivaArtistaChordPro ||
            elemento is DiretivaTomChordPro ||
            elemento is DiretivaSchemaAppCifras ||
            elemento is DiretivaIdAppCifras ||
            elemento is InicioRefraoChordPro ||
            elemento is FimRefraoChordPro ||
            elemento is LinhaChordPro &&
                elemento.elementos.whereType<AcordeLinhaChordPro>().any(
                  (acorde) => acorde.resultado is AcordeInterpretado,
                ),
      );

  bool _possuiRotulosDeSecao(String conteudo) => _linhas(conteudo).any((linha) {
    final correspondencia = _rotuloSecao.firstMatch(linha);
    return correspondencia != null &&
        _nomesSecao.contains(correspondencia.group(1)!.trim().toLowerCase());
  });

  bool _possuiLinhaDeAcordesProvavel(String conteudo) =>
      _linhas(conteudo).any(_eLinhaDeAcordesProvavel);

  bool _eLinhaDeAcordesProvavel(String linha) {
    final tokens = linha.trim().split(RegExp(r'\s+'));
    if (tokens.length == 1 && tokens.single.isEmpty) {
      return false;
    }
    if (!tokens.every(_candidatoAcorde.hasMatch)) {
      return false;
    }
    return tokens.length > 1 || tokens.single.length > 1;
  }

  _TomTexto _extrairTomTexto(String conteudo) {
    for (final linha in _linhas(conteudo)) {
      final correspondencia = _linhaTom.firstMatch(linha);
      if (correspondencia == null) {
        continue;
      }
      final documento = _parserDocumento.interpretar(
        '{key: ${correspondencia.group(1)!}}',
      );
      final diretivasTom = documento.elementos.whereType<DiretivaTomChordPro>();
      return _TomTexto(
        encontrado: true,
        tom: documento.elementos.length == 1 && diretivasTom.length == 1
            ? diretivasTom.single.tom
            : null,
      );
    }
    return const _TomTexto(encontrado: false);
  }

  _MetadadosChordPro _extrairMetadadosChordPro(
    DocumentoChordPro documento,
    List<AvisoAnaliseEntrada> avisos,
  ) => _MetadadosChordPro(
    titulo: _extrairTitulo(documento, avisos),
    artista: _extrairArtista(documento, avisos),
    tom: _extrairTom(documento, avisos),
  );

  String? _extrairTitulo(
    DocumentoChordPro documento,
    List<AvisoAnaliseEntrada> avisos,
  ) {
    final diretivas = documento.elementos.whereType<DiretivaTituloChordPro>();
    if (diretivas.isEmpty) {
      _adicionarAvisoAusente(avisos, CampoMetadadoEntrada.titulo);
      return null;
    }
    if (diretivas.length != 1) {
      _adicionarAvisoDuplicado(avisos, CampoMetadadoEntrada.titulo);
      return null;
    }
    if (diretivas.single.titulo.isEmpty) {
      _adicionarAvisoInvalido(avisos, CampoMetadadoEntrada.titulo);
      return null;
    }
    return diretivas.single.titulo;
  }

  String? _extrairArtista(
    DocumentoChordPro documento,
    List<AvisoAnaliseEntrada> avisos,
  ) {
    final diretivas = documento.elementos.whereType<DiretivaArtistaChordPro>();
    if (diretivas.isEmpty) {
      _adicionarAvisoAusente(avisos, CampoMetadadoEntrada.artista);
      return null;
    }
    if (diretivas.length != 1) {
      _adicionarAvisoDuplicado(avisos, CampoMetadadoEntrada.artista);
      return null;
    }
    if (diretivas.single.artista.isEmpty) {
      _adicionarAvisoInvalido(avisos, CampoMetadadoEntrada.artista);
      return null;
    }
    return diretivas.single.artista;
  }

  Tom? _extrairTom(
    DocumentoChordPro documento,
    List<AvisoAnaliseEntrada> avisos,
  ) {
    final diretivas = documento.elementos.whereType<DiretivaTomChordPro>();
    if (diretivas.isEmpty) {
      _adicionarAvisoAusente(avisos, CampoMetadadoEntrada.tom);
      return null;
    }
    if (diretivas.length != 1) {
      _adicionarAvisoDuplicado(avisos, CampoMetadadoEntrada.tom);
      return null;
    }
    if (diretivas.single.tom == null) {
      _adicionarAvisoInvalido(avisos, CampoMetadadoEntrada.tom);
      return null;
    }
    return diretivas.single.tom;
  }

  void _adicionarAvisosDeDiretivasEDosAcordes(
    DocumentoChordPro documento,
    List<AvisoAnaliseEntrada> avisos,
  ) {
    for (final diretiva
        in documento.elementos.whereType<DiretivaDesconhecidaChordPro>()) {
      avisos.add(
        AvisoAnaliseEntrada(
          tipo: TipoAvisoAnaliseEntrada.diretivaDesconhecida,
          detalhe: diretiva.nome,
        ),
      );
    }
    for (final acorde in documento.elementos.whereType<LinhaChordPro>().expand(
      (linha) => linha.elementos.whereType<AcordeLinhaChordPro>(),
    )) {
      if (acorde.resultado is AcordeNaoInterpretavel) {
        avisos.add(
          AvisoAnaliseEntrada(
            tipo: TipoAvisoAnaliseEntrada.acordeNaoInterpretavel,
            detalhe: acorde.conteudoOriginal,
          ),
        );
      }
    }
  }

  Iterable<String> _linhas(String conteudo) =>
      conteudo.split(RegExp(r'\r\n|\n|\r'));

  void _adicionarAvisoAusente(
    List<AvisoAnaliseEntrada> avisos,
    CampoMetadadoEntrada campo,
  ) => avisos.add(
    AvisoAnaliseEntrada(
      tipo: TipoAvisoAnaliseEntrada.metadadoAusente,
      campo: campo,
    ),
  );

  void _adicionarAvisoDuplicado(
    List<AvisoAnaliseEntrada> avisos,
    CampoMetadadoEntrada campo,
  ) => avisos.add(
    AvisoAnaliseEntrada(
      tipo: TipoAvisoAnaliseEntrada.metadadoDuplicado,
      campo: campo,
    ),
  );

  void _adicionarAvisoInvalido(
    List<AvisoAnaliseEntrada> avisos,
    CampoMetadadoEntrada campo,
  ) => avisos.add(
    AvisoAnaliseEntrada(
      tipo: TipoAvisoAnaliseEntrada.metadadoInvalido,
      campo: campo,
    ),
  );
}

class _TomTexto {
  const _TomTexto({required this.encontrado, this.tom});

  final bool encontrado;
  final Tom? tom;
}

class _MetadadosChordPro {
  const _MetadadosChordPro({this.titulo, this.artista, this.tom});

  final String? titulo;
  final String? artista;
  final Tom? tom;
}
