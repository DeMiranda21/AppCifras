import 'dart:convert';

// ignore_for_file: prefer_initializing_formals

import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../portas/aplicador_sincronizacao_pasta_curada.dart';
import '../portas/pasta_curada_externa.dart';
import '../portas/repositorio_sincronizacao.dart';
import 'configuracao_pasta_sincronizada.dart';
import 'modelos_sincronizacao.dart';
import 'montar_inventario_pasta_curada.dart';

enum CodigoErroSincronizacao {
  configuracaoAusente,
  acessoPasta,
  enumeracaoPasta,
  leituraArquivo,
  arquivoInvalido,
  grupoInvalido,
  grupoNovoSemPrincipal,
  colisaoVersaoLocal,
  alternativaUsadaEmLista,
  falhaAplicacao,
  falhaAoAvaliarAusencias,
  falhaAoMarcarAusencia,
  falhaAoAtualizarConfiguracao,
}

class ErroSincronizacao {
  const ErroSincronizacao({
    required this.codigo,
    required this.mensagem,
    this.localizador,
  });

  final CodigoErroSincronizacao codigo;
  final String mensagem;
  final String? localizador;
}

enum CodigoAvisoSincronizacao {
  principalExternaDivergente,
  alternativaUsadaEmLista,
}

class AvisoSincronizacao {
  const AvisoSincronizacao({
    required this.codigo,
    required this.mensagem,
    this.localizador,
  });

  final CodigoAvisoSincronizacao codigo;
  final String mensagem;
  final String? localizador;
}

class ResultadoSincronizacao {
  ResultadoSincronizacao({
    required this.adicionadas,
    required this.atualizadas,
    required this.inalteradas,
    required this.origensAusentes,
    required Iterable<ErroSincronizacao> erros,
    required Iterable<AvisoSincronizacao> avisos,
    required this.enumeracaoCompleta,
  }) : erros = List.unmodifiable(erros),
       avisos = List.unmodifiable(avisos);

  final int adicionadas;
  final int atualizadas;
  final int inalteradas;
  final int origensAusentes;
  final List<ErroSincronizacao> erros;
  final List<AvisoSincronizacao> avisos;
  final bool enumeracaoCompleta;
}

class SincronizarPastaCurada {
  SincronizarPastaCurada({
    required PastaCuradaExterna pastaExterna,
    required RepositorioConfiguracaoPastaSincronizada repositorioConfiguracao,
    required RepositorioOrigensSincronizadas repositorioOrigens,
    required RepositorioMusicas repositorioMusicas,
    required RepositorioVersoesMusicas repositorioVersoes,
    required AplicadorSincronizacaoPastaCurada aplicador,
    MontarInventarioPastaCurada? montarInventario,
    ParserDocumentoChordPro? parserDocumento,
    DateTime Function()? agora,
  }) : _pastaExterna = pastaExterna,
       _repositorioConfiguracao = repositorioConfiguracao,
       _repositorioOrigens = repositorioOrigens,
       _repositorioMusicas = repositorioMusicas,
       _repositorioVersoes = repositorioVersoes,
       _aplicador = aplicador,
       _montarInventario = montarInventario ?? MontarInventarioPastaCurada(),
       _parserDocumento = parserDocumento ?? ParserDocumentoChordPro(),
       _agora = agora ?? DateTime.now;

  final PastaCuradaExterna _pastaExterna;
  final RepositorioConfiguracaoPastaSincronizada _repositorioConfiguracao;
  final RepositorioOrigensSincronizadas _repositorioOrigens;
  final RepositorioMusicas _repositorioMusicas;
  final RepositorioVersoesMusicas _repositorioVersoes;
  final AplicadorSincronizacaoPastaCurada _aplicador;
  final MontarInventarioPastaCurada _montarInventario;
  final ParserDocumentoChordPro _parserDocumento;
  final DateTime Function() _agora;

