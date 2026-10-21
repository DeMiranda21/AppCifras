import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/curadoria_biblioteca.dart';
import '../../tool/detector_tonal.dart';

void main() {
  final caminhoBiblioteca =
      Platform.environment['APPCIFRAS_BIBLIOTECA_CALIBRACAO'];

  test(
    'calibração real preserva os 93 resultados de referência',
    () async {
      final resumo = await CuradoriaBiblioteca().executar(
        OpcoesCuradoria(
          biblioteca: Directory(caminhoBiblioteca!),
          lote: 'Lote 02',
          simular: true,
        ),
      );
      final calibracao = resumo.calibracaoTonal;

      expect(calibracao.totalComTomExplicito, 93);
      expect(
        calibracao.porConfianca[ConfiancaDeteccaoTom.alta],
        isA<EstatisticaCalibracaoTonal>()
            .having((e) => e.total, 'total', 7)
            .having((e) => e.corretos, 'corretos', 7),
      );
      expect(
        calibracao.porConfianca[ConfiancaDeteccaoTom.media],
        isA<EstatisticaCalibracaoTonal>()
            .having((e) => e.total, 'total', 76)
            .having((e) => e.corretos, 'corretos', 53),
      );
      expect(
        calibracao.porConfianca[ConfiancaDeteccaoTom.baixa],
        isA<EstatisticaCalibracaoTonal>()
            .having((e) => e.total, 'total', 10)
            .having((e) => e.corretos, 'corretos', 5),
      );
    },
    skip: caminhoBiblioteca == null
        ? 'Defina APPCIFRAS_BIBLIOTECA_CALIBRACAO para a integração real.'
        : false,
  );
}
