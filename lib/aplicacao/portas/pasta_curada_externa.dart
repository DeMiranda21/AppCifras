import 'dart:typed_data';

class PastaCuradaSelecionada {
  PastaCuradaSelecionada({required this.uriArvore, this.nomeLegivel}) {
    if (uriArvore.trim().isEmpty) {
      throw ArgumentError.value(uriArvore, 'uriArvore');
    }
  }

  final String uriArvore;
  final String? nomeLegivel;
}

class DocumentoPastaCurada {
  DocumentoPastaCurada({
    required this.localizador,
    required this.nome,
    required this.ehDiretorio,
    this.tipoMime,
  }) {
    if (localizador.trim().isEmpty) {
      throw ArgumentError.value(localizador, 'localizador');
    }
  }

  final String localizador;
  final String nome;
  final bool ehDiretorio;
  final String? tipoMime;
}

class ResultadoEnumeracaoPastaCurada {
  ResultadoEnumeracaoPastaCurada({
    required Iterable<DocumentoPastaCurada> documentos,
    required this.completa,
  }) : documentos = List.unmodifiable(documentos);

  final List<DocumentoPastaCurada> documentos;
  final bool completa;
}

enum TipoFalhaPastaCurada {
  autorizacaoRevogada,
  provedorIndisponivel,
  leitura,
  autorizacaoNaoPersistida,
}

class FalhaPastaCurada implements Exception {
  const FalhaPastaCurada(this.tipo, this.mensagem);

  final TipoFalhaPastaCurada tipo;
  final String mensagem;

  @override
  String toString() => mensagem;
}

abstract interface class PastaCuradaExterna {
  Future<PastaCuradaSelecionada?> selecionarPasta();

  Future<void> verificarAcesso(String uriArvore);

  Future<ResultadoEnumeracaoPastaCurada> listarFilhosDiretos(String uriArvore);

  Future<Uint8List> lerBytes(DocumentoPastaCurada documento);
}
