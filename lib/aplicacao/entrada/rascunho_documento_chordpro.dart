import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import 'resultado_analise_entrada_musica.dart';

enum CampoMetadadoRascunho { titulo, artista, tom }

class RevisaoMetadadosChordPro {
  const RevisaoMetadadosChordPro({this.titulo, this.artista, this.tom});

  final String? titulo;
  final String? artista;
  final String? tom;
}

class RascunhoNaoPodeSerFinalizado implements Exception {
  const RascunhoNaoPodeSerFinalizado(this.campos);

  final Set<CampoMetadadoRascunho> campos;
}

class RascunhoDocumentoChordPro {
  RascunhoDocumentoChordPro._({
    required this.conteudoRecebido,
    required this._documento,
    required this.revisao,
  });

  factory RascunhoDocumentoChordPro.criar({
    required String conteudoChordPro,
    required ParserDocumentoChordPro parserDocumento,
  }) => RascunhoDocumentoChordPro._(
    conteudoRecebido: conteudoChordPro,
    documento: parserDocumento.interpretar(conteudoChordPro),
    revisao: const RevisaoMetadadosChordPro(),
  );

  factory RascunhoDocumentoChordPro.aPartirDaAnalise({
    required ResultadoAnaliseEntradaMusica analise,
    required ParserDocumentoChordPro parserDocumento,
  }) {
    if (analise.classificacao !=
        ClassificacaoEntradaMusica.chordProConfirmado) {
      throw ArgumentError(
        'O rascunho ChordPro exige uma entrada confirmada como ChordPro.',
      );
    }
    return RascunhoDocumentoChordPro.criar(
      conteudoChordPro: analise.conteudoOriginal,
      parserDocumento: parserDocumento,
    );
  }

  final String conteudoRecebido;
  final DocumentoChordPro _documento;
  final RevisaoMetadadosChordPro revisao;

  String? get tituloDetectado => _tituloValido?.titulo;
  String? get artistaDetectado => _artistaValido?.artista;
  String? get tomDetectado => _tomValido?.valorOriginal.trim();

  Set<CampoMetadadoRascunho> get conflitos => {
    if (_titulos.length > 1) CampoMetadadoRascunho.titulo,
    if (_artistas.length > 1) CampoMetadadoRascunho.artista,
    if (_tons.length > 1) CampoMetadadoRascunho.tom,
  };

  RascunhoDocumentoChordPro comRevisao(RevisaoMetadadosChordPro novaRevisao) =>
      RascunhoDocumentoChordPro._(
        conteudoRecebido: conteudoRecebido,
        documento: _documento,
        revisao: novaRevisao,
      );

  String produzirConteudoFinal() {
    if (conflitos.isNotEmpty) {
      throw RascunhoNaoPodeSerFinalizado(conflitos);
    }

    final camposInvalidos = <CampoMetadadoRascunho>{};
    final titulo = _valorFinal(
      revisado: revisao.titulo,
      detectado: tituloDetectado,
      campo: CampoMetadadoRascunho.titulo,
      camposInvalidos: camposInvalidos,
    );
    final artista = _valorFinal(
      revisado: revisao.artista,
      detectado: artistaDetectado,
      campo: CampoMetadadoRascunho.artista,
      camposInvalidos: camposInvalidos,
    );
    final tom = _valorFinal(
      revisado: revisao.tom,
      detectado: tomDetectado,
      campo: CampoMetadadoRascunho.tom,
      camposInvalidos: camposInvalidos,
    );
    if (camposInvalidos.isNotEmpty) {
      throw RascunhoNaoPodeSerFinalizado(camposInvalidos);
    }

    var conteudo = conteudoRecebido;
    final diretivasAusentes = <String>[];
    conteudo = _revisarDiretiva(
      conteudo: conteudo,
      nome: 'title',
      diretiva: _tituloDiretivaUnica,
      valorRevisado: revisao.titulo,
      valorFinal: titulo!,
      diretivasAusentes: diretivasAusentes,
    );
    conteudo = _revisarDiretiva(
      conteudo: conteudo,
      nome: 'artist',
      diretiva: _artistaDiretivaUnica,
      valorRevisado: revisao.artista,
      valorFinal: artista!,
      diretivasAusentes: diretivasAusentes,
    );
    conteudo = _revisarDiretiva(
      conteudo: conteudo,
      nome: 'key',
      diretiva: _tomDiretivaUnica,
      valorRevisado: revisao.tom,
      valorFinal: tom!,
      diretivasAusentes: diretivasAusentes,
    );
    if (diretivasAusentes.isEmpty) {
      return conteudo;
    }

    final separador = conteudo.contains('\r\n') ? '\r\n' : '\n';
    final cabecalho = diretivasAusentes.join(separador);
    return conteudo.isEmpty ? cabecalho : '$cabecalho$separador$conteudo';
  }

  List<DiretivaTituloChordPro> get _titulos =>
      _documento.elementos.whereType<DiretivaTituloChordPro>().toList();
  List<DiretivaArtistaChordPro> get _artistas =>
      _documento.elementos.whereType<DiretivaArtistaChordPro>().toList();
  List<DiretivaTomChordPro> get _tons =>
      _documento.elementos.whereType<DiretivaTomChordPro>().toList();

  DiretivaTituloChordPro? get _tituloDiretivaUnica =>
      _titulos.length == 1 ? _titulos.single : null;
  DiretivaArtistaChordPro? get _artistaDiretivaUnica =>
      _artistas.length == 1 ? _artistas.single : null;
  DiretivaTomChordPro? get _tomDiretivaUnica =>
      _tons.length == 1 ? _tons.single : null;

  DiretivaTituloChordPro? get _tituloValido =>
      _titulos.length == 1 && _titulos.single.titulo.isNotEmpty
      ? _titulos.single
      : null;
  DiretivaArtistaChordPro? get _artistaValido =>
      _artistas.length == 1 && _artistas.single.artista.isNotEmpty
      ? _artistas.single
      : null;
  DiretivaTomChordPro? get _tomValido =>
      _tons.length == 1 && _tons.single.tom != null ? _tons.single : null;

  String? _valorFinal({
    required String? revisado,
    required String? detectado,
    required CampoMetadadoRascunho campo,
    required Set<CampoMetadadoRascunho> camposInvalidos,
  }) {
    if (revisado != null) {
      if (revisado.trim().isEmpty) {
        camposInvalidos.add(campo);
        return null;
      }
      return revisado;
    }
    if (detectado == null) {
      camposInvalidos.add(campo);
    }
    return detectado;
  }

  String _revisarDiretiva({
    required String conteudo,
    required String nome,
    required DiretivaChordPro? diretiva,
    required String? valorRevisado,
    required String valorFinal,
    required List<String> diretivasAusentes,
  }) {
    if (diretiva == null) {
      diretivasAusentes.add('{$nome: $valorFinal}');
      return conteudo;
    }
    if (valorRevisado == null) {
      return conteudo;
    }
    final linha = RegExp(
      '^${RegExp.escape(diretiva.conteudoOriginal)}(\\r\\n|\\n|\\r|\$)',
      multiLine: true,
    );
    return conteudo.replaceFirstMapped(
      linha,
      (correspondencia) => '{$nome: $valorFinal}${correspondencia.group(1)!}',
    );
  }
}
