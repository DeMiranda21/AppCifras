import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/curadoria_biblioteca.dart';
import '../../tool/politica_melhor_tom.dart';
import '../../tool/politica_relativo_maior.dart';

void main() {
  late Directory biblioteca;

  setUp(() async {
    biblioteca = await Directory.systemTemp.createTemp('curadoria-seletiva-');
  });

  tearDown(() async {
    if (await biblioteca.exists()) {
      await biblioteca.delete(recursive: true);
    }
  });

  test(
    'seleciona uma origem e mantém origem, CHO e manifesto não selecionados',
    () async {
      await _prepararLote(biblioteca, 'Lote 04', ['Uma', 'Outra']);
      final manifestoAntes = await _manifesto(biblioteca);
      final outraAntes = _entrada(manifestoAntes, 'Lote 04/Outra.txt');
      final txtOutra = await _arquivoOrigem(
        biblioteca,
        'Lote 04/Outra.txt',
      ).readAsBytes();
      final choOutra = await _arquivoDestino(
        biblioteca,
        outraAntes,
      ).readAsBytes();
      final relatorio = File(_caminho(biblioteca.path, 'relatorio.md'));
      final relatorioAntes = await relatorio.readAsBytes();
      await _habilitarPolitica(biblioteca);

      final resumo = await _executar(biblioteca, ['Lote 04/Uma.txt']);

      expect(resumo.totalSelecionadas, 1);
      expect(resumo.processadas, 1);
      expect(resumo.entradas.single['origem'], 'Lote 04/Uma.txt');
      expect(
        await _arquivoOrigem(biblioteca, 'Lote 04/Outra.txt').readAsBytes(),
        txtOutra,
      );
      expect(
        await _arquivoDestino(biblioteca, outraAntes).readAsBytes(),
        choOutra,
      );
      final manifestoDepois = await _manifesto(biblioteca);
      expect(
        jsonEncode(_entrada(manifestoDepois, 'Lote 04/Outra.txt')),
        jsonEncode(outraAntes),
      );
      expect(await relatorio.readAsBytes(), relatorioAntes);
    },
  );

  test(
    'seleção pode cruzar lotes e o resumo contém somente selecionadas',
    () async {
      await _prepararLote(biblioteca, 'Lote 04', ['Quatro', 'Fora']);
      await _prepararLote(biblioteca, 'Lote 05', ['Cinco']);
      await _habilitarPolitica(biblioteca);

      final resumo = await _executar(biblioteca, [
        'Lote 05/Cinco.txt',
        'Lote 04/Quatro.txt',
      ]);

      expect(resumo.totalSelecionadas, 2);
      expect(resumo.entradas.map((e) => e['origem']), [
        'Lote 04/Quatro.txt',
        'Lote 05/Cinco.txt',
      ]);
      expect(
        resumo.entradas.map((e) => e['origem']),
        isNot(contains('Lote 04/Fora.txt')),
      );
    },
  );

  test('rejeita origem duplicada antes de alterar estado', () async {
    await _prepararLote(biblioteca, 'Lote 04', ['Uma']);
    final antes = await _fotografar(biblioteca);
    await expectLater(
      _executar(biblioteca, ['Lote 04/Uma.txt', 'Lote 04/Uma.txt']),
      throwsArgumentError,
    );
    expect(await _fotografar(biblioteca), antes);
  });

  test('rejeita origem inexistente', () async {
    await _prepararLote(biblioteca, 'Lote 04', ['Uma']);
    await expectLater(
      _executar(biblioteca, ['Lote 04/Inexistente.txt']),
      throwsArgumentError,
    );
  });

  test('rejeita tentativa de sair da biblioteca', () async {
    await _prepararLote(biblioteca, 'Lote 04', ['Uma']);
    await expectLater(
      _executar(biblioteca, ['../fora.txt']),
      throwsArgumentError,
    );
  });

  test(
    'retoma interrupção entre CHO e manifesto e repetição é idempotente',
    () async {
      await _prepararLote(biblioteca, 'Lote 04', ['Parcial']);
      await _habilitarPolitica(biblioteca);
      var interromper = true;
      final arquivoLista = await _lista(biblioteca, ['Lote 04/Parcial.txt']);
      final opcoes = OpcoesCuradoriaSeletiva(
        biblioteca: biblioteca,
        origensArquivo: arquivoLista,
      );
      final curadoria = CuradoriaBiblioteca(
        depoisDePersistirChoSeletivo: (origem) async {
          if (interromper) {
            interromper = false;
            throw StateError('interrupção sintética');
          }
        },
      );

      await expectLater(curadoria.executarSeletivo(opcoes), throwsStateError);
      expect(
        _entrada(await _manifesto(biblioteca), 'Lote 04/Parcial.txt')['status'],
        'revisar',
      );
      final checkpointParcial = jsonDecode(
        await File(
          _caminho(biblioteca.path, '.curadoria-seletiva-checkpoint.json'),
        ).readAsString(),
      ) as Map;
      expect((checkpointParcial['pendente'] as Map)['fase'], 'cho_persistido');

      final retomada = await CuradoriaBiblioteca().executarSeletivo(opcoes);
      expect(retomada.processadas, 1);
      expect(retomada.entradas.single['status'], 'pronto');
      final manifestoAposRetomada = await _manifesto(biblioteca);
      final fotoAposRetomada = await _fotografar(biblioteca);

      final repetida = await CuradoriaBiblioteca().executarSeletivo(opcoes);
      expect(repetida.processadas, 0);
      expect(repetida.ignoradas, 1);
      expect(
        jsonEncode(await _manifesto(biblioteca)),
        jsonEncode(manifestoAposRetomada),
      );
      final fotoRepetida = await _fotografar(biblioteca);
      for (final caminho in fotoAposRetomada.keys.where(
        (p) => p.endsWith('.cho'),
      )) {
        expect(fotoRepetida[caminho], fotoAposRetomada[caminho]);
      }
    },
  );

  test(
    'origem concluída sem checkpoint seletivo é reconhecida e ignorada',
    () async {
      await _habilitarPolitica(biblioteca);
      await _prepararLote(biblioteca, 'Lote 04', ['Concluida']);
      final relatorio = File(_caminho(biblioteca.path, 'relatorio.md'));
      final relatorioAntes = await relatorio.readAsBytes();

      final resumo = await _executar(biblioteca, ['Lote 04/Concluida.txt']);

      expect(resumo.processadas, 0);
      expect(resumo.ignoradas, 1);
      expect(await relatorio.readAsBytes(), relatorioAntes);
    },
  );

  test('modo seletivo não calibra nem regenera relatório global', () async {
    await _prepararLote(biblioteca, 'Lote 04', ['SemCalibracao']);
    await _habilitarPolitica(biblioteca);
    final relatorio = File(_caminho(biblioteca.path, 'relatorio.md'));
    final relatorioAntes = await relatorio.readAsBytes();
    final lista = await _lista(biblioteca, ['Lote 04/SemCalibracao.txt']);
    final curadoria = CuradoriaBiblioteca(
      calibradorTonal: (_) => throw StateError('calibração indevida'),
    );

    final resumo = await curadoria.executarSeletivo(
      OpcoesCuradoriaSeletiva(biblioteca: biblioteca, origensArquivo: lista),
    );

    expect(resumo.processadas, 1);
    expect(await relatorio.readAsBytes(), relatorioAntes);
  });

  test(
    'política tonal processa somente a origem explicitamente selecionada',
    () async {
      await _prepararLote(biblioteca, 'Lote 04', ['Selecionada', 'Fora']);
      final lista = await _lista(biblioteca, ['Lote 04/Selecionada.txt']);
      final antes = await _fotografar(biblioteca);

      final resumo = await CuradoriaBiblioteca().executarSeletivo(
        OpcoesCuradoriaSeletiva(
          biblioteca: biblioteca,
          origensArquivo: lista,
          simular: true,
          configuracao: _configuracaoMelhorTom,
        ),
      );

      expect(resumo.entradas, hasLength(1));
      expect(resumo.entradas.single['origem'], 'Lote 04/Selecionada.txt');
      expect(resumo.entradas.single['status'], 'pronto');
      expect(resumo.entradas.single['origemTom'], 'politica_melhor_tom');
      expect(await _fotografar(biblioteca), antes);
    },
  );

  test(
    'outra pendência impede política tonal antes de qualquer escrita',
    () async {
      final lote = Directory(_caminho(biblioteca.path, 'Lote 04'));
      await lote.create(recursive: true);
      await File(_caminho(lote.path, 'Ambigua.txt')).writeAsString(
        'Ambígua - Artista\n[Am]a [F]b [G]c [C]d [Am]e\nlinha [incompleta',
      );
      await CuradoriaBiblioteca().executar(
        OpcoesCuradoria(biblioteca: biblioteca, lote: 'Lote 04'),
      );
      final lista = await _lista(biblioteca, ['Lote 04/Ambigua.txt']);
      final antes = await _fotografar(biblioteca);

      await expectLater(
        CuradoriaBiblioteca().executarSeletivo(
          OpcoesCuradoriaSeletiva(
            biblioteca: biblioteca,
            origensArquivo: lista,
            configuracao: _configuracaoMelhorTom,
          ),
        ),
        throwsStateError,
      );
      expect(await _fotografar(biblioteca), antes);
    },
  );

  test('tom explícito e override prevalecem sobre política tonal', () async {
    final lote = Directory(_caminho(biblioteca.path, 'Lote 04'));
    await lote.create(recursive: true);
    await File(
      _caminho(lote.path, 'Explicita.txt'),
    ).writeAsString('Explícita - Artista\nTom: F\n[Am]a [F]b [G]c [C]d [Am]e');
    await File(_caminho(lote.path, 'Override.txt'))
        .writeAsString('Override - Artista\n[Am]a [F]b [G]c [C]d [Am]e');
    final override = File(_caminho(biblioteca.path, 'adicional.json'));
    await override.writeAsString(
      jsonEncode({
        'schema': 1,
        'overrides': {
          'Lote 04/Override.txt': {'tom': 'D'},
        },
      }),
    );

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(
        biblioteca: biblioteca,
        lote: 'Lote 04',
        simular: true,
        configuracao: _configuracaoMelhorTom,
        arquivosOverridesAdicionais: [override],
      ),
    );
    final explicita = resumo.entradas.singleWhere(
      (e) => e['origem'] == 'Lote 04/Explicita.txt',
    );
    final sobrescrita = resumo.entradas.singleWhere(
      (e) => e['origem'] == 'Lote 04/Override.txt',
    );

    expect(explicita['tom'], 'F');
    expect(explicita['origemTom'], 'declarado');
    expect(sobrescrita['tom'], 'D');
    expect(sobrescrita['origemTom'], 'override');
  });

  test('política tonal mantém retomada segura após interrupção', () async {
    await _prepararLote(biblioteca, 'Lote 04', ['Retomavel']);
    final lista = await _lista(biblioteca, ['Lote 04/Retomavel.txt']);
    final opcoes = OpcoesCuradoriaSeletiva(
      biblioteca: biblioteca,
      origensArquivo: lista,
      configuracao: _configuracaoMelhorTom,
    );
    var interromper = true;
    final curadoria = CuradoriaBiblioteca(
      depoisDePersistirChoSeletivo: (_) async {
        if (interromper) {
          interromper = false;
          throw StateError('interrupção sintética');
        }
      },
    );

    await expectLater(curadoria.executarSeletivo(opcoes), throwsStateError);
    final retomada = await CuradoriaBiblioteca().executarSeletivo(opcoes);

    expect(retomada.processadas, 1);
    expect(retomada.entradas.single['status'], 'pronto');
    expect(retomada.entradas.single['origemTom'], 'politica_melhor_tom');

    final repetida = await CuradoriaBiblioteca().executarSeletivo(opcoes);
    expect(repetida.processadas, 0);
    expect(repetida.ignoradas, 1);
    expect(repetida.entradas.single['status'], 'pronto');
  });
}

