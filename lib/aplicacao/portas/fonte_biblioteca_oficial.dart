import 'dart:typed_data';

import '../publicacao/manifesto_biblioteca_oficial.dart';

abstract interface class FonteBibliotecaOficial {
  Future<ManifestoBibliotecaOficial> obterManifesto();

  Future<Uint8List> baixarArquivo(
    String caminho, {
    required int tamanhoEsperado,
  });

  void fechar();
}
