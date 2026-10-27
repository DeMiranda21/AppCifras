import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';

class ArquivoSincronizacaoCandidato {
  ArquivoSincronizacaoCandidato({
    required this.localizador,
    required this.nomeLegivel,
    required Iterable<int> bytes,
  }) : bytes = List<int>.unmodifiable(bytes);

  final String localizador;
  final String nomeLegivel;
  final List<int> bytes;
}

enum CodigoErroArquivoSincronizacao {
  extensaoInvalida,
  utf8Invalido,
  schemaAusenteOuInvalido,
  idMusicaAusenteOuInvalido,
  idVersaoAusenteOuInvalido,
  nomeVersaoInvalido,
  principalInvalida,
  chordProInvalido,
}

class ErroArquivoSincronizacao {
  const ErroArquivoSincronizacao(this.codigo);

  final CodigoErroArquivoSincronizacao codigo;
}

sealed class ResultadoValidacaoArquivoSincronizacao {
  const ResultadoValidacaoArquivoSincronizacao(this.candidato);

  final ArquivoSincronizacaoCandidato candidato;
}

class ArquivoSincronizacaoValidado
    extends ResultadoValidacaoArquivoSincronizacao {
  ArquivoSincronizacaoValidado({
    required ArquivoSincronizacaoCandidato candidato,
    required this.idMusica,
    required this.idVersaoMusica,
    required this.nomeVersao,
    required this.principalDeclarada,
    required this.hashSha256,
    required this.titulo,
    required this.artista,
    required this.documento,
  }) : super(candidato);

  final IdMusica idMusica;
  final IdVersaoMusica idVersaoMusica;
  final String nomeVersao;
  final bool principalDeclarada;
  final String hashSha256;
  final String titulo;
  final String artista;
  final DocumentoChordPro documento;
}

class ArquivoSincronizacaoInvalido
    extends ResultadoValidacaoArquivoSincronizacao {
  ArquivoSincronizacaoInvalido({
    required ArquivoSincronizacaoCandidato candidato,
    required Iterable<ErroArquivoSincronizacao> erros,
  }) : erros = List<ErroArquivoSincronizacao>.unmodifiable(erros),
       super(candidato);

  final List<ErroArquivoSincronizacao> erros;
}

enum CodigoErroGrupoSincronizacao {
  idVersaoDuplicado,
  idVersaoAssociadoAMusicasDiferentes,
  tituloMusicaDivergente,
  artistaMusicaDivergente,
}

class ErroGrupoSincronizacao {
  ErroGrupoSincronizacao({
    required this.codigo,
    required Iterable<String> localizadores,
  }) : localizadores = List<String>.unmodifiable(localizadores);

  final CodigoErroGrupoSincronizacao codigo;
  final List<String> localizadores;
}

enum CodigoInaptidaoCriacaoMusicaNova { quantidadePrincipalInvalida }

class AvaliacaoCriacaoMusicaNova {
  const AvaliacaoCriacaoMusicaNova._({
    required this.principalInicial,
    required this.inaptidao,
    required this.quantidadePrincipais,
  });

  const AvaliacaoCriacaoMusicaNova.apta(IdVersaoMusica principalInicial)
    : this._(
        principalInicial: principalInicial,
        inaptidao: null,
        quantidadePrincipais: 1,
      );

  const AvaliacaoCriacaoMusicaNova.inapta(int quantidadePrincipais)
    : this._(
        principalInicial: null,
        inaptidao: CodigoInaptidaoCriacaoMusicaNova.quantidadePrincipalInvalida,
        quantidadePrincipais: quantidadePrincipais,
      );

  final IdVersaoMusica? principalInicial;
  final CodigoInaptidaoCriacaoMusicaNova? inaptidao;
  final int quantidadePrincipais;

  bool get apta => inaptidao == null;
}

class GrupoMusicaSincronizacaoValido {
  GrupoMusicaSincronizacaoValido({
    required this.idMusica,
    required this.titulo,
    required this.artista,
    required Iterable<ArquivoSincronizacaoValidado> arquivos,
    required this.avaliacaoCriacao,
  }) : arquivos = List<ArquivoSincronizacaoValidado>.unmodifiable(arquivos);

  final IdMusica idMusica;
  final String titulo;
  final String artista;
  final List<ArquivoSincronizacaoValidado> arquivos;
  final AvaliacaoCriacaoMusicaNova avaliacaoCriacao;
}

class GrupoMusicaSincronizacaoRejeitado {
  GrupoMusicaSincronizacaoRejeitado({
    required this.idMusica,
    required Iterable<ArquivoSincronizacaoValidado> arquivos,
    required Iterable<ErroGrupoSincronizacao> erros,
  }) : arquivos = List<ArquivoSincronizacaoValidado>.unmodifiable(arquivos),
       erros = List<ErroGrupoSincronizacao>.unmodifiable(erros);

  final IdMusica idMusica;
  final List<ArquivoSincronizacaoValidado> arquivos;
  final List<ErroGrupoSincronizacao> erros;
}

class InventarioSincronizacao {
  InventarioSincronizacao({
    required Iterable<ArquivoSincronizacaoValidado> arquivosValidos,
    required Iterable<ArquivoSincronizacaoInvalido> arquivosInvalidos,
    required Iterable<GrupoMusicaSincronizacaoValido> gruposValidos,
    required Iterable<GrupoMusicaSincronizacaoRejeitado> gruposRejeitados,
  }) : arquivosValidos = List<ArquivoSincronizacaoValidado>.unmodifiable(
         arquivosValidos,
       ),
       arquivosInvalidos = List<ArquivoSincronizacaoInvalido>.unmodifiable(
         arquivosInvalidos,
       ),
       gruposValidos = List<GrupoMusicaSincronizacaoValido>.unmodifiable(
         gruposValidos,
       ),
       gruposRejeitados = List<GrupoMusicaSincronizacaoRejeitado>.unmodifiable(
         gruposRejeitados,
       );

  final List<ArquivoSincronizacaoValidado> arquivosValidos;
  final List<ArquivoSincronizacaoInvalido> arquivosInvalidos;
  final List<GrupoMusicaSincronizacaoValido> gruposValidos;
  final List<GrupoMusicaSincronizacaoRejeitado> gruposRejeitados;
}
