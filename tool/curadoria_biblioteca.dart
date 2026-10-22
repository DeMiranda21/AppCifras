import 'dart:convert';
import 'dart:io';

import 'package:appcifras/aplicacao/entrada/classificador_linha_cifra_textual.dart';
import 'package:appcifras/aplicacao/sincronizacao/modelos_sincronizacao.dart';
import 'package:appcifras/aplicacao/sincronizacao/validar_arquivo_pasta_curada.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'conversor_curadoria.dart';
import 'detector_tonal.dart';
import 'overrides_curadoria.dart';
import 'politica_melhor_tom.dart';
import 'politica_relativo_maior.dart';

enum StatusCuradoria { pronto, revisar, bloqueado }

class OpcoesCuradoria {
  const OpcoesCuradoria({
    required this.biblioteca,
    required this.lote,
    this.simular = false,
    this.reavaliar = false,
    this.adotarChoEditado = false,
    this.substituirChoEditado = false,
    this.arquivosOverridesAdicionais = const [],
    this.configuracao,
  });

  final Directory biblioteca;
  final String lote;
  final bool simular;
  final bool reavaliar;
  final bool adotarChoEditado;
  final bool substituirChoEditado;
  final List<File> arquivosOverridesAdicionais;
  final ConfiguracaoCuradoria? configuracao;
}

class OpcoesCuradoriaSeletiva {
  const OpcoesCuradoriaSeletiva({
    required this.biblioteca,
    required this.origensArquivo,
    this.simular = false,
    this.arquivosOverridesAdicionais = const [],
    this.configuracao,
  });

  final Directory biblioteca;
  final File origensArquivo;
  final bool simular;
  final List<File> arquivosOverridesAdicionais;
  final ConfiguracaoCuradoria? configuracao;
}

class ResumoCuradoriaSeletiva {
  const ResumoCuradoriaSeletiva({
    required this.totalSelecionadas,
    required this.processadas,
    required this.recuperadas,
    required this.ignoradas,
    required this.prontos,
    required this.revisar,
    required this.bloqueados,
    required this.entradas,
  });

  final int totalSelecionadas;
  final int processadas;
  final int recuperadas;
  final int ignoradas;
  final int prontos;
  final int revisar;
  final int bloqueados;
  final List<Map<String, Object?>> entradas;
}

class ResumoCuradoria {
  const ResumoCuradoria({
    required this.total,
    required this.prontos,
    required this.revisar,
    required this.bloqueados,
    required this.inalterados,
    required this.conflitos,
    required this.entradas,
    required this.calibracaoTonal,
  });

  final int total;
  final int prontos;
  final int revisar;
  final int bloqueados;
  final int inalterados;
  final int conflitos;
  final List<Map<String, Object?>> entradas;
  final ResultadoCalibracaoTonal calibracaoTonal;
}

class CuradoriaBiblioteca {
  CuradoriaBiblioteca({
    Uuid? uuid,
    this.depoisDePersistirChoSeletivo,
    this.calibradorTonal,
  }) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Future<void> Function(String origem)? depoisDePersistirChoSeletivo;
  final Future<ResultadoCalibracaoTonal> Function(Directory biblioteca)?
  calibradorTonal;
  final ConversorCuradoriaConservador _conversor =
      ConversorCuradoriaConservador();
  final ClassificadorLinhaCifraTextual _classificador =
      ClassificadorLinhaCifraTextual();
  final ParserAcorde _parserAcorde = ParserAcorde();
  final ValidarArquivoPastaCurada _validador = ValidarArquivoPastaCurada();
  final DetectorTonal _detectorTonal = DetectorTonal();

  static final RegExp _tom = RegExp(
    r'^\s*(?:tom|key)\s*:\s*\[?([A-G](?:[#b])?m?)\]?\s*$',
    caseSensitive: false,
  );
  static final RegExp _cabecalhoCifra = RegExp(
    r'^\s*cifra\s*:',
    caseSensitive: false,
  );
  static final RegExp _uuidValido = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final Set<String> _execucoesAtivas = <String>{};

  Future<ResumoCuradoria> executar(OpcoesCuradoria opcoes) async {
    if (opcoes.adotarChoEditado && opcoes.substituirChoEditado) {
      throw ArgumentError(
        'Escolha somente uma política para CHO editado: adotar ou substituir.',
      );
    }
    if (opcoes.simular) return _executarInterno(opcoes);
    final chaveExecucao = opcoes.biblioteca.absolute.path.toLowerCase();
    if (!_execucoesAtivas.add(chaveExecucao)) {
      throw StateError('Já existe uma curadoria em execução nesta biblioteca.');
    }
    final lock = File(
      _juntar(opcoes.biblioteca.path, '.curadoria-execucao.lock'),
    );
    await lock.parent.create(recursive: true);
    RandomAccessFile? handle;
    try {
      handle = await lock.open(mode: FileMode.append);
      await handle.lock(FileLock.exclusive);
      return await _executarInterno(opcoes);
    } finally {
      if (handle != null) {
        await handle.unlock();
        await handle.close();
      }
      _execucoesAtivas.remove(chaveExecucao);
    }
  }

  Future<ResumoCuradoriaSeletiva> executarSeletivo(
    OpcoesCuradoriaSeletiva opcoes,
  ) async {
    if (opcoes.simular) return _simularSeletivoInterno(opcoes);
    final chaveExecucao = opcoes.biblioteca.absolute.path.toLowerCase();
    if (!_execucoesAtivas.add(chaveExecucao)) {
      throw StateError('Já existe uma curadoria em execução nesta biblioteca.');
    }
    final lock = File(
      _juntar(opcoes.biblioteca.path, '.curadoria-execucao.lock'),
    );
    await lock.parent.create(recursive: true);
    RandomAccessFile? handle;
    try {
      handle = await lock.open(mode: FileMode.append);
      await handle.lock(FileLock.exclusive);
      return await _executarSeletivoInterno(opcoes);
    } finally {
      if (handle != null) {
        await handle.unlock();
        await handle.close();
      }
      _execucoesAtivas.remove(chaveExecucao);
    }
  }

  Future<ResumoCuradoriaSeletiva> _simularSeletivoInterno(
    OpcoesCuradoriaSeletiva opcoes,
  ) async {
    final origens = await _lerOrigensSeletivas(opcoes);
    final manifestoArquivo = File(
      _juntar(opcoes.biblioteca.path, 'manifest.json'),
    );
    if (!await manifestoArquivo.exists()) {
      throw StateError(
        'Manifesto inexistente; o modo seletivo exige origens já registradas.',
      );
    }
    final manifesto = await _lerManifesto(manifestoArquivo);
    _validarManifesto(manifesto);
    final entradas = (manifesto['entradas'] as List)
        .cast<Map<String, Object?>>();
    final configuracao =
        opcoes.configuracao ??
        await ConfiguracaoCuradoria.carregar(opcoes.biblioteca);
    _validarSelecaoPoliticaMelhorTom(origens, entradas, configuracao);
    final overrides = await OverridesCuradoria.carregar(
      opcoes.biblioteca,
      adicionais: opcoes.arquivosOverridesAdicionais,
    );
    final permiteAlta = entradas.any(
      (entrada) =>
          entrada['origemTom'] == 'inferido' &&
          entrada['confiancaTom'] == ConfiancaDeteccaoTom.alta.name,
    );
    final simuladas = <Map<String, Object?>>[];
    for (final relativo in origens) {
      final anterior = _entradaPorOrigem(entradas, relativo);
      if (anterior == null) {
        throw ArgumentError('Origem não registrada no manifesto: $relativo');
      }
      final origem = File(_juntarRelativo(opcoes.biblioteca.path, relativo));
      final bytes = await origem.readAsBytes();
      final nova =
          _processar(
              opcoes: OpcoesCuradoria(
                biblioteca: opcoes.biblioteca,
                lote: relativo.split('/').first,
                simular: true,
                reavaliar: true,
                arquivosOverridesAdicionais: opcoes.arquivosOverridesAdicionais,
                configuracao: configuracao,
              ),
              origem: origem,
              relativo: relativo,
              bytes: bytes,
              hash: sha256.convert(bytes).toString(),
              anterior: anterior,
              entradas: entradas,
              override: overrides.paraOrigem(relativo),
              identidadePendente: null,
              permiteAplicacaoAutomaticaAlta: permiteAlta,
              configuracao: configuracao,
            )
            ..remove('_conteudoCho')
            ..remove('_destinoAbsoluto');
      simuladas.add(nova);
    }
    return ResumoCuradoriaSeletiva(
      totalSelecionadas: simuladas.length,
      processadas: simuladas.length,
      recuperadas: 0,
      ignoradas: 0,
      prontos: _contar(simuladas, StatusCuradoria.pronto),
      revisar: _contar(simuladas, StatusCuradoria.revisar),
      bloqueados: _contar(simuladas, StatusCuradoria.bloqueado),
      entradas: List.unmodifiable(simuladas),
    );
  }

