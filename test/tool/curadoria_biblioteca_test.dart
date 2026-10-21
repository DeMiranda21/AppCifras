import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../../tool/curadoria_biblioteca.dart';
import '../../tool/conversor_curadoria.dart';
import '../../tool/inventario_biblioteca.dart';

void main() {
  late Directory temporaria;

  setUp(() async {
    temporaria = await Directory.systemTemp.createTemp('appcifras_curadoria_');
  });

  tearDown(() async {
    if (await temporaria.exists()) await temporaria.delete(recursive: true);
  });

  test('detecta UTF-8 e Windows-1252 sem substituir caracteres', () {
    expect(detectarCodificacao(utf8.encode('Canção')).codificacao, 'utf-8');
    final legado = detectarCodificacao([0x43, 0x61, 0x6e, 0xe7, 0xe3, 0x6f]);
    expect(legado.texto, 'Canção');
    expect(legado.codificacao, 'windows-1252');
    expect(legado.requerRevisao, isTrue);
  });

  test(
    'processa arquivos isoladamente, mantém nomes e gera schema 2',
    () async {
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}Lote 02',
      );
      await lote.create();
      await File(
        '${lote.path}${Platform.pathSeparator}Canção.txt',
      ).writeAsString('Canção - Artista\n\nTom: [C]\n\nC       G\nLetra longa');
      await File('${lote.path}${Platform.pathSeparator}Sem artista.txt')
          .writeAsString('Sem artista\n\nTom: C\n\nC\nLetra');

      final resumo = await CuradoriaBiblioteca(uuid: const Uuid())
          .executar(OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'));

      expect(resumo.total, 2);
      expect(resumo.bloqueados, 1);
      final saidas = await temporaria
          .list(recursive: true)
          .where((e) => e.path.endsWith('.cho'))
          .cast<File>()
          .toList();
      expect(saidas, hasLength(1));
      expect(saidas.single.path, endsWith('Canção.cho'));
      final cho = await saidas.single.readAsString();
      expect(cho, contains('{appcifras_schema:2}'));
      expect(cho, contains('{title:Canção}'));
      expect(cho, contains('[C]Letra [G]longa'));
    },
  );

  test('retoma pelo hash e conserva UUIDs', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    final origem = File('${lote.path}${Platform.pathSeparator}Uma.txt');
    await origem.writeAsString('Uma - Pessoa\nTom: D\nD\nTexto');
    final curadoria = CuradoriaBiblioteca(uuid: const Uuid());
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final primeiro = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final id = primeiro['entradas'][0]['idMusica'];

    final segunda = await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final manifesto = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    expect(segunda.inalterados, 1);
    expect(manifesto['entradas'][0]['idMusica'], id);
  });

  test('detecta conflito de nome sem sobrescrever arquivo existente', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    final prontos = Directory(
      '${temporaria.path}${Platform.pathSeparator}prontos',
    );
    await lote.create();
    await prontos.create();
    await File('${prontos.path}${Platform.pathSeparator}Mesmo.cho')
        .writeAsString('sentinela');
    await File('${lote.path}${Platform.pathSeparator}Mesmo.txt')
        .writeAsString('Mesmo - Artista\nTom: C\nC\nTexto');

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    expect(
      resumo.bloqueados,
      1,
      reason: await File(
        '${temporaria.path}${Platform.pathSeparator}manifest.json',
      ).readAsString(),
    );
    expect(
      await File('${prontos.path}${Platform.pathSeparator}Mesmo.cho')
          .readAsString(),
      'sentinela',
    );
  });

  test('comparação semântica aceita movimentação segura dos acordes', () {
    final comparacao = CuradoriaBiblioteca().compararSemantica(
      'C       G\nLetra longa',
      '[C]Letra [G]longa',
    );
    expect(comparacao.equivalente, isTrue);
    expect(comparacao.acordesOrigem, 2);
    expect(comparacao.acordesDestino, 2);
  });

  test('comparação ignora transformação estrutural esperada', () {
    final curadoria = CuradoriaBiblioteca();
    final secao = curadoria.compararSemantica(
      '[Intro] ( [C] [G] ) x2',
      '{comment: [Intro]}\n( [C] [G] ) x2',
    );
    final instrumental = curadoria.compararSemantica(
      'Intro: D E A B C G',
      '{comment: [Intro]}\n[D] [E] [A] [B] [C] [G]',
    );

    expect(secao.equivalente, isTrue);
    expect(instrumental.equivalente, isTrue);
  });

  test('comparação detecta palavra removida e acorde alterado', () {
    final curadoria = CuradoriaBiblioteca();
    expect(
      curadoria
          .compararSemantica('[C]Uma frase inteira', '[C]Uma frase')
          .equivalente,
      isFalse,
    );
    expect(
      curadoria.compararSemantica('[C]Uma frase', '[D]Uma frase').equivalente,
      isFalse,
    );
  });

  test(
    'Windows-1252 inequívoco é observação técnica e pode ficar pronto',
    () async {
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}Lote 02',
      );
      await lote.create();
      await File('${lote.path}${Platform.pathSeparator}Canção.txt')
          .writeAsBytes([
            ...ascii.encode('Can'),
            0xe7,
            0xe3,
            ...ascii.encode('o - Artista\nTom: C\nC\nLetra'),
          ]);

      final resumo = await CuradoriaBiblioteca().executar(
        OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
      );
      final manifesto = jsonDecode(
        await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
            .readAsString(),
      ) as Map<String, dynamic>;

      expect(resumo.prontos, 1);
      expect(manifesto['entradas'][0]['codificacaoOrigem'], 'windows-1252');
      expect(manifesto['entradas'][0]['motivosRevisao'], isEmpty);
    },
  );

  test('usa artista evidenciado no nome do arquivo', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Tu es - FHOP.txt')
        .writeAsString('Tu És / Águas Purificadoras\nTom: D\nD\nLetra');

    await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final manifesto = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;

    expect(manifesto['entradas'][0]['artista'], 'FHOP');
    expect(manifesto['entradas'][0]['status'], 'pronto');
  });

  test('movimenta saída reclassificada e preserva UUIDs', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    final origem = File('${lote.path}${Platform.pathSeparator}Mover.txt');
    await origem.writeAsString('Mover - Artista\nTom: C\nC\nLetra');
    final curadoria = CuradoriaBiblioteca();
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final antes = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final idMusica = antes['entradas'][0]['idMusica'];
    final idVersao = antes['entradas'][0]['idVersaoMusica'];

    await origem.writeAsString(
      'Mover - Artista\nTom: C\nC\nLetra com [colchete quebrado',
    );
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final depois = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;

    expect(depois['entradas'][0]['idMusica'], idMusica);
    expect(depois['entradas'][0]['idVersaoMusica'], idVersao);
    expect(depois['entradas'][0]['status'], 'revisar');
    expect(
      await File(
        '${temporaria.path}${Platform.pathSeparator}prontos${Platform.pathSeparator}Mover.cho',
      ).exists(),
      isFalse,
    );
    expect(
      await File(
        '${temporaria.path}${Platform.pathSeparator}revisar${Platform.pathSeparator}Mover.cho',
      ).exists(),
      isTrue,
    );

    await origem.writeAsString('Mover - Artista\nTom: C\nC\nLetra');
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', reavaliar: true),
    );
    expect(
      await File(
        '${temporaria.path}${Platform.pathSeparator}revisar${Platform.pathSeparator}Mover.cho',
      ).exists(),
      isFalse,
    );
    expect(
      await File(
        '${temporaria.path}${Platform.pathSeparator}prontos${Platform.pathSeparator}Mover.cho',
      ).exists(),
      isTrue,
    );
  });

  test('falha em um arquivo não interrompe os demais', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Inválido.txt')
        .writeAsBytes([0x41, 0x00, 0x42]);
    await File('${lote.path}${Platform.pathSeparator}Válido.txt')
        .writeAsString('Válido - Artista\nTom: E\nE\nLetra');

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );

    expect(resumo.total, 2);
    expect(resumo.bloqueados, 1);
    expect(
      await File(
        '${temporaria.path}${Platform.pathSeparator}prontos${Platform.pathSeparator}Válido.cho',
      ).exists(),
      isTrue,
    );
  });

  test('preserva acordes separados quando a posição não é segura', () {
    final resultado = ConversorCuradoriaConservador().converter(
      'C          G\nOi',
    );

    expect(resultado.chordPro, '[C] [G]\nOi');
    expect(resultado.motivosRevisao, isEmpty);
    expect(resultado.paresPreservadosEmLinhaSeparada, 1);
    expect(
      resultado.decisoes.first.estrategia,
      EstrategiaLinhaCuradoria.preservadaEmLinhaSeparada,
    );
  });

  test('preserva separados quando acordes convergem na mesma posição', () {
    final resultado = ConversorCuradoriaConservador().converter(
      'C   G\nPalavra',
    );
    expect(resultado.chordPro, '[C] [G]\nPalavra');
    expect(resultado.motivosRevisao, isEmpty);
    expect(resultado.paresPreservadosEmLinhaSeparada, 1);
  });

  test('preserva linha instrumental, tablatura e espaços da letra', () {
    final resultado = ConversorCuradoriaConservador().converter(
      'C G Am F\n\nE|--0--|\n  verso   curto',
    );

    expect(resultado.chordPro, contains('[C] [G] [Am] [F]'));
    expect(resultado.chordPro, contains('E|--0--|'));
    expect(resultado.chordPro, contains('  verso   curto'));
    expect(resultado.motivosRevisao, isEmpty);
    final anotada = ConversorCuradoriaConservador().converter('( B  E ) x2');
    expect(anotada.chordPro, '( [B] [E] ) x2');
    expect(anotada.motivosRevisao, isEmpty);
    expect(
      CuradoriaBiblioteca()
          .compararSemantica('( B  E ) x2', anotada.chordPro)
          .equivalente,
      isTrue,
    );
  });

  test('mistura ambígua de acordes e texto exige revisão', () {
    final resultado = ConversorCuradoriaConservador().converter(
      'C palavra G outra',
    );
    expect(resultado.motivosRevisao, isNotEmpty);
    expect(
      resultado.decisoes.single.estrategia,
      EstrategiaLinhaCuradoria.exigeRevisao,
    );
  });

  test('token de acorde inválido e colchetes malformados exigem revisão', () {
    final conversor = ConversorCuradoriaConservador();
    expect(conversor.converter('H7').motivosRevisao, isNotEmpty);
    expect(
      conversor.converter('Letra [C').motivosRevisao,
      contains('Colchetes malformados na linha 1.'),
    );
  });

  test('CHO editado manualmente não é sobrescrito sem opção explícita', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Manual.txt')
        .writeAsString('Manual - Artista\nTom: C\nC\nLetra');
    final curadoria = CuradoriaBiblioteca();
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final cho = File(
      '${temporaria.path}${Platform.pathSeparator}prontos${Platform.pathSeparator}Manual.cho',
    );
    await cho.writeAsString('edição humana');

    final resultado = await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', reavaliar: true),
    );

    expect(await cho.readAsString(), 'edição humana');
    expect(resultado.conflitos, 1);
    expect(resultado.entradas.single['conflitoChoEditado'], isTrue);
  });

  test('adoção explícita registra o hash da edição humana', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Adotar.txt')
        .writeAsString('Adotar - Artista\nTom: C\nC\nLetra');
    final curadoria = CuradoriaBiblioteca();
    await curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final cho = File(
      '${temporaria.path}${Platform.pathSeparator}prontos${Platform.pathSeparator}Adotar.cho',
    );
    await cho.writeAsString('edição humana adotada');
    await curadoria.executar(
      OpcoesCuradoria(
        biblioteca: temporaria,
        lote: 'Lote 02',
        reavaliar: true,
        adotarChoEditado: true,
      ),
    );
    final manifesto = jsonDecode(
      await File('${temporaria.path}${Platform.pathSeparator}manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;

    expect(await cho.readAsString(), 'edição humana adotada');
    expect(manifesto['entradas'][0]['conflitoChoEditado'], isFalse);
    expect(manifesto['entradas'][0]['hashChoGerado'], hasLength(64));
  });

  test('override é aplicado somente ao caminho exato', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Alvo.txt')
        .writeAsString('Alvo\nTom: C\nC\nLetra');
    await File('${lote.path}${Platform.pathSeparator}Parecido.txt')
        .writeAsString('Alvo\nTom: C\nC\nLetra');
    await File(
      '${temporaria.path}${Platform.pathSeparator}curadoria_overrides.json',
    ).writeAsString(
      jsonEncode({
        'schema': 1,
        'overrides': {
          'Lote 02/Alvo.txt': {'artista': 'Artista confirmado'},
        },
      }),
    );

    final resultado = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    final alvo = resultado.entradas.singleWhere(
      (e) => e['nomeOrigem'] == 'Alvo.txt',
    );
    final parecido = resultado.entradas.singleWhere(
      (e) => e['nomeOrigem'] == 'Parecido.txt',
    );
    expect(alvo['artista'], 'Artista confirmado');
    expect(alvo['overrideAplicado'], isTrue);
    expect(parecido['artista'], isNull);
    expect(parecido['overrideAplicado'], isFalse);
  });

  test(
    'combina override adicional sem substituir os campos anteriores',
    () async {
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}Lote 02',
      );
      await lote.create();
      await File('${lote.path}${Platform.pathSeparator}Alvo.txt')
          .writeAsString('Alvo\nC G C\nLetra');
      await File(
        '${temporaria.path}${Platform.pathSeparator}curadoria_overrides.json',
      ).writeAsString(
        jsonEncode({
          'schema': 1,
          'overrides': {
            'Lote 02/Alvo.txt': {'artista': 'Artista preservado'},
          },
        }),
      );
      final adicional = File(
        '${temporaria.path}${Platform.pathSeparator}adicional.json',
      );
      await adicional.writeAsString(
        jsonEncode({
          'schema': 1,
          'overrides': {
            'Lote 02/Alvo.txt': {'tom': 'C'},
          },
        }),
      );

      final resultado = await CuradoriaBiblioteca().executar(
        OpcoesCuradoria(
          biblioteca: temporaria,
          lote: 'Lote 02',
          simular: true,
          arquivosOverridesAdicionais: [adicional],
        ),
      );
      final alvo = resultado.entradas.single;
      expect(alvo['artista'], 'Artista preservado');
      expect(alvo['tom'], 'C');
      expect(alvo['origemTom'], 'override');
    },
  );

  test('recusa conflito entre override anterior e adicional', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Alvo.txt')
        .writeAsString('Alvo - Artista\nC G C\nLetra');
    await File(
      '${temporaria.path}${Platform.pathSeparator}curadoria_overrides.json',
    ).writeAsString(
      jsonEncode({
        'schema': 1,
        'overrides': {
          'Lote 02/Alvo.txt': {'tom': 'C'},
        },
      }),
    );
    final adicional = File(
      '${temporaria.path}${Platform.pathSeparator}adicional.json',
    );
    await adicional.writeAsString(
      jsonEncode({
        'schema': 1,
        'overrides': {
          'Lote 02/Alvo.txt': {'tom': 'D'},
        },
      }),
    );

    await expectLater(
      CuradoriaBiblioteca().executar(
        OpcoesCuradoria(
          biblioteca: temporaria,
          lote: 'Lote 02',
          simular: true,
          arquivosOverridesAdicionais: [adicional],
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('simulação não altera nenhum arquivo', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Simular.txt')
        .writeAsString('Simular - Artista\nTom: C\nC\nLetra');
    final antes = await _fotografar(temporaria);

    await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(
        biblioteca: temporaria,
        lote: 'Lote 02',
        simular: true,
        reavaliar: true,
      ),
    );

    expect(await _fotografar(temporaria), antes);
  });

  test('inventário global é somente leitura e cobre todos os lotes', () async {
    for (final nome in ['Lote 01', 'Lote 02']) {
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}$nome',
      );
      await lote.create();
      await File('${lote.path}${Platform.pathSeparator}Mesma.txt')
          .writeAsString('Mesma - Artista\nTom: C\nC G\nLetra');
    }
    final antes = await _fotografar(temporaria);
    final resultado = await InventariadorBibliotecaGlobal().executar(
      temporaria,
    );

    expect(resultado.total, 2);
    expect(resultado.markdown, contains('Lote 01'));
    expect(
      resultado.markdown,
      contains('Conflitos exatos de nome-base entre lotes: 1'),
    );
    expect(await _fotografar(temporaria), antes);
  });

  test('impede duas execuções simultâneas na mesma biblioteca', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Uma.txt')
        .writeAsString('Uma - Artista\nTom: C\nC\nLetra');
    final curadoria = CuradoriaBiblioteca();
    final primeira = curadoria.executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );
    await expectLater(
      curadoria.executar(
        OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
      ),
      throwsStateError,
    );
    await primeira;
  });

  test('retoma UUIDs registrados antes da gravação do CHO', () async {
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Pendente.txt')
        .writeAsString('Pendente - Artista\nTom: C\nC\nLetra');
    const idMusica = '11111111-1111-4111-8111-111111111111';
    const idVersao = '22222222-2222-4222-8222-222222222222';
    await File(
      '${temporaria.path}${Platform.pathSeparator}.curadoria-checkpoint.json',
    ).writeAsString(
      jsonEncode({
        'lote': 'Lote 02',
        'concluido': false,
        'pendente': {
          'origem': 'Lote 02/Pendente.txt',
          'idMusica': idMusica,
          'idVersaoMusica': idVersao,
        },
      }),
    );

    final resultado = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
    );

    expect(resultado.entradas.single['idMusica'], idMusica);
    expect(resultado.entradas.single['idVersaoMusica'], idVersao);
  });

  test(
    'política relativo maior torna pronta ambiguidade tonal isolada',
    () async {
      await _habilitarPoliticaRelativoMaior(temporaria);
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}Lote 02',
      );
      await lote.create();
      await File('${lote.path}${Platform.pathSeparator}Relativos.txt')
          .writeAsString('Relativos - Artista\n[Am]a [F]b [G]c [C]d [Am]e');

      final resumo = await CuradoriaBiblioteca().executar(
        OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', simular: true),
      );
      final entrada = resumo.entradas.single;

      expect(resumo.prontos, 1);
      expect(entrada['tom'], 'C');
      expect(entrada['origemTom'], 'politica_relativo_maior');
      expect(entrada['confiancaTom'], 'media');
      expect(
        entrada['politicaRelativoMaior'],
        isA<Map>()
            .having((m) => m['relativoMenorDescartado'], 'relativo', 'Am')
            .having((m) => m['candidatosSaoRelativos'], 'relativos', isTrue)
            .having((m) => m['possivelModulacao'], 'modulação', isFalse)
            .having(
              (m) => m['terceiroCandidatoCompetitivo'],
              'terceiro',
              isFalse,
            ),
      );
    },
  );

  test('outra pendência permanece em revisão após a política', () async {
    await _habilitarPoliticaRelativoMaior(temporaria);
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Revisar.txt')
        .writeAsString(
          'Revisar - Artista\n[Am]a [F]b [G]c [C]d [Am]e\nlinha [incompleta',
        );

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', simular: true),
    );
    final entrada = resumo.entradas.single;

    expect(resumo.revisar, 1);
    expect(entrada['origemTom'], 'politica_relativo_maior');
    expect(entrada['motivosRevisao'], isNotEmpty);
  });

  test('tom explícito prevalece sobre a política editorial', () async {
    await _habilitarPoliticaRelativoMaior(temporaria);
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File(
      '${lote.path}${Platform.pathSeparator}Explicito.txt',
    ).writeAsString('Explícito - Artista\nTom: F\n[Am]a [F]b [G]c [C]d [Am]e');

    final entrada = (await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', simular: true),
    )).entradas.single;

    expect(entrada['tom'], 'F');
    expect(entrada['origemTom'], 'declarado');
    expect(entrada.containsKey('politicaRelativoMaior'), isFalse);
  });

  test('override anterior prevalece sobre a política editorial', () async {
    await _habilitarPoliticaRelativoMaior(temporaria);
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Override.txt')
        .writeAsString('Override - Artista\n[Am]a [F]b [G]c [C]d [Am]e');
    await File(
      '${temporaria.path}${Platform.pathSeparator}curadoria_overrides.json',
    ).writeAsString(
      jsonEncode({
        'schema': 1,
        'overrides': {
          'Lote 02/Override.txt': {'tom': 'D'},
        },
      }),
    );

    final entrada = (await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', simular: true),
    )).entradas.single;

    expect(entrada['tom'], 'D');
    expect(entrada['origemTom'], 'override');
    expect(entrada['overrideAplicado'], isTrue);
    expect(entrada.containsKey('politicaRelativoMaior'), isFalse);
  });

  test('inferência de confiança alta prevalece sobre a política', () async {
    await _habilitarPoliticaRelativoMaior(temporaria);
    final calibracao = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 01',
    );
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 02',
    );
    await calibracao.create();
    await lote.create();
    const corpo =
        '[C]a [F]b [G7]c [C]d\n'
        '[C]e [F]f [G7]g [C]h\n'
        '[C]i [F]j [G7]k [C]l';
    await File('${calibracao.path}${Platform.pathSeparator}Calibrar.txt')
        .writeAsString('Calibrar - Artista\nTom: C\n$corpo');
    await File('${lote.path}${Platform.pathSeparator}Alta.txt')
        .writeAsString('Alta - Artista\n$corpo');

    final entrada = (await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02', simular: true),
    )).entradas.single;

    expect(entrada['tom'], 'C');
    expect(entrada['origemTom'], 'inferido');
    expect(entrada['confiancaTom'], 'alta');
    expect(entrada.containsKey('politicaRelativoMaior'), isFalse);
  });

  test(
    'recupera manifesto válido do backup após escrita interrompida',
    () async {
      final lote = Directory(
        '${temporaria.path}${Platform.pathSeparator}Lote 02',
      );
      await lote.create();
      await File('${lote.path}${Platform.pathSeparator}Recuperar.txt')
          .writeAsString('Recuperar - Artista\nTom: C\nC\nLetra');
      final curadoria = CuradoriaBiblioteca();
      await curadoria.executar(
        OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
      );
      final manifesto = File(
        '${temporaria.path}${Platform.pathSeparator}manifest.json',
      );
      final backup = File('${manifesto.path}.bak');
      expect(await backup.exists(), isTrue);
      await manifesto.writeAsString('{interrompido');

      final resultado = await curadoria.executar(
        OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 02'),
      );

      expect(resultado.total, 1);
      expect(resultado.entradas.single['nomeOrigem'], 'Recuperar.txt');
    },
  );
}

Future<void> _habilitarPoliticaRelativoMaior(Directory biblioteca) =>
    File('${biblioteca.path}${Platform.pathSeparator}curadoria_config.json')
        .writeAsString(
          jsonEncode({
            'schema': 1,
            'politica_relativo_maior': {
              'habilitada': true,
              'margem_terceiro_competitivo': 4,
              'minimo_acordes': 4,
            },
          }),
        );

Future<Map<String, List<int>>> _fotografar(Directory raiz) async {
  final resultado = <String, List<int>>{};
  await for (final item in raiz.list(recursive: true, followLinks: false)) {
    if (item is File) {
      resultado[item.path.substring(raiz.path.length)] = await item
          .readAsBytes();
    }
  }
  return resultado;
}
