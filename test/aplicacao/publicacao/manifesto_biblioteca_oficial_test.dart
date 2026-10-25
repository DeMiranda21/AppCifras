import 'dart:convert';

import 'package:appcifras/aplicacao/publicacao/manifesto_biblioteca_oficial.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EntradaManifestoBibliotecaOficial entrada({
    String idMusica = 'musica-1',
    String idVersao = 'versao-1',
    String? caminho,
  }) => EntradaManifestoBibliotecaOficial(
    idMusica: IdMusica(idMusica),
    idVersaoMusica: IdVersaoMusica(idVersao),
    sha256: 'a' * 64,
    tamanhoBytes: 123,
    caminho: caminho ?? 'musicas/$idVersao.cho',
  );

  ManifestoBibliotecaOficial manifesto(
    Iterable<EntradaManifestoBibliotecaOficial> arquivos,
  ) => ManifestoBibliotecaOficial(
    schema: 1,
    geracao: '20261025T120000Z',
    publicadoEm: DateTime.utc(2026, 10, 25, 12),
    arquivos: arquivos,
  );

  test('serializa e desserializa manifesto válido com uma música', () {
    final original = manifesto([entrada()]);

    final restaurado = ManifestoBibliotecaOficial.decodificar(
      original.codificar(),
    );

    expect(restaurado.schema, 1);
    expect(restaurado.geracao, '20261025T120000Z');
    expect(restaurado.publicadoEm, DateTime.utc(2026, 10, 25, 12));
    expect(restaurado.arquivos.single.idMusica.valor, 'musica-1');
    expect(restaurado.arquivos.single.idVersaoMusica.valor, 'versao-1');
    expect(restaurado.arquivos.single.tamanhoBytes, 123);
  });

  test('ordena deterministicamente por Música e Versão', () {
    final resultado = manifesto([
      entrada(idMusica: 'musica-b', idVersao: 'v-3'),
      entrada(idMusica: 'musica-a', idVersao: 'v-2'),
      entrada(idMusica: 'musica-a', idVersao: 'v-1'),
    ]);

    expect(
      resultado.arquivos.map(
        (item) => '${item.idMusica.valor}/${item.idVersaoMusica.valor}',
      ),
      ['musica-a/v-1', 'musica-a/v-2', 'musica-b/v-3'],
    );
  });

  test('rejeita schema desconhecido', () {
    expect(
      () => ManifestoBibliotecaOficial(
        schema: 2,
        geracao: 'geracao-1',
        publicadoEm: DateTime.utc(2026),
        arquivos: const [],
      ),
      throwsFormatException,
    );
  });

  test('rejeita IdVersaoMusica duplicado mesmo entre Músicas', () {
    expect(
      () => manifesto([
        entrada(idMusica: 'musica-a', idVersao: 'versao-repetida'),
        entrada(idMusica: 'musica-b', idVersao: 'versao-repetida'),
      ]),
      throwsFormatException,
    );
  });

  test('rejeita hash, tamanho e IDs inválidos ao desserializar', () {
    final base =
        jsonDecode(manifesto([entrada()]).codificar()) as Map<String, Object?>;
    final arquivo = Map<String, Object?>.from(
      (base['files'] as List<Object?>).single as Map<String, Object?>,
    );

    expect(
      () => ManifestoBibliotecaOficial.fromJson({
        ...base,
        'files': [
          {...arquivo, 'sha256': 'abc'},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ManifestoBibliotecaOficial.fromJson({
        ...base,
        'files': [
          {...arquivo, 'size': 0},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ManifestoBibliotecaOficial.fromJson({
        ...base,
        'files': [
          {...arquivo, 'idMusica': '   '},
        ],
      }),
      throwsFormatException,
    );
  });

  test('rejeita traversal, URL absoluta e separador de Windows', () {
    for (final caminho in [
      '../segredo.cho',
      'musicas/../segredo.cho',
      'https://exemplo.test/musica.cho',
      '/musicas/musica.cho',
      r'musicas\musica.cho',
      'musicas/%2e%2e/segredo.cho',
    ]) {
      expect(
        () => entrada(caminho: caminho),
        throwsFormatException,
        reason: caminho,
      );
    }
  });

  test('mantém milhares de entradas sem truncamento', () {
    final arquivos = List.generate(
      4000,
      (indice) => entrada(
        idMusica: 'musica-${indice ~/ 2}',
        idVersao: 'versao-$indice',
      ),
    );

    final restaurado = ManifestoBibliotecaOficial.decodificar(
      manifesto(arquivos).codificar(),
    );

    expect(restaurado.arquivos, hasLength(4000));
    expect(
      restaurado.arquivos.map((item) => item.idVersaoMusica.valor).toSet(),
      hasLength(4000),
    );
  });
}
