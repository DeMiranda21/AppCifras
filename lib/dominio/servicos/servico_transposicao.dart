import '../objetos_de_valor/acorde.dart';
import '../objetos_de_valor/nota.dart';
import '../objetos_de_valor/tom.dart';

/// Transpõe estruturas musicais sem alterar suas características originais.
class ServicoTransposicao {
  static const _nomesDiatonicos = [
    NomeNota.c,
    NomeNota.d,
    NomeNota.e,
    NomeNota.f,
    NomeNota.g,
    NomeNota.a,
    NomeNota.b,
  ];

  static const _intervalosMaiores = [0, 2, 4, 5, 7, 9, 11];
  static const _intervalosMenoresNaturais = [0, 2, 3, 5, 7, 8, 10];

  /// Transpõe [nota] pela quantidade de [semitons] informada.
  Nota transporNota(Nota nota, int semitons, {Tom? tomDestino}) {
    final classeDeAlturaDestino = _normalizarClasseDeAltura(
      nota.classeDeAltura + semitons,
    );

    if (tomDestino != null) {
      final notaDaTonalidade = _notasDaTonalidade(
        tomDestino,
      ).where((notaTonal) => notaTonal.classeDeAltura == classeDeAlturaDestino);
      if (notaDaTonalidade.isNotEmpty) {
        return notaDaTonalidade.first;
      }

      return _notaParaClasseDeAltura(
        classeDeAlturaDestino,
        preferencia: _preferenciaDaTonalidade(tomDestino, nota),
      );
    }

    return _notaParaClasseDeAltura(
      classeDeAlturaDestino,
      preferencia: _preferenciaSemContexto(nota),
    );
  }

  /// Transpõe a fundamental e o baixo opcional de [acorde].
  Acorde transporAcorde(Acorde acorde, int semitons, {Tom? tomDestino}) =>
      Acorde(
        notaFundamental: transporNota(
          acorde.notaFundamental,
          semitons,
          tomDestino: tomDestino,
        ),
        qualidade: acorde.qualidade,
        extensoes: acorde.extensoes,
        alteracoes: acorde.alteracoes,
        suspensoes: acorde.suspensoes,
        adicoes: acorde.adicoes,
        baixo: acorde.baixo == null
            ? null
            : transporNota(acorde.baixo!, semitons, tomDestino: tomDestino),
      );

  List<Nota> _notasDaTonalidade(Tom tom) {
    final intervalos = switch (tom.modo) {
      ModoTom.maior => _intervalosMaiores,
      ModoTom.menor => _intervalosMenoresNaturais,
    };
    final indiceDaFundamental = _nomesDiatonicos.indexOf(
      tom.notaFundamental.nome,
    );

    return List.generate(intervalos.length, (indice) {
      final nome =
          _nomesDiatonicos[(indiceDaFundamental + indice) %
              _nomesDiatonicos.length];
      final classeDeAltura = _normalizarClasseDeAltura(
        tom.notaFundamental.classeDeAltura + intervalos[indice],
      );
      return _notaDiatonica(nome, classeDeAltura);
    }).whereType<Nota>().toList(growable: false);
  }

  Nota? _notaDiatonica(NomeNota nome, int classeDeAltura) {
    final diferenca = _diferencaComSinal(
      classeDeAltura - nome.classeDeAlturaNatural,
    );

    return switch (diferenca) {
      -1 => Nota(nome: nome, alteracao: AlteracaoNota.bemol),
      0 => Nota(nome: nome),
      1 => Nota(nome: nome, alteracao: AlteracaoNota.sustenido),
      _ => null,
    };
  }

  AlteracaoNota _preferenciaDaTonalidade(Tom tomDestino, Nota notaOriginal) {
    final balancoDeAcidentes = _notasDaTonalidade(tomDestino).fold<int>(
      0,
      (total, nota) => total + nota.alteracao.deslocamentoCromatico,
    );

    if (balancoDeAcidentes > 0) {
      return AlteracaoNota.sustenido;
    }
    if (balancoDeAcidentes < 0) {
      return AlteracaoNota.bemol;
    }
    return _preferenciaSemContexto(notaOriginal);
  }

  AlteracaoNota _preferenciaSemContexto(Nota notaOriginal) =>
      notaOriginal.alteracao == AlteracaoNota.bemol
      ? AlteracaoNota.bemol
      : AlteracaoNota.sustenido;

  Nota _notaParaClasseDeAltura(
    int classeDeAltura, {
    required AlteracaoNota preferencia,
  }) {
    for (final nome in _nomesDiatonicos) {
      if (nome.classeDeAlturaNatural == classeDeAltura) {
        return Nota(nome: nome);
      }
    }

    for (final nome in _nomesDiatonicos) {
      final classeComAcidente = _normalizarClasseDeAltura(
        nome.classeDeAlturaNatural + preferencia.deslocamentoCromatico,
      );
      if (classeComAcidente == classeDeAltura) {
        return Nota(nome: nome, alteracao: preferencia);
      }
    }

    throw StateError('Não foi possível representar a nota transposta.');
  }

  int _normalizarClasseDeAltura(int valor) => valor % 12;

  int _diferencaComSinal(int valor) {
    final diferencaNormalizada = valor % 12;
    return diferencaNormalizada > 6
        ? diferencaNormalizada - 12
        : diferencaNormalizada;
  }
}