  Future<ResumoCuradoria> _executarInterno(OpcoesCuradoria opcoes) async {
    final configuracao =
        opcoes.configuracao ??
        await ConfiguracaoCuradoria.carregar(opcoes.biblioteca);
    final calibracaoTonal = await (calibradorTonal ?? _calibrarDetectorTonal)(
      opcoes.biblioteca,
    );
    final lote = Directory(_juntar(opcoes.biblioteca.path, opcoes.lote));
    if (!await lote.exists()) {
      throw ArgumentError('Lote não encontrado: ${lote.path}');
    }
    final arquivos = await lote
        .list(followLinks: false)
        .where(
          (item) => item is File && item.path.toLowerCase().endsWith('.txt'),
        )
        .cast<File>()
        .toList();
    arquivos.sort((a, b) => _nome(a.path).compareTo(_nome(b.path)));

    final manifestoArquivo = File(
      _juntar(opcoes.biblioteca.path, 'manifest.json'),
    );
    final relatorioArquivo = File(
      _juntar(opcoes.biblioteca.path, 'relatorio.md'),
    );
    final checkpointArquivo = File(
      _juntar(opcoes.biblioteca.path, '.curadoria-checkpoint.json'),
    );
    final manifesto = await _lerManifesto(manifestoArquivo);
    _validarManifesto(manifesto);
    final checkpoint = await _lerCheckpoint(checkpointArquivo);
    final overrides = await OverridesCuradoria.carregar(
      opcoes.biblioteca,
      adicionais: opcoes.arquivosOverridesAdicionais,
    );
    final entradas = (manifesto['entradas'] as List)
        .cast<Map<String, Object?>>();

    if (!opcoes.simular) {
      for (final pasta in StatusCuradoria.values) {
        await Directory(_juntar(opcoes.biblioteca.path, _pastaDeSaida(pasta)))
            .create(recursive: true);
      }
      if (!await manifestoArquivo.exists()) {
        await _salvarJsonAtomico(manifestoArquivo, manifesto);
      }
      if (!await relatorioArquivo.exists()) {
        await _salvarTextoAtomico(
          relatorioArquivo,
          '# Relatório consolidado da curadoria\n',
        );
      }
    }

    var inalterados = 0;
    for (var indice = 0; indice < arquivos.length; indice++) {
      final origem = arquivos[indice];
      final relativo = '${opcoes.lote}/${_nome(origem.path)}';
      final bytes = await origem.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final anterior = _entradaPorOrigem(entradas, relativo);
      if (!opcoes.reavaliar &&
          anterior != null &&
          anterior['hashOrigem'] == hash) {
        inalterados++;
        continue;
      }

      Map<String, Object?> nova;
      try {
        final edicaoManual = await _detectarEdicaoManual(
          biblioteca: opcoes.biblioteca,
          entradaAnterior: anterior,
        );
        if (edicaoManual != null && !opcoes.substituirChoEditado) {
          if (opcoes.adotarChoEditado) {
            nova = {
              ...anterior!,
              'hashChoGerado': edicaoManual.hashAtual,
              'conflitoChoEditado': false,
              'observacoes': [
                ...(anterior['observacoes'] as List? ?? const []),
                'Edição humana do CHO adotada explicitamente.',
              ],
              '_preservarChoExistente': true,
            };
          } else {
            const motivo =
                'CHO existente difere do último conteúdo gerado; use opção explícita para adotar ou substituir.';
            nova = {
              ...anterior!,
              'status': StatusCuradoria.revisar.name,
              'conflitoChoEditado': true,
              'motivosRevisao': [
                ...(anterior['motivosRevisao'] as List? ?? const []),
                motivo,
              ],
              'observacoes': [
                ...(anterior['observacoes'] as List? ?? const []),
                motivo,
              ],
              '_preservarChoExistente': true,
            };
          }
        } else {
          final identidadePendente = _identidadePendente(checkpoint, relativo);
          nova = _processar(
            opcoes: opcoes,
            origem: origem,
            relativo: relativo,
            bytes: bytes,
            hash: hash,
            anterior: anterior,
            entradas: entradas,
            override: overrides.paraOrigem(relativo),
            identidadePendente: identidadePendente,
            permiteAplicacaoAutomaticaAlta:
                calibracaoTonal.permiteAplicacaoAutomaticaAlta,
            configuracao: configuracao,
          );
        }
      } catch (erro, pilha) {
        nova = _entradaFalha(
          opcoes.lote,
          relativo,
          origem,
          hash,
          anterior,
          'Falha isolada: $erro',
          pilha,
        );
      }
      if (anterior == null) {
        entradas.add(nova);
      } else {
        entradas[entradas.indexOf(anterior)] = nova;
      }

      if (!opcoes.simular) {
        final conteudo = nova.remove('_conteudoCho') as String?;
        final preservarChoExistente =
            nova.remove('_preservarChoExistente') == true;
        nova.remove('_destinoAbsoluto');
        await _salvarJsonAtomico(checkpointArquivo, {
          'lote': opcoes.lote,
          'total': arquivos.length,
          'processadosNestaExecucao': indice,
          'ultimoArquivo': indice == 0
              ? null
              : _nome(arquivos[indice - 1].path),
          'concluido': false,
          'pendente': {
            'origem': relativo,
            'idMusica': nova['idMusica'],
            'idVersaoMusica': nova['idVersaoMusica'],
            'destino': nova['destino'],
            'hashChoGerado': nova['hashChoGerado'],
          },
        });
        if (!preservarChoExistente) {
          await _persistirCho(
            biblioteca: opcoes.biblioteca,
            entradaAnterior: anterior,
            entradaNova: nova,
            conteudo: conteudo,
          );
        }
        manifesto['atualizadoEm'] = DateTime.now().toUtc().toIso8601String();
        _validarManifesto(manifesto);
        await _salvarJsonAtomico(manifestoArquivo, manifesto);
        await _salvarJsonAtomico(checkpointArquivo, {
          'lote': opcoes.lote,
          'total': arquivos.length,
          'processadosNestaExecucao': indice + 1,
          'ultimoArquivo': _nome(origem.path),
          'concluido': false,
          'pendente': null,
        });
      }
    }

    final doLote = entradas.where((e) => e['lote'] == opcoes.lote).toList();
    final resumo = ResumoCuradoria(
      total: arquivos.length,
      prontos: _contar(doLote, StatusCuradoria.pronto),
      revisar: _contar(doLote, StatusCuradoria.revisar),
      bloqueados: _contar(doLote, StatusCuradoria.bloqueado),
      inalterados: inalterados,
      conflitos: doLote
          .where(
            (e) => e['conflitoNome'] == true || e['conflitoChoEditado'] == true,
          )
          .length,
      entradas: List.unmodifiable(doLote),
      calibracaoTonal: calibracaoTonal,
    );
    if (!opcoes.simular) {
      manifesto['atualizadoEm'] = DateTime.now().toUtc().toIso8601String();
      manifesto['ultimaExecucao'] = {
        'lote': opcoes.lote,
        'total': arquivos.length,
        'processados': arquivos.length - inalterados,
        'inalterados': inalterados,
        'concluida': true,
      };
      await _salvarJsonAtomico(manifestoArquivo, manifesto);
      await _salvarJsonAtomico(checkpointArquivo, {
        'lote': opcoes.lote,
        'total': arquivos.length,
        'processadosNestaExecucao': arquivos.length - inalterados,
        'concluido': true,
      });
      await _salvarTextoAtomico(
        relatorioArquivo,
        _gerarRelatorio(
          entradas,
          loteAtual: opcoes.lote,
          inalteradosNoLoteAtual: inalterados,
        ),
      );
    }
    return resumo;
  }

  Future<ResumoCuradoriaSeletiva> _executarSeletivoInterno(
    OpcoesCuradoriaSeletiva opcoes,
  ) async {
    final origens = await _lerOrigensSeletivas(opcoes);
    final digestSelecao = sha256
        .convert(utf8.encode(origens.join('\n')))
        .toString();
    final manifestoArquivo = File(
      _juntar(opcoes.biblioteca.path, 'manifest.json'),
    );
    if (!await manifestoArquivo.exists()) {
      throw StateError(
        'Manifesto inexistente; o modo seletivo exige origens já registradas.',
      );
    }
    final manifesto = await _lerManifesto(manifestoArquivo);
    _validarManifesto(manifesto);
    final entradas = (manifesto['entradas'] as List)
        .cast<Map<String, Object?>>();
    for (final origem in origens) {
      if (_entradaPorOrigem(entradas, origem) == null) {
        throw ArgumentError('Origem não registrada no manifesto: $origem');
      }
    }
    final configuracao =
        opcoes.configuracao ??
        await ConfiguracaoCuradoria.carregar(opcoes.biblioteca);

    final checkpointArquivo = File(
      _juntar(opcoes.biblioteca.path, '.curadoria-seletiva-checkpoint.json'),
    );
    var checkpoint = await _lerCheckpoint(checkpointArquivo);
    if (checkpoint['concluido'] != true &&
        checkpoint.isNotEmpty &&
        checkpoint['digestSelecao'] != digestSelecao) {
      throw StateError(
        'Há outra seleção incompleta no checkpoint seletivo; retome-a antes de iniciar uma nova.',
      );
    }
    final checkpointCorresponde = checkpoint['digestSelecao'] == digestSelecao;
    final concluidasNoCheckpoint =
        checkpointCorresponde && checkpoint['concluidas'] is Map
        ? Map<String, Object?>.from(checkpoint['concluidas'] as Map).keys
              .toSet()
        : const <String>{};
    final pendenteNoCheckpoint =
        checkpointCorresponde && checkpoint['pendente'] is Map
        ? (checkpoint['pendente'] as Map)['origem'] as String?
        : null;
    final origensAindaNaoIniciadas = origens
        .where(
          (origem) =>
              !concluidasNoCheckpoint.contains(origem) &&
              origem != pendenteNoCheckpoint,
        )
        .toList(growable: false);
    _validarSelecaoPoliticaMelhorTom(
      origensAindaNaoIniciadas,
      entradas,
      configuracao,
    );
    if (!checkpointCorresponde) {
      checkpoint = <String, Object?>{
        'schema': 1,
        'digestSelecao': digestSelecao,
        'origens': origens,
        'concluido': false,
        'concluidas': <String, Object?>{},
        'pendente': null,
      };
      await _salvarJsonAtomico(checkpointArquivo, checkpoint);
    }

    final overrides = await OverridesCuradoria.carregar(
      opcoes.biblioteca,
      adicionais: opcoes.arquivosOverridesAdicionais,
    );
    final permiteAlta = entradas.any(
      (entrada) =>
          entrada['origemTom'] == 'inferido' &&
          entrada['confiancaTom'] == ConfiancaDeteccaoTom.alta.name,
    );
    final checkpointNormalArquivo = File(
      _juntar(opcoes.biblioteca.path, '.curadoria-checkpoint.json'),
    );
    final checkpointNormal = await _lerCheckpoint(checkpointNormalArquivo);
    final concluidas = Map<String, Object?>.from(
      checkpoint['concluidas'] is Map
          ? checkpoint['concluidas'] as Map
          : const <String, Object?>{},
    );
    var processadas = 0;
    var recuperadas = 0;
    var ignoradas = 0;

    for (final relativo in origens) {
      final origem = File(_juntarRelativo(opcoes.biblioteca.path, relativo));
      final bytes = await origem.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final anterior = _entradaPorOrigem(entradas, relativo)!;
      final pendenteSeletivo = _pendenteParaOrigem(checkpoint, relativo);
      final pendenteNormal = _identidadePendente(checkpointNormal, relativo);
      if (pendenteSeletivo == null && pendenteNormal == null) {
        final edicaoManual = await _detectarEdicaoManual(
          biblioteca: opcoes.biblioteca,
          entradaAnterior: anterior,
        );
        if (edicaoManual != null) {
          throw StateError(
            'CHO editado manualmente em $relativo; a execução seletiva não o substituirá.',
          );
        }
      }
      final identidadePendente = pendenteSeletivo?['entradaNova'] is Map
          ? Map<String, Object?>.from(pendenteSeletivo!['entradaNova'] as Map)
          : pendenteNormal;
      final lote = relativo.split('/').first;
      final nova = _processar(
        opcoes: OpcoesCuradoria(
          biblioteca: opcoes.biblioteca,
          lote: lote,
          reavaliar: true,
          arquivosOverridesAdicionais: opcoes.arquivosOverridesAdicionais,
          configuracao: configuracao,
        ),
        origem: origem,
        relativo: relativo,
        bytes: bytes,
        hash: hash,
        anterior: anterior,
        entradas: entradas,
        override: overrides.paraOrigem(relativo),
        identidadePendente: identidadePendente,
        permiteAplicacaoAutomaticaAlta: permiteAlta,
        configuracao: configuracao,
      );
      final conteudo = nova.remove('_conteudoCho') as String?;
      nova.remove('_destinoAbsoluto');
      final jaConcluida =
          _entradasEquivalentes(anterior, nova) &&
          await _estadoChoCorresponde(opcoes.biblioteca, nova);
      if (jaConcluida) {
        ignoradas++;
        if (pendenteSeletivo != null) {
          final rollback = pendenteSeletivo['rollback'];
          await _removerRollback(
            rollback is Map ? Map<String, Object?>.from(rollback) : null,
          );
        }
        if (pendenteNormal != null &&
            _pendenciaCorresponde(pendenteNormal, nova)) {
          recuperadas++;
          await _salvarJsonAtomico(checkpointNormalArquivo, {
            ...checkpointNormal,
            'pendente': null,
            'recuperadoPorExecucaoSeletiva': relativo,
          });
        }
        concluidas[relativo] = _registroConcluido(nova, hash);
        checkpoint = {
          ...checkpoint,
          'concluido': false,
          'concluidas': concluidas,
          'pendente': pendenteSeletivo != null ? null : checkpoint['pendente'],
        };
        await _salvarJsonAtomico(checkpointArquivo, checkpoint);
        continue;
      }

      final recuperandoNormal = pendenteNormal != null;
      if (recuperandoNormal && !_pendenciaCorresponde(pendenteNormal, nova)) {
        throw StateError(
          'A operação parcial de $relativo não corresponde ao resultado seletivo esperado.',
        );
      }
      if (pendenteSeletivo != null &&
          !_pendenciaSeletivaCorresponde(pendenteSeletivo, anterior, nova)) {
        await _reverterPendenciaSeletiva(opcoes.biblioteca, pendenteSeletivo);
      }

      final indice = entradas.indexOf(anterior);
      final entradasProspectivas = <Map<String, Object?>>[
        ...entradas.take(indice),
        nova,
        ...entradas.skip(indice + 1),
      ];
      final manifestoProspectivo = <String, Object?>{
        ...manifesto,
        'atualizadoEm': DateTime.now().toUtc().toIso8601String(),
        'entradas': entradasProspectivas,
      };
      _validarManifesto(manifestoProspectivo);

      final rollback = pendenteSeletivo?['rollback'] is Map
          ? Map<String, Object?>.from(pendenteSeletivo!['rollback'] as Map)
          : await _prepararRollback(opcoes.biblioteca, anterior, relativo);
      final pendente = <String, Object?>{
        'origem': relativo,
        'fase': 'preparada',
        'hashOrigem': hash,
        'entradaAnterior': Map<String, Object?>.from(anterior),
        'entradaNova': Map<String, Object?>.from(nova),
        'rollback': rollback,
      };
      checkpoint = {
        ...checkpoint,
        'concluido': false,
        'concluidas': concluidas,
        'pendente': pendente,
      };
      await _salvarJsonAtomico(checkpointArquivo, checkpoint);

      await _persistirCho(
        biblioteca: opcoes.biblioteca,
        entradaAnterior: anterior,
        entradaNova: nova,
        conteudo: conteudo,
      );
      pendente['fase'] = 'cho_persistido';
      checkpoint = {...checkpoint, 'pendente': pendente};
      await _salvarJsonAtomico(checkpointArquivo, checkpoint);
      await depoisDePersistirChoSeletivo?.call(relativo);

      await _salvarJsonAtomico(manifestoArquivo, manifestoProspectivo);
      entradas[indice] = nova;
      manifesto
        ..['atualizadoEm'] = manifestoProspectivo['atualizadoEm']
        ..['entradas'] = entradas;
      await _removerRollback(rollback);
      concluidas[relativo] = _registroConcluido(nova, hash);
      checkpoint = {
        ...checkpoint,
        'concluido': false,
        'concluidas': concluidas,
        'pendente': null,
      };
      await _salvarJsonAtomico(checkpointArquivo, checkpoint);
      processadas++;
      if (recuperandoNormal) {
        recuperadas++;
        await _salvarJsonAtomico(checkpointNormalArquivo, {
          ...checkpointNormal,
          'pendente': null,
          'recuperadoPorExecucaoSeletiva': relativo,
        });
      }
    }

    final selecionadas = origens
        .map((origem) => _entradaPorOrigem(entradas, origem)!)
        .toList(growable: false);
    final resumo = ResumoCuradoriaSeletiva(
      totalSelecionadas: origens.length,
      processadas: processadas,
      recuperadas: recuperadas,
      ignoradas: ignoradas,
      prontos: _contar(selecionadas, StatusCuradoria.pronto),
      revisar: _contar(selecionadas, StatusCuradoria.revisar),
      bloqueados: _contar(selecionadas, StatusCuradoria.bloqueado),
      entradas: List.unmodifiable(selecionadas),
    );
    await _salvarJsonAtomico(checkpointArquivo, {
      ...checkpoint,
      'concluido': true,
      'pendente': null,
      'resumo': {
        'totalSelecionadas': resumo.totalSelecionadas,
        'processadas': resumo.processadas,
        'recuperadas': resumo.recuperadas,
        'ignoradas': resumo.ignoradas,
        'prontos': resumo.prontos,
        'revisar': resumo.revisar,
        'bloqueados': resumo.bloqueados,
      },
    });
    return resumo;
  }

