import '../../dominio/objetos_de_valor/id_musica.dart';

// ignore_for_file: prefer_initializing_formals
import '../portas/repositorio_sincronizacao.dart';
import '../sincronizacao/aplicar_grupo_sincronizacao.dart';
import '../sincronizacao/modelos_sincronizacao.dart';
import '../sincronizacao/montar_inventario_sincronizacao.dart';
import '../sincronizacao/resultado_sincronizacao.dart';
import 'estado_biblioteca_oficial.dart';
import 'falha_biblioteca_oficial.dart';
import 'preparar_atualizacao_biblioteca_oficial.dart';

enum EtapaErroAtualizacaoBibliotecaOficial {
  preparacao,
  download,
  validacaoArquivo,
  validacaoGrupo,
  aplicacao,
  origem,
  ausencia,
  geracao,
}

class ErroAtualizacaoBibliotecaOficial {
  const ErroAtualizacaoBibliotecaOficial({
    required this.etapa,
    required this.mensagem,
    this.localizador,
    this.idMusica,
  });

  final EtapaErroAtualizacaoBibliotecaOficial etapa;
  final String mensagem;
  final String? localizador;
  final IdMusica? idMusica;
}

class ResultadoAtualizacaoBibliotecaOficial {
  ResultadoAtualizacaoBibliotecaOficial({
    required this.geracao,
    required this.adicionadas,
    required this.atualizadas,
    required this.inalteradas,
    required this.origensAusentes,
    required this.geracaoRegistrada,
    required Iterable<ErroAtualizacaoBibliotecaOficial> erros,
    required Iterable<AvisoSincronizacao> avisos,
  }) : erros = List.unmodifiable(erros),
       avisos = List.unmodifiable(avisos);

  final String? geracao;
  final int adicionadas;
  final int atualizadas;
  final int inalteradas;
  final int origensAusentes;
  final bool geracaoRegistrada;
  final List<ErroAtualizacaoBibliotecaOficial> erros;
  final List<AvisoSincronizacao> avisos;
  bool get concluida => geracaoRegistrada && erros.isEmpty;
}

class AtualizarBibliotecaOficial {
  AtualizarBibliotecaOficial({
    required PrepararAtualizacaoBibliotecaOficial preparar,
    required AplicarGrupoSincronizacao aplicarGrupo,
    required RepositorioOrigensSincronizadas repositorioOrigens,
    required RepositorioEstadoBibliotecaOficial repositorioEstado,
    MontarInventarioSincronizacao? montarInventario,
    DateTime Function()? agora,
  }) : _preparar = preparar,
       _aplicarGrupo = aplicarGrupo,
       _repositorioOrigens = repositorioOrigens,
       _repositorioEstado = repositorioEstado,
       _montarInventario = montarInventario ?? MontarInventarioSincronizacao(),
       _agora = agora ?? DateTime.now;

  final PrepararAtualizacaoBibliotecaOficial _preparar;
  final AplicarGrupoSincronizacao _aplicarGrupo;
  final RepositorioOrigensSincronizadas _repositorioOrigens;
  final RepositorioEstadoBibliotecaOficial _repositorioEstado;
  final MontarInventarioSincronizacao _montarInventario;
  final DateTime Function() _agora;

