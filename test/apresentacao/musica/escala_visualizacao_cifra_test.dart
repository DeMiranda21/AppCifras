import 'package:appcifras/apresentacao/musica/escala_visualizacao_cifra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EscalaVisualizacaoCifra', () {
    test('inicia no tamanho padrão', () {
      expect(EscalaVisualizacaoCifra.padrao.valor, 1);
    });

    test('respeita os limites mínimo e máximo', () {
      expect(EscalaVisualizacaoCifra(0.1).valor, 0.75);
      expect(EscalaVisualizacaoCifra(10).valor, 1.8);
    });

    test('aplica fator de pinça sem ultrapassar os limites', () {
      expect(EscalaVisualizacaoCifra.padrao.aplicarFator(1.5).valor, 1.5);
      expect(EscalaVisualizacaoCifra.padrao.aplicarFator(0.1).valor, 0.75);
      expect(EscalaVisualizacaoCifra.padrao.aplicarFator(4).valor, 1.8);
    });
  });
}
