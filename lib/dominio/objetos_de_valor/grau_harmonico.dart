import 'acorde.dart';

/// A função harmônica de um acorde dentro de uma tonalidade.
class GrauHarmonico {
  GrauHarmonico({
    required this.numero,
    required this.qualidade,
    Iterable<ExtensaoAcorde> extensoes = const [],
    Iterable<AlteracaoAcorde> alteracoes = const [],
    Iterable<SuspensaoAcorde> suspensoes = const [],
    Iterable<AdicaoAcorde> adicoes = const [],
  }) : extensoes = Set.unmodifiable(extensoes),
       alteracoes = Set.unmodifiable(alteracoes),
       suspensoes = Set.unmodifiable(suspensoes),
       adicoes = Set.unmodifiable(adicoes) {
    if (numero < 1 || numero > 7) {
      throw ArgumentError.value(numero, 'numero', 'Deve estar entre 1 e 7.');
    }
    if (qualidade == QualidadeAcorde.quinta) {
      throw ArgumentError.value(
        qualidade,
        'qualidade',
        'Acordes de quinta não possuem grau harmônico no MVP.',
      );
    }
  }

  final int numero;
  final QualidadeAcorde qualidade;
  final Set<ExtensaoAcorde> extensoes;
  final Set<AlteracaoAcorde> alteracoes;
  final Set<SuspensaoAcorde> suspensoes;
  final Set<AdicaoAcorde> adicoes;

  /// A forma romana do grau sem formatar suas características adicionais.
  String get representacaoRomana {
    const romanos = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
    final romano = romanos[numero - 1];

    return switch (qualidade) {
      QualidadeAcorde.maior => romano,
      QualidadeAcorde.menor => romano.toLowerCase(),
      QualidadeAcorde.quinta => throw StateError(
        'Acordes de quinta não possuem grau harmônico no MVP.',
      ),
      QualidadeAcorde.diminuto => '${romano.toLowerCase()}°',
      QualidadeAcorde.aumentado => '$romano+',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is GrauHarmonico &&
      numero == other.numero &&
      qualidade == other.qualidade &&
      _conjuntosIguais(extensoes, other.extensoes) &&
      _conjuntosIguais(alteracoes, other.alteracoes) &&
      _conjuntosIguais(suspensoes, other.suspensoes) &&
      _conjuntosIguais(adicoes, other.adicoes);

  @override
  int get hashCode => Object.hash(
    numero,
    qualidade,
    Object.hashAllUnordered(extensoes),
    Object.hashAllUnordered(alteracoes),
    Object.hashAllUnordered(suspensoes),
    Object.hashAllUnordered(adicoes),
  );

  static bool _conjuntosIguais<T>(Set<T> primeiro, Set<T> segundo) =>
      primeiro.length == segundo.length && primeiro.containsAll(segundo);
}
