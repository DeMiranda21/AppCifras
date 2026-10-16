import '../../dominio/entidades/versao_musica.dart';

enum AcaoEdicaoConteudoVersao { sobrescrever, criarNovaVersao }

class PoliticaEdicaoVersao {
  const PoliticaEdicaoVersao();

  DecisaoEdicaoVersao decidir({
    required VersaoMusica versao,
    required bool usadaEmLista,
    bool sincronizada = false,
  }) {
    if (sincronizada) {
      return const DecisaoEdicaoVersao({
        AcaoEdicaoConteudoVersao.criarNovaVersao,
      });
    }
    if (versao.principal) {
      return const DecisaoEdicaoVersao({
        AcaoEdicaoConteudoVersao.sobrescrever,
        AcaoEdicaoConteudoVersao.criarNovaVersao,
      });
    }
    return DecisaoEdicaoVersao({
      usadaEmLista
          ? AcaoEdicaoConteudoVersao.criarNovaVersao
          : AcaoEdicaoConteudoVersao.sobrescrever,
    });
  }
}

class DecisaoEdicaoVersao {
  const DecisaoEdicaoVersao(this._acoesConteudo);

  final Set<AcaoEdicaoConteudoVersao> _acoesConteudo;

  bool permite(AcaoEdicaoConteudoVersao acao) => _acoesConteudo.contains(acao);

  bool get podeSobrescreverConteudo =>
      permite(AcaoEdicaoConteudoVersao.sobrescrever);

  bool get podeCriarNovaVersao =>
      permite(AcaoEdicaoConteudoVersao.criarNovaVersao);

  bool get exigeEscolha => podeSobrescreverConteudo && podeCriarNovaVersao;

  bool get deveCriarNovaVersao =>
      podeCriarNovaVersao && !podeSobrescreverConteudo;

  AcaoEdicaoConteudoVersao? get acaoAutomatica =>
      exigeEscolha ? null : _acoesConteudo.single;

  bool get podeRenomear => true;
}
