import 'dart:convert';
import 'dart:io';

class OverrideCuradoriaArquivo {
  const OverrideCuradoriaArquivo({
    this.titulo,
    this.artista,
    this.tom,
    this.nomeVersao,
    this.decisaoDuplicidade,
    this.idMusicaCompartilhado,
    this.principal,
    this.aprovado,
    this.observacao,
  });

  final String? titulo;
  final String? artista;
  final String? tom;
  final String? nomeVersao;
  final String? decisaoDuplicidade;
  final String? idMusicaCompartilhado;
  final bool? principal;
  final bool? aprovado;
  final String? observacao;

  bool get vazio =>
      titulo == null &&
      artista == null &&
      tom == null &&
      nomeVersao == null &&
      decisaoDuplicidade == null &&
      idMusicaCompartilhado == null &&
      principal == null &&
      aprovado == null &&
      observacao == null;
}

class OverridesCuradoria {
  const OverridesCuradoria._(this._porOrigem);

  static const vazio = OverridesCuradoria._({});

  final Map<String, OverrideCuradoriaArquivo> _porOrigem;

  OverrideCuradoriaArquivo? paraOrigem(String origem) => _porOrigem[origem];

  static Future<OverridesCuradoria> carregar(Directory biblioteca) async {
    final arquivo = File(
      '${biblioteca.path}${Platform.pathSeparator}curadoria_overrides.json',
    );
    if (!await arquivo.exists()) return vazio;
    late final Object? decodificado;
    try {
      decodificado = jsonDecode(await arquivo.readAsString());
    } on FormatException catch (erro) {
      throw FormatException('curadoria_overrides.json inválido: $erro');
    }
    if (decodificado is! Map<String, dynamic> ||
        decodificado['schema'] != 1 ||
        decodificado['overrides'] is! Map) {
      throw const FormatException(
        'curadoria_overrides.json deve conter schema 1 e objeto overrides.',
      );
    }
    final resultado = <String, OverrideCuradoriaArquivo>{};
    final mapa = Map<String, dynamic>.from(decodificado['overrides'] as Map);
    for (final entrada in mapa.entries) {
      final origem = entrada.key;
      if (origem.startsWith('/') ||
          origem.startsWith('\\') ||
          origem.contains('..') ||
          !origem.toLowerCase().endsWith('.txt') ||
          entrada.value is! Map) {
        throw FormatException('Origem inválida em overrides: $origem');
      }
      final dados = Map<String, dynamic>.from(entrada.value as Map);
      const permitidos = {
        'titulo',
        'artista',
        'tom',
        'nomeVersao',
        'decisaoDuplicidade',
        'idMusicaCompartilhado',
        'principal',
        'aprovado',
        'observacao',
      };
      final desconhecidos = dados.keys.where(
        (chave) => !permitidos.contains(chave),
      );
      if (desconhecidos.isNotEmpty) {
        throw FormatException(
          'Campos desconhecidos no override de $origem: ${desconhecidos.join(', ')}',
        );
      }
      String? texto(String campo) {
        final valor = dados[campo];
        if (valor == null) return null;
        if (valor is! String || valor.trim().isEmpty) {
          throw FormatException('$campo inválido no override de $origem.');
        }
        return valor.trim();
      }

      bool? booleano(String campo) {
        final valor = dados[campo];
        if (valor == null) return null;
        if (valor is! bool) {
          throw FormatException(
            '$campo deve ser booleano no override de $origem.',
          );
        }
        return valor;
      }

      final tom = texto('tom');
      if (tom != null && !RegExp(r'^[A-G](?:[#b])?m?$').hasMatch(tom)) {
        throw FormatException('Tom inválido no override de $origem.');
      }
      final idCompartilhado = texto('idMusicaCompartilhado');
      if (idCompartilhado != null &&
          !RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            caseSensitive: false,
          ).hasMatch(idCompartilhado)) {
        throw FormatException(
          'idMusicaCompartilhado inválido no override de $origem.',
        );
      }
      final override = OverrideCuradoriaArquivo(
        titulo: texto('titulo'),
        artista: texto('artista'),
        tom: tom,
        nomeVersao: texto('nomeVersao'),
        decisaoDuplicidade: texto('decisaoDuplicidade'),
        idMusicaCompartilhado: idCompartilhado,
        principal: booleano('principal'),
        aprovado: booleano('aprovado'),
        observacao: texto('observacao'),
      );
      if (!override.vazio) resultado[origem] = override;
    }
    return OverridesCuradoria._(Map.unmodifiable(resultado));
  }
}
