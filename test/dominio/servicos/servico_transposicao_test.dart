import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/servico_transposicao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final servico = ServicoTransposicao();

  group('ServicoTransposicao - notas', () {
    test('transpõe uma nota ascendentemente', () {
      final resultado = servico.transporNota(const Nota(nome: NomeNota.c), 2);

      expect(resultado, const Nota(nome: NomeNota.d));
    });

    test('transpõe uma nota descendentemente', () {
      final resultado = servico.transporNota(const Nota(nome: NomeNota.d), -2);

      expect(resultado, const Nota(nome: NomeNota.c));
    });

    test('percorre corretamente o ciclo cromático', () {
      final acima = servico.transporNota(const Nota(nome: NomeNota.b), 1);
      final abaixo = servico.transporNota(const Nota(nome: NomeNota.c), -1);

      expect(acima, const Nota(nome: NomeNota.c));
      expect(abaixo, const Nota(nome: NomeNota.b));
    });

    test('prefere a grafia da tonalidade de destino', () {
      final resultado = servico.transporNota(
        const Nota(nome: NomeNota.c),
        3,
        tomDestino: const Tom(
          notaFundamental: Nota(
            nome: NomeNota.e,
            alteracao: AlteracaoNota.bemol,
          ),
          modo: ModoTom.maior,
        ),
      );

      expect(
        resultado,
        const Nota(nome: NomeNota.e, alteracao: AlteracaoNota.bemol),
      );
    });

    test('preserva a família de sustenido sem contexto tonal', () {
      final resultado = servico.transporNota(
        const Nota(nome: NomeNota.c, alteracao: AlteracaoNota.sustenido),
        2,
      );

      expect(
        resultado,
        const Nota(nome: NomeNota.d, alteracao: AlteracaoNota.sustenido),
      );
    });

    test('preserva a família de bemol sem contexto tonal', () {
      final resultado = servico.transporNota(
        const Nota(nome: NomeNota.d, alteracao: AlteracaoNota.bemol),
        2,
      );

      expect(
        resultado,
        const Nota(nome: NomeNota.e, alteracao: AlteracaoNota.bemol),
      );
    });

    test('prefere sustenido para uma origem natural sem contexto tonal', () {
      final resultado = servico.transporNota(const Nota(nome: NomeNota.c), 1);

      expect(
        resultado,
        const Nota(nome: NomeNota.c, alteracao: AlteracaoNota.sustenido),
      );
    });
  });

  group('ServicoTransposicao - acordes', () {
    test('transpõe Am preservando a qualidade menor', () {
      final resultado = servico.transporAcorde(
        Acorde(
          notaFundamental: const Nota(nome: NomeNota.a),
          qualidade: QualidadeAcorde.menor,
        ),
        2,
      );

      expect(resultado.notaFundamental, const Nota(nome: NomeNota.b));
      expect(resultado.qualidade, QualidadeAcorde.menor);
    });

    test('transpõe a fundamental e o baixo de uma inversão', () {
      final resultado = servico.transporAcorde(
        Acorde(
          notaFundamental: const Nota(nome: NomeNota.g),
          baixo: const Nota(nome: NomeNota.b),
        ),
        2,
        tomDestino: const Tom(
          notaFundamental: Nota(nome: NomeNota.a),
          modo: ModoTom.maior,
        ),
      );

      expect(resultado.notaFundamental, const Nota(nome: NomeNota.a));
      expect(
        resultado.baixo,
        const Nota(nome: NomeNota.c, alteracao: AlteracaoNota.sustenido),
      );
    });

    test('preserva a qualidade de quinta durante a transposição', () {
      final resultado = servico.transporAcorde(
        Acorde(
          notaFundamental: const Nota(nome: NomeNota.c),
          qualidade: QualidadeAcorde.quinta,
          baixo: const Nota(nome: NomeNota.g),
        ),
        2,
      );

      expect(resultado.notaFundamental, const Nota(nome: NomeNota.d));
      expect(resultado.baixo, const Nota(nome: NomeNota.a));
      expect(resultado.qualidade, QualidadeAcorde.quinta);
    });

    test('preserva as características estruturais do acorde', () {
      final acordeOriginal = Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol)},
        suspensoes: {SuspensaoAcorde.quarta},
        adicoes: {AdicaoAcorde.nona},
      );

      final resultado = servico.transporAcorde(acordeOriginal, 2);

      expect(
        resultado.notaFundamental,
        const Nota(nome: NomeNota.g, alteracao: AlteracaoNota.sustenido),
      );
      expect(resultado.qualidade, acordeOriginal.qualidade);
      expect(resultado.extensoes, acordeOriginal.extensoes);
      expect(resultado.alteracoes, acordeOriginal.alteracoes);
      expect(resultado.suspensoes, acordeOriginal.suspensoes);
      expect(resultado.adicoes, acordeOriginal.adicoes);
      expect(
        acordeOriginal.notaFundamental,
        const Nota(nome: NomeNota.f, alteracao: AlteracaoNota.sustenido),
      );
    });
  });
}