  Future<ResultadoAtualizacaoBibliotecaOficial> executar() async {
    late final PreparacaoAtualizacaoBibliotecaOficial preparacao;
    try {
      preparacao = await _preparar.executar();
    } on FalhaBibliotecaOficial catch (falha) {
      return _falhaPreparacao(falha.mensagem);
    } catch (erro) {
      return _falhaPreparacao('Falha ao preparar a biblioteca oficial: $erro');
    }

    final erros = <ErroAtualizacaoBibliotecaOficial>[];
    final avisos = <AvisoSincronizacao>[];
    final musicasComFalha = <IdMusica>{};
    final remotosPorCaminho = {
      for (final remoto in preparacao.manifesto.arquivos)
        remoto.caminho: remoto,
    };

    for (final erro in preparacao.erros) {
      musicasComFalha.add(erro.remoto.idMusica);
      erros.add(
        ErroAtualizacaoBibliotecaOficial(
          etapa: EtapaErroAtualizacaoBibliotecaOficial.download,
          localizador: erro.remoto.caminho,
          idMusica: erro.remoto.idMusica,
          mensagem: erro.falha.mensagem,
        ),
      );
    }

    final candidatos = preparacao.arquivosBaixados
        .where((arquivo) => !musicasComFalha.contains(arquivo.remoto.idMusica))
        .map(
          (arquivo) => ArquivoSincronizacaoCandidato(
            localizador: arquivo.remoto.caminho,
            nomeLegivel: arquivo.remoto.caminho,
            bytes: arquivo.bytes,
          ),
        )
        .toList(growable: false);
    final inventario = _montarInventario.executar(candidatos);

    for (final arquivo in inventario.arquivosInvalidos) {
      final remoto = remotosPorCaminho[arquivo.candidato.localizador];
      if (remoto != null) musicasComFalha.add(remoto.idMusica);
      erros.add(
        ErroAtualizacaoBibliotecaOficial(
          etapa: EtapaErroAtualizacaoBibliotecaOficial.validacaoArquivo,
          localizador: arquivo.candidato.localizador,
          idMusica: remoto?.idMusica,
          mensagem:
              'Arquivo oficial inválido: '
              '${arquivo.erros.map((erro) => erro.codigo.name).join(', ')}.',
        ),
      );
    }
    final localizadoresComIdentidadeDivergente = <String>{};
    for (final arquivo in inventario.arquivosValidos) {
      final remoto = remotosPorCaminho[arquivo.candidato.localizador];
      if (remoto == null ||
          (remoto.idMusica == arquivo.idMusica &&
              remoto.idVersaoMusica == arquivo.idVersaoMusica)) {
        continue;
      }
      localizadoresComIdentidadeDivergente.add(arquivo.candidato.localizador);
      musicasComFalha
        ..add(remoto.idMusica)
        ..add(arquivo.idMusica);
      erros.add(
        ErroAtualizacaoBibliotecaOficial(
          etapa: EtapaErroAtualizacaoBibliotecaOficial.validacaoArquivo,
          localizador: arquivo.candidato.localizador,
          idMusica: remoto.idMusica,
          mensagem:
              'A identidade do ChordPro não corresponde à entrada do '
              'manifesto oficial.',
        ),
      );
    }
    for (final grupo in inventario.gruposRejeitados) {
      musicasComFalha.add(grupo.idMusica);
      erros.add(
        ErroAtualizacaoBibliotecaOficial(
          etapa: EtapaErroAtualizacaoBibliotecaOficial.validacaoGrupo,
          localizador: grupo.arquivos.firstOrNull?.candidato.localizador,
          idMusica: grupo.idMusica,
          mensagem:
              'Grupo oficial inválido: '
              '${grupo.erros.map((erro) => erro.codigo.name).join(', ')}.',
        ),
      );
    }

    var adicionadas = 0;
    var atualizadas = 0;
    for (final grupo in inventario.gruposValidos) {
      if (musicasComFalha.contains(grupo.idMusica) ||
          grupo.arquivos.any(
            (arquivo) => localizadoresComIdentidadeDivergente.contains(
              arquivo.candidato.localizador,
            ),
          )) {
        continue;
      }
      final resultado = await _aplicarGrupo.executar(grupo);
      adicionadas += resultado.adicionadas;
      atualizadas += resultado.atualizadas;
      avisos.addAll(resultado.avisos);
      if (!resultado.concluida) {
        musicasComFalha.add(grupo.idMusica);
        for (final erro in resultado.erros) {
          erros.add(
            ErroAtualizacaoBibliotecaOficial(
              etapa: EtapaErroAtualizacaoBibliotecaOficial.aplicacao,
              localizador: erro.localizador,
              idMusica: grupo.idMusica,
              mensagem: erro.mensagem,
            ),
          );
        }
      }
    }

    for (final item in preparacao.inalteradas) {
      if (musicasComFalha.contains(item.remoto.idMusica)) continue;
      final origem = item.origemLocal!;
      if (origem.presente &&
          origem.localizadorExterno == item.remoto.caminho &&
          origem.hashSha256 == item.remoto.sha256) {
        continue;
      }
      try {
        await _repositorioOrigens.marcarPresente(
          item.remoto.idVersaoMusica,
          localizadorExterno: item.remoto.caminho,
          hashSha256: item.remoto.sha256,
        );
      } catch (erro) {
        musicasComFalha.add(item.remoto.idMusica);
        erros.add(
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.origem,
            localizador: item.remoto.caminho,
            idMusica: item.remoto.idMusica,
            mensagem: 'Falha ao atualizar a origem oficial: $erro',
          ),
        );
      }
    }

    var origensAusentes = 0;
    for (final origem in preparacao.ausentes) {
      if (!origem.presente) continue;
      try {
        await _repositorioOrigens.marcarAusente(origem.idVersaoMusica);
        origensAusentes++;
      } catch (erro) {
        erros.add(
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.ausencia,
            localizador: origem.localizadorExterno,
            mensagem: 'Falha ao marcar origem oficial ausente: $erro',
          ),
        );
      }
    }

    var geracaoRegistrada = false;
    if (erros.isEmpty) {
      try {
        await _repositorioEstado.salvarEstadoBibliotecaOficial(
          EstadoBibliotecaOficial(
            ultimaGeracao: preparacao.geracao,
            ultimaAtualizacao: _agora(),
          ),
        );
        geracaoRegistrada = true;
      } catch (erro) {
        erros.add(
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.geracao,
            mensagem: 'Falha ao registrar a geração oficial: $erro',
          ),
        );
      }
    }

    return ResultadoAtualizacaoBibliotecaOficial(
      geracao: preparacao.geracao,
      adicionadas: adicionadas,
      atualizadas: atualizadas,
      inalteradas: preparacao.inalteradas.length,
      origensAusentes: origensAusentes,
      geracaoRegistrada: geracaoRegistrada,
      erros: erros,
      avisos: avisos,
    );
  }

  ResultadoAtualizacaoBibliotecaOficial _falhaPreparacao(String mensagem) =>
      ResultadoAtualizacaoBibliotecaOficial(
        geracao: null,
        adicionadas: 0,
        atualizadas: 0,
        inalteradas: 0,
        origensAusentes: 0,
        geracaoRegistrada: false,
        erros: [
          ErroAtualizacaoBibliotecaOficial(
            etapa: EtapaErroAtualizacaoBibliotecaOficial.preparacao,
            mensagem: mensagem,
          ),
        ],
        avisos: const [],
      );
}
