import '../../dominio/entidades/versao_musica.dart';

class PoliticaEdicaoVersao {
  const PoliticaEdicaoVersao();

  DecisaoEdicaoVersao decidir({
    required VersaoMusica versao,
    required bool usadaEmLista,
  }) => DecisaoEdicaoVersao(
    podeSobrescreverConteudo: !versao.principal && !usadaEmLista,
  );
}

class DecisaoEdicaoVersao {
  const DecisaoEdicaoVersao({required this.podeSobrescreverConteudo});

  final bool podeSobrescreverConteudo;

  bool get deveCriarNovaVersao => !podeSobrescreverConteudo;

  bool get podeRenomear => true;
}