  Future<ResultadoSincronizacao> executar() async {
    final erros = <ErroSincronizacao>[];
    final avisos = <AvisoSincronizacao>[];
    var adicionadas = 0;
    var atualizadas = 0;
    var inalteradas = 0;
    var origensAusentes = 0;
    final configuracao = await _repositorioConfiguracao.obter();
    if (configuracao == null) {
      return _resultadoGlobal(
        CodigoErroSincronizacao.configuracaoAusente,
        'Nenhuma pasta curada está configurada.',
      );
    }

    try {
      await _pastaExterna.verificarAcesso(configuracao.uriArvore);
    } catch (erro) {
      return _resultadoGlobal(
        CodigoErroSincronizacao.acessoPasta,
        'Não foi possível acessar a pasta curada: $erro',
      );
    }

    late final ResultadoEnumeracaoPastaCurada enumeracao;
    try {
      enumeracao = await _pastaExterna.listarFilhosDiretos(
        configuracao.uriArvore,
      );
    } catch (erro) {
      return _resultadoGlobal(
        CodigoErroSincronizacao.enumeracaoPasta,
        'Não foi possível enumerar a pasta curada: $erro',
      );
    }

    final documentos = enumeracao.documentos;
    final candidatos = <ArquivoSincronizacaoCandidato>[];
    final idsFisicamentePresentes = <IdVersaoMusica>{};
    var leituraCompleta = enumeracao.completa;
    var ausenciasSeguras = enumeracao.completa;
    if (!enumeracao.completa) {
      erros.add(
        const ErroSincronizacao(
          codigo: CodigoErroSincronizacao.enumeracaoPasta,
          mensagem:
              'O provedor não concluiu a enumeração da pasta a tempo; '
              'nenhuma origem será marcada como ausente.',
        ),
      );
    }
    for (final documento in documentos.where(
      (item) => !item.ehDiretorio && item.nome.toLowerCase().endsWith('.cho'),
    )) {
      try {
        final bytes = await _pastaExterna.lerBytes(documento);
        final candidato = ArquivoSincronizacaoCandidato(
          localizador: documento.localizador,
          nomeLegivel: documento.nome,
          bytes: bytes,
        );
        candidatos.add(candidato);
        final idReconhecido = _reconhecerIdVersao(candidato);
        if (idReconhecido != null) {
          idsFisicamentePresentes.add(idReconhecido);
        } else {
          ausenciasSeguras = false;
        }
      } catch (erro) {
        leituraCompleta = false;
        ausenciasSeguras = false;
        erros.add(
          ErroSincronizacao(
            codigo: CodigoErroSincronizacao.leituraArquivo,
            localizador: documento.localizador,
            mensagem: 'Não foi possível ler ${documento.nome}: $erro',
          ),
        );
      }
    }

    final inventario = _montarInventario.executar(candidatos);
    idsFisicamentePresentes.addAll(
      inventario.arquivosValidos.map((arquivo) => arquivo.idVersaoMusica),
    );
    for (final arquivo in inventario.arquivosInvalidos) {
      erros.add(
        ErroSincronizacao(
          codigo: CodigoErroSincronizacao.arquivoInvalido,
          localizador: arquivo.candidato.localizador,
          mensagem:
              'Arquivo inválido: '
              '${arquivo.erros.map((erro) => erro.codigo.name).join(', ')}.',
        ),
      );
    }
    for (final grupo in inventario.gruposRejeitados) {
      erros.add(
        ErroSincronizacao(
          codigo: CodigoErroSincronizacao.grupoInvalido,
          localizador: grupo.arquivos.isEmpty
              ? null
              : grupo.arquivos.first.candidato.localizador,
          mensagem:
              'Grupo ${grupo.idMusica.valor} inválido: '
              '${grupo.erros.map((erro) => erro.codigo.name).join(', ')}.',
        ),
      );
    }

    for (final grupo in inventario.gruposValidos) {
      final contadores = await _aplicarGrupo(grupo, erros, avisos);
      adicionadas += contadores.adicionadas;
      atualizadas += contadores.atualizadas;
      inalteradas += contadores.inalteradas;
    }

    if (leituraCompleta && ausenciasSeguras) {
      try {
        for (final origem in await _repositorioOrigens.listar()) {
          if (!origem.presente ||
              idsFisicamentePresentes.contains(origem.idVersaoMusica)) {
            continue;
          }
          try {
            await _repositorioOrigens.marcarAusente(origem.idVersaoMusica);
            origensAusentes++;
          } catch (erro) {
            erros.add(
              ErroSincronizacao(
                codigo: CodigoErroSincronizacao.falhaAoMarcarAusencia,
                localizador: origem.localizadorExterno,
                mensagem:
                    'Não foi possível marcar a origem como ausente: '
                    '$erro',
              ),
            );
          }
        }
      } catch (erro) {
        erros.add(
          ErroSincronizacao(
            codigo: CodigoErroSincronizacao.falhaAoAvaliarAusencias,
            mensagem: 'Não foi possível consultar as origens locais: $erro',
          ),
        );
      }
    }

    if (leituraCompleta) {
      try {
        await _repositorioConfiguracao.salvarConfiguracao(
          ConfiguracaoPastaSincronizada(
            uriArvore: configuracao.uriArvore,
            autorizacaoPersistente: configuracao.autorizacaoPersistente,
            nomeLegivel: configuracao.nomeLegivel,
            ultimaSincronizacaoConcluida: _agora(),
          ),
        );
      } catch (erro) {
        erros.add(
          ErroSincronizacao(
            codigo: CodigoErroSincronizacao.falhaAoAtualizarConfiguracao,
            mensagem:
                'A sincronização terminou, mas a data não foi salva: '
                '$erro',
          ),
        );
      }
    }
    return ResultadoSincronizacao(
      adicionadas: adicionadas,
      atualizadas: atualizadas,
      inalteradas: inalteradas,
      origensAusentes: origensAusentes,
      erros: erros,
      avisos: avisos,
      enumeracaoCompleta: leituraCompleta,
    );
  }

