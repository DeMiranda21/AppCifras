import 'dart:io';

import 'package:appcifras/infraestrutura/publicacao/publicador_biblioteca_local.dart';

Future<void> main(List<String> argumentos) async {
  final opcoes = _lerOpcoes(argumentos);
  if (opcoes == null ||
      !opcoes.containsKey('entrada') ||
      !opcoes.containsKey('saida')) {
    stderr.writeln(
      'Uso: dart run tool/publicar_biblioteca.dart '
      '--entrada <pasta> --saida <pasta> '
      '[--geracao <id>] [--publicado-em <ISO-8601>] '
      '[--relatorio <arquivo>]',
    );
    exitCode = 64;
    return;
  }

  DateTime? publicadoEm;
  final publicadoEmTexto = opcoes['publicado-em'];
  if (publicadoEmTexto != null) {
    publicadoEm = DateTime.tryParse(publicadoEmTexto);
    if (publicadoEm == null) {
      stderr.writeln('Valor inválido para --publicado-em.');
      exitCode = 64;
      return;
    }
  }

  final saida = Directory(opcoes['saida']!);
  final relatorio = File(opcoes['relatorio'] ?? '${saida.path}.relatorio.md');
  final resultado = await PublicadorBibliotecaLocal().publicar(
    entrada: Directory(opcoes['entrada']!),
    saida: saida,
    relatorio: relatorio,
    geracao: opcoes['geracao'],
    publicadoEm: publicadoEm,
  );
  stdout.write(resultado.gerarRelatorio());
  stdout.writeln('Relatório: ${relatorio.path}');
  if (resultado.sucesso) {
    stdout.writeln('Publicação: ${saida.path}');
  } else {
    exitCode = 1;
  }
}

Map<String, String>? _lerOpcoes(List<String> argumentos) {
  if (argumentos.length.isOdd) return null;
  final resultado = <String, String>{};
  for (var indice = 0; indice < argumentos.length; indice += 2) {
    final nome = argumentos[indice];
    if (!nome.startsWith('--') || indice + 1 >= argumentos.length) {
      return null;
    }
    final chave = nome.substring(2);
    if (!const {
      'entrada',
      'saida',
      'geracao',
      'publicado-em',
      'relatorio',
    }.contains(chave)) {
      return null;
    }
    resultado[chave] = argumentos[indice + 1];
  }
  return resultado;
}
