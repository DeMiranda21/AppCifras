import 'dart:async';
import 'dart:convert';

import 'package:appcifras/aplicacao/biblioteca_oficial/falha_biblioteca_oficial.dart';
import 'package:appcifras/infraestrutura/http/fonte_biblioteca_oficial_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const baseUrl = 'https://biblioteca.exemplo.test/base';

  String manifesto({
    int schema = 1,
    String path = 'musicas/versao.cho',
    int size = 8,
    String? hash,
  }) => jsonEncode({
    'schema': schema,
    'generation': 'geracao-http',
    'publishedAt': '2026-10-25T12:00:00.000Z',
    'files': [
      {
        'idMusica': 'musica',
        'idVersaoMusica': 'versao',
        'sha256': hash ?? 'a' * 64,
        'size': size,
        'path': path,
      },
    ],
  });

  Matcher falha(TipoFalhaBibliotecaOficial tipo) =>
      isA<FalhaBibliotecaOficial>().having((erro) => erro.tipo, 'tipo', tipo);

  test('obtém e valida manifesto pela base URL HTTPS', () async {
    final requisicoes = <Uri>[];
    final fonte = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((request) async {
        requisicoes.add(request.url);
        return http.Response(
          manifesto(),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final resultado = await fonte.obterManifesto();

    expect(resultado.geracao, 'geracao-http');
    expect(resultado.arquivos.single.caminho, 'musicas/versao.cho');
    expect(requisicoes.single, Uri.parse('$baseUrl/manifest.json'));
    fonte.fechar();
  });

  test('rejeita base URL que não seja HTTPS', () {
    expect(
      () => FonteBibliotecaOficialHttp(baseUrl: 'http://exemplo.test'),
      throwsArgumentError,
    );
    expect(
      () => FonteBibliotecaOficialHttp(
        baseUrl: 'https://usuario@exemplo.test?x=1',
      ),
      throwsArgumentError,
    );
  });

  test('distingue 404 de manifesto', () async {
    final fonte = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async => http.Response('', 404)),
    );

    await expectLater(
      fonte.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.manifestoNaoEncontrado)),
    );
  });

  test('rejeita manifesto inválido e schema não suportado', () async {
    final invalida = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async => http.Response('{inválido', 200)),
    );
    await expectLater(
      invalida.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.manifestoInvalido)),
    );

    final schema = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient(
        (_) async => http.Response(manifesto(schema: 99), 200),
      ),
    );
    await expectLater(
      schema.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.schemaNaoSuportado)),
    );
  });

  test('rejeita path inseguro antes de qualquer requisição', () async {
    var requisicoes = 0;
    final fonte = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async {
        requisicoes++;
        return http.Response('conteudo', 200);
      }),
    );

    for (final path in [
      '../segredo.cho',
      'musicas/%2e%2e/segredo.cho',
      'https://outro.test/arquivo.cho',
      '//outro.test/arquivo.cho',
      r'musicas\arquivo.cho',
      'musicas/arquivo.cho?download=1',
    ]) {
      await expectLater(
        fonte.baixarArquivo(path, tamanhoEsperado: 8),
        throwsA(falha(TipoFalhaBibliotecaOficial.caminhoInseguro)),
        reason: path,
      );
    }
    expect(requisicoes, 0);
  });

  test('baixa arquivo somente no mesmo host e confere tamanho', () async {
    final requisicoes = <Uri>[];
    final fonte = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((request) async {
        requisicoes.add(request.url);
        return http.Response('conteudo', 200);
      }),
    );

    final resultado = await fonte.baixarArquivo(
      'musicas/versao.cho',
      tamanhoEsperado: 8,
    );

    expect(utf8.decode(resultado), 'conteudo');
    expect(requisicoes.single.host, 'biblioteca.exemplo.test');
    expect(requisicoes.single.scheme, 'https');
  });

  test('distingue 404 de arquivo e HTTP 5xx', () async {
    final arquivo404 = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async => http.Response('', 404)),
    );
    await expectLater(
      arquivo404.baixarArquivo('musicas/v.cho', tamanhoEsperado: 1),
      throwsA(falha(TipoFalhaBibliotecaOficial.arquivoNaoEncontrado)),
    );

    final servidor = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async => http.Response('', 503)),
    );
    await expectLater(
      servidor.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.httpServidor)),
    );
  });

  test('não segue redirect para outra autoridade', () async {
    final fonte = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((request) async {
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://outro.test/manifest.json'},
        );
      }),
    );

    await expectLater(
      fonte.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.httpInesperado)),
    );
  });

  test('distingue timeout e falha de conexão', () async {
    final timeout = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      timeout: const Duration(milliseconds: 10),
      cliente: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response(manifesto(), 200);
      }),
    );
    await expectLater(
      timeout.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.timeout)),
    );

    final semConexao = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((request) async {
        throw http.ClientException('offline', request.url);
      }),
    );
    await expectLater(
      semConexao.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.semConexao)),
    );
  });

  test('rejeita Content-Length e corpo com tamanho divergente', () async {
    final declarado = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: _ClienteStream(bytes: utf8.encode('conteudo'), contentLength: 9),
    );
    await expectLater(
      declarado.baixarArquivo('musicas/v.cho', tamanhoEsperado: 8),
      throwsA(falha(TipoFalhaBibliotecaOficial.tamanhoDivergente)),
    );

    final corpo = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      cliente: MockClient((_) async => http.Response('curto', 200)),
    );
    await expectLater(
      corpo.baixarArquivo('musicas/v.cho', tamanhoEsperado: 8),
      throwsA(falha(TipoFalhaBibliotecaOficial.tamanhoDivergente)),
    );
  });

  test('aplica limites de tamanho ao manifesto e aos arquivos', () async {
    final manifestoGrande = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      limiteManifestoBytes: 5,
      cliente: MockClient((_) async => http.Response(manifesto(), 200)),
    );
    await expectLater(
      manifestoGrande.obterManifesto(),
      throwsA(falha(TipoFalhaBibliotecaOficial.limiteExcedido)),
    );

    final arquivoGrande = FonteBibliotecaOficialHttp(
      baseUrl: baseUrl,
      limiteArquivoBytes: 4,
      cliente: MockClient((_) async => http.Response('1234', 200)),
    );
    await expectLater(
      arquivoGrande.baixarArquivo('musicas/v.cho', tamanhoEsperado: 5),
      throwsA(falha(TipoFalhaBibliotecaOficial.limiteExcedido)),
    );
  });
}

class _ClienteStream extends http.BaseClient {
  _ClienteStream({required this.bytes, required this.contentLength});

  final List<int> bytes;
  final int contentLength;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(bytes),
        200,
        request: request,
        contentLength: contentLength,
      );
}