  Future<_ContadoresGrupo> _aplicarGrupo(
    GrupoMusicaSincronizacaoValido grupo,
    List<ErroSincronizacao> erros,
    List<AvisoSincronizacao> avisos,
  ) async {
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
          return const _ContadoresGrupo();
        }
        for (final arquivo in grupo.arquivos) {
          if (await _repositorioVersoes.obterVersaoPorId(
                arquivo.idVersaoMusica,
              ) !=
              null) {
            _registrarColisao(grupo, arquivo, erros);
            return const _ContadoresGrupo();
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
        return _ContadoresGrupo(adicionadas: grupo.arquivos.length);
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
          if (arquivo.principalDeclarada) {
            _avisarPrincipal(arquivo, avisos);
          }
          continue;
        }
        final origem = await _repositorioOrigens.obterPorVersao(versao.id);
        if (versao.idMusica != grupo.idMusica || origem == null) {
          _registrarColisao(grupo, arquivo, erros);
          return const _ContadoresGrupo();
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
      return _ContadoresGrupo(
        adicionadas: adicionadas,
        atualizadas: atualizadas,
        inalteradas: inalteradas,
      );
    } catch (erro) {
      erros.add(
        ErroSincronizacao(
          codigo: CodigoErroSincronizacao.falhaAplicacao,
          localizador: grupo.arquivos.first.candidato.localizador,
          mensagem: 'Falha ao aplicar a música ${grupo.idMusica.valor}: $erro',
        ),
      );
      return const _ContadoresGrupo();
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

  IdVersaoMusica? _reconhecerIdVersao(ArquivoSincronizacaoCandidato candidato) {
    try {
      final conteudo = utf8.decode(candidato.bytes, allowMalformed: false);
      final ids = _parserDocumento
          .interpretar(conteudo)
          .elementos
          .whereType<DiretivaIdVersaoAppCifras>()
          .where((diretiva) => diretiva.id != null)
          .map((diretiva) => diretiva.id!)
          .toList();
      return ids.length == 1 ? IdVersaoMusica(ids.single) : null;
    } catch (_) {
      return null;
    }
  }

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

  ResultadoSincronizacao _resultadoGlobal(
    CodigoErroSincronizacao codigo,
    String mensagem,
  ) => ResultadoSincronizacao(
    adicionadas: 0,
    atualizadas: 0,
    inalteradas: 0,
    origensAusentes: 0,
    erros: [ErroSincronizacao(codigo: codigo, mensagem: mensagem)],
    avisos: const [],
    enumeracaoCompleta: false,
  );
}

class _ContadoresGrupo {
  const _ContadoresGrupo({
    this.adicionadas = 0,
    this.atualizadas = 0,
    this.inalteradas = 0,
  });

  final int adicionadas;
  final int atualizadas;
  final int inalteradas;
}
