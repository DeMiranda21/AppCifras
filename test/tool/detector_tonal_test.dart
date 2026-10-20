import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/curadoria_biblioteca.dart';
import '../../tool/detector_tonal.dart';

void main() {
  final detector = DetectorTonal();

  test('detecta tonalidade maior evidente', () {
    final resultado = detector.detectar('C F G C\nAm Dm G7 C\nC F G C');
    expect(resultado.tomDetectado, 'C');
    expect(resultado.confianca, ConfiancaDeteccaoTom.alta);
  });

  test('detecta tonalidade menor evidente', () {
    final resultado = detector.detectar('Am Dm E7 Am\nF Dm E7 Am\nAm E7 Am');
    expect(resultado.tomDetectado, 'Am');
    expect(resultado.confianca, ConfiancaDeteccaoTom.alta);
  });

  test('distingue maior do relativo menor pela resolução', () {
    final resultado = detector.detectar('Am F C G\nDm G C\nF G C\nC');
    expect(resultado.tomDetectado, 'C');
    expect(resultado.confianca, isNot(ConfiancaDeteccaoTom.baixa));
  });

  test('usa cadência dominante com sétima para confirmar a tônica', () {
    final resultado = detector.detectar('D G A7 D\nBm G A7 D\nEm A7 D');
    expect(resultado.tomDetectado, 'D');
    expect(resultado.evidencias.join(' '), contains('dominante'));
  });

  test('reconhece cadência V–I sem tomar o primeiro acorde como regra', () {
    final resultado = detector.detectar('Am D G\nC D G\nEm Am D G');
    expect(resultado.tomDetectado, 'G');
    expect(resultado.evidencias.join(' '), contains('V–I'));
  });

  test('reconhece cadência menor pela dominante maior', () {
    final resultado = detector.detectar(
      'Em Am B7 Em\nC Am B7 Em\nEm D C B7 Em',
    );
    expect(resultado.tomDetectado, 'Em');
    expect(resultado.confianca, isNot(ConfiancaDeteccaoTom.baixa));
  });

  test('dominante secundária resolvida não desloca o centro tonal', () {
    final resultado = detector.detectar(
      'C A7 Dm G7 C\nF A7 Dm G7 C\nC E7 Am D7 G G7 C',
    );
    expect(resultado.tomDetectado, 'C');
    expect(resultado.evidencias.join(' '), contains('secundária'));
  });

  test('acorde emprestado não desloca o centro tonal', () {
    final resultado = detector.detectar('C F Fm C\nAm Dm G7 C\nC F Fm C');
    expect(resultado.tomDetectado, 'C');
  });

  test('possível modulação não recebe confiança alta', () {
    final resultado = detector.detectar('C F G C\nC F G C\nD G A D\nD G A D');
    expect(resultado.possivelModulacao, isTrue);
    expect(resultado.confianca, ConfiancaDeteccaoTom.baixa);
  });

  test('poucos acordes permanecem com confiança baixa', () {
    final resultado = detector.detectar('C G');
    expect(resultado.confianca, ConfiancaDeteccaoTom.baixa);
  });

  test('ignora bloco final de desenhos de acordes', () {
    final resultado = detector.detectar(
      'A D E7 A\nF#m D E7 A\nA D E7 A\n\nAcordes\nC\nx32010\nG\n320003',
    );
    expect(resultado.tomDetectado, 'A');
    expect(resultado.quantidadeAcordes, 12);
  });

  test('linha estruturalmente problemática não causa retrocesso excessivo', () {
    final linha = '${'-' * 33}|${'-' * 14}11----L--11---------|';

    final resultado = detector.detectar(linha);

    expect(resultado.quantidadeAcordes, 0);
    expect(resultado.confianca, ConfiancaDeteccaoTom.baixa);
  });

  test('entrada longa semelhante termina sem falha', () {
    final linha = '${'-' * 100000}|11----L--11---------|';

    final resultado = detector.detectar(linha);

    expect(resultado.quantidadeAcordes, 0);
  });

  test('ignora desenho de acorde válido no meio do corpo musical', () {
    final resultado = detector.detectar('C F G C\nx32010 320003\nAm Dm G7 C');

    expect(resultado.quantidadeAcordes, 8);
  });

  test('não confunde linha musical comum com desenho de acorde', () {
    final resultado = detector.detectar('C G Am F');

    expect(resultado.quantidadeAcordes, 4);
  });

  test('tom explícito prevalece sobre a inferência', () async {
    final temporaria = await Directory.systemTemp.createTemp(
      'appcifras_tom_explicito_',
    );
    addTearDown(() => temporaria.delete(recursive: true));
    final lote = Directory('${temporaria.path}${Platform.pathSeparator}Lote');
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Teste.txt')
        .writeAsString('Teste - Artista\nTom: F\nG C D G\nEm C D G\nG C D G');

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote', simular: true),
    );

    expect(resumo.entradas.single['tom'], 'F');
    expect(resumo.entradas.single['origemTom'], 'declarado');
    expect(resumo.entradas.single['tomDetectado'], isNull);
  });

  test('calibração considera tonalidades enarmônicas equivalentes', () async {
    final temporaria = await Directory.systemTemp.createTemp(
      'appcifras_tom_enarmonico_',
    );
    addTearDown(() => temporaria.delete(recursive: true));
    final lote = Directory(
      '${temporaria.path}${Platform.pathSeparator}Lote 01',
    );
    await lote.create();
    await File('${lote.path}${Platform.pathSeparator}Enarmonico.txt')
        .writeAsString(
          'Enarmônico - Artista\nTom: Db\nC# F# G#7 C#\nA#m F# G#7 C#\nC# F# G#7 C#',
        );

    final resumo = await CuradoriaBiblioteca().executar(
      OpcoesCuradoria(biblioteca: temporaria, lote: 'Lote 01', simular: true),
    );

    expect(resumo.calibracaoTonal.totalComTomExplicito, 1);
    expect(resumo.calibracaoTonal.casos.single['correto'], isTrue);
  });
}
