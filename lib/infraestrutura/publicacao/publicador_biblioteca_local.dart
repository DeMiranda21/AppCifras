import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import '../../aplicacao/sincronizacao/modelos_sincronizacao.dart';
import '../../aplicacao/sincronizacao/montar_inventario_pasta_curada.dart';

class ResultadoPublicacaoBiblioteca {
  ResultadoPublicacaoBiblioteca({
    required this.sucesso,
    required this.geracao,
    required this.quantidadeMusicas,
    required this.quantidadeVersoes,
    required this.bytesTotais,
    required Iterable<String> erros,
    required Iterable<String> avisos,
    this.manifesto,
  }) : erros = List.unmodifiable(erros),
       avisos = List.unmodifiable(avisos);

  final bool sucesso;
  final String geracao;
  final int quantidadeMusicas;
  final int quantidadeVersoes;
  final int bytesTotais;
  final List<String> erros;
  final List<String> avisos;
  final ManifestoBibliotecaOficial? manifesto;

  String gerarRelatorio() {
    final buffer = StringBuffer()
      ..writeln('# Publicação da Biblioteca Oficial')
      ..writeln()
      ..writeln('- Resultado: ${sucesso ? 'SUCESSO' : 'FALHA'}')
      ..writeln('- Geração: $geracao')
      ..writeln('- Músicas: $quantidadeMusicas')
      ..writeln('- Versões: $quantidadeVersoes')
      ..writeln('- Arquivos: $quantidadeVersoes')
      ..writeln('- Bytes: $bytesTotais')
      ..writeln('- Erros: ${erros.length}')
      ..writeln('- Avisos: ${avisos.length}');
    if (erros.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Erros');
      for (final erro in erros) {
        buffer.writeln('- $erro');
      }
    }
    if (avisos.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Avisos');
      for (final aviso in avisos) {
        buffer.writeln('- $aviso');
      }
    }
    return buffer.toString();
  }
}

class PublicadorBibliotecaLocal {
  PublicadorBibliotecaLocal({
    MontarInventarioPastaCurada? montarInventario,
    DateTime Function()? agora,
  }) : _montarInventario = montarInventario ?? MontarInventarioPastaCurada(),
       _agora = agora ?? DateTime.now;

  final MontarInventarioPastaCurada _montarInventario;
  final DateTime Function() _agora;

