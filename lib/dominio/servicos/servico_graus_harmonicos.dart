import '../objetos_de_valor/acorde.dart';
import '../objetos_de_valor/grau_harmonico.dart';
import '../objetos_de_valor/tom.dart';

/// Resultado da tentativa de converter uma cifra para grau harmônico.
sealed class ResultadoConversaoGraus {
  const ResultadoConversaoGraus();
}

/// Resultado para um acorde que pode ser exibido como grau harmônico.
class AcordeConvertidoEmGrau extends ResultadoConversaoGraus {
  const AcordeConvertidoEmGrau(this.grau);

  final GrauHarmonico grau;
}

/// Resultado para um acorde que deve continuar em cifra absoluta no MVP.
class AcordeMantidoComoCifra extends ResultadoConversaoGraus {
  const AcordeMantidoComoCifra(this.acorde);

  final Acorde acorde;
}

/// Converte acordes diatônicos simples para graus harmônicos no MVP.
class ServicoGrausHarmonicos {
  static const _grausMaiores = [
    _DefinicaoGrau(1, 0, QualidadeAcorde.maior),
    _DefinicaoGrau(2, 2, QualidadeAcorde.menor),
    _DefinicaoGrau(3, 4, QualidadeAcorde.menor),
    _DefinicaoGrau(4, 5, QualidadeAcorde.maior),
    _DefinicaoGrau(5, 7, QualidadeAcorde.maior),
    _DefinicaoGrau(6, 9, QualidadeAcorde.menor),
    _DefinicaoGrau(7, 11, QualidadeAcorde.diminuto),
  ];

  static const _grausMenoresNaturais = [
    _DefinicaoGrau(1, 0, QualidadeAcorde.menor),
    _DefinicaoGrau(2, 2, QualidadeAcorde.diminuto),
    _DefinicaoGrau(3, 3, QualidadeAcorde.maior),
    _DefinicaoGrau(4, 5, QualidadeAcorde.menor),
    _DefinicaoGrau(5, 7, QualidadeAcorde.menor),
    _DefinicaoGrau(6, 8, QualidadeAcorde.maior),
    _DefinicaoGrau(7, 10, QualidadeAcorde.maior),
  ];

  /// Converte [acorde] quando ele corresponde a um grau diatônico de [tom].
  ResultadoConversaoGraus converter(Acorde acorde, Tom tom) {
    if (acorde.baixo != null ||
        acorde.alteracoes.isNotEmpty ||
        acorde.qualidade == QualidadeAcorde.quinta) {
      return AcordeMantidoComoCifra(acorde);
    }

    final graus = switch (tom.modo) {
      ModoTom.maior => _grausMaiores,
      ModoTom.menor => _grausMenoresNaturais,
    };
    final grauEsperado = graus.where(
      (grau) =>
          _normalizarClasseDeAltura(
            tom.notaFundamental.classeDeAltura + grau.semitonsDaTonica,
          ) ==
          acorde.notaFundamental.classeDeAltura,
    );

    if (grauEsperado.isEmpty) {
      return AcordeMantidoComoCifra(acorde);
    }

    final definicao = grauEsperado.first;
    final possuiSuspensao = acorde.suspensoes.isNotEmpty;
    if (!possuiSuspensao && acorde.qualidade != definicao.qualidade) {
      return AcordeMantidoComoCifra(acorde);
    }

    final classesDaEscala = graus
        .map(
          (grau) => _normalizarClasseDeAltura(
            tom.notaFundamental.classeDeAltura + grau.semitonsDaTonica,
          ),
        )
        .toSet();
    final componentes = _classesDeAlturaDoAcorde(acorde);
    if (!componentes.every(classesDaEscala.contains)) {
      return AcordeMantidoComoCifra(acorde);
    }

    return AcordeConvertidoEmGrau(
      GrauHarmonico(
        numero: definicao.numero,
        qualidade: definicao.qualidade,
        extensoes: acorde.extensoes,
        alteracoes: acorde.alteracoes,
        suspensoes: acorde.suspensoes,
        adicoes: acorde.adicoes,
      ),
    );
  }

  Set<int> _classesDeAlturaDoAcorde(Acorde acorde) {
    final intervalos = switch (acorde.qualidade) {
      QualidadeAcorde.maior => <int>{0, 4, 7},
      QualidadeAcorde.menor => <int>{0, 3, 7},
      QualidadeAcorde.quinta => throw StateError(
        'Acordes de quinta não são convertidos para graus no MVP.',
      ),
      QualidadeAcorde.diminuto => <int>{0, 3, 6},
      QualidadeAcorde.aumentado => <int>{0, 4, 8},
    };

    if (acorde.suspensoes.isNotEmpty) {
      intervalos.remove(acorde.qualidade == QualidadeAcorde.maior ? 4 : 3);
      for (final suspensao in acorde.suspensoes) {
        intervalos.add(suspensao == SuspensaoAcorde.segunda ? 2 : 5);
      }
    }

    for (final extensao in acorde.extensoes) {
      intervalos.add(switch (extensao) {
        ExtensaoAcorde.sexta => 9,
        ExtensaoAcorde.setima => 10,
        ExtensaoAcorde.setimaMaior => 11,
        ExtensaoAcorde.nona => 14,
        ExtensaoAcorde.decimaPrimeira => 17,
        ExtensaoAcorde.decimaTerceira => 21,
      });
    }
    for (final adicao in acorde.adicoes) {
      intervalos.add(adicao == AdicaoAcorde.nona ? 14 : 17);
    }

    return intervalos
        .map(
          (intervalo) => _normalizarClasseDeAltura(
            acorde.notaFundamental.classeDeAltura + intervalo,
          ),
        )
        .toSet();
  }

  int _normalizarClasseDeAltura(int valor) => valor % 12;
}

class _DefinicaoGrau {
  const _DefinicaoGrau(this.numero, this.semitonsDaTonica, this.qualidade);

  final int numero;
  final int semitonsDaTonica;
  final QualidadeAcorde qualidade;
}