  Future<List<String>> _lerOrigensSeletivas(
    OpcoesCuradoriaSeletiva opcoes,
  ) async {
    if (!await opcoes.origensArquivo.exists()) {
      throw ArgumentError(
        'Arquivo de origens não encontrado: ${opcoes.origensArquivo.path}',
      );
    }
    final texto = await opcoes.origensArquivo.readAsString(encoding: utf8);
    final origens = <String>[];
    final vistas = <String>{};
    final raizReal = await opcoes.biblioteca.resolveSymbolicLinks();
    for (final bruta in texto.split(RegExp(r'\r\n|\n|\r'))) {
      final origem = bruta.trim().replaceAll('\\', '/');
      if (origem.isEmpty) continue;
      final partes = origem.split('/');
      if (partes.length != 2 ||
          !RegExp(r'^Lote \d+$').hasMatch(partes.first) ||
          partes.any(
            (parte) => parte.isEmpty || parte == '.' || parte == '..',
          ) ||
          !partes.last.toLowerCase().endsWith('.txt') ||
          origem.contains(':')) {
        throw ArgumentError('Origem fora da biblioteca ou inválida: $origem');
      }
      if (!vistas.add(origem.toLowerCase())) {
        throw ArgumentError('Origem duplicada: $origem');
      }
      final arquivo = File(_juntarRelativo(opcoes.biblioteca.path, origem));
      if (!await arquivo.exists()) {
        throw ArgumentError('Origem inexistente: $origem');
      }
      final real = await arquivo.resolveSymbolicLinks();
      final prefixo = raizReal.endsWith(Platform.pathSeparator)
          ? raizReal
          : '$raizReal${Platform.pathSeparator}';
      if (!real.toLowerCase().startsWith(prefixo.toLowerCase())) {
        throw ArgumentError('Origem fora da biblioteca: $origem');
      }
      origens.add(origem);
    }
    if (origens.isEmpty) {
      throw ArgumentError('O arquivo de origens está vazio.');
    }
    origens.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(origens);
  }

