import 'dart:convert';

import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';

const int schemaManifestoBibliotecaOficialAtual = 1;

class EntradaManifestoBibliotecaOficial {
  EntradaManifestoBibliotecaOficial({
    required this.idMusica,
    required this.idVersaoMusica,
    required String sha256,
    required this.tamanhoBytes,
    required String caminho,
  }) : sha256 = _validarSha256(sha256),
       caminho = validarCaminhoRelativoBibliotecaOficial(caminho) {
    if (tamanhoBytes <= 0) {
      throw FormatException('O tamanho do arquivo deve ser maior que zero.');
    }
  }

  final IdMusica idMusica;
  final IdVersaoMusica idVersaoMusica;
  final String sha256;
  final int tamanhoBytes;
  final String caminho;

  Map<String, Object> toJson() => {
    'idMusica': idMusica.valor,
    'idVersaoMusica': idVersaoMusica.valor,
    'sha256': sha256,
    'size': tamanhoBytes,
    'path': caminho,
  };

  factory EntradaManifestoBibliotecaOficial.fromJson(
    Map<String, Object?> json,
  ) {
    final idMusica = _lerId(json, 'idMusica');
    final idVersao = _lerId(json, 'idVersaoMusica');
    return EntradaManifestoBibliotecaOficial(
      idMusica: IdMusica(idMusica),
      idVersaoMusica: IdVersaoMusica(idVersao),
      sha256: _lerString(json, 'sha256'),
      tamanhoBytes: _lerInteiro(json, 'size'),
      caminho: _lerString(json, 'path'),
    );
  }

  static String _validarSha256(String valor) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(valor)) {
      throw FormatException('SHA-256 inválido no manifesto.');
    }
    return valor;
  }
}

class SchemaManifestoBibliotecaOficialNaoSuportado extends FormatException {
  SchemaManifestoBibliotecaOficialNaoSuportado(int schema)
    : super('Schema de manifesto desconhecido: $schema.');
}

class CaminhoBibliotecaOficialInseguro extends FormatException {
  CaminhoBibliotecaOficialInseguro(String caminho)
    : super('Path relativo inseguro no manifesto: $caminho');
}

String validarCaminhoRelativoBibliotecaOficial(String valor) {
  if (valor.isEmpty ||
      valor.startsWith('/') ||
      valor.startsWith('\\') ||
      valor.contains('\\') ||
      valor.contains('?') ||
      valor.contains('#') ||
      valor.contains('%') ||
      valor.contains('://') ||
      valor.startsWith('//')) {
    throw CaminhoBibliotecaOficialInseguro(valor);
  }
  final segmentos = valor.split('/');
  if (segmentos.any(
    (segmento) =>
        segmento.isEmpty ||
        segmento == '.' ||
        segmento == '..' ||
        !RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(segmento),
  )) {
    throw CaminhoBibliotecaOficialInseguro(valor);
  }
  return valor;
}

class ManifestoBibliotecaOficial {
  ManifestoBibliotecaOficial({
    required this.schema,
    required String geracao,
    required DateTime publicadoEm,
    required Iterable<EntradaManifestoBibliotecaOficial> arquivos,
  }) : geracao = _validarGeracao(geracao),
       publicadoEm = publicadoEm.toUtc(),
       arquivos = _validarEOrdenarArquivos(arquivos) {
    if (schema != schemaManifestoBibliotecaOficialAtual) {
      throw SchemaManifestoBibliotecaOficialNaoSuportado(schema);
    }
  }

  final int schema;
  final String geracao;
  final DateTime publicadoEm;
  final List<EntradaManifestoBibliotecaOficial> arquivos;

  Map<String, Object> toJson() => {
    'schema': schema,
    'generation': geracao,
    'publishedAt': publicadoEm.toIso8601String(),
    'files': arquivos.map((arquivo) => arquivo.toJson()).toList(),
  };

  String codificar() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';

  factory ManifestoBibliotecaOficial.fromJson(Map<String, Object?> json) {
    final schema = _lerInteiro(json, 'schema');
    final geracao = _lerString(json, 'generation');
    final publicadoEmTexto = _lerString(json, 'publishedAt');
    final arquivosJson = json['files'];
    if (arquivosJson is! List<Object?>) {
      throw const FormatException('A lista files é obrigatória.');
    }
    late final DateTime publicadoEm;
    try {
      publicadoEm = DateTime.parse(publicadoEmTexto);
    } on FormatException {
      throw const FormatException('publishedAt inválido.');
    }
    return ManifestoBibliotecaOficial(
      schema: schema,
      geracao: geracao,
      publicadoEm: publicadoEm,
      arquivos: arquivosJson.map((arquivo) {
        if (arquivo is! Map<String, Object?>) {
          throw const FormatException('Entrada de arquivo inválida.');
        }
        return EntradaManifestoBibliotecaOficial.fromJson(arquivo);
      }),
    );
  }

  factory ManifestoBibliotecaOficial.decodificar(String conteudo) {
    late final Object? json;
    try {
      json = jsonDecode(conteudo);
    } on FormatException {
      throw const FormatException('JSON do manifesto inválido.');
    }
    if (json is! Map<String, Object?>) {
      throw const FormatException('A raiz do manifesto deve ser um objeto.');
    }
    return ManifestoBibliotecaOficial.fromJson(json);
  }

  static String _validarGeracao(String valor) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(valor)) {
      throw FormatException('Identificador de geração inválido: $valor');
    }
    return valor;
  }

  static List<EntradaManifestoBibliotecaOficial> _validarEOrdenarArquivos(
    Iterable<EntradaManifestoBibliotecaOficial> arquivos,
  ) {
    final resultado = arquivos.toList()
      ..sort((a, b) {
        final porMusica = a.idMusica.valor.compareTo(b.idMusica.valor);
        return porMusica != 0
            ? porMusica
            : a.idVersaoMusica.valor.compareTo(b.idVersaoMusica.valor);
      });
    final idsVersao = <String>{};
    final caminhos = <String>{};
    for (final arquivo in resultado) {
      if (!idsVersao.add(arquivo.idVersaoMusica.valor)) {
        throw FormatException(
          'IdVersaoMusica duplicado: ${arquivo.idVersaoMusica.valor}.',
        );
      }
      if (!caminhos.add(arquivo.caminho)) {
        throw FormatException('Path duplicado: ${arquivo.caminho}.');
      }
    }
    return List.unmodifiable(resultado);
  }
}

String _lerString(Map<String, Object?> json, String chave) {
  final valor = json[chave];
  if (valor is! String || valor.isEmpty) {
    throw FormatException('Campo $chave inválido.');
  }
  return valor;
}

String _lerId(Map<String, Object?> json, String chave) {
  final valor = _lerString(json, chave);
  if (valor.trim() != valor ||
      valor.runes.any((codigo) => codigo < 0x20 || codigo == 0x7f)) {
    throw FormatException('Campo $chave inválido.');
  }
  return valor;
}

int _lerInteiro(Map<String, Object?> json, String chave) {
  final valor = json[chave];
  if (valor is! int) {
    throw FormatException('Campo $chave inválido.');
  }
  return valor;
}
