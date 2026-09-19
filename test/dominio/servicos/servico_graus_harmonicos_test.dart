import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/objetos_de_valor/grau_harmonico.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/servico_graus_harmonicos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final servico = ServicoGrausHarmonicos();
  const doMaior = Tom(
    notaFundamental: Nota(nome: NomeNota.c),
    modo: ModoTom.maior,
  );

  group('ServicoGrausHarmonicos - tonalidade maior', () {
    test('converte os graus diatônicos básicos de C maior', () {
      final casos = [
        (
          Acorde(notaFundamental: const Nota(nome: NomeNota.c)),
          1,
          QualidadeAcorde.maior,
          'I',
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.d),
            qualidade: QualidadeAcorde.menor,
          ),
          2,
          QualidadeAcorde.menor,
          'ii',
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.e),
            qualidade: QualidadeAcorde.menor,
          ),
          3,
          QualidadeAcorde.menor,
          'iii',
        ),
        (
          Acorde(notaFundamental: const Nota(nome: NomeNota.f)),
          4,
          QualidadeAcorde.maior,
          'IV',
        ),
        (
          Acorde(notaFundamental: const Nota(nome: NomeNota.g)),
          5,
          QualidadeAcorde.maior,
          'V',
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.a),
            qualidade: QualidadeAcorde.menor,
          ),
          6,
          QualidadeAcorde.menor,
          'vi',
        ),
      ];

      for (final caso in casos) {
        final resultado = servico.converter(caso.$1, doMaior);

        expect(resultado, isA<AcordeConvertidoEmGrau>());
        final convertido = resultado as AcordeConvertidoEmGrau;
        expect(convertido.grau.numero, caso.$2);
        expect(convertido.grau.qualidade, caso.$3);
        expect(convertido.grau.representacaoRomana, caso.$4);
      }
    });

    test('converte o vii diminuto de C maior', () {
      final resultado = servico.converter(
        Acorde(
          notaFundamental: const Nota(nome: NomeNota.b),
          qualidade: QualidadeAcorde.diminuto,
        ),
        doMaior,
      );

      expect(resultado, isA<AcordeConvertidoEmGrau>());
      expect(
        (resultado as AcordeConvertidoEmGrau).grau.representacaoRomana,
        'vii°',
      );
    });

    test('converte extensões, adições e suspensões diatônicas', () {
      final casos = [
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.c),
            extensoes: {ExtensaoAcorde.setimaMaior},
          ),
          1,
          {ExtensaoAcorde.setimaMaior},
          <AdicaoAcorde>{},
          <SuspensaoAcorde>{},
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.e),
            qualidade: QualidadeAcorde.menor,
            extensoes: {ExtensaoAcorde.setima},
          ),
          3,
          {ExtensaoAcorde.setima},
          <AdicaoAcorde>{},
          <SuspensaoAcorde>{},
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.c),
            adicoes: {AdicaoAcorde.nona},
          ),
          1,
          <ExtensaoAcorde>{},
          {AdicaoAcorde.nona},
          <SuspensaoAcorde>{},
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.d),
            suspensoes: {SuspensaoAcorde.quarta},
          ),
          2,
          <ExtensaoAcorde>{},
          <AdicaoAcorde>{},
          {SuspensaoAcorde.quarta},
        ),
      ];

      for (final caso in casos) {
        final resultado = servico.converter(caso.$1, doMaior);

        expect(resultado, isA<AcordeConvertidoEmGrau>());
        final grau = (resultado as AcordeConvertidoEmGrau).grau;
        expect(grau.numero, caso.$2);
        expect(grau.extensoes, caso.$3);
        expect(grau.adicoes, caso.$4);
        expect(grau.suspensoes, caso.$5);
      }
    });

    test('mantém C7 como cifra absoluta por conter nota não diatônica', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
      );

      final resultado = servico.converter(acorde, doMaior);

      expect(resultado, isA<AcordeMantidoComoCifra>());
      expect((resultado as AcordeMantidoComoCifra).acorde, same(acorde));
    });

    test('mantém estrutura que não corresponde ao grau esperado', () {
      final acorde = Acorde(notaFundamental: const Nota(nome: NomeNota.d));

      final resultado = servico.converter(acorde, doMaior);

      expect(resultado, isA<AcordeMantidoComoCifra>());
      expect((resultado as AcordeMantidoComoCifra).acorde, same(acorde));
    });

    test('mantém inversões como cifras absolutas', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.g),
        baixo: const Nota(nome: NomeNota.b),
      );

      final resultado = servico.converter(acorde, doMaior);

      expect(resultado, isA<AcordeMantidoComoCifra>());
      expect((resultado as AcordeMantidoComoCifra).acorde, same(acorde));
    });

    test('mantém acordes de quinta como cifras absolutas', () {
      final acorde = Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.quinta,
      );

      final resultado = servico.converter(acorde, doMaior);

      expect(resultado, isA<AcordeMantidoComoCifra>());
      expect((resultado as AcordeMantidoComoCifra).acorde, same(acorde));
    });
  });

  group('ServicoGrausHarmonicos - tonalidade menor natural', () {
    test('converte os graus diatônicos de A menor natural', () {
      const laMenor = Tom(
        notaFundamental: Nota(nome: NomeNota.a),
        modo: ModoTom.menor,
      );
      final casos = [
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.a),
            qualidade: QualidadeAcorde.menor,
          ),
          'i',
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.b),
            qualidade: QualidadeAcorde.diminuto,
          ),
          'ii°',
        ),
        (Acorde(notaFundamental: const Nota(nome: NomeNota.c)), 'III'),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.d),
            qualidade: QualidadeAcorde.menor,
          ),
          'iv',
        ),
        (
          Acorde(
            notaFundamental: const Nota(nome: NomeNota.e),
            qualidade: QualidadeAcorde.menor,
          ),
          'v',
        ),
        (Acorde(notaFundamental: const Nota(nome: NomeNota.f)), 'VI'),
        (Acorde(notaFundamental: const Nota(nome: NomeNota.g)), 'VII'),
      ];

      for (final caso in casos) {
        final resultado = servico.converter(caso.$1, laMenor);

        expect(resultado, isA<AcordeConvertidoEmGrau>());
        expect(
          (resultado as AcordeConvertidoEmGrau).grau.representacaoRomana,
          caso.$2,
        );
      }
    });
  });

  group('ServicoGrausHarmonicos - enarmonia', () {
    test('reconhece fundamental enarmônica no tom de Eb maior', () {
      const miBemolMaior = Tom(
        notaFundamental: Nota(nome: NomeNota.e, alteracao: AlteracaoNota.bemol),
        modo: ModoTom.maior,
      );
      final acorde = Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.d,
          alteracao: AlteracaoNota.sustenido,
        ),
      );

      final resultado = servico.converter(acorde, miBemolMaior);

      expect(resultado, isA<AcordeConvertidoEmGrau>());
      expect(
        (resultado as AcordeConvertidoEmGrau).grau.representacaoRomana,
        'I',
      );
    });
  });

  group('GrauHarmonico', () {
    test('não permite qualidade de quinta no MVP', () {
      expect(
        () => GrauHarmonico(numero: 1, qualidade: QualidadeAcorde.quinta),
        throwsArgumentError,
      );
    });

    test('mantém suas coleções imutáveis', () {
      final grau = GrauHarmonico(
        numero: 1,
        qualidade: QualidadeAcorde.maior,
        adicoes: {AdicaoAcorde.nona},
      );

      expect(() => grau.adicoes.add(AdicaoAcorde.nona), throwsUnsupportedError);
    });
  });
}
