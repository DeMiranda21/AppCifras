import 'nota.dart';

/// A estrutura básica de um acorde.
enum QualidadeAcorde { maior, menor, quinta, diminuto, aumentado }

/// Extensões que podem compor um acorde.
enum ExtensaoAcorde {
  sexta,
  setima,
  setimaMaior,
  nona,
  decimaPrimeira,
  decimaTerceira,
}

/// Suspensões que podem substituir a terça de um acorde.
enum SuspensaoAcorde { segunda, quarta }

/// Notas adicionadas a um acorde sem formar uma extensão.
enum AdicaoAcorde { nona, decimaPrimeira }

/// Uma alteração aplicada a um grau do acorde, como a quinta bemol.
class AlteracaoAcorde {
  factory AlteracaoAcorde({
    required int grau,
    required AlteracaoNota alteracao,
  }) {
    if (grau <= 0) {
      throw ArgumentError.value(grau, 'grau', 'Deve ser maior que zero.');
    }
    if (alteracao == AlteracaoNota.natural) {
      throw ArgumentError.value(
        alteracao,
        'alteracao',
        'Uma alteração de acorde deve ser bemol ou sustenido.',
      );
    }

    return AlteracaoAcorde._(grau: grau, alteracao: alteracao);
  }

  const AlteracaoAcorde._({required this.grau, required this.alteracao});

  final int grau;
  final AlteracaoNota alteracao;

  @override
  bool operator ==(Object other) =>
      other is AlteracaoAcorde &&
      grau == other.grau &&
      alteracao == other.alteracao;

  @override
  int get hashCode => Object.hash(grau, alteracao);
}

/// A estrutura musical de um acorde, independente de sua grafia textual.
class Acorde {
  Acorde({
    required this.notaFundamental,
    this.qualidade = QualidadeAcorde.maior,
    Iterable<ExtensaoAcorde> extensoes = const [],
    Iterable<AlteracaoAcorde> alteracoes = const [],
    Iterable<SuspensaoAcorde> suspensoes = const [],
    Iterable<AdicaoAcorde> adicoes = const [],
    this.baixo,
  }) : extensoes = Set.unmodifiable(extensoes),
       alteracoes = Set.unmodifiable(alteracoes),
       suspensoes = Set.unmodifiable(suspensoes),
       adicoes = Set.unmodifiable(adicoes);

  final Nota notaFundamental;
  final QualidadeAcorde qualidade;
  final Set<ExtensaoAcorde> extensoes;
  final Set<AlteracaoAcorde> alteracoes;
  final Set<SuspensaoAcorde> suspensoes;
  final Set<AdicaoAcorde> adicoes;
  final Nota? baixo;

  @override
  bool operator ==(Object other) =>
      other is Acorde &&
      notaFundamental == other.notaFundamental &&
      qualidade == other.qualidade &&
      _conjuntosIguais(extensoes, other.extensoes) &&
      _conjuntosIguais(alteracoes, other.alteracoes) &&
      _conjuntosIguais(suspensoes, other.suspensoes) &&
      _conjuntosIguais(adicoes, other.adicoes) &&
      baixo == other.baixo;

  @override
  int get hashCode => Object.hash(
    notaFundamental,
    qualidade,
    Object.hashAllUnordered(extensoes),
    Object.hashAllUnordered(alteracoes),
    Object.hashAllUnordered(suspensoes),
    Object.hashAllUnordered(adicoes),
    baixo,
  );

  static bool _conjuntosIguais<T>(Set<T> primeiro, Set<T> segundo) =>
      primeiro.length == segundo.length && primeiro.containsAll(segundo);
}
