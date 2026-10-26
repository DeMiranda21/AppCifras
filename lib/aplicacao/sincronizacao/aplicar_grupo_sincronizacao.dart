import '../../dominio/repositorios/repositorio_musicas.dart';

// ignore_for_file: prefer_initializing_formals
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../portas/aplicador_sincronizacao_pasta_curada.dart';
import '../portas/repositorio_sincronizacao.dart';
import 'modelos_sincronizacao.dart';
import 'resultado_sincronizacao.dart';

class ResultadoAplicacaoGrupoSincronizacao {
  ResultadoAplicacaoGrupoSincronizacao({
    this.adicionadas = 0,
    this.atualizadas = 0,
    this.inalteradas = 0,
    Iterable<ErroSincronizacao> erros = const [],
    Iterable<AvisoSincronizacao> avisos = const [],
  }) : erros = List.unmodifiable(erros),
       avisos = List.unmodifiable(avisos);

  final int adicionadas;
  final int atualizadas;
  final int inalteradas;
  final List<ErroSincronizacao> erros;
  final List<AvisoSincronizacao> avisos;
  bool get concluida => erros.isEmpty;
}

/// Núcleo comum de aplicação usado tanto pelo SAF quanto pela biblioteca HTTPS.
class AplicarGrupoSincronizacao {
  const AplicarGrupoSincronizacao({
    required RepositorioOrigensSincronizadas repositorioOrigens,
    required RepositorioMusicas repositorioMusicas,
    required RepositorioVersoesMusicas repositorioVersoes,
    required AplicadorSincronizacaoPastaCurada aplicador,
  }) : _repositorioOrigens = repositorioOrigens,
       _repositorioMusicas = repositorioMusicas,
       _repositorioVersoes = repositorioVersoes,
       _aplicador = aplicador;

  final RepositorioOrigensSincronizadas _repositorioOrigens;
  final RepositorioMusicas _repositorioMusicas;
  final RepositorioVersoesMusicas _repositorioVersoes;
  final AplicadorSincronizacaoPastaCurada _aplicador;

