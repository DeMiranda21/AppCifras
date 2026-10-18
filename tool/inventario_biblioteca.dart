import 'dart:io';

import 'package:appcifras/aplicacao/entrada/classificador_linha_cifra_textual.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';

import 'curadoria_biblioteca.dart';

class ResultadoInventarioGlobal {
  const ResultadoInventarioGlobal({
    required this.markdown,
    required this.total,
  });

  final String markdown;
  final int total;
}

class InventariadorBibliotecaGlobal {
  final ClassificadorLinhaCifraTextual _classificador =
      ClassificadorLinhaCifraTextual();
  final ParserAcorde _parser = ParserAcorde();

  Future<ResultadoInventarioGlobal> executar(Directory biblioteca) async {
    if (!await biblioteca.exists()) {
      throw ArgumentError('Biblioteca não encontrada: ${biblioteca.path}');
    }
    final lotes = await biblioteca
        .list(followLinks: false)
        .where((item) => item is Directory && _ehLote(_nome(item.path)))
        .cast<Directory>()
        .toList();
    lotes.sort((a, b) => _nome(a.path).compareTo(_nome(b.path)));

    final itens = <_ItemInventario>[];
    final formatos = <String, int>{};
    for (final lote in lotes) {
      final arquivos = await lote
          .list(followLinks: false)
          .where((item) => item is File)
          .cast<File>()
          .toList();
      arquivos.sort((a, b) => _nome(a.path).compareTo(_nome(b.path)));
      for (final arquivo in arquivos) {
        final extensao = _extensao(arquivo.path);
        if (extensao != '.txt') {
          formatos.update(
            extensao.isEmpty ? '(sem extensão)' : extensao,
            (valor) => valor + 1,
            ifAbsent: () => 1,
          );
          continue;
        }
        itens.add(await _inspecionar(lote, arquivo));
      }
    }
    return ResultadoInventarioGlobal(
      total: itens.length,
      markdown: _relatorio(lotes, itens, formatos),
    );
  }

  Future<_ItemInventario> _inspecionar(Directory lote, File arquivo) async {
    final decodificado = detectarCodificacao(await arquivo.readAsBytes());
    final linhas = decodificado.texto.split(RegExp(r'\r\n|\n|\r'));
    var linhasAcordes = 0;
    var chordPro = false;
    var tablatura = false;
    var colchetesProblematicos = false;
    var cabecalhos = 0;
    final secoesIncomuns = <String>[];
    final acordesDesconhecidos = <String>[];
    for (final linha in linhas) {
      final limpa = linha.trim();
      if (_classificador.ehLinhaDeAcordes(linha)) linhasAcordes++;
      if (RegExp(
        r'^\{(?:title|artist|key|comment|start_of_)',
        caseSensitive: false,
      ).hasMatch(limpa)) {
        chordPro = true;
      }
      if (RegExp(r'\[[A-G][^\]]*\]').hasMatch(linha)) chordPro = true;
      if (RegExp(r'^[EADGBe]\|').hasMatch(limpa)) tablatura = true;
      if ('['.allMatches(linha).length != ']'.allMatches(linha).length) {
        colchetesProblematicos = true;
      }
      if (RegExp(
        r'^(?:tom|key|cifra)\s*:',
        caseSensitive: false,
      ).hasMatch(limpa)) {
        cabecalhos++;
      }
      final secao = RegExp(r'^([^:]{2,40}):\s*$').firstMatch(limpa);
      if (secao != null && !_classificador.ehRotuloDeSecao(limpa)) {
        secoesIncomuns.add(secao.group(1)!);
      }
      acordesDesconhecidos.addAll(_acordesDesconhecidosDaLinha(limpa));
    }
    return _ItemInventario(
      lote: _nome(lote.path),
      nome: _nome(arquivo.path),
      codificacao: decodificado.codificacao,
      vazio: decodificado.texto.trim().isEmpty,
      linhasAcordes: linhasAcordes,
      acordesDesconhecidos: acordesDesconhecidos.toSet().toList(),
      chordPro: chordPro,
      tablatura: tablatura,
      colchetesProblematicos: colchetesProblematicos,
      cabecalhos: cabecalhos,
      secoesIncomuns: secoesIncomuns.toSet().toList(),
    );
  }

