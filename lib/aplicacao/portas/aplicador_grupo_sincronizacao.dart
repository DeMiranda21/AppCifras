import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';

class VersaoNovaSincronizacao {
  const VersaoNovaSincronizacao({
    required this.id,
    required this.nome,
    required this.conteudoChordPro,
    required this.principal,
    required this.localizadorExterno,
    required this.hashSha256,
  });

  final IdVersaoMusica id;
  final String nome;
  final String conteudoChordPro;
  final bool principal;
  final String localizadorExterno;
  final String hashSha256;
}

class VersaoExistenteSincronizacao {
  const VersaoExistenteSincronizacao({
    required this.id,
    required this.nome,
    required this.localizadorExterno,
    required this.hashSha256,
    this.conteudoChordProAtualizado,
  });

  final IdVersaoMusica id;
  final String nome;
  final String localizadorExterno;
  final String hashSha256;
  final String? conteudoChordProAtualizado;
}

class PlanoAplicacaoGrupoSincronizacao {
  PlanoAplicacaoGrupoSincronizacao({
    required this.idMusica,
    required this.criarMusica,
    required this.titulo,
    required this.artista,
    required Iterable<VersaoNovaSincronizacao> versoesNovas,
    required Iterable<VersaoExistenteSincronizacao> versoesExistentes,
  }) : versoesNovas = List.unmodifiable(versoesNovas),
       versoesExistentes = List.unmodifiable(versoesExistentes);

  final IdMusica idMusica;
  final bool criarMusica;
  final String titulo;
  final String artista;
  final List<VersaoNovaSincronizacao> versoesNovas;
  final List<VersaoExistenteSincronizacao> versoesExistentes;
}

abstract interface class AplicadorGrupoSincronizacao {
  Future<void> aplicar(PlanoAplicacaoGrupoSincronizacao plano);
}