  void _validarSelecaoPoliticaMelhorTom(
    List<String> origens,
    List<Map<String, Object?>> entradas,
    ConfiguracaoCuradoria configuracao,
  ) {
    if (!configuracao.politicaMelhorTom.habilitada) return;
    const motivosTonais = {
      'Tom sugerido por inferência com confiança média; exige revisão humana.',
      'Tom não identificado com confiança suficiente.',
      'Tom não atribuído: possível modulação ou centros tonais concorrentes.',
      'Tom não identificado ou inválido.',
    };
    for (final origem in origens) {
      if (origem.toLowerCase() == 'lote 11/yeshua.txt') {
        throw StateError('Origem protegida não pode ser processada: $origem');
      }
      final entrada = _entradaPorOrigem(entradas, origem);
      final motivos = (entrada?['motivosRevisao'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false);
      if (entrada == null ||
          !const {'revisar', 'bloqueado'}.contains(entrada['status']) ||
          motivos.isEmpty ||
          motivos.any((motivo) => !motivosTonais.contains(motivo))) {
        throw StateError(
          'A política de melhor tom aceita somente pendência exclusivamente tonal: $origem',
        );
      }
    }
  }

  Map<String, Object?>? _pendenteParaOrigem(
    Map<String, Object?> checkpoint,
    String origem,
  ) {
    final pendente = checkpoint['pendente'];
    if (pendente is! Map || pendente['origem'] != origem) return null;
    return Map<String, Object?>.from(pendente);
  }

  bool _entradasEquivalentes(
    Map<String, Object?> atual,
    Map<String, Object?> esperada,
  ) {
    Map<String, Object?> normalizar(Map<String, Object?> entrada) => {
      for (final item in entrada.entries)
        if (item.key != 'processadoEm' && !item.key.startsWith('_'))
          item.key: item.value,
    };
    return jsonEncode(normalizar(atual)) == jsonEncode(normalizar(esperada));
  }

  Future<bool> _estadoChoCorresponde(
    Directory biblioteca,
    Map<String, Object?> entrada,
  ) async {
    final destino = entrada['destino'] as String?;
    final hash = entrada['hashChoGerado'] as String?;
    if (destino == null) return hash == null;
    final arquivo = _arquivoDeDestinoValido(biblioteca, destino, entrada);
    if (!await arquivo.exists() || hash == null) return false;
    return sha256.convert(await arquivo.readAsBytes()).toString() == hash;
  }

  Map<String, Object?> _registroConcluido(
    Map<String, Object?> entrada,
    String hashOrigem,
  ) => {
    'hashOrigem': hashOrigem,
    'destino': entrada['destino'],
    'hashChoGerado': entrada['hashChoGerado'],
    'status': entrada['status'],
  };

  bool _pendenciaCorresponde(
    Map<String, Object?> pendente,
    Map<String, Object?> nova,
  ) =>
      pendente['idMusica'] == nova['idMusica'] &&
      pendente['idVersaoMusica'] == nova['idVersaoMusica'] &&
      pendente['destino'] == nova['destino'] &&
      pendente['hashChoGerado'] == nova['hashChoGerado'];

  bool _pendenciaSeletivaCorresponde(
    Map<String, Object?> pendente,
    Map<String, Object?> anterior,
    Map<String, Object?> nova,
  ) {
    final anteriorPendente = pendente['entradaAnterior'];
    final novaPendente = pendente['entradaNova'];
    return anteriorPendente is Map &&
        novaPendente is Map &&
        _entradasEquivalentes(
          Map<String, Object?>.from(anteriorPendente),
          anterior,
        ) &&
        _entradasEquivalentes(Map<String, Object?>.from(novaPendente), nova);
  }

  Future<Map<String, Object?>?> _prepararRollback(
    Directory biblioteca,
    Map<String, Object?> anterior,
    String origem,
  ) async {
    final destino = anterior['destino'] as String?;
    if (destino == null) return null;
    final arquivo = _arquivoDeDestinoValido(biblioteca, destino, anterior);
    if (!await arquivo.exists()) return null;
    final pasta = Directory(_juntar(biblioteca.path, '.curadoria-pendencias'));
    await pasta.create(recursive: true);
    final nome = '${sha256.convert(utf8.encode(origem))}.cho';
    final copia = File(_juntar(pasta.path, nome));
    await arquivo.copy(copia.path);
    return {
      'arquivo': copia.path,
      'destino': destino,
      'hash': sha256.convert(await copia.readAsBytes()).toString(),
    };
  }

  Future<void> _reverterPendenciaSeletiva(
    Directory biblioteca,
    Map<String, Object?> pendente,
  ) async {
    final anterior = pendente['entradaAnterior'];
    final nova = pendente['entradaNova'];
    if (anterior is! Map || nova is! Map) {
      throw StateError('Checkpoint seletivo parcial não pode ser revertido.');
    }
    final entradaAnterior = Map<String, Object?>.from(anterior);
    final entradaNova = Map<String, Object?>.from(nova);
    final destinoNovo = entradaNova['destino'] as String?;
    if (destinoNovo != null) {
      final arquivoNovo = _arquivoDeDestinoValido(
        biblioteca,
        destinoNovo,
        entradaNova,
      );
      if (await arquivoNovo.exists()) {
        final hashAtual = sha256
            .convert(await arquivoNovo.readAsBytes())
            .toString();
        if (hashAtual != entradaNova['hashChoGerado']) {
          throw StateError(
            'CHO parcial foi alterado e não pode ser revertido com segurança.',
          );
        }
        await arquivoNovo.delete();
      }
    }
    final rollback = pendente['rollback'];
    if (rollback is Map) {
      final copia = File(rollback['arquivo'] as String);
      if (!await copia.exists()) {
        throw StateError(
          'Cópia de reversão da operação seletiva não foi encontrada.',
        );
      }
      final hash = sha256.convert(await copia.readAsBytes()).toString();
      if (hash != rollback['hash']) {
        throw StateError(
          'Cópia de reversão da operação seletiva está corrompida.',
        );
      }
      final destino = _arquivoDeDestinoValido(
        biblioteca,
        rollback['destino'] as String,
        entradaAnterior,
      );
      await destino.parent.create(recursive: true);
      await copia.copy(destino.path);
      await copia.delete();
    }
  }

  Future<void> _removerRollback(Map<String, Object?>? rollback) async {
    if (rollback == null) return;
    final arquivo = File(rollback['arquivo'] as String);
    if (await arquivo.exists()) await arquivo.delete();
  }

  Future<ResultadoCalibracaoTonal> _calibrarDetectorTonal(
    Directory biblioteca,
  ) async {
    final totais = <ConfiancaDeteccaoTom, int>{
      for (final nivel in ConfiancaDeteccaoTom.values) nivel: 0,
    };
    final corretos = <ConfiancaDeteccaoTom, int>{
      for (final nivel in ConfiancaDeteccaoTom.values) nivel: 0,
    };
    final divergencias = <Map<String, Object?>>[];
    final casos = <Map<String, Object?>>[];
    var totalExplicito = 0;
    if (!await biblioteca.exists()) {
      return ResultadoCalibracaoTonal(
        totalComTomExplicito: 0,
        porConfianca: {
          for (final nivel in ConfiancaDeteccaoTom.values)
            nivel: const EstatisticaCalibracaoTonal(total: 0, corretos: 0),
        },
        divergencias: const [],
        casos: const [],
      );
    }
    final lotes = await biblioteca
        .list(followLinks: false)
        .where((item) => item is Directory)
        .cast<Directory>()
        .where((pasta) => RegExp(r'^Lote \d+$').hasMatch(_nome(pasta.path)))
        .toList();
    for (final lote in lotes) {
      await for (final item in lote.list(recursive: true, followLinks: false)) {
        if (item is! File || !item.path.toLowerCase().endsWith('.txt')) {
          continue;
        }
        try {
          final texto = detectarCodificacao(await item.readAsBytes()).texto;
          final declarados = <String>[];
          for (final linha in texto.split(RegExp(r'\r\n|\n|\r'))) {
            final match = _tom.firstMatch(linha);
            if (match != null) declarados.add(_normalizarTom(match.group(1)!));
          }
          if (declarados.length != 1) continue;
          totalExplicito++;
          final esperado = declarados.single;
          final resultado = _detectorTonal.detectar(texto);
          final nivel = resultado.confianca;
          totais[nivel] = totais[nivel]! + 1;
          final correto =
              resultado.tomDetectado != null &&
              _tonsEquivalentes(esperado, resultado.tomDetectado!);
          final caso = <String, Object?>{
            'arquivo': item.path.substring(biblioteca.path.length + 1),
            'declarado': esperado,
            'detectado': resultado.tomDetectado,
            'correto': correto,
            'confianca': nivel.name,
            'quantidadeAcordes': resultado.quantidadeAcordes,
            'primeiroAcorde': resultado.primeiroAcorde,
            'ultimoAcorde': resultado.ultimoAcorde,
            'pontuacaoPrimeiro': resultado.primeiroCandidato?.pontuacao,
            'segundoCandidato': resultado.segundoCandidato?.tom,
            'pontuacaoSegundo': resultado.segundoCandidato?.pontuacao,
            'diferencaPontuacao': double.parse(
              resultado.diferencaPontuacao.toStringAsFixed(2),
            ),
            'evidenciasPrimeiro': resultado.evidencias,
            'evidenciasSegundo': resultado.evidenciasSegundoCandidato,
            'possivelModulacao': resultado.possivelModulacao,
          };
          casos.add(caso);
          if (correto) {
            corretos[nivel] = corretos[nivel]! + 1;
          } else {
            divergencias.add(caso);
          }
        } on FormatException {
          // Arquivo sem decodificação inequívoca não serve como calibração.
        }
      }
    }
    return ResultadoCalibracaoTonal(
      totalComTomExplicito: totalExplicito,
      porConfianca: {
        for (final nivel in ConfiancaDeteccaoTom.values)
          nivel: EstatisticaCalibracaoTonal(
            total: totais[nivel]!,
            corretos: corretos[nivel]!,
          ),
      },
      divergencias: List.unmodifiable(divergencias),
      casos: List.unmodifiable(casos),
    );
  }

  bool _tonsEquivalentes(String a, String b) {
    final menorA = a.endsWith('m');
    final menorB = b.endsWith('m');
    if (menorA != menorB) return false;
    final raizA = menorA ? a.substring(0, a.length - 1) : a;
    final raizB = menorB ? b.substring(0, b.length - 1) : b;
    int classe(String nota) {
      const naturais = {
        'C': 0,
        'D': 2,
        'E': 4,
        'F': 5,
        'G': 7,
        'A': 9,
        'B': 11,
      };
      var valor = naturais[nota[0].toUpperCase()]!;
      if (nota.length > 1) valor += nota[1] == '#' ? 1 : -1;
      return valor % 12;
    }

    return classe(raizA) == classe(raizB);
  }

  Map<String, Object?> _processar({
    required OpcoesCuradoria opcoes,
    required File origem,
    required String relativo,
    required List<int> bytes,
    required String hash,
    required Map<String, Object?>? anterior,
    required List<Map<String, Object?>> entradas,
    required OverrideCuradoriaArquivo? override,
    required Map<String, Object?>? identidadePendente,
    required bool permiteAplicacaoAutomaticaAlta,
    required ConfiguracaoCuradoria configuracao,
  }) {
    final decodificado = detectarCodificacao(bytes);
    final extraida = _extrairMetadados(decodificado.texto, _base(origem.path));
    final analise = _aplicarOverride(extraida, override);
    var tomEfetivo = analise.tom;
    var origemTom = extraida.tom != null
        ? 'declarado'
        : (override?.tom != null ? 'override' : 'ausente');
    ResultadoDeteccaoTom? deteccaoTom;
    ResultadoPoliticaRelativoMaior? avaliacaoPoliticaRelativoMaior;
    ResultadoPoliticaMelhorTom? avaliacaoPoliticaMelhorTom;
    var confiancaTom = ConfiancaDeteccaoTom.baixa;
    if (tomEfetivo == null) {
      deteccaoTom = _detectorTonal.detectar(analise.corpo);
      confiancaTom = deteccaoTom.confianca;
      avaliacaoPoliticaMelhorTom = PoliticaMelhorTom(
        configuracao.politicaMelhorTom,
      ).avaliar(deteccaoTom);
      if (avaliacaoPoliticaMelhorTom.aplicada) {
        tomEfetivo = avaliacaoPoliticaMelhorTom.candidatoEscolhido!.tom;
        origemTom = 'politica_melhor_tom';
      } else {
        if (confiancaTom == ConfiancaDeteccaoTom.alta &&
            !permiteAplicacaoAutomaticaAlta) {
          confiancaTom = ConfiancaDeteccaoTom.media;
        }
        if (deteccaoTom.tomDetectado != null &&
            confiancaTom == ConfiancaDeteccaoTom.alta) {
          tomEfetivo = deteccaoTom.tomDetectado;
          origemTom = 'inferido';
        } else {
          if (override == null) {
            avaliacaoPoliticaRelativoMaior = PoliticaRelativoMaior(
              configuracao.politicaRelativoMaior,
            ).avaliar(deteccaoTom);
          }
          if (avaliacaoPoliticaRelativoMaior?.aplicada == true) {
            tomEfetivo = avaliacaoPoliticaRelativoMaior!.tomMaior;
            origemTom = 'politica_relativo_maior';
          } else if (deteccaoTom.tomDetectado != null &&
              confiancaTom == ConfiancaDeteccaoTom.media) {
            tomEfetivo = deteccaoTom.tomDetectado;
            origemTom = 'inferido';
          }
        }
      }
    }
    final observacoes = <String>[
      ...decodificado.observacoes,
      ...analise.observacoes,
    ];
    final motivosRevisao = <String>[];
    if (origemTom == 'politica_relativo_maior') {
      observacoes.add(
        'Tom maior selecionado por política editorial entre relativos; '
        'não representa inferência musical de confiança alta.',
      );
    }
    if (origemTom == 'politica_melhor_tom') {
      observacoes.add(
        'Primeiro candidato do detector aceito por política editorial '
        'para pendência exclusivamente tonal.',
      );
    }
    final idMusica =
        override?.idMusicaCompartilhado ??
        _idEstavel(anterior ?? identidadePendente, 'idMusica');
    final idVersao = _idEstavel(
      anterior ?? identidadePendente,
      'idVersaoMusica',
      diferenteDe: idMusica,
    );
    var status = StatusCuradoria.pronto;

    if (origemTom == 'inferido' && confiancaTom == ConfiancaDeteccaoTom.media) {
      final motivo =
          'Tom sugerido por inferência com confiança média; exige revisão humana.';
      observacoes.add(motivo);
      motivosRevisao.add(motivo);
      status = StatusCuradoria.revisar;
    }

    if (analise.titulo == null ||
        analise.artista == null ||
        tomEfetivo == null) {
      status = StatusCuradoria.bloqueado;
      if (analise.titulo == null) {
        const motivo = 'Título não identificado.';
        observacoes.add(motivo);
        motivosRevisao.add(motivo);
      }
      if (analise.artista == null) {
        const motivo = 'Artista não identificado.';
        observacoes.add(motivo);
        motivosRevisao.add(motivo);
      }
      if (tomEfetivo == null) {
        final motivo = deteccaoTom?.possivelModulacao == true
            ? 'Tom não atribuído: possível modulação ou centros tonais concorrentes.'
            : 'Tom não identificado com confiança suficiente.';
        observacoes.add(motivo);
        motivosRevisao.add(motivo);
      }
    }

    String? cho;
    ComparacaoSemantica? comparacao;
    ResultadoConversaoCuradoria? resultadoConversao;
    if (status != StatusCuradoria.bloqueado) {
      final conversao = _conversor.converter(analise.corpo);
      resultadoConversao = conversao;
      motivosRevisao.addAll(conversao.motivosRevisao);
      cho = _montarChordPro(
        idMusica: idMusica,
        idVersao: idVersao,
        titulo: analise.titulo!,
        artista: analise.artista!,
        tom: tomEfetivo!,
        nomeVersao:
            override?.nomeVersao ??
            (anterior?['nomeVersao'] as String? ?? 'Original'),
        principal:
            override?.principal ?? (anterior?['principal'] as bool? ?? true),
        corpo: conversao.chordPro,
      );
      comparacao = compararSemantica(analise.corpo, conversao.chordPro);
      if (!comparacao.equivalente) {
        final motivo =
            'Comparação semântica encontrou divergência: ${comparacao.resumo}.';
        observacoes.add(motivo);
        motivosRevisao.add(motivo);
        status = StatusCuradoria.revisar;
      }
      final problemasChordPro = _problemasChordPro(conversao.chordPro);
      observacoes.addAll(problemasChordPro);
      motivosRevisao.addAll(problemasChordPro);
      if (analise.ambiguo) {
        motivosRevisao.add('Metadados de título/artista permanecem ambíguos.');
      }
      if (motivosRevisao.isNotEmpty) {
        status = StatusCuradoria.revisar;
      }
      final validacao = _validador.executar(
        ArquivoSincronizacaoCandidato(
          localizador: relativo,
          nomeLegivel: '${_base(origem.path)}.cho',
          bytes: utf8.encode(cho),
        ),
      );
      if (validacao is ArquivoSincronizacaoInvalido ||
          !_uuidValido.hasMatch(idMusica) ||
          !_uuidValido.hasMatch(idVersao) ||
          idMusica == idVersao) {
        status = StatusCuradoria.bloqueado;
        const motivo = 'Arquivo gerado não passou pelo contrato schema 2.';
        observacoes.add(motivo);
        motivosRevisao.add(motivo);
        cho = null;
      }
    }

    final nomeCho = '${_base(origem.path)}.cho';
    final conflito = _detectarConflito(
      opcoes.biblioteca,
      relativo,
      nomeCho,
      anterior,
      entradas,
      identidadePendente: identidadePendente,
      hashChoGerado: cho == null
          ? null
          : sha256.convert(utf8.encode(cho)).toString(),
    );
    if (conflito != null) {
      status = StatusCuradoria.bloqueado;
      observacoes.add(conflito);
      motivosRevisao.add(conflito);
      cho = null;
    }
    final destinoRelativo = cho == null
        ? null
        : '${_pastaDeSaida(status)}/$nomeCho';
    final destinoAbsoluto = destinoRelativo == null
        ? null
        : _juntar(opcoes.biblioteca.path, destinoRelativo);

    return {
      'lote': opcoes.lote,
      'origem': relativo,
      'nomeOrigem': _nome(origem.path),
      'nomeDestino': nomeCho,
      'destino': destinoRelativo,
      'idMusica': idMusica,
      'idVersaoMusica': idVersao,
      'titulo': analise.titulo,
      'artista': analise.artista,
      'tom': tomEfetivo,
      'tomDetectado': deteccaoTom?.tomDetectado,
      'origemTom': origemTom,
      'confiancaTom': origemTom == 'inferido' || deteccaoTom != null
          ? confiancaTom.name
          : null,
      'evidenciasTom': deteccaoTom?.evidencias ?? const <String>[],
      'segundoCandidatoTom': deteccaoTom?.segundoCandidato?.toJson(),
      'diferencaPontuacaoTom': deteccaoTom == null
          ? null
          : double.parse(deteccaoTom.diferencaPontuacao.toStringAsFixed(2)),
      'possivelModulacao': deteccaoTom?.possivelModulacao ?? false,
      if (configuracao.politicaMelhorTom.habilitada &&
          avaliacaoPoliticaMelhorTom != null)
        'politicaMelhorTom': avaliacaoPoliticaMelhorTom.toJson(deteccaoTom!),
      if (avaliacaoPoliticaRelativoMaior?.aplicada == true)
        'politicaRelativoMaior': avaliacaoPoliticaRelativoMaior!.toJson(
          deteccao: deteccaoTom!,
          configuracao: configuracao.politicaRelativoMaior,
        ),
      if (configuracao.politicaRelativoMaior.habilitada &&
          avaliacaoPoliticaRelativoMaior != null)
        'avaliacaoPoliticaRelativoMaior': avaliacaoPoliticaRelativoMaior.toJson(
          deteccao: deteccaoTom!,
          configuracao: configuracao.politicaRelativoMaior,
        ),
      if (configuracao.politicaRelativoMaior.habilitada ||
          configuracao.politicaMelhorTom.habilitada)
        'configuracaoCuradoria': {
          'origem': configuracao.origem,
          if (configuracao.politicaRelativoMaior.habilitada) ...{
            'politicaRelativoMaiorHabilitada': true,
            'margemTerceiroCompetitivo':
                configuracao.politicaRelativoMaior.margemTerceiroCompetitivo,
            'minimoAcordes': configuracao.politicaRelativoMaior.minimoAcordes,
          },
          if (configuracao.politicaMelhorTom.habilitada)
            'politicaMelhorTomHabilitada': true,
        },
      'nomeVersao':
          override?.nomeVersao ??
          (anterior?['nomeVersao'] as String? ?? 'Original'),
      'principal':
          override?.principal ?? (anterior?['principal'] as bool? ?? true),
      'overrideAplicado': override != null,
      'decisaoDuplicidade': override?.decisaoDuplicidade,
      'aprovacaoHumana': override?.aprovado,
      'status': status.name,
      'codificacaoOrigem': decodificado.codificacao,
      'hashOrigem': hash,
      'hashChoGerado': cho == null
          ? null
          : sha256.convert(utf8.encode(cho)).toString(),
      'comparacaoSemantica': comparacao?.toJson(),
      'decisoesLinhas': resultadoConversao?.decisoes
          .map((d) => d.toJson())
          .toList(),
      'paresPreservadosEmLinhaSeparada':
          resultadoConversao?.paresPreservadosEmLinhaSeparada,
      'conflitoNome': conflito != null,
      'motivosRevisao': motivosRevisao,
      'observacoes': observacoes,
      'processadoEm': DateTime.now().toUtc().toIso8601String(),
      '_conteudoCho': cho,
      '_destinoAbsoluto': destinoAbsoluto,
    };
  }

  Map<String, Object?> _entradaFalha(
    String lote,
    String relativo,
    File origem,
    String hash,
    Map<String, Object?>? anterior,
    String motivo,
    StackTrace pilha,
  ) {
    final idMusica = _idEstavel(anterior, 'idMusica');
    final idVersao = _idEstavel(
      anterior,
      'idVersaoMusica',
      diferenteDe: idMusica,
    );
    return {
      'lote': lote,
      'origem': relativo,
      'nomeOrigem': _nome(origem.path),
      'nomeDestino': '${_base(origem.path)}.cho',
      'destino': null,
      'idMusica': idMusica,
      'idVersaoMusica': idVersao,
      'status': StatusCuradoria.bloqueado.name,
      'hashOrigem': hash,
      'conflitoNome': false,
      'motivosRevisao': [motivo],
      'observacoes': [motivo, pilha.toString().split('\n').first],
      'processadoEm': DateTime.now().toUtc().toIso8601String(),
    };
  }

  AnaliseMetadados _extrairMetadados(String texto, String nomeBase) {
    final linhas = texto.split(RegExp(r'\r\n|\n|\r'));
    final observacoes = <String>[];
    String? tom;
    int? indiceTom;
    for (var i = 0; i < linhas.length; i++) {
      final match = _tom.firstMatch(linhas[i]);
      if (match != null) {
        if (tom != null) {
          observacoes.add('Mais de uma declaração de tom encontrada.');
          tom = null;
          indiceTom = null;
          break;
        }
        tom = _normalizarTom(match.group(1)!);
        indiceTom = i;
      }
    }

    final candidatos = <int>[];
    for (var i = 0; i < linhas.length; i++) {
      if (i == indiceTom ||
          linhas[i].trim().isEmpty ||
          _cabecalhoCifra.hasMatch(linhas[i])) {
        continue;
      }
      if (indiceTom != null && i > indiceTom) break;
      candidatos.add(i);
    }
    String? titulo;
    String? artista;
    const ambiguo = false;
    final remover = <int>{?indiceTom};
    if (candidatos.isNotEmpty) {
      final primeira = linhas[candidatos.first].trim();
      final separador = primeira.lastIndexOf(' - ');
      if (separador > 0 && separador < primeira.length - 3) {
        final esquerda = primeira.substring(0, separador).trim();
        final direita = primeira.substring(separador + 3).trim();
        final nomeNormalizado = _normalizar(nomeBase);
        final esquerdaNoNome = nomeNormalizado.contains(_normalizar(esquerda));
        final direitaNoNome = nomeNormalizado.contains(_normalizar(direita));
        if (direitaNoNome && !esquerdaNoNome) {
          titulo = direita;
          artista = esquerda;
        } else {
          titulo = esquerda;
          artista = direita;
        }
        remover.add(candidatos.first);
      } else {
        titulo = primeira;
        remover.add(candidatos.first);
        if (candidatos.length > 1) {
          final segunda = linhas[candidatos[1]].trim();
          if (!_pareceConteudoMusical(segunda)) {
            artista = segunda;
            remover.add(candidatos[1]);
          }
        }
      }
    }
    if (artista == null && titulo != null) {
      final separadorNome = nomeBase.lastIndexOf(' - ');
      if (separadorNome > 0 && separadorNome < nomeBase.length - 3) {
        final tituloNoNome = nomeBase.substring(0, separadorNome).trim();
        final artistaNoNome = nomeBase.substring(separadorNome + 3).trim();
        if (_normalizar(titulo).contains(_normalizar(tituloNoNome)) &&
            artistaNoNome.isNotEmpty) {
          artista = artistaNoNome;
          observacoes.add('Artista identificado pelo nome do arquivo.');
        }
      }
    }
    for (var i = 0; i < linhas.length; i++) {
      if (_cabecalhoCifra.hasMatch(linhas[i])) remover.add(i);
    }
    final corpo = <String>[
      for (var i = 0; i < linhas.length; i++)
        if (!remover.contains(i)) linhas[i],
    ].join('\n').trim();
    return AnaliseMetadados(
      titulo: _naoVazio(titulo),
      artista: _naoVazio(artista),
      tom: _naoVazio(tom),
      corpo: corpo,
      ambiguo: ambiguo,
      observacoes: observacoes,
    );
  }

  bool _pareceConteudoMusical(String linha) =>
      linha.startsWith('[') ||
      linha.startsWith('{') ||
      _classificador.ehLinhaDeAcordes(linha) ||
      _classificador.ehRotuloDeSecao(linha);

  String _montarChordPro({
    required String idMusica,
    required String idVersao,
    required String titulo,
    required String artista,
    required String tom,
    required String nomeVersao,
    required bool principal,
    required String corpo,
  }) =>
      '{appcifras_schema:2}\n'
      '{appcifras_id:$idMusica}\n'
      '{appcifras_version_id:$idVersao}\n'
      '{appcifras_version_name:$nomeVersao}\n'
      '{appcifras_primary:$principal}\n\n'
      '{title:$titulo}\n'
      '{artist:$artista}\n'
      '{key:$tom}\n\n'
      '$corpo\n';

  AnaliseMetadados _aplicarOverride(
    AnaliseMetadados analise,
    OverrideCuradoriaArquivo? override,
  ) {
    if (override == null) return analise;
    return AnaliseMetadados(
      titulo: override.titulo ?? analise.titulo,
      artista: override.artista ?? analise.artista,
      tom: analise.tom ?? override.tom,
      corpo: analise.corpo,
      ambiguo: false,
      observacoes: [
        ...analise.observacoes,
        if (override.observacao != null)
          'Override humano: ${override.observacao}',
        if (override.aprovado == true) 'Arquivo aprovado por revisão humana.',
      ],
    );
  }

  ComparacaoSemantica compararSemantica(String origem, String convertido) {
    final projecaoOrigem = _projetarSemantica(origem);
    final projecaoDestino = _projetarSemantica(convertido);
    final origemTexto = projecaoOrigem.texto;
    final destinoTexto = projecaoDestino.texto;
    final acordesOrigem = projecaoOrigem.acordes;
    final acordesDestino = projecaoDestino.acordes;
    return ComparacaoSemantica(
      textoPreservado: _listasIguais(origemTexto, destinoTexto),
      acordesPreservados: _listasIguais(acordesOrigem, acordesDestino),
      linhasTextoOrigem: origemTexto.length,
      linhasTextoDestino: destinoTexto.length,
      acordesOrigem: acordesOrigem.length,
      acordesDestino: acordesDestino.length,
      secoesPreservadas: _listasIguais(
        projecaoOrigem.secoes,
        projecaoDestino.secoes,
      ),
      repeticoesPreservadas: _listasIguais(
        projecaoOrigem.repeticoes,
        projecaoDestino.repeticoes,
      ),
      observacoesPreservadas: _listasIguais(
        projecaoOrigem.observacoes,
        projecaoDestino.observacoes,
      ),
      tablaturasPreservadas: _listasIguais(
        projecaoOrigem.tablaturas,
        projecaoDestino.tablaturas,
      ),
      associacoesPreservadas: _listasIguais(
        projecaoOrigem.associacoes,
        projecaoDestino.associacoes,
      ),
    );
  }

  _ProjecaoSemantica _projetarSemantica(String texto) {
    final unidadesTexto = <String>[];
    final acordes = <String>[];
    final secoes = <String>[];
    final repeticoes = <String>[];
    final observacoes = <String>[];
    final tablaturas = <String>[];
    final associacoes = <String>[];
    final linhas = texto.split(RegExp(r'\r\n|\n|\r'));
    var secaoInstrumentalNaLinhaAnterior = false;
    for (var indice = 0; indice < linhas.length; indice++) {
      final suprimirAssociacao = secaoInstrumentalNaLinhaAnterior;
      secaoInstrumentalNaLinhaAnterior = false;
      var linha = linhas[indice];
      final comment = RegExp(r'^\{comment:\s*(.*)\}$').firstMatch(linha.trim());
      if (comment != null) linha = comment.group(1)!;

      if (RegExp(r'^[EADGBe]\|').hasMatch(linha.trim())) {
        tablaturas.add(linha.trim());
        continue;
      }

      final rotulo = _separarRotuloSemantico(linha);
      if (rotulo != null) {
        secoes.add(_normalizar(rotulo.nome));
        linha = rotulo.restante;
        if (linha.trim().isEmpty && _ehSecaoInstrumental(rotulo.nome)) {
          secaoInstrumentalNaLinhaAnterior = true;
        }
      }

      final linhaAcordes = _acordesDaLinhaExclusiva(linha);
      if (linhaAcordes != null) {
        acordes.addAll(linhaAcordes);
        if (rotulo == null &&
            !suprimirAssociacao &&
            indice + 1 < linhas.length &&
            _linhaDeLetraAssociavel(linhas[indice + 1])) {
          associacoes.add(
            '${linhaAcordes.join('|')}=>${_normalizarEspacos(linhas[indice + 1])}',
          );
        }
        continue;
      }

      final instrumentalAnotado = _interpretarInstrumentalComMarcadores(linha);
      if (instrumentalAnotado != null) {
        acordes.addAll(instrumentalAnotado.acordes);
        for (final marcador in instrumentalAnotado.marcadores) {
          final limpo = marcador.replaceAll(RegExp(r'^[(),]+|[(),]+$'), '');
          if (limpo.isEmpty) {
            unidadesTexto.add(marcador);
          } else if (_ehRepeticao(limpo)) {
            repeticoes.add(limpo.toLowerCase());
          } else {
            unidadesTexto.add(marcador);
          }
        }
        continue;
      }

      final acordesEmColchetes = <String>[];
      linha = linha.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (match) {
        final valor = match.group(1)!;
        if (_parserAcorde.interpretar(valor) is AcordeInterpretado) {
          acordesEmColchetes.add(valor);
          return '';
        }
        return match.group(0)!;
      });
      acordes.addAll(acordesEmColchetes);

      if (rotulo != null) {
        final instrumental = _interpretarInstrumentalComMarcadores(linha);
        if (instrumental != null) {
          acordes.addAll(instrumental.acordes);
          unidadesTexto.addAll(instrumental.marcadores);
          continue;
        }
      }

      final normalizada = _normalizarEspacos(linha);
      if (normalizada.isEmpty) continue;
      if (acordesEmColchetes.isNotEmpty &&
          rotulo == null &&
          _ehLetraSemantica(normalizada)) {
        associacoes.add('${acordesEmColchetes.join('|')}=>$normalizada');
      }
      if (_pareceObservacao(normalizada)) {
        observacoes.add(normalizada);
        continue;
      }
      final tokens = normalizada.split(' ');
      for (final token in tokens) {
        if (_ehRepeticao(token)) {
          repeticoes.add(token.toLowerCase());
        } else {
          unidadesTexto.add(token);
        }
      }
    }
    return _ProjecaoSemantica(
      texto: unidadesTexto,
      acordes: acordes,
      secoes: secoes,
      repeticoes: repeticoes,
      observacoes: observacoes,
      tablaturas: tablaturas,
      associacoes: associacoes,
    );
  }

