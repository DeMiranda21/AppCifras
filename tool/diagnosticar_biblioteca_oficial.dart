import 'dart:io';

import 'package:appcifras/aplicacao/biblioteca_oficial/preparar_atualizacao_biblioteca_oficial.dart';
import 'package:appcifras/aplicacao/portas/repositorio_sincronizacao.dart';
import 'package:appcifras/dominio/entidades/origem_sincronizada_versao.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/infraestrutura/http/fonte_biblioteca_oficial_http.dart';

Future<void> main(List<String> argumentos) async {
  final baseUrl = _lerOpcao(argumentos, '--base-url');
  if (baseUrl == null) {
    stderr.writeln(
      'Uso: dart run tool/diagnosticar_biblioteca_oficial.dart '
      '--base-url <https://host/base>',
    );
    exitCode = 64;
    return;
  }

  final fonte = FonteBibliotecaOficialHttp(baseUrl: baseUrl);
  try {
    final primeira = await PrepararAtualizacaoBibliotecaOficial(
      fonte,
      _RepositorioSomenteLeitura(const []),
    ).executar();
    stdout.writeln('Geração: ${primeira.geracao}');
    stdout.writeln('Publicada em: ${primeira.publicadoEm.toIso8601String()}');
    stdout.writeln(
      'Arquivos no manifesto: ${primeira.manifesto.arquivos.length}',
    );
    stdout.writeln('Arquivos baixados: ${primeira.arquivosBaixados.length}');
    stdout.writeln('Erros: ${primeira.erros.length}');
    for (final erro in primeira.erros) {
      stderr.writeln('${erro.remoto.caminho}: ${erro.falha.mensagem}');
    }
    if (primeira.erros.isNotEmpty) {
      exitCode = 1;
      return;
    }

    final origensEquivalentes = primeira.manifesto.arquivos
        .map(
          (arquivo) => OrigemSincronizadaVersao(
            idVersaoMusica: arquivo.idVersaoMusica,
            localizadorExterno: arquivo.caminho,
            hashSha256: arquivo.sha256,
            estado: EstadoOrigemSincronizada.presente,
          ),
        )
        .toList(growable: false);
    final segunda = await PrepararAtualizacaoBibliotecaOficial(
      fonte,
      _RepositorioSomenteLeitura(origensEquivalentes),
    ).executar();
    stdout.writeln(
      'Segunda preparação — inalterados: ${segunda.inalteradas.length}; '
      'downloads: ${segunda.arquivosBaixados.length}; '
      'erros: ${segunda.erros.length}',
    );
    if (segunda.arquivosBaixados.isNotEmpty || segunda.erros.isNotEmpty) {
      exitCode = 1;
    }
  } finally {
    fonte.fechar();
  }
}

String? _lerOpcao(List<String> argumentos, String nome) {
  final indice = argumentos.indexOf(nome);
  if (indice < 0 || indice + 1 >= argumentos.length) return null;
  return argumentos[indice + 1];
}

class _RepositorioSomenteLeitura implements RepositorioOrigensSincronizadas {
  const _RepositorioSomenteLeitura(this._origens);

  final List<OrigemSincronizadaVersao> _origens;

  @override
  Future<List<OrigemSincronizadaVersao>> listar() async => _origens;

  @override
  Future<OrigemSincronizadaVersao?> obterPorVersao(IdVersaoMusica id) async =>
      null;

  @override
  Future<void> salvarOrigem(OrigemSincronizadaVersao origem) =>
      throw UnsupportedError('Diagnóstico somente leitura.');

  @override
  Future<void> marcarAusente(IdVersaoMusica id) =>
      throw UnsupportedError('Diagnóstico somente leitura.');

  @override
  Future<void> marcarPresente(
    IdVersaoMusica id, {
    required String localizadorExterno,
    required String hashSha256,
  }) => throw UnsupportedError('Diagnóstico somente leitura.');

  @override
  Future<void> remover(IdVersaoMusica id) =>
      throw UnsupportedError('Diagnóstico somente leitura.');
}