  String _relatorio(
    List<Directory> lotes,
    List<_ItemInventario> itens,
    Map<String, int> formatos,
  ) {
    final codificacoes = <String, int>{};
    for (final item in itens) {
      codificacoes.update(item.codificacao, (v) => v + 1, ifAbsent: () => 1);
    }
    final porNome = <String, List<String>>{};
    final porTituloNormalizado = <String, List<String>>{};
    for (final item in itens) {
      porNome.putIfAbsent(item.nome.toLowerCase(), () => []).add(item.caminho);
      final base = _normalizar(_base(item.nome));
      porTituloNormalizado.putIfAbsent(base, () => []).add(item.caminho);
    }
    final conflitos = porNome.values.where((v) => v.length > 1).toList();
    final duplicatas = porTituloNormalizado.values
        .where((v) => v.length > 1)
        .toList();
    final buffer = StringBuffer('# Inventário global somente leitura\n\n')
      ..writeln('- Lotes encontrados: ${lotes.length}')
      ..writeln('- Arquivos TXT: ${itens.length}')
      ..writeln('- Codificações: ${_mapa(codificacoes)}')
      ..writeln(
        '- Linhas exclusivas de acordes: ${itens.fold<int>(0, (s, i) => s + i.linhasAcordes)}',
      )
      ..writeln(
        '- Arquivos aparentemente ChordPro: ${itens.where((i) => i.chordPro).length}',
      )
      ..writeln(
        '- Arquivos com tablatura: ${itens.where((i) => i.tablatura).length}',
      )
      ..writeln('- Arquivos vazios: ${itens.where((i) => i.vazio).length}')
      ..writeln(
        '- Arquivos com colchetes problemáticos: ${itens.where((i) => i.colchetesProblematicos).length}',
      )
      ..writeln(
        '- Cabeçalhos reconhecidos: ${itens.fold<int>(0, (s, i) => s + i.cabecalhos)}',
      )
      ..writeln(
        '- Conflitos exatos de nome-base entre lotes: ${conflitos.length}',
      )
      ..writeln(
        '- Possíveis duplicatas por nome normalizado: ${duplicatas.length}',
      )
      ..writeln(
        '- Formatos não cobertos: ${formatos.isEmpty ? 'nenhum' : _mapa(formatos)}',
      )
      ..writeln();
    for (final lote in lotes) {
      final nome = _nome(lote.path);
      final doLote = itens.where((i) => i.lote == nome).toList();
      buffer
        ..writeln('## $nome')
        ..writeln()
        ..writeln('- TXT: ${doLote.length}')
        ..writeln(
          '- Codificações: ${_mapa({for (final c in doLote.map((i) => i.codificacao).toSet()) c: doLote.where((i) => i.codificacao == c).length})}',
        );
      for (final item in doLote.where((i) => i.temAlerta)) {
        buffer.writeln('- ${item.nome}: ${item.alertas.join('; ')}');
      }
      buffer.writeln();
    }
    if (conflitos.isNotEmpty) {
      buffer.writeln('## Conflitos de nomes\n');
      for (final grupo in conflitos) {
        buffer.writeln('- ${grupo.join(', ')}');
      }
      buffer.writeln();
    }
    if (duplicatas.isNotEmpty) {
      buffer.writeln('## Possíveis duplicatas\n');
      for (final grupo in duplicatas) {
        buffer.writeln('- ${grupo.join(', ')}');
      }
    }
    return buffer.toString();
  }

  bool _ehLote(String nome) =>
      RegExp(r'^lote\b', caseSensitive: false).hasMatch(nome);
  List<String> _acordesDesconhecidosDaLinha(String linha) {
    if (linha.isEmpty || linha.length > 180) return const [];
    var conteudo = linha;
    final rotulo = RegExp(r'^([^:]+):\s*(.+)$').firstMatch(conteudo);
    if (rotulo != null &&
        _classificador.ehNomeDeSecao(rotulo.group(1)!.trim())) {
      conteudo = rotulo.group(2)!;
    }
    final desconhecidos = <String>[];
    var tokensMusicais = 0;
    for (final original in conteudo.split(RegExp(r'\s+'))) {
      final candidato = _removerMarcadores(original);
      if (candidato.isEmpty ||
          RegExp(
            r'^(?:x\d+|\d+x)$',
            caseSensitive: false,
          ).hasMatch(candidato)) {
        continue;
      }
      if (_parser.interpretar(candidato) is AcordeInterpretado) {
        tokensMusicais++;
      } else if (_pareceAcorde(candidato)) {
        tokensMusicais++;
        desconhecidos.add(candidato);
      } else {
        return const [];
      }
    }
    return tokensMusicais == 0 ? const [] : desconhecidos;
  }

  String _removerMarcadores(String original) {
    var token = original.replaceAll(RegExp(r'^[,\[]+|[,\]]+$'), '');
    if (token == '(' || token == ')') return '';
    if (token.startsWith('(')) token = token.substring(1);
    final abre = '('.allMatches(token).length;
    final fecha = ')'.allMatches(token).length;
    if (token.endsWith(')') && fecha > abre) {
      token = token.substring(0, token.length - 1);
    }
    return token;
  }

  bool _pareceAcorde(String token) =>
      RegExp(r'^[A-G][#b]?[A-Za-z0-9+#/()º°-]*$').hasMatch(token);
  String _mapa(Map<String, int> mapa) =>
      (mapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
  String _nome(String caminho) => caminho.split(RegExp(r'[\\/]')).last;
  String _extensao(String caminho) {
    final nome = _nome(caminho);
    final ponto = nome.lastIndexOf('.');
    return ponto < 0 ? '' : nome.substring(ponto).toLowerCase();
  }

  String _base(String nome) {
    final ponto = nome.lastIndexOf('.');
    return ponto < 0 ? nome : nome.substring(0, ponto);
  }

  String _normalizar(String valor) => valor
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

class _ItemInventario {
  const _ItemInventario({
    required this.lote,
    required this.nome,
    required this.codificacao,
    required this.vazio,
    required this.linhasAcordes,
    required this.acordesDesconhecidos,
    required this.chordPro,
    required this.tablatura,
    required this.colchetesProblematicos,
    required this.cabecalhos,
    required this.secoesIncomuns,
  });
  final String lote;
  final String nome;
  final String codificacao;
  final bool vazio;
  final int linhasAcordes;
  final List<String> acordesDesconhecidos;
  final bool chordPro;
  final bool tablatura;
  final bool colchetesProblematicos;
  final int cabecalhos;
  final List<String> secoesIncomuns;
  String get caminho => '$lote/$nome';
  bool get temAlerta => alertas.isNotEmpty;
  List<String> get alertas => [
    if (vazio) 'arquivo vazio',
    if (acordesDesconhecidos.isNotEmpty)
      'acordes desconhecidos: ${acordesDesconhecidos.join(', ')}',
    if (chordPro) 'conteúdo já parece ChordPro',
    if (tablatura) 'tablatura',
    if (colchetesProblematicos) 'colchetes problemáticos',
    if (secoesIncomuns.isNotEmpty)
      'seções incomuns: ${secoesIncomuns.join(', ')}',
  ];
}