  Future<ResultadoPublicacaoBiblioteca> publicar({
    required Directory entrada,
    required Directory saida,
    required File relatorio,
    String? geracao,
    DateTime? publicadoEm,
  }) async {
    final instante = (publicadoEm ?? _agora()).toUtc();
    final geracaoEfetiva = geracao ?? _geracaoPadrao(instante);
    final erros = <String>[];
    final avisos = <String>[];

    if (!await entrada.exists()) {
      erros.add('A pasta de entrada não existe: ${entrada.path}.');
    }
    if (_estaDentroDe(saida.absolute.path, entrada.absolute.path)) {
      erros.add('A saída não pode ficar dentro da pasta curada de entrada.');
    }
    final relatorioSeguro = !_estaDentroDe(
      relatorio.absolute.path,
      entrada.absolute.path,
    );
    if (!relatorioSeguro) {
      erros.add(
        'O relatório não pode ficar dentro da pasta curada de entrada.',
      );
    }
    if (await saida.exists()) {
      erros.add(
        'A saída final já existe e não será sobrescrita: ${saida.path}.',
      );
    }
    try {
      ManifestoBibliotecaOficial(
        schema: schemaManifestoBibliotecaOficialAtual,
        geracao: geracaoEfetiva,
        publicadoEm: instante,
        arquivos: const [],
      );
    } on FormatException catch (erro) {
      erros.add(erro.message);
    }
    if (erros.isNotEmpty) {
      return _finalizarFalha(
        relatorio: relatorio,
        geracao: geracaoEfetiva,
        erros: erros,
        avisos: avisos,
        escreverRelatorio: relatorioSeguro,
      );
    }

    final entidades = await entrada.list(followLinks: false).toList();
    final arquivosEntrada = entidades.whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final arquivosCho = arquivosEntrada
        .where((arquivo) => arquivo.path.toLowerCase().endsWith('.cho'))
        .toList();
    final ignorados = entidades.length - arquivosCho.length;
    if (ignorados > 0) {
      avisos.add('$ignorados item(ns) não-.cho ou diretório(s) ignorado(s).');
    }
    if (arquivosCho.isEmpty) {
      erros.add('Nenhum arquivo .cho foi encontrado na pasta de entrada.');
      return _finalizarFalha(
        relatorio: relatorio,
        geracao: geracaoEfetiva,
        erros: erros,
        avisos: avisos,
      );
    }

    final bytesPorLocalizador = <String, List<int>>{};
    final candidatos = <ArquivoSincronizacaoCandidato>[];
    for (final arquivo in arquivosCho) {
      final bytes = await arquivo.readAsBytes();
      bytesPorLocalizador[arquivo.path] = bytes;
      candidatos.add(
        ArquivoSincronizacaoCandidato(
          localizador: arquivo.path,
          nomeLegivel: _nomeArquivo(arquivo.path),
          bytes: bytes,
        ),
      );
    }

    final inventario = _montarInventario.executar(candidatos);
    for (final arquivo in inventario.arquivosInvalidos) {
      erros.add(
        '${arquivo.candidato.nomeLegivel}: '
        '${arquivo.erros.map((erro) => erro.codigo.name).join(', ')}.',
      );
    }
    for (final grupo in inventario.gruposRejeitados) {
      erros.add(
        'Música ${grupo.idMusica.valor}: '
        '${grupo.erros.map((erro) => erro.codigo.name).join(', ')}.',
      );
    }
    for (final grupo in inventario.gruposValidos) {
      if (!grupo.avaliacaoCriacao.apta) {
        erros.add(
          'Música ${grupo.idMusica.valor}: exige exatamente uma versão '
          'principal; encontradas '
          '${grupo.avaliacaoCriacao.quantidadePrincipais}.',
        );
      }
    }
    if (erros.isNotEmpty) {
      return _finalizarFalha(
        relatorio: relatorio,
        geracao: geracaoEfetiva,
        erros: erros,
        avisos: avisos,
        quantidadeMusicas: inventario.gruposValidos.length,
        quantidadeVersoes: inventario.arquivosValidos.length,
        bytesTotais: inventario.arquivosValidos.fold(
          0,
          (total, arquivo) => total + arquivo.candidato.bytes.length,
        ),
      );
    }

    final entradas = inventario.arquivosValidos.map((arquivo) {
      return EntradaManifestoBibliotecaOficial(
        idMusica: arquivo.idMusica,
        idVersaoMusica: arquivo.idVersaoMusica,
        sha256: arquivo.hashSha256,
        tamanhoBytes: arquivo.candidato.bytes.length,
        caminho: _caminhoPublicado(arquivo.idVersaoMusica.valor),
      );
    }).toList();
    final manifesto = ManifestoBibliotecaOficial(
      schema: schemaManifestoBibliotecaOficialAtual,
      geracao: geracaoEfetiva,
      publicadoEm: instante,
      arquivos: entradas,
    );
    final quantidadeMusicas = inventario.gruposValidos.length;
    final bytesTotais = entradas.fold<int>(
      0,
      (total, entrada) => total + entrada.tamanhoBytes,
    );
    final resultado = ResultadoPublicacaoBiblioteca(
      sucesso: true,
      geracao: geracaoEfetiva,
      quantidadeMusicas: quantidadeMusicas,
      quantidadeVersoes: entradas.length,
      bytesTotais: bytesTotais,
      erros: const [],
      avisos: avisos,
      manifesto: manifesto,
    );

    final paiSaida = saida.parent;
    await paiSaida.create(recursive: true);
    final temporaria = Directory(
      '${saida.path}.tmp-$pid-${_agora().microsecondsSinceEpoch}',
    );
    try {
      final pastaMusicas = Directory(
        '${temporaria.path}${Platform.pathSeparator}musicas',
      );
      await pastaMusicas.create(recursive: true);
      for (final entradaManifesto in manifesto.arquivos) {
        final validado = inventario.arquivosValidos.singleWhere(
          (arquivo) =>
              arquivo.idVersaoMusica == entradaManifesto.idVersaoMusica,
        );
        final bytes = bytesPorLocalizador[validado.candidato.localizador]!;
        final destino = File(
          '${temporaria.path}${Platform.pathSeparator}'
          '${entradaManifesto.caminho.replaceAll('/', Platform.pathSeparator)}',
        );
        await destino.writeAsBytes(bytes, flush: true);
        final bytesPublicados = await destino.readAsBytes();
        if (bytesPublicados.length != entradaManifesto.tamanhoBytes ||
            sha256.convert(bytesPublicados).toString() !=
                entradaManifesto.sha256) {
          throw StateError(
            'Verificação falhou para ${entradaManifesto.caminho}.',
          );
        }
      }
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .writeAsString(manifesto.codificar(), encoding: utf8, flush: true);
      await File(
        '${temporaria.path}${Platform.pathSeparator}relatorio.md',
      ).writeAsString(resultado.gerarRelatorio(), encoding: utf8, flush: true);
      await temporaria.rename(saida.path);
      try {
        await _escreverRelatorio(relatorio, resultado);
        return resultado;
      } catch (erro) {
        return ResultadoPublicacaoBiblioteca(
          sucesso: true,
          geracao: resultado.geracao,
          quantidadeMusicas: resultado.quantidadeMusicas,
          quantidadeVersoes: resultado.quantidadeVersoes,
          bytesTotais: resultado.bytesTotais,
          erros: const [],
          avisos: [
            ...resultado.avisos,
            'A geração é válida, mas o relatório externo falhou: $erro',
          ],
          manifesto: manifesto,
        );
      }
    } catch (erro) {
      if (await temporaria.exists()) {
        await temporaria.delete(recursive: true);
      }
      return _finalizarFalha(
        relatorio: relatorio,
        geracao: geracaoEfetiva,
        erros: ['Falha ao finalizar a publicação: $erro'],
        avisos: avisos,
        quantidadeMusicas: quantidadeMusicas,
        quantidadeVersoes: entradas.length,
        bytesTotais: bytesTotais,
      );
    }
  }