  List<String>? _acordesDaLinhaExclusiva(String linha) {
    if (_classificador.ehLinhaDeAcordes(linha)) {
      return linha.trim().split(RegExp(r'\s+'));
    }
    final matches = RegExp(r'\[([^\]]+)\]').allMatches(linha).toList();
    if (matches.isEmpty ||
        linha.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim().isNotEmpty) {
      return null;
    }
    final valores = matches.map((m) => m.group(1)!).toList();
    return valores.every(
          (valor) => _parserAcorde.interpretar(valor) is AcordeInterpretado,
        )
        ? valores
        : null;
  }

  bool _linhaDeLetraAssociavel(String linha) =>
      linha.trim().isNotEmpty &&
      _separarRotuloSemantico(linha) == null &&
      _acordesDaLinhaExclusiva(linha) == null &&
      !linha.trim().startsWith('{') &&
      !RegExp(r'^[EADGBe]\|').hasMatch(linha.trim()) &&
      _ehLetraSemantica(_normalizarEspacos(linha));

  bool _ehLetraSemantica(String linha) =>
      RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(linha) &&
      !_pareceObservacao(linha) &&
      !linha.split(' ').every((token) {
        final limpo = token.replaceAll(RegExp(r'^[(),]+|[(),]+$'), '');
        return limpo.isEmpty || _ehRepeticao(limpo);
      });

