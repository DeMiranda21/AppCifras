import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tom', () {
    test('é definido por nota fundamental e modo maior', () {
      const tom = Tom(
        notaFundamental: Nota(nome: NomeNota.c),
        modo: ModoTom.maior,
      );

      expect(tom.notaFundamental, const Nota(nome: NomeNota.c));
      expect(tom.modo, ModoTom.maior);
    });

    test('suporta o modo menor', () {
      const tom = Tom(
        notaFundamental: Nota(nome: NomeNota.a),
        modo: ModoTom.menor,
      );

      expect(tom.notaFundamental, const Nota(nome: NomeNota.a));
      expect(tom.modo, ModoTom.menor);
    });

    test('considera iguais tons com os mesmos atributos', () {
      const primeiro = Tom(
        notaFundamental: Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        modo: ModoTom.menor,
      );
      const segundo = Tom(
        notaFundamental: Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        modo: ModoTom.menor,
      );

      expect(primeiro, segundo);
      expect(primeiro.hashCode, segundo.hashCode);
    });

    test('distingue modos e grafias de nota', () {
      const doMaior = Tom(
        notaFundamental: Nota(nome: NomeNota.c),
        modo: ModoTom.maior,
      );
      const doMenor = Tom(
        notaFundamental: Nota(nome: NomeNota.c),
        modo: ModoTom.menor,
      );
      const siSustenidoMaior = Tom(
        notaFundamental: Nota(
          nome: NomeNota.b,
          alteracao: AlteracaoNota.sustenido,
        ),
        modo: ModoTom.maior,
      );

      expect(doMaior, isNot(doMenor));
      expect(doMaior, isNot(siSustenidoMaior));
    });
  });
}