  Future<ResultadoPublicacaoBiblioteca> _finalizarFalha({
    required File relatorio,
    required String geracao,
    required List<String> erros,
    required List<String> avisos,
    int quantidadeMusicas = 0,
    int quantidadeVersoes = 0,
    int bytesTotais = 0,
    bool escreverRelatorio = true,
  }) async {
    final resultado = ResultadoPublicacaoBiblioteca(
      sucesso: false,
      geracao: geracao,
      quantidadeMusicas: quantidadeMusicas,
      quantidadeVersoes: quantidadeVersoes,
      bytesTotais: bytesTotais,
      erros: erros,
      avisos: avisos,
    );
    if (escreverRelatorio) {
      await _escreverRelatorio(relatorio, resultado);
    }
    return resultado;
  }

  Future<void> _escreverRelatorio(
    File arquivo,
    ResultadoPublicacaoBiblioteca resultado,
  ) async {
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsString(
      resultado.gerarRelatorio(),
      encoding: utf8,
      flush: true,
    );
  }

  String _geracaoPadrao(DateTime instante) =>
      instante.toUtc().toIso8601String().replaceAll(RegExp(r'[-:.]'), '');

  String _nomeArquivo(String caminho) => caminho
      .split(RegExp(r'[\\/]'))
      .where((segmento) => segmento.isNotEmpty)
      .last;

  String _caminhoPublicado(String idVersaoMusica) {
    final nomeSeguro = base64Url
        .encode(utf8.encode(idVersaoMusica))
        .replaceAll('=', '');
    return 'musicas/$nomeSeguro.cho';
  }

  bool _estaDentroDe(String candidato, String pasta) {
    final candidatoNormalizado = _normalizarCaminho(candidato);
    final pastaNormalizada = _normalizarCaminho(pasta);
    return candidatoNormalizado == pastaNormalizada ||
        candidatoNormalizado.startsWith(
          '$pastaNormalizada${Platform.pathSeparator}',
        );
  }

  String _normalizarCaminho(String caminho) => Platform.isWindows
      ? caminho.toLowerCase().replaceAll('/', Platform.pathSeparator)
      : caminho;
}
