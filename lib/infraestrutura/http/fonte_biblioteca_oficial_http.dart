import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../aplicacao/biblioteca_oficial/falha_biblioteca_oficial.dart';
import '../../aplicacao/portas/fonte_biblioteca_oficial.dart';
import '../../aplicacao/publicacao/manifesto_biblioteca_oficial.dart';

const String baseUrlBibliotecaOficialConfigurada = String.fromEnvironment(
  'APPCIFRAS_LIBRARY_BASE_URL',
);

class FonteBibliotecaOficialHttp implements FonteBibliotecaOficial {
  FonteBibliotecaOficialHttp({
    required String baseUrl,
    http.Client? cliente,
    this.timeout = const Duration(seconds: 20),
    this.limiteManifestoBytes = 8 * 1024 * 1024,
    this.limiteArquivoBytes = 4 * 1024 * 1024,
  }) : _baseUri = _validarBaseUrl(baseUrl),
       _cliente = cliente ?? http.Client();

  final Uri _baseUri;
  final http.Client _cliente;
  final Duration timeout;
  final int limiteManifestoBytes;
  final int limiteArquivoBytes;

  @override
  Future<ManifestoBibliotecaOficial> obterManifesto() async {
    final bytes = await _obterBytes(
      _resolver('manifest.json'),
      limiteBytes: limiteManifestoBytes,
      manifesto: true,
    );
    late final String conteudo;
    try {
      conteudo = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.manifestoInvalido,
        'O manifesto não contém UTF-8 válido.',
      );
    }
    try {
      return ManifestoBibliotecaOficial.decodificar(conteudo);
    } on SchemaManifestoBibliotecaOficialNaoSuportado catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.schemaNaoSuportado,
        erro.message,
      );
    } on CaminhoBibliotecaOficialInseguro catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.caminhoInseguro,
        erro.message,
      );
    } on FormatException catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.manifestoInvalido,
        'Manifesto inválido: ${erro.message}',
      );
    }
  }

  @override
  Future<Uint8List> baixarArquivo(
    String caminho, {
    required int tamanhoEsperado,
  }) async {
    try {
      validarCaminhoRelativoBibliotecaOficial(caminho);
    } on FormatException catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.caminhoInseguro,
        erro.message,
      );
    }
    if (tamanhoEsperado <= 0 || tamanhoEsperado > limiteArquivoBytes) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.limiteExcedido,
        'Tamanho declarado fora do limite para $caminho.',
      );
    }
    return _obterBytes(
      _resolver(caminho),
      limiteBytes: limiteArquivoBytes,
      tamanhoEsperado: tamanhoEsperado,
      manifesto: false,
    );
  }

  Future<Uint8List> _obterBytes(
    Uri uri, {
    required int limiteBytes,
    required bool manifesto,
    int? tamanhoEsperado,
  }) async {
    try {
      return await _executarGet(
        uri,
        limiteBytes: limiteBytes,
        manifesto: manifesto,
        tamanhoEsperado: tamanhoEsperado,
      ).timeout(timeout);
    } on FalhaBibliotecaOficial {
      rethrow;
    } on TimeoutException {
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.timeout,
        'Tempo limite ao acessar a Biblioteca Oficial.',
      );
    } on http.ClientException catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.semConexao,
        'Não foi possível acessar a Biblioteca Oficial: ${erro.message}',
      );
    } on Object catch (erro) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.semConexao,
        'Não foi possível acessar a Biblioteca Oficial: $erro',
      );
    }
  }

  Future<Uint8List> _executarGet(
    Uri uri, {
    required int limiteBytes,
    required bool manifesto,
    int? tamanhoEsperado,
  }) async {
    final requisicao = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['accept-encoding'] = 'identity'
      ..headers['accept'] = manifesto
          ? 'application/json'
          : 'text/plain, application/octet-stream';
    final resposta = await _cliente.send(requisicao);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      await resposta.stream.drain<void>();
      if (resposta.statusCode == 404) {
        throw FalhaBibliotecaOficial(
          manifesto
              ? TipoFalhaBibliotecaOficial.manifestoNaoEncontrado
              : TipoFalhaBibliotecaOficial.arquivoNaoEncontrado,
          manifesto
              ? 'manifest.json não foi encontrado.'
              : 'Arquivo da Biblioteca Oficial não foi encontrado.',
          statusHttp: resposta.statusCode,
        );
      }
      throw FalhaBibliotecaOficial(
        resposta.statusCode >= 500
            ? TipoFalhaBibliotecaOficial.httpServidor
            : TipoFalhaBibliotecaOficial.httpInesperado,
        'Resposta HTTP inesperada: ${resposta.statusCode}.',
        statusHttp: resposta.statusCode,
      );
    }

    final declarado = resposta.contentLength;
    if (declarado != null && declarado > limiteBytes) {
      await resposta.stream.drain<void>();
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.limiteExcedido,
        'Resposta maior que o limite permitido.',
      );
    }
    if (tamanhoEsperado != null &&
        declarado != null &&
        declarado != tamanhoEsperado) {
      await resposta.stream.drain<void>();
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.tamanhoDivergente,
        'Content-Length divergente: esperado $tamanhoEsperado, '
        'recebido $declarado.',
      );
    }

    final construtor = BytesBuilder(copy: false);
    var total = 0;
    await for (final trecho in resposta.stream) {
      total += trecho.length;
      if (total > limiteBytes) {
        throw const FalhaBibliotecaOficial(
          TipoFalhaBibliotecaOficial.limiteExcedido,
          'Resposta maior que o limite permitido.',
        );
      }
      construtor.add(trecho);
    }
    if (declarado != null && total != declarado) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.tamanhoDivergente,
        'Content-Length divergente do corpo recebido.',
      );
    }
    if (tamanhoEsperado != null && total != tamanhoEsperado) {
      throw FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.tamanhoDivergente,
        'Tamanho divergente: esperado $tamanhoEsperado, recebido $total.',
      );
    }
    return construtor.takeBytes();
  }

  Uri _resolver(String caminho) {
    final baseComBarra = _baseUri.replace(
      path: _baseUri.path.endsWith('/') ? _baseUri.path : '${_baseUri.path}/',
    );
    final resolvida = baseComBarra.resolve(caminho);
    if (resolvida.scheme != _baseUri.scheme ||
        resolvida.host != _baseUri.host ||
        resolvida.port != _baseUri.port ||
        resolvida.userInfo.isNotEmpty) {
      throw const FalhaBibliotecaOficial(
        TipoFalhaBibliotecaOficial.caminhoInseguro,
        'O path tentou alterar a autoridade da Biblioteca Oficial.',
      );
    }
    return resolvida;
  }

  static Uri _validarBaseUrl(String valor) {
    final uri = Uri.tryParse(valor);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(
        valor,
        'baseUrl',
        'A base URL deve ser uma URL HTTPS sem query, fragmento ou credenciais.',
      );
    }
    return uri;
  }

  @override
  void fechar() => _cliente.close();
}

class FonteBibliotecaOficialIndisponivel implements FonteBibliotecaOficial {
  const FonteBibliotecaOficialIndisponivel();

  Never _indisponivel() => throw const FalhaBibliotecaOficial(
    TipoFalhaBibliotecaOficial.configuracaoAusente,
    'APPCIFRAS_LIBRARY_BASE_URL não foi configurada no build.',
  );

  @override
  Future<ManifestoBibliotecaOficial> obterManifesto() async => _indisponivel();

  @override
  Future<Uint8List> baixarArquivo(
    String caminho, {
    required int tamanhoEsperado,
  }) async => _indisponivel();

  @override
  void fechar() {}
}
