import 'dart:io';

import 'curadoria_biblioteca.dart';
import 'inventario_biblioteca.dart';

Future<void> main(List<String> argumentos) async {
  if (argumentos.contains('--inventario-global')) {
    final biblioteca = _valor(argumentos, '--biblioteca');
    if (biblioteca == null ||
        argumentos.any(
          (a) =>
              !{'--inventario-global', '--biblioteca'}.contains(a) &&
              a != biblioteca,
        )) {
      stderr.writeln(
        'Uso: dart run tool/curadoria.dart --biblioteca <pasta> --inventario-global',
      );
      exitCode = 64;
      return;
    }
    try {
      final resultado = await InventariadorBibliotecaGlobal().executar(
        Directory(biblioteca),
      );
      stdout.write(resultado.markdown);
    } catch (erro, pilha) {
      stderr
        ..writeln('Falha no inventário: $erro')
        ..writeln(pilha);
      exitCode = 1;
    }
    return;
  }
  final opcoes = _lerOpcoes(argumentos);
  if (opcoes == null) {
    stderr.writeln(
      'Uso: dart run tool/curadoria.dart --biblioteca <pasta> --lote <nome> [--simular] [--reavaliar] [--adotar-cho-editado|--substituir-cho-editado] [--detalhes]',
    );
    exitCode = 64;
    return;
  }
  try {
    final resumo = await CuradoriaBiblioteca().executar(opcoes);
    stdout
      ..writeln('Lote: ${opcoes.lote}${opcoes.simular ? ' (simulação)' : ''}')
      ..writeln('TXT: ${resumo.total}')
      ..writeln('Prontos: ${resumo.prontos}')
      ..writeln('Revisar: ${resumo.revisar}')
      ..writeln('Bloqueados: ${resumo.bloqueados}')
      ..writeln('Inalterados: ${resumo.inalterados}')
      ..writeln('Conflitos: ${resumo.conflitos}')
      ..writeln(
        'Arquivos com pares preservados em linhas separadas: '
        '${resumo.entradas.where((e) => ((e['paresPreservadosEmLinhaSeparada'] as int?) ?? 0) > 0).length}',
      )
      ..writeln(
        'Pares preservados em linhas separadas: '
        '${resumo.entradas.fold<int>(0, (soma, e) => soma + ((e['paresPreservadosEmLinhaSeparada'] as int?) ?? 0))}',
      );
    if (argumentos.contains('--detalhes')) {
      for (final entrada in resumo.entradas) {
        stdout.writeln('${entrada['nomeOrigem']} — ${entrada['status']}');
        final motivos = (entrada['motivosRevisao'] as List? ?? const []);
        for (final motivo in motivos) {
          stdout.writeln('  - $motivo');
        }
        for (final decisao
            in (entrada['decisoesLinhas'] as List? ?? const [])) {
          if (decisao is Map && decisao['estrategia'] == 'exigeRevisao') {
            stdout.writeln(
              '    linha ${decisao['linhaOrigem']}: ${decisao['conteudoOrigem']}',
            );
          }
        }
      }
    }
  } catch (erro, pilha) {
    stderr
      ..writeln('Falha ao iniciar a curadoria: $erro')
      ..writeln(pilha);
    exitCode = 1;
  }
}

OpcoesCuradoria? _lerOpcoes(List<String> argumentos) {
  String? biblioteca;
  String? lote;
  var simular = false;
  var reavaliar = false;
  var adotarChoEditado = false;
  var substituirChoEditado = false;
  for (var i = 0; i < argumentos.length; i++) {
    switch (argumentos[i]) {
      case '--biblioteca' when i + 1 < argumentos.length:
        biblioteca = argumentos[++i];
      case '--lote' when i + 1 < argumentos.length:
        lote = argumentos[++i];
      case '--simular':
        simular = true;
      case '--reavaliar':
        reavaliar = true;
      case '--adotar-cho-editado':
        adotarChoEditado = true;
      case '--substituir-cho-editado':
        substituirChoEditado = true;
      case '--detalhes':
        break;
      default:
        return null;
    }
  }
  if (biblioteca == null || lote == null) return null;
  return OpcoesCuradoria(
    biblioteca: Directory(biblioteca),
    lote: lote,
    simular: simular,
    reavaliar: reavaliar,
    adotarChoEditado: adotarChoEditado,
    substituirChoEditado: substituirChoEditado,
  );
}

String? _valor(List<String> argumentos, String opcao) {
  final indice = argumentos.indexOf(opcao);
  return indice >= 0 && indice + 1 < argumentos.length
      ? argumentos[indice + 1]
      : null;
}
