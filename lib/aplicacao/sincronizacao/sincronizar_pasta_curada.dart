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
import 'aplicar_grupo_sincronizacao.dart';
import 'configuracao_pasta_sincronizada.dart';
import 'modelos_sincronizacao.dart';
import 'montar_inventario_pasta_curada.dart';
import 'resultado_sincronizacao.dart';

export 'resultado_sincronizacao.dart';

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
       _aplicarGrupo = AplicarGrupoSincronizacao(
         repositorioOrigens: repositorioOrigens,
         repositorioMusicas: repositorioMusicas,
         repositorioVersoes: repositorioVersoes,
         aplicador: aplicador,
       ),
       _montarInventario = montarInventario ?? MontarInventarioPastaCurada(),
       _parserDocumento = parserDocumento ?? ParserDocumentoChordPro(),
       _agora = agora ?? DateTime.now;

  final PastaCuradaExterna _pastaExterna;
  final RepositorioConfiguracaoPastaSincronizada _repositorioConfiguracao;
  final RepositorioOrigensSincronizadas _repositorioOrigens;
  final AplicarGrupoSincronizacao _aplicarGrupo;
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
      final resultadoGrupo = await _aplicarGrupo.executar(grupo);
      adicionadas += resultadoGrupo.adicionadas;
      atualizadas += resultadoGrupo.atualizadas;
      inalteradas += resultadoGrupo.inalteradas;
      erros.addAll(resultadoGrupo.erros);
      avisos.addAll(resultadoGrupo.avisos);
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
