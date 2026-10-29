import 'package:appcifras/dominio/objetos_de_valor/data_culto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita datas civis válidas e compara cronologicamente', () {
    final anterior = DataCulto(ano: 2026, mes: 10, dia: 20);
    final posterior = DataCulto(ano: 2026, mes: 10, dia: 21);

    expect(anterior, DataCulto(ano: 2026, mes: 10, dia: 20));
    expect(anterior.compareTo(posterior), lessThan(0));
    expect(posterior.compareTo(anterior), greaterThan(0));
  });

  test('valida dias, meses e anos bissextos', () {
    expect(() => DataCulto(ano: 2024, mes: 2, dia: 29), returnsNormally);
    expect(
      () => DataCulto(ano: 2025, mes: 2, dia: 29),
      throwsArgumentError,
    );
    expect(() => DataCulto(ano: 2026, mes: 13, dia: 1), throwsArgumentError);
    expect(() => DataCulto(ano: 0, mes: 1, dia: 1), throwsArgumentError);
  });
}