const _configuracaoMelhorTom = ConfiguracaoCuradoria(
  politicaMelhorTom: ConfiguracaoPoliticaMelhorTom(habilitada: true),
);

Future<void> _prepararLote(
  Directory biblioteca,
  String lote,
  List<String> nomes,
) async {
  final pasta = Directory(_caminho(biblioteca.path, lote));
  await pasta.create(recursive: true);
  for (final nome in nomes) {
    await File(_caminho(pasta.path, '$nome.txt'))
        .writeAsString('$nome - Artista\n[Am]a [F]b [G]c [C]d [Am]e');
  }
  await CuradoriaBiblioteca().executar(
    OpcoesCuradoria(biblioteca: biblioteca, lote: lote),
  );
}

Future<void> _habilitarPolitica(Directory biblioteca) =>
    File(_caminho(biblioteca.path, 'curadoria_config.json')).writeAsString(
      jsonEncode({
        'schema': 1,
        'politica_relativo_maior': {
          'habilitada': true,
          'margem_terceiro_competitivo': 4,
          'minimo_acordes': 4,
        },
      }),
    );

Future<ResumoCuradoriaSeletiva> _executar(
  Directory biblioteca,
  List<String> origens,
) async {
  final arquivo = await _lista(biblioteca, origens);
  return CuradoriaBiblioteca().executarSeletivo(
    OpcoesCuradoriaSeletiva(biblioteca: biblioteca, origensArquivo: arquivo),
  );
}

