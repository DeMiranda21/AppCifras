import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../dominio/objetos_de_valor/id_versao_musica.dart';

class ArquivoChordProInexistente implements Exception {
  const ArquivoChordProInexistente(this.id);

  final IdVersaoMusica id;
}

class ArquivoChordProJaExiste implements Exception {
  const ArquivoChordProJaExiste(this.id);

  final IdVersaoMusica id;
}

class ArmazenamentoArquivosChordPro {
  ArmazenamentoArquivosChordPro(this._diretorioMusicas);

  final Directory _diretorioMusicas;

  String nomeArquivo(IdVersaoMusica id) =>
      '${Uri.encodeComponent(id.valor)}.cho';

  Future<void> salvar(IdVersaoMusica id, String conteudo) async {
    await _diretorioMusicas.create(recursive: true);
    final destino = _arquivo(id);
    if (await destino.exists()) {
      throw ArquivoChordProJaExiste(id);
    }

    final temporario = File('${destino.path}.tmp');
    try {
      await temporario.writeAsString(conteudo, encoding: utf8, flush: true);
      await temporario.rename(destino.path);
    } catch (_) {
      if (await temporario.exists()) {
        await temporario.delete();
      }
      rethrow;
    }
  }

  Future<void> substituir(IdVersaoMusica id, String conteudo) async {
    final destino = _arquivo(id);
    if (!await destino.exists()) {
      throw ArquivoChordProInexistente(id);
    }

    final temporario = File('${destino.path}.tmp');
    final anterior = File('${destino.path}.bak');
    try {
      await temporario.writeAsString(conteudo, encoding: utf8, flush: true);
      if (await anterior.exists()) {
        await anterior.delete();
      }
      await destino.rename(anterior.path);
      await temporario.rename(destino.path);
      await anterior.delete();
    } catch (_) {
      if (!await destino.exists() && await anterior.exists()) {
        await anterior.rename(destino.path);
      }
      if (await temporario.exists()) {
        await temporario.delete();
      }
      rethrow;
    }
  }

  Future<String> obter(IdVersaoMusica id) async {
    final arquivo = _arquivo(id);
    if (!await arquivo.exists()) {
      throw ArquivoChordProInexistente(id);
    }
    return arquivo.readAsString(encoding: utf8);
  }

  Future<bool> existe(IdVersaoMusica id) => _arquivo(id).exists();

  Future<void> excluir(IdVersaoMusica id) async {
    final arquivo = _arquivo(id);
    if (!await arquivo.exists()) {
      throw ArquivoChordProInexistente(id);
    }
    await arquivo.delete();
  }

  File _arquivo(IdVersaoMusica id) => File(
    '${_diretorioMusicas.path}${Platform.pathSeparator}${nomeArquivo(id)}',
  );
}

class FabricaArmazenamentoArquivosChordPro {
  const FabricaArmazenamentoArquivosChordPro();

  Future<ArmazenamentoArquivosChordPro> criar() async {
    final diretorioDados = await getApplicationSupportDirectory();
    return ArmazenamentoArquivosChordPro(
      Directory('${diretorioDados.path}${Platform.pathSeparator}musicas'),
    );
  }
}