  bool _pareceObservacao(String linha) =>
      linha.startsWith('(') ||
      linha.startsWith('*') ||
      RegExp(
        r'^(?:obs|observa[cç][aã]o)\s*:',
        caseSensitive: false,
      ).hasMatch(linha);

  bool _ehSecaoInstrumental(String nome) => RegExp(
    r'^(?:intro|introdu[cç][aã]o|solo|instrumental|passagem|interl[uú]dio)$',
    caseSensitive: false,
  ).hasMatch(nome.trim());

  bool _ehRepeticao(String token) =>
      RegExp(r'^(?:x\d+|\d+x)$', caseSensitive: false).hasMatch(token) ||
      RegExp(
        r'^(?:repete|repetir|volta)$',
        caseSensitive: false,
      ).hasMatch(token);

  String _normalizarEspacos(String linha) =>
      linha.trim().replaceAll(RegExp(r'\s+'), ' ');

  _RotuloSemantico? _separarRotuloSemantico(String linha) {
    final entreColchetes = RegExp(r'^\s*\[([^\]]+)\](.*)$').firstMatch(linha);
    if (entreColchetes != null) {
      final nome = entreColchetes.group(1)!.trim();
      if (_classificador.ehNomeDeSecao(nome)) {
        return _RotuloSemantico(nome, entreColchetes.group(2) ?? '');
      }
    }
    final comDoisPontos = RegExp(r'^\s*([^:]+):\s*(.*)$').firstMatch(linha);
    if (comDoisPontos != null) {
      final nome = comDoisPontos.group(1)!.trim();
      if (_classificador.ehNomeDeSecao(nome)) {
        return _RotuloSemantico(nome, comDoisPontos.group(2) ?? '');
      }
    }
    if (_classificador.ehRotuloDeSecao(linha)) {
      return _RotuloSemantico(linha.trim().replaceFirst(RegExp(r':$'), ''), '');
    }
    return null;
  }

  _InstrumentalComMarcadores? _interpretarInstrumentalComMarcadores(
    String linha,
  ) {
    final acordes = <String>[];
    final marcadores = <String>[];
    for (final tokenOriginal in linha.trim().split(RegExp(r'\s+'))) {
      if (tokenOriginal.isEmpty) continue;
      var token = _removerMarcadoresDeGrupo(tokenOriginal);
      if (token.startsWith('[') && token.endsWith(']')) {
        token = token.substring(1, token.length - 1);
      }
      if (token.isEmpty) {
        marcadores.add(tokenOriginal);
      } else if (_parserAcorde.interpretar(token) is AcordeInterpretado) {
        acordes.add(token);
      } else if (RegExp(
        r'^(?:x\d+|\d+x)$',
        caseSensitive: false,
      ).hasMatch(token)) {
        marcadores.add(token.toLowerCase());
      } else {
        return null;
      }
    }
    if (acordes.isEmpty) return null;
    return _InstrumentalComMarcadores(acordes, marcadores);
  }

  String _removerMarcadoresDeGrupo(String original) {
    var token = original.replaceAll(RegExp(r'^,+|,+$'), '');
    if (token == '(' || token == ')') return '';
    if (token.startsWith('(')) token = token.substring(1);
    final abre = '('.allMatches(token).length;
    final fecha = ')'.allMatches(token).length;
    if (token.endsWith(')') && fecha > abre) {
      token = token.substring(0, token.length - 1);
    }
    return token;
  }

  List<String> _problemasChordPro(String corpo) {
    final problemas = <String>[];
    final linhas = corpo.split(RegExp(r'\r\n|\n|\r'));
    for (var indice = 0; indice < linhas.length; indice++) {
      final linha = linhas[indice];
      if ('['.allMatches(linha).length != ']'.allMatches(linha).length) {
        problemas.add('Colchetes desbalanceados na linha ${indice + 1}.');
        continue;
      }
      for (final match in RegExp(r'\[([^\]]+)\]').allMatches(linha)) {
        final valor = match.group(1)!.trim();
        if (_parserAcorde.interpretar(valor) is AcordeNaoInterpretavel &&
            !_pareceRotuloDescritivo(valor)) {
          problemas.add(
            'Acorde ou símbolo não interpretável "$valor" na linha ${indice + 1}.',
          );
        }
      }
    }
    return problemas;
  }

  bool _pareceRotuloDescritivo(String valor) =>
      _classificador.ehNomeDeSecao(valor) ||
      RegExp(
        r'^(?:tab|solo|refr[aã]o|coro|parte|intro|introdu[cç][aã]o|verso|estrofe|ponte|final|instrumental)\b',
        caseSensitive: false,
      ).hasMatch(valor.trim());

