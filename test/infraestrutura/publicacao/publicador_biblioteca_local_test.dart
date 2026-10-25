import 'dart:convert';
import 'dart:io';

import 'package:appcifras/aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import 'package:appcifras/infraestrutura/publicacao/publicador_biblioteca_local.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaria;
  late Directory entrada;
  late Directory saida;
  late File relatorio;
  late PublicadorBibliotecaLocal publicador;

  setUp(() async {
    temporaria = await Directory.systemTemp.createTemp('appcifras-publicador-');
    entrada = Directory('${temporaria.path}${Platform.pathSeparator}entrada');
    saida = Directory('${temporaria.path}${Platform.pathSeparator}publicacao');
    relatorio = File('${temporaria.path}${Platform.pathSeparator}relatorio.md');
    await entrada.create();
    publicador = PublicadorBibliotecaLocal(
      agora: () => DateTime.utc(2026, 10, 25, 12),
    );
  });

  tearDown(() async {
    if (await temporaria.exists()) {
      await temporaria.delete(recursive: true);
    }
  });

  Future<File> criarCho({
    required String nomeArquivo,
    required String idMusica,
    required String idVersao,
    String titulo = 'Título',
    String artista = 'Artista',
    String nomeVersao = 'Principal',
    bool principal = true,
    String corpo = '[C]Conteúdo',
  }) async {
    final arquivo = File(
      '${entrada.path}${Platform.pathSeparator}$nomeArquivo',
    );
    await arquivo.writeAsString(
      [
        '{appcifras_schema:2}',
        '{appcifras_id:$idMusica}',
        '{appcifras_version_id:$idVersao}',
        '{appcifras_version_name:$nomeVersao}',
        '{appcifras_primary:$principal}',
        '{title:$titulo}',
        '{artist:$artista}',
        '{key:C}',
        corpo,
      ].join('\n'),
      encoding: utf8,
    );
    return arquivo;
  }

  Future<ResultadoPublicacaoBiblioteca> publicar() => publicador.publicar(
    entrada: entrada,
    saida: saida,
    relatorio: relatorio,
    geracao: 'geracao-teste',
    publicadoEm: DateTime.utc(2026, 10, 25, 12),
  );

  test('publica múltiplas músicas e versões com hash e size exatos', () async {
    final principal = await criarCho(
      nomeArquivo: 'z.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-1',
    );
    await criarCho(
      nomeArquivo: 'a.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-2',
      nomeVersao: 'Acústica',
      principal: false,
    );
    await criarCho(
      nomeArquivo: 'outra.cho',
      idMusica: 'musica-2',
      idVersao: 'versao-3',
      titulo: 'Outra',
      artista: 'Outro artista',
    );
    final bytesOriginais = await principal.readAsBytes();

    final resultado = await publicar();

    expect(resultado.sucesso, isTrue);
    expect(resultado.quantidadeMusicas, 2);
    expect(resultado.quantidadeVersoes, 3);
    expect(await saida.exists(), isTrue);
    final manifesto = ManifestoBibliotecaOficial.decodificar(
      await File('${saida.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    );
    expect(manifesto.arquivos.map((item) => item.idVersaoMusica.valor), [
      'versao-1',
      'versao-2',
      'versao-3',
    ]);
    for (final item in manifesto.arquivos) {
      final publicado = File(
        '${saida.path}${Platform.pathSeparator}'
        '${item.caminho.replaceAll('/', Platform.pathSeparator)}',
      );
      final bytes = await publicado.readAsBytes();
      expect(bytes.length, item.tamanhoBytes);
      expect(sha256.convert(bytes).toString(), item.sha256);
    }
    expect(await principal.readAsBytes(), bytesOriginais);
    expect(await relatorio.readAsString(), contains('Resultado: SUCESSO'));
  });

  test('mesma entrada gera mesmos paths e mesmo resultado lógico', () async {
    await criarCho(
      nomeArquivo: 'primeiro-nome.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-estavel',
    );
    final primeiro = await publicar();
    final primeiroManifesto = primeiro.manifesto!;
    final outraSaida = Directory(
      '${temporaria.path}${Platform.pathSeparator}publicacao-2',
    );
    final segundo = await publicador.publicar(
      entrada: entrada,
      saida: outraSaida,
      relatorio: File('${temporaria.path}${Platform.pathSeparator}r2.md'),
      geracao: 'outra-geracao',
      publicadoEm: DateTime.utc(2026, 10, 26),
    );

    expect(segundo.sucesso, isTrue);
    expect(
      segundo.manifesto!.arquivos.single.caminho,
      primeiroManifesto.arquivos.single.caminho,
    );
    expect(
      segundo.manifesto!.arquivos.single.sha256,
      primeiroManifesto.arquivos.single.sha256,
    );
  });

  test('arquivo ChordPro inválido impede publicação final', () async {
    await File('${entrada.path}${Platform.pathSeparator}invalido.cho')
        .writeAsString('{title:Sem schema}');

    final resultado = await publicar();

    expect(resultado.sucesso, isFalse);
    expect(resultado.erros, isNotEmpty);
    expect(await saida.exists(), isFalse);
    expect(await relatorio.readAsString(), contains('Resultado: FALHA'));
  });

  test('conflito de identidade impede publicação final', () async {
    await criarCho(
      nomeArquivo: 'a.cho',
      idMusica: 'musica-a',
      idVersao: 'versao-repetida',
    );
    await criarCho(
      nomeArquivo: 'b.cho',
      idMusica: 'musica-b',
      idVersao: 'versao-repetida',
      titulo: 'Outra',
      artista: 'Outro artista',
    );

    final resultado = await publicar();

    expect(resultado.sucesso, isFalse);
    expect(
      resultado.erros.join('\n'),
      contains('idVersaoAssociadoAMusicasDiferentes'),
    );
    expect(await saida.exists(), isFalse);
  });

  test('música sem exatamente uma principal não é publicada', () async {
    await criarCho(
      nomeArquivo: 'alternativa.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-1',
      principal: false,
    );

    final resultado = await publicar();

    expect(resultado.sucesso, isFalse);
    expect(
      resultado.erros.join('\n'),
      contains('exatamente uma versão principal'),
    );
    expect(await saida.exists(), isFalse);
  });

  test('não sobrescreve geração final existente', () async {
    await criarCho(
      nomeArquivo: 'valida.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-1',
    );
    await saida.create();
    final marcador = File(
      '${saida.path}${Platform.pathSeparator}existente.txt',
    );
    await marcador.writeAsString('preservar');

    final resultado = await publicar();

    expect(resultado.sucesso, isFalse);
    expect(await marcador.readAsString(), 'preservar');
  });

  test('não cria saída nem relatório dentro da pasta curada', () async {
    await criarCho(
      nomeArquivo: 'valida.cho',
      idMusica: 'musica-1',
      idVersao: 'versao-1',
    );
    final saidaInterna = Directory(
      '${entrada.path}${Platform.pathSeparator}publicacao',
    );
    final relatorioInterno = File(
      '${entrada.path}${Platform.pathSeparator}relatorio.md',
    );

    final resultado = await publicador.publicar(
      entrada: entrada,
      saida: saidaInterna,
      relatorio: relatorioInterno,
      geracao: 'geracao-teste',
    );

    expect(resultado.sucesso, isFalse);
    expect(await saidaInterna.exists(), isFalse);
    expect(await relatorioInterno.exists(), isFalse);
  });
}
