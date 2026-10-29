import 'package:appcifras/dominio/objetos_de_valor/data_culto.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/infraestrutura/persistencia/codec_data_culto_persistencia.dart';
import 'package:appcifras/infraestrutura/persistencia/codec_tom_persistencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codecData = CodecDataCultoPersistencia();
  const codecTom = CodecTomPersistencia();

  test('DataCulto faz round-trip em inteiro AAAAMMDD', () {
    final data = DataCulto(ano: 2026, mes: 10, dia: 27);
    expect(codecData.codificar(data), 20261027);
    expect(codecData.decodificar(20261027), data);
    expect(() => codecData.decodificar(20260230), throwsFormatException);
  });

  test('Tom faz round-trip preservando enarmonia e modo', () {
    const tons = [
      Tom(notaFundamental: Nota(nome: NomeNota.c), modo: ModoTom.maior),
      Tom(
        notaFundamental: Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        modo: ModoTom.menor,
      ),
      Tom(
        notaFundamental: Nota(
          nome: NomeNota.b,
          alteracao: AlteracaoNota.bemol,
        ),
        modo: ModoTom.maior,
      ),
    ];

    for (final tom in tons) {
      expect(codecTom.decodificar(codecTom.codificar(tom)), tom);
    }
  });

  test('Tom inválido falha explicitamente e null não pertence ao codec', () {
    expect(() => codecTom.decodificar('C#m'), throwsFormatException);
    expect(
      () => codecTom.decodificar('1|c|acidente-invalido|maior'),
      throwsFormatException,
    );
  });
}
