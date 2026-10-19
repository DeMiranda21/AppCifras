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

  static Future<OverridesCuradoria> carregar(
    Directory biblioteca, {
    Iterable<File> adicionais = const [],
  }) async {
    final arquivoBase = File(
      '${biblioteca.path}${Platform.pathSeparator}curadoria_overrides.json',
    );
    final arquivos = <File>[
      if (await arquivoBase.exists()) arquivoBase,
      ...adicionais,
    ];
    if (arquivos.isEmpty) return vazio;
    final resultado = <String, OverrideCuradoriaArquivo>{};
    final fontes = <String, String>{};
    for (final arquivo in arquivos) {
      if (!await arquivo.exists()) {
        throw ArgumentError(
          'Arquivo de overrides não encontrado: ${arquivo.path}',
        );
      }
      final lidos = await _carregarArquivo(arquivo);
      for (final entrada in lidos.entries) {
        final anterior = resultado[entrada.key];
        if (anterior == null) {
          resultado[entrada.key] = entrada.value;
          fontes[entrada.key] = arquivo.path;
          continue;
        }
        resultado[entrada.key] = _combinar(
          entrada.key,
          anterior,
          entrada.value,
          fontes[entrada.key]!,
          arquivo.path,
        );
      }
    }
    return OverridesCuradoria._(Map.unmodifiable(resultado));
  }

  static Future<Map<String, OverrideCuradoriaArquivo>> _carregarArquivo(
    File arquivo,
  ) async {
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
    return resultado;
  }

  static OverrideCuradoriaArquivo _combinar(
    String origem,
    OverrideCuradoriaArquivo base,
    OverrideCuradoriaArquivo adicional,
    String fonteBase,
    String fonteAdicional,
  ) {
    T? campo<T>(String nome, T? a, T? b) {
      if (a != null && b != null && a != b) {
        throw FormatException(
          'Conflito no campo $nome do override $origem entre '
          '$fonteBase e $fonteAdicional.',
        );
      }
      return b ?? a;
    }

    return OverrideCuradoriaArquivo(
      titulo: campo('titulo', base.titulo, adicional.titulo),
      artista: campo('artista', base.artista, adicional.artista),
      tom: campo('tom', base.tom, adicional.tom),
      nomeVersao: campo('nomeVersao', base.nomeVersao, adicional.nomeVersao),
      decisaoDuplicidade: campo(
        'decisaoDuplicidade',
        base.decisaoDuplicidade,
        adicional.decisaoDuplicidade,
      ),
      idMusicaCompartilhado: campo(
        'idMusicaCompartilhado',
        base.idMusicaCompartilhado,
        adicional.idMusicaCompartilhado,
      ),
      principal: campo('principal', base.principal, adicional.principal),
      aprovado: campo('aprovado', base.aprovado, adicional.aprovado),
      observacao: campo('observacao', base.observacao, adicional.observacao),
    );
  }
}