  Future<void> _persistirCho({
    required Directory biblioteca,
    required Map<String, Object?>? entradaAnterior,
    required Map<String, Object?> entradaNova,
    required String? conteudo,
  }) async {
    final anteriorRelativo = entradaAnterior?['destino'] as String?;
    final novoRelativo = entradaNova['destino'] as String?;
    final arquivoAnterior = anteriorRelativo == null
        ? null
        : _arquivoDeDestinoValido(biblioteca, anteriorRelativo, entradaNova);
    final arquivoNovo = novoRelativo == null
        ? null
        : _arquivoDeDestinoValido(biblioteca, novoRelativo, entradaNova);
    final hashEsperado = entradaNova['hashChoGerado'] as String?;

    if (conteudo == null || arquivoNovo == null) {
      if (arquivoAnterior != null && await arquivoAnterior.exists()) {
        await _criarBackupRecuperavel(biblioteca, arquivoAnterior);
        await arquivoAnterior.delete();
      }
      return;
    }

    if (arquivoAnterior != null &&
        arquivoAnterior.path.toLowerCase() == arquivoNovo.path.toLowerCase()) {
      if (await arquivoAnterior.exists()) {
        final atual = sha256
            .convert(await arquivoAnterior.readAsBytes())
            .toString();
        if (atual == hashEsperado) return;
        await _criarBackupRecuperavel(biblioteca, arquivoAnterior);
      }
      await _salvarTextoAtomico(arquivoNovo, conteudo, criarBackup: false);
      return;
    }

    if (await arquivoNovo.exists()) {
      final atual = sha256.convert(await arquivoNovo.readAsBytes()).toString();
      if (atual != hashEsperado) {
        throw StateError(
          'Destino conflitante não será sobrescrito: ${arquivoNovo.path}',
        );
      }
      if (arquivoAnterior != null && await arquivoAnterior.exists()) {
        final hashAnterior = sha256
            .convert(await arquivoAnterior.readAsBytes())
            .toString();
        if (hashAnterior != hashEsperado) {
          throw StateError(
            'Retomada encontrou duas cópias diferentes: ${arquivoAnterior.path} e ${arquivoNovo.path}',
          );
        }
        await arquivoAnterior.delete();
      }
      return;
    }

    if (arquivoAnterior != null && await arquivoAnterior.exists()) {
      await _criarBackupRecuperavel(biblioteca, arquivoAnterior);
      await _salvarTextoAtomico(arquivoAnterior, conteudo, criarBackup: false);
      await arquivoNovo.parent.create(recursive: true);
      await arquivoAnterior.rename(arquivoNovo.path);
      return;
    }
    await _salvarTextoAtomico(arquivoNovo, conteudo, criarBackup: false);
  }

  File _arquivoDeDestinoValido(
    Directory biblioteca,
    String relativo,
    Map<String, Object?> entrada,
  ) {
    final partes = relativo.split('/');
    const pastasPermitidas = {'prontos', 'revisar', 'bloqueados'};
    if (partes.length != 2 ||
        !pastasPermitidas.contains(partes.first) ||
        partes.last != entrada['nomeDestino']) {
      throw StateError('Destino inválido no manifesto: $relativo');
    }
    return File(_juntar(_juntar(biblioteca.path, partes.first), partes.last));
  }

  Future<void> _criarBackupRecuperavel(
    Directory biblioteca,
    File arquivo,
  ) async {
    final instante = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final pasta = Directory(
      _juntar(_juntar(biblioteca.path, '.curadoria-backups'), instante),
    );
    await pasta.create(recursive: true);
    var destino = File(_juntar(pasta.path, _nome(arquivo.path)));
    var sufixo = 2;
    while (await destino.exists()) {
      destino = File(_juntar(pasta.path, '${_base(arquivo.path)}-$sufixo.cho'));
      sufixo++;
    }
    await arquivo.copy(destino.path);
  }

  String? _detectarConflito(
    Directory biblioteca,
    String origem,
    String nomeCho,
    Map<String, Object?>? anterior,
    List<Map<String, Object?>> entradas, {
    Map<String, Object?>? identidadePendente,
    String? hashChoGerado,
  }) {
    final outro = entradas.where(
      (e) => e['origem'] != origem && e['nomeDestino'] == nomeCho,
    );
    if (outro.isNotEmpty) {
      return 'Conflito de nome com ${outro.first['origem']}.';
    }
    for (final status in StatusCuradoria.values) {
      final arquivo = File(
        _juntar(_juntar(biblioteca.path, _pastaDeSaida(status)), nomeCho),
      );
      if (arquivo.existsSync() && anterior == null) {
        final relativoDestino = '${_pastaDeSaida(status)}/$nomeCho';
        final retomadaValida =
            identidadePendente?['destino'] == relativoDestino &&
            identidadePendente?['hashChoGerado'] == hashChoGerado &&
            sha256.convert(arquivo.readAsBytesSync()).toString() ==
                hashChoGerado;
        if (retomadaValida) continue;
        return 'Destino já existe sem vínculo com esta origem: ${arquivo.path}.';
      }
    }
    return null;
  }

  Future<_EdicaoManualDetectada?> _detectarEdicaoManual({
    required Directory biblioteca,
    required Map<String, Object?>? entradaAnterior,
  }) async {
    if (entradaAnterior == null) return null;
    final destino = entradaAnterior['destino'] as String?;
    final hashGerado = entradaAnterior['hashChoGerado'] as String?;
    if (destino == null) return null;
    final arquivo = _arquivoDeDestinoValido(
      biblioteca,
      destino,
      entradaAnterior,
    );
    if (!await arquivo.exists()) return null;
    final hashAtual = sha256.convert(await arquivo.readAsBytes()).toString();
    return hashGerado != null && hashAtual == hashGerado
        ? null
        : _EdicaoManualDetectada(hashAtual);
  }

  Map<String, Object?>? _identidadePendente(
    Map<String, Object?> checkpoint,
    String origem,
  ) {
    final pendente = checkpoint['pendente'];
    if (pendente is! Map || pendente['origem'] != origem) return null;
    return Map<String, Object?>.from(pendente);
  }

  Future<Map<String, Object?>> _lerCheckpoint(File arquivo) async {
    if (!await arquivo.exists()) return <String, Object?>{};
    try {
      final valor = jsonDecode(await arquivo.readAsString());
      if (valor is! Map) {
        throw const FormatException('Checkpoint não é objeto.');
      }
      return Map<String, Object?>.from(valor);
    } on Object {
      final backup = File('${arquivo.path}.bak');
      if (!await backup.exists()) rethrow;
      final valor = jsonDecode(await backup.readAsString());
      if (valor is! Map) {
        throw const FormatException('Backup do checkpoint inválido.');
      }
      return Map<String, Object?>.from(valor);
    }
  }

