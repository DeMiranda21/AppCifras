import '../entidades/versao_musica.dart';

class VersaoPrincipalNaoPodeSerArquivada implements Exception {
  const VersaoPrincipalNaoPodeSerArquivada(this.versao);
  final VersaoMusica versao;
}

class VersaoPrincipalNaoPodeSerExcluida implements Exception {
  const VersaoPrincipalNaoPodeSerExcluida(this.versao);
  final VersaoMusica versao;
}

class VersaoMusicaEmUsoEmLista implements Exception {
  const VersaoMusicaEmUsoEmLista(this.versao);
  final VersaoMusica versao;
}
