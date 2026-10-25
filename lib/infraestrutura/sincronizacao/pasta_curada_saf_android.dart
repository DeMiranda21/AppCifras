import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../../aplicacao/portas/pasta_curada_externa.dart';

class PastaCuradaSafAndroid implements PastaCuradaExterna {
  const PastaCuradaSafAndroid({MethodChannel? canal})
    : _canal = canal ?? const MethodChannel(_nomeCanal);

  static const _nomeCanal = 'appcifras/pasta_curada';
  final MethodChannel _canal;

  @override
  Future<PastaCuradaSelecionada?> selecionarPasta() async {
    try {
      final resultado = await _canal.invokeMapMethod<String, Object?>(
        'selecionarPasta',
      );
      if (resultado == null) return null;
      return PastaCuradaSelecionada(
        uriArvore: resultado['uri']! as String,
        nomeLegivel: resultado['nome'] as String?,
      );
    } on PlatformException catch (erro) {
      throw _converterErro(erro);
    }
  }

  @override
  Future<void> verificarAcesso(String uriArvore) async {
    try {
      await _canal.invokeMethod<void>('verificarAcesso', {'uri': uriArvore});
    } on PlatformException catch (erro) {
      throw _converterErro(erro);
    }
  }

  @override
  Future<ResultadoEnumeracaoPastaCurada> listarFilhosDiretos(
    String uriArvore,
  ) async {
    try {
      final resultado = await _canal.invokeMapMethod<String, Object?>(
        'listarFilhosDiretos',
        {'uri': uriArvore},
      );
      if (resultado == null) {
        throw const FalhaPastaCurada(
          TipoFalhaPastaCurada.leitura,
          'O provedor não retornou o resultado da enumeração.',
        );
      }
      final documentosBrutos =
          resultado['documentos'] as List<Object?>? ?? const <Object?>[];
      final documentos = documentosBrutos
          .map((item) {
            final dados = Map<Object?, Object?>.from(item! as Map);
            return DocumentoPastaCurada(
              localizador: dados['localizador']! as String,
              nome: dados['nome']! as String,
              ehDiretorio: dados['ehDiretorio']! as bool,
              tipoMime: dados['tipoMime'] as String?,
            );
          })
          .toList(growable: false);
      final completa = resultado['completa'] as bool? ?? false;
      developer.log(
        'Dart recebeu ${documentos.length} documentos; '
        'completa=$completa; tentativas=${resultado['tentativas']}; '
        'linhasBrutas=${resultado['linhasBrutas']}; '
        'arquivosCho=${resultado['arquivosCho']}.',
        name: 'AppCifrasSAF',
      );
      return ResultadoEnumeracaoPastaCurada(
        documentos: documentos,
        completa: completa,
      );
    } on PlatformException catch (erro) {
      throw _converterErro(erro);
    }
  }

  @override
  Future<Uint8List> lerBytes(DocumentoPastaCurada documento) async {
    try {
      final bytes = await _canal.invokeMethod<Uint8List>('lerBytes', {
        'localizador': documento.localizador,
      });
      if (bytes == null) {
        throw const FalhaPastaCurada(
          TipoFalhaPastaCurada.leitura,
          'O provedor não retornou o conteúdo do arquivo.',
        );
      }
      return bytes;
    } on PlatformException catch (erro) {
      throw _converterErro(erro);
    }
  }

  FalhaPastaCurada _converterErro(PlatformException erro) {
    final tipo = switch (erro.code) {
      'access_revoked' => TipoFalhaPastaCurada.autorizacaoRevogada,
      'provider_unavailable' => TipoFalhaPastaCurada.provedorIndisponivel,
      'persist_permission_failed' =>
        TipoFalhaPastaCurada.autorizacaoNaoPersistida,
      _ => TipoFalhaPastaCurada.leitura,
    };
    return FalhaPastaCurada(
      tipo,
      erro.message ?? 'Não foi possível acessar a pasta selecionada.',
    );
  }
}
