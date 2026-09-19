import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Acorde', () {
    const doNatural = Nota(nome: NomeNota.c);

    test('representa C estruturalmente', () {
      final acorde = Acorde(notaFundamental: doNatural);

      expect(acorde.notaFundamental, doNatural);
      expect(acorde.qualidade, QualidadeAcorde.maior);
      expect(acorde.extensoes, isEmpty);
      expect(acorde.alteracoes, isEmpty);
      expect(acorde.suspensoes, isEmpty);
      expect(acorde.adicoes, isEmpty);
      expect(acorde.baixo, isNull);
    });

    test('representa Am estruturalmente', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.a),
        qualidade: QualidadeAcorde.menor,
      );

      expect(acorde.qualidade, QualidadeAcorde.menor);
    });

    test('representa G/B por meio do baixo opcional', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.g),
        baixo: const Nota(nome: NomeNota.b),
      );

      expect(acorde.notaFundamental, const Nota(nome: NomeNota.g));
      expect(acorde.baixo, const Nota(nome: NomeNota.b));
    });

    test('representa Cadd9 por meio de uma adição', () {
      final acorde = Acorde(
        notaFundamental: doNatural,
        adicoes: {AdicaoAcorde.nona},
      );

      expect(acorde.adicoes, {AdicaoAcorde.nona});
      expect(acorde.extensoes, isEmpty);
    });

    test('representa Dsus4 por meio de uma suspensão', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.d),
        suspensoes: {SuspensaoAcorde.quarta},
      );

      expect(acorde.suspensoes, {SuspensaoAcorde.quarta});
    });

    test('representa F#m7(b5) com extensão e alteração', () {
      final acorde = Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol)},
      );

      expect(acorde.qualidade, QualidadeAcorde.menor);
      expect(acorde.extensoes, {ExtensaoAcorde.setima});
      expect(acorde.alteracoes, {
        AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol),
      });
    });

    test('é imutável e compara suas coleções sem considerar a ordem', () {
      final primeiro = Acorde(
        notaFundamental: doNatural,
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.nona},
        adicoes: {AdicaoAcorde.nona},
      );
      final segundo = Acorde(
        notaFundamental: doNatural,
        extensoes: {ExtensaoAcorde.nona, ExtensaoAcorde.setima},
        adicoes: {AdicaoAcorde.nona},
      );

      expect(primeiro, segundo);
      expect(primeiro.hashCode, segundo.hashCode);
      expect(
        () => primeiro.extensoes.add(ExtensaoAcorde.sexta),
        throwsUnsupportedError,
      );
    });
  });

  group('AlteracaoAcorde', () {
    test('exige grau positivo e alteração não natural', () {
      expect(
        () => AlteracaoAcorde(grau: 0, alteracao: AlteracaoNota.bemol),
        throwsArgumentError,
      );
      expect(
        () => AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.natural),
        throwsArgumentError,
      );
    });
  });
}