Future<File> _lista(Directory biblioteca, List<String> origens) async {
  final arquivo = File(_caminho(biblioteca.path, 'selecionadas.txt'));
  await arquivo.writeAsString('${origens.join('\n')}\n');
  return arquivo;
}

Future<Map<String, Object?>> _manifesto(Directory biblioteca) async =>
    Map<String, Object?>.from(
      jsonDecode(
        await File(_caminho(biblioteca.path, 'manifest.json')).readAsString(),
      ) as Map,
    );

Map<String, Object?> _entrada(Map<String, Object?> manifesto, String origem) =>
    Map<String, Object?>.from(
      (manifesto['entradas'] as List).cast<Map>().singleWhere(
        (e) => e['origem'] == origem,
      ),
    );

File _arquivoOrigem(Directory biblioteca, String origem) => File(
  _caminho(biblioteca.path, origem.replaceAll('/', Platform.pathSeparator)),
);

File _arquivoDestino(Directory biblioteca, Map<String, Object?> entrada) =>
    File(
      _caminho(
        biblioteca.path,
        (entrada['destino'] as String).replaceAll('/', Platform.pathSeparator),
      ),
    );

Future<Map<String, List<int>>> _fotografar(Directory raiz) async {
  final resultado = <String, List<int>>{};
  await for (final item in raiz.list(recursive: true, followLinks: false)) {
    if (item is File && !item.path.endsWith('selecionadas.txt')) {
      resultado[item.path.substring(raiz.path.length)] = await item
          .readAsBytes();
    }
  }
  return resultado;
}

String _caminho(String a, String b) =>
    '${a.replaceAll(RegExp(r'[\\/]+$'), '')}${Platform.pathSeparator}$b';