  void _validarManifesto(Map<String, Object?> manifesto) {
    if (manifesto['schema'] != 1 || manifesto['entradas'] is! List) {
      throw const FormatException('Manifesto inválido: schema ou entradas.');
    }
    final origens = <String>{};
    final idsVersao = <String>{};
    for (final bruto in manifesto['entradas'] as List) {
      if (bruto is! Map) {
        throw const FormatException(
          'Manifesto inválido: entrada não é objeto.',
        );
      }
      final entrada = Map<String, Object?>.from(bruto);
      final origem = entrada['origem'];
      final nomeDestino = entrada['nomeDestino'];
      final idMusica = entrada['idMusica'];
      final idVersao = entrada['idVersaoMusica'];
      final status = entrada['status'];
      if (origem is! String ||
          !origens.add(origem) ||
          nomeDestino is! String ||
          idMusica is! String ||
          !_uuidValido.hasMatch(idMusica) ||
          idVersao is! String ||
          !_uuidValido.hasMatch(idVersao) ||
          !idsVersao.add(idVersao) ||
          idMusica == idVersao ||
          !StatusCuradoria.values.map((e) => e.name).contains(status)) {
        throw FormatException('Manifesto inválido na entrada $origem.');
      }
      final destino = entrada['destino'];
      if (destino != null) {
        final partes = (destino as String).split('/');
        if (partes.length != 2 ||
            !const {
              'prontos',
              'revisar',
              'bloqueados',
            }.contains(partes.first) ||
            partes.last != nomeDestino) {
          throw FormatException('Destino inválido na entrada $origem.');
        }
      }
      for (final campo in ['hashOrigem', 'hashChoGerado']) {
        final hash = entrada[campo];
        if (hash != null &&
            (hash is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash))) {
          throw FormatException('$campo inválido na entrada $origem.');
        }
      }
    }
  }

  Future<Map<String, Object?>> _lerManifesto(File arquivo) async {
    if (!await arquivo.exists()) {
      return <String, Object?>{
        'schema': 1,
        'atualizadoEm': null,
        'entradas': <Map<String, Object?>>[],
      };
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(await arquivo.readAsString()) as Map<String, dynamic>;
    } on Object {
      final backup = File('${arquivo.path}.bak');
      if (!await backup.exists()) rethrow;
      json = jsonDecode(await backup.readAsString()) as Map<String, dynamic>;
    }
    final entradas = (json['entradas'] as List? ?? const [])
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
    return <String, Object?>{...json, 'entradas': entradas};
  }

  String _gerarRelatorio(
    List<Map<String, Object?>> entradas, {
    required String loteAtual,
    required int inalteradosNoLoteAtual,
  }) {
    final lotes = <String, List<Map<String, Object?>>>{};
    for (final entrada in entradas) {
      lotes.putIfAbsent(entrada['lote'] as String, () => []).add(entrada);
    }
    final buffer = StringBuffer('# Relatório consolidado da curadoria\n\n');
    for (final nomeLote in lotes.keys.toList()..sort()) {
      final itens = lotes[nomeLote]!;
      final comparados = itens
          .where((e) => e['comparacaoSemantica'] is Map)
          .toList();
      final equivalentes = comparados.where((e) {
        final comparacao = e['comparacaoSemantica'] as Map;
        return comparacao['equivalente'] == true;
      }).length;
      final duplicidades = _possiveisDuplicidades(itens);
      buffer
        ..writeln('## $nomeLote')
        ..writeln()
        ..writeln('- TXT encontrados/registrados: ${itens.length}')
        ..writeln(
          '- Convertidos em CHO: ${itens.where((e) => e['destino'] != null).length}',
        )
        ..writeln('- Prontos: ${_contar(itens, StatusCuradoria.pronto)}')
        ..writeln('- Revisar: ${_contar(itens, StatusCuradoria.revisar)}')
        ..writeln('- Bloqueados: ${_contar(itens, StatusCuradoria.bloqueado)}')
        ..writeln('- Comparação semântica equivalente: $equivalentes')
        ..writeln(
          '- Comparação semântica divergente: ${comparados.length - equivalentes}',
        )
        ..writeln(
          '- Comparação não aplicável: ${itens.length - comparados.length}',
        )
        ..writeln(
          '- Conflitos de nome: ${itens.where((e) => e['conflitoNome'] == true).length}',
        )
        ..writeln(
          '- Conflitos por edição manual de CHO: ${itens.where((e) => e['conflitoChoEditado'] == true).length}',
        )
        ..writeln(
          '- Pares preservados em linhas separadas: ${itens.fold<int>(0, (soma, e) => soma + ((e['paresPreservadosEmLinhaSeparada'] as int?) ?? 0))}',
        );
      if (nomeLote == loteAtual) {
        buffer.writeln(
          '- Já processados e inalterados na última execução: $inalteradosNoLoteAtual',
        );
      }
      buffer.writeln(
        '- Possíveis duplicidades ou múltiplas versões: ${duplicidades.length}',
      );
      if (duplicidades.isNotEmpty) {
        for (final grupo in duplicidades) {
          buffer.writeln('  - ${grupo.join(', ')}');
        }
      }
      buffer.writeln();
      buffer.writeln('### Decisões individuais');
      buffer.writeln();
      for (final item in itens) {
        buffer.writeln('#### ${item['nomeOrigem']} — ${item['status']}');
        if (item['origemTom'] != null) {
          buffer.writeln(
            '- Tom: ${item['tom'] ?? item['tomDetectado'] ?? 'não atribuído'} '
            '(origem: ${item['origemTom']}, confiança: ${item['confiancaTom'] ?? 'não aplicável'}).',
          );
        }
        if (item['segundoCandidatoTom'] is Map) {
          final segundo = item['segundoCandidatoTom'] as Map;
          buffer.writeln(
            '- Segundo candidato tonal: ${segundo['tom']} '
            '(diferença: ${item['diferencaPontuacaoTom']}).',
          );
        }
        if (item['politicaRelativoMaior'] is Map) {
          final politica = item['politicaRelativoMaior'] as Map;
          buffer.writeln(
            '- Política editorial relativo maior: '
            '${politica['tomMaiorEscolhido']} escolhido; '
            '${politica['relativoMenorDescartado']} descartado; '
            'pontuações ${politica['pontuacaoMaior']} e '
            '${politica['pontuacaoMenor']}; diferença '
            '${politica['diferencaPontuacaoMaiorMenor']}; '
            '${politica['quantidadeAcordes']} acordes; '
            'modulação ausente; terceiro candidato não competitivo '
            '(margem ${politica['margemTerceiroCompetitivo']}).',
          );
        }
        for (final evidencia in (item['evidenciasTom'] as List? ?? const [])) {
          buffer.writeln('- Evidência tonal: $evidencia');
        }
        final motivos = (item['motivosRevisao'] as List? ?? const [])
            .cast<Object?>();
        if (motivos.isEmpty) {
          buffer.writeln(
            '- Motivo editorial: nenhum; arquivo apto como pronto.',
          );
        } else {
          for (final motivo in motivos) {
            buffer.writeln('- Motivo editorial: $motivo');
          }
        }
        final observacoes = (item['observacoes'] as List? ?? const [])
            .cast<Object?>();
        for (final observacao in observacoes) {
          if (!motivos.contains(observacao)) {
            buffer.writeln('- Observação técnica: $observacao');
          }
        }
        final decisoes = (item['decisoesLinhas'] as List? ?? const []);
        for (final decisaoBruta in decisoes) {
          final decisao = decisaoBruta as Map;
          final associada = decisao['linhaLetraAssociada'] == null
              ? ''
              : ', letra ${decisao['linhaLetraAssociada']}';
          buffer.writeln(
            '- Linha ${decisao['linhaOrigem']}$associada: '
            '${decisao['estrategia']} — ${decisao['descricao']}',
          );
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  List<List<String>> _possiveisDuplicidades(List<Map<String, Object?>> itens) {
    final grupos = <String, List<String>>{};
    for (final item in itens) {
      final titulo = item['titulo'] as String?;
      final artista = item['artista'] as String?;
      if (titulo == null || artista == null) continue;
      final chave = '${_normalizar(titulo)}|${_normalizar(artista)}';
      grupos.putIfAbsent(chave, () => []).add(item['nomeOrigem'] as String);
    }
    return grupos.values.where((grupo) => grupo.length > 1).toList();
  }

  Future<void> _salvarJsonAtomico(File arquivo, Object valor) =>
      _salvarTextoAtomico(
        arquivo,
        '${const JsonEncoder.withIndent('  ').convert(valor)}\n',
      );

  Future<void> _salvarTextoAtomico(
    File arquivo,
    String conteudo, {
    bool criarBackup = true,
  }) async {
    await arquivo.parent.create(recursive: true);
    final temporario = File('${arquivo.path}.tmp');
    await temporario.writeAsString(conteudo, encoding: utf8, flush: true);
    if (criarBackup && await arquivo.exists()) {
      final backup = File('${arquivo.path}.bak');
      final backupTemporario = File('${backup.path}.tmp');
      await arquivo.copy(backupTemporario.path);
      if (await backup.exists()) await backup.delete();
      await backupTemporario.rename(backup.path);
    }
    if (await arquivo.exists()) await arquivo.delete();
    await temporario.rename(arquivo.path);
  }

  String _idEstavel(
    Map<String, Object?>? anterior,
    String campo, {
    String? diferenteDe,
  }) {
    final existente = anterior?[campo] as String?;
    if (existente != null &&
        _uuidValido.hasMatch(existente) &&
        existente != diferenteDe) {
      return existente;
    }
    var novo = _uuid.v4();
    while (novo == diferenteDe) {
      novo = _uuid.v4();
    }
    return novo;
  }

  Map<String, Object?>? _entradaPorOrigem(
    List<Map<String, Object?>> entradas,
    String origem,
  ) {
    for (final entrada in entradas) {
      if (entrada['origem'] == origem) return entrada;
    }
    return null;
  }

  int _contar(List<Map<String, Object?>> itens, StatusCuradoria status) =>
      itens.where((e) => e['status'] == status.name).length;

  String _pastaDeSaida(StatusCuradoria status) => switch (status) {
    StatusCuradoria.pronto => 'prontos',
    StatusCuradoria.revisar => 'revisar',
    StatusCuradoria.bloqueado => 'bloqueados',
  };

  String _normalizarTom(String tom) =>
      '${tom[0].toUpperCase()}${tom.substring(1)}';
  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  String? _naoVazio(String? valor) =>
      valor == null || valor.trim().isEmpty ? null : valor.trim();
  bool _listasIguais(List<String> a, List<String> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((e) => e);
  String _nome(String caminho) => caminho.split(RegExp(r'[\\/]')).last;
  String _base(String caminho) {
    final nome = _nome(caminho);
    final ponto = nome.lastIndexOf('.');
    return ponto < 0 ? nome : nome.substring(0, ponto);
  }

  String _juntar(String a, String b) =>
      '${a.replaceAll(RegExp(r'[\\/]+$'), '')}${Platform.pathSeparator}$b';
  String _juntarRelativo(String raiz, String relativo) =>
      relativo.split('/').fold(raiz, (atual, parte) => _juntar(atual, parte));
}

class _ProjecaoSemantica {
  const _ProjecaoSemantica({
    required this.texto,
    required this.acordes,
    required this.secoes,
    required this.repeticoes,
    required this.observacoes,
    required this.tablaturas,
    required this.associacoes,
  });

  final List<String> texto;
  final List<String> acordes;
  final List<String> secoes;
  final List<String> repeticoes;
  final List<String> observacoes;
  final List<String> tablaturas;
  final List<String> associacoes;
}

class _RotuloSemantico {
  const _RotuloSemantico(this.nome, this.restante);

  final String nome;
  final String restante;
}

class _InstrumentalComMarcadores {
  const _InstrumentalComMarcadores(this.acordes, this.marcadores);

  final List<String> acordes;
  final List<String> marcadores;
}

class _EdicaoManualDetectada {
  const _EdicaoManualDetectada(this.hashAtual);

  final String hashAtual;
}

class AnaliseMetadados {
  const AnaliseMetadados({
    required this.titulo,
    required this.artista,
    required this.tom,
    required this.corpo,
    required this.ambiguo,
    required this.observacoes,
  });
  final String? titulo;
  final String? artista;
  final String? tom;
  final String corpo;
  final bool ambiguo;
  final List<String> observacoes;
}

class TextoDecodificado {
  const TextoDecodificado(
    this.texto,
    this.codificacao,
    this.requerRevisao,
    this.observacoes,
  );
  final String texto;
  final String codificacao;
  final bool requerRevisao;
  final List<String> observacoes;
}

TextoDecodificado detectarCodificacao(List<int> bytes) {
  final semBom =
      bytes.length >= 3 &&
          bytes[0] == 0xef &&
          bytes[1] == 0xbb &&
          bytes[2] == 0xbf
      ? bytes.sublist(3)
      : bytes;
  try {
    final texto = utf8.decode(semBom, allowMalformed: false);
    _validarControles(texto);
    return TextoDecodificado(
      texto,
      bytes.length == semBom.length ? 'utf-8' : 'utf-8-bom',
      false,
      const [],
    );
  } on FormatException {
    final texto = String.fromCharCodes(semBom.map(_windows1252));
    _validarControles(texto);
    return TextoDecodificado(texto, 'windows-1252', true, const [
      'Origem não é UTF-8; decodificada conservadoramente como Windows-1252.',
    ]);
  }
}

void _validarControles(String texto) {
  final possuiControles = texto.runes.any(
    (r) => r < 32 && r != 9 && r != 10 && r != 13,
  );
  if (possuiControles) {
    throw const FormatException(
      'Codificação não pôde ser determinada com segurança.',
    );
  }
}

int _windows1252(int byte) =>
    const <int, int>{
      0x80: 0x20ac,
      0x82: 0x201a,
      0x83: 0x0192,
      0x84: 0x201e,
      0x85: 0x2026,
      0x86: 0x2020,
      0x87: 0x2021,
      0x88: 0x02c6,
      0x89: 0x2030,
      0x8a: 0x0160,
      0x8b: 0x2039,
      0x8c: 0x0152,
      0x8e: 0x017d,
      0x91: 0x2018,
      0x92: 0x2019,
      0x93: 0x201c,
      0x94: 0x201d,
      0x95: 0x2022,
      0x96: 0x2013,
      0x97: 0x2014,
      0x98: 0x02dc,
      0x99: 0x2122,
      0x9a: 0x0161,
      0x9b: 0x203a,
      0x9c: 0x0153,
      0x9e: 0x017e,
      0x9f: 0x0178,
    }[byte] ??
    byte;

class ComparacaoSemantica {
  const ComparacaoSemantica({
    required this.textoPreservado,
    required this.acordesPreservados,
    required this.linhasTextoOrigem,
    required this.linhasTextoDestino,
    required this.acordesOrigem,
    required this.acordesDestino,
    required this.secoesPreservadas,
    required this.repeticoesPreservadas,
    required this.observacoesPreservadas,
    required this.tablaturasPreservadas,
    required this.associacoesPreservadas,
  });
  final bool textoPreservado;
  final bool acordesPreservados;
  final int linhasTextoOrigem;
  final int linhasTextoDestino;
  final int acordesOrigem;
  final int acordesDestino;
  final bool secoesPreservadas;
  final bool repeticoesPreservadas;
  final bool observacoesPreservadas;
  final bool tablaturasPreservadas;
  final bool associacoesPreservadas;
  bool get equivalente =>
      textoPreservado &&
      acordesPreservados &&
      secoesPreservadas &&
      repeticoesPreservadas &&
      observacoesPreservadas &&
      tablaturasPreservadas &&
      associacoesPreservadas;
  String get resumo {
    final divergencias = <String>[
      if (!textoPreservado) 'palavras $linhasTextoOrigem/$linhasTextoDestino',
      if (!acordesPreservados) 'acordes $acordesOrigem/$acordesDestino',
      if (!secoesPreservadas) 'ordem de seções',
      if (!repeticoesPreservadas) 'repetições',
      if (!observacoesPreservadas) 'observações',
      if (!tablaturasPreservadas) 'tablaturas',
      if (!associacoesPreservadas) 'associação entre acordes e letra',
    ];
    return divergencias.isEmpty ? 'equivalente' : divergencias.join(', ');
  }

  Map<String, Object> toJson() => {
    'equivalente': equivalente,
    'textoPreservado': textoPreservado,
    'acordesPreservados': acordesPreservados,
    'linhasTextoOrigem': linhasTextoOrigem,
    'linhasTextoDestino': linhasTextoDestino,
    'acordesOrigem': acordesOrigem,
    'acordesDestino': acordesDestino,
    'secoesPreservadas': secoesPreservadas,
    'repeticoesPreservadas': repeticoesPreservadas,
    'observacoesPreservadas': observacoesPreservadas,
    'tablaturasPreservadas': tablaturasPreservadas,
    'associacoesPreservadas': associacoesPreservadas,
  };
}