  Future<ResultadoAplicacaoGrupoSincronizacao> executar(
    GrupoMusicaSincronizacaoValido grupo,
  ) async {
    final erros = <ErroSincronizacao>[];
    final avisos = <AvisoSincronizacao>[];
    try {
      final musica = await _repositorioMusicas.obterPorId(grupo.idMusica);
      if (musica == null) {
        if (!grupo.avaliacaoCriacao.apta) {
          erros.add(
            ErroSincronizacao(
              codigo: CodigoErroSincronizacao.grupoNovoSemPrincipal,
              localizador: grupo.arquivos.first.candidato.localizador,
              mensagem: 'Música nova exige exatamente uma versão principal.',
            ),
          );
          return ResultadoAplicacaoGrupoSincronizacao(erros: erros);
        }
        for (final arquivo in grupo.arquivos) {
          if (await _repositorioVersoes.obterVersaoPorId(
                arquivo.idVersaoMusica,
              ) !=
              null) {
            _registrarColisao(grupo, arquivo, erros);
            return ResultadoAplicacaoGrupoSincronizacao(erros: erros);
          }
        }
        await _aplicador.aplicar(
          PlanoAplicacaoGrupoSincronizacao(
            idMusica: grupo.idMusica,
            criarMusica: true,
            titulo: grupo.titulo,
            artista: grupo.artista,
            versoesNovas: grupo.arquivos.map(
              (arquivo) => _nova(
                arquivo,
                principal:
                    arquivo.idVersaoMusica ==
                    grupo.avaliacaoCriacao.principalInicial,
              ),
            ),
            versoesExistentes: const [],
          ),
        );
        return ResultadoAplicacaoGrupoSincronizacao(
          adicionadas: grupo.arquivos.length,
        );
      }

      final novas = <VersaoNovaSincronizacao>[];
      final existentes = <VersaoExistenteSincronizacao>[];
      var adicionadas = 0;
      var atualizadas = 0;
      var inalteradas = 0;
      for (final arquivo in grupo.arquivos) {
        final versao = await _repositorioVersoes.obterVersaoPorId(
          arquivo.idVersaoMusica,
        );
        if (versao == null) {
          novas.add(_nova(arquivo, principal: false));
          adicionadas++;
          if (arquivo.principalDeclarada) _avisarPrincipal(arquivo, avisos);
          continue;
        }
        final origem = await _repositorioOrigens.obterPorVersao(versao.id);
        if (versao.idMusica != grupo.idMusica || origem == null) {
          _registrarColisao(grupo, arquivo, erros);
          return ResultadoAplicacaoGrupoSincronizacao(
            erros: erros,
            avisos: avisos,
          );
        }
        if (versao.principal != arquivo.principalDeclarada) {
          _avisarPrincipal(arquivo, avisos);
        }
        if (origem.hashSha256 == arquivo.hashSha256) {
          existentes.add(
            VersaoExistenteSincronizacao(
              id: versao.id,
              nome: versao.nome,
              localizadorExterno: arquivo.candidato.localizador,
              hashSha256: origem.hashSha256,
            ),
          );
          inalteradas++;
          continue;
        }
        if (!versao.principal &&
            await _repositorioVersoes.estaUsadaEmLista(versao.id)) {
          erros.add(
            ErroSincronizacao(
              codigo: CodigoErroSincronizacao.alternativaUsadaEmLista,
              localizador: arquivo.candidato.localizador,
              mensagem:
                  'A alternativa usada em Lista exige um novo '
                  'appcifras_version_id.',
            ),
          );
          avisos.add(
            AvisoSincronizacao(
              codigo: CodigoAvisoSincronizacao.alternativaUsadaEmLista,
              localizador: arquivo.candidato.localizador,
              mensagem: 'A versão local foi preservada.',
            ),
          );
          existentes.add(
            VersaoExistenteSincronizacao(
              id: versao.id,
              nome: versao.nome,
              localizadorExterno: arquivo.candidato.localizador,
              hashSha256: origem.hashSha256,
            ),
          );
          continue;
        }
        existentes.add(
          VersaoExistenteSincronizacao(
            id: versao.id,
            nome: arquivo.nomeVersao,
            localizadorExterno: arquivo.candidato.localizador,
            hashSha256: arquivo.hashSha256,
            conteudoChordProAtualizado: arquivo.documento.conteudoOriginal,
          ),
        );
        atualizadas++;
      }

      await _aplicador.aplicar(
        PlanoAplicacaoGrupoSincronizacao(
          idMusica: grupo.idMusica,
          criarMusica: false,
          titulo: grupo.titulo,
          artista: grupo.artista,
          versoesNovas: novas,
          versoesExistentes: existentes,
        ),
      );
      return ResultadoAplicacaoGrupoSincronizacao(
        adicionadas: adicionadas,
        atualizadas: atualizadas,
        inalteradas: inalteradas,
        erros: erros,
        avisos: avisos,
      );
    } catch (erro) {
      erros.add(
        ErroSincronizacao(
          codigo: CodigoErroSincronizacao.falhaAplicacao,
          localizador: grupo.arquivos.first.candidato.localizador,
          mensagem: 'Falha ao aplicar a música ${grupo.idMusica.valor}: $erro',
        ),
      );
      return ResultadoAplicacaoGrupoSincronizacao(erros: erros, avisos: avisos);
    }
  }

  VersaoNovaSincronizacao _nova(
    ArquivoSincronizacaoValidado arquivo, {
    required bool principal,
  }) => VersaoNovaSincronizacao(
    id: arquivo.idVersaoMusica,
    nome: arquivo.nomeVersao,
    conteudoChordPro: arquivo.documento.conteudoOriginal,
    principal: principal,
    localizadorExterno: arquivo.candidato.localizador,
    hashSha256: arquivo.hashSha256,
  );

  void _registrarColisao(
    GrupoMusicaSincronizacaoValido grupo,
    ArquivoSincronizacaoValidado arquivo,
    List<ErroSincronizacao> erros,
  ) {
    erros.add(
      ErroSincronizacao(
        codigo: CodigoErroSincronizacao.colisaoVersaoLocal,
        localizador: arquivo.candidato.localizador,
        mensagem:
            'O ID ${arquivo.idVersaoMusica.valor} já pertence a uma '
            'versão local; o grupo ${grupo.idMusica.valor} foi rejeitado.',
      ),
    );
  }

  void _avisarPrincipal(
    ArquivoSincronizacaoValidado arquivo,
    List<AvisoSincronizacao> avisos,
  ) {
    avisos.add(
      AvisoSincronizacao(
        codigo: CodigoAvisoSincronizacao.principalExternaDivergente,
        localizador: arquivo.candidato.localizador,
        mensagem: 'A marca de principal externa não alterou a principal local.',
      ),
    );
  }
}
