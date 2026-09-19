import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nota', () {
    test('representa uma nota natural', () {
      const nota = Nota(nome: NomeNota.c);

      expect(nota.nome, NomeNota.c);
      expect(nota.alteracao, AlteracaoNota.natural);
      expect(nota.classeDeAltura, 0);
      expect(nota.toString(), 'C');
    });

    test('representa as grafias com acidentes documentadas', () {
      const doSustenido = Nota(
        nome: NomeNota.c,
        alteracao: AlteracaoNota.sustenido,
      );
      const reBemol = Nota(nome: NomeNota.d, alteracao: AlteracaoNota.bemol);
      const miBemol = Nota(nome: NomeNota.e, alteracao: AlteracaoNota.bemol);
      const faSustenido = Nota(
        nome: NomeNota.f,
        alteracao: AlteracaoNota.sustenido,
      );
      const siBemol = Nota(nome: NomeNota.b, alteracao: AlteracaoNota.bemol);

      expect(doSustenido.toString(), 'C#');
      expect(reBemol.toString(), 'Db');
      expect(miBemol.toString(), 'Eb');
      expect(faSustenido.toString(), 'F#');
      expect(siBemol.toString(), 'Bb');
    });

    test('distingue grafias enarmônicas na igualdade estrutural', () {
      const doSustenido = Nota(
        nome: NomeNota.c,
        alteracao: AlteracaoNota.sustenido,
      );
      const reBemol = Nota(nome: NomeNota.d, alteracao: AlteracaoNota.bemol);

      expect(doSustenido, isNot(reBemol));
    });

    test('reconhece notas enarmônicas como o mesmo som', () {
      const doSustenido = Nota(
        nome: NomeNota.c,
        alteracao: AlteracaoNota.sustenido,
      );
      const reBemol = Nota(nome: NomeNota.d, alteracao: AlteracaoNota.bemol);
      const doBemol = Nota(nome: NomeNota.c, alteracao: AlteracaoNota.bemol);
      const si = Nota(nome: NomeNota.b);

      expect(doSustenido.classeDeAltura, 1);
      expect(reBemol.classeDeAltura, 1);
      expect(doSustenido.temMesmoSomQue(reBemol), isTrue);
      expect(doBemol.classeDeAltura, 11);
      expect(doBemol.temMesmoSomQue(si), isTrue);
    });

    test('considera iguais notas com os mesmos atributos', () {
      const primeira = Nota(
        nome: NomeNota.f,
        alteracao: AlteracaoNota.sustenido,
      );
      const segunda = Nota(
        nome: NomeNota.f,
        alteracao: AlteracaoNota.sustenido,
      );

      expect(primeira, segunda);
      expect(primeira.hashCode, segunda.hashCode);
    });
  });
}
