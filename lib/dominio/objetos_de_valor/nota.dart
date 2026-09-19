/// Os nomes naturais usados para representar uma nota musical.
enum NomeNota {
  a('A', 9),
  b('B', 11),
  c('C', 0),
  d('D', 2),
  e('E', 4),
  f('F', 5),
  g('G', 7);

  const NomeNota(this.simbolo, this.classeDeAlturaNatural);

  final String simbolo;
  final int classeDeAlturaNatural;
}

/// A alteração aplicada ao nome natural de uma nota.
enum AlteracaoNota {
  bemol('b', -1),
  natural('', 0),
  sustenido('#', 1);

  const AlteracaoNota(this.simbolo, this.deslocamentoCromatico);

  final String simbolo;
  final int deslocamentoCromatico;
}

/// Uma nota da escala cromática, identificada por nome e alteração.
///
/// A grafia é preservada como parte do valor: por exemplo, C# e Db possuem o
/// mesmo som, mas não são a mesma [Nota].
class Nota {
  const Nota({required this.nome, this.alteracao = AlteracaoNota.natural});

  final NomeNota nome;
  final AlteracaoNota alteracao;

  /// Posição da nota na escala cromática, de C (0) a B (11).
  int get classeDeAltura {
    final valor = nome.classeDeAlturaNatural + alteracao.deslocamentoCromatico;
    return valor % 12;
  }

  /// Informa se esta nota e [outra] representam o mesmo som.
  bool temMesmoSomQue(Nota outra) => classeDeAltura == outra.classeDeAltura;

  @override
  bool operator ==(Object other) =>
      other is Nota && nome == other.nome && alteracao == other.alteracao;

  @override
  int get hashCode => Object.hash(nome, alteracao);

  @override
  String toString() => '${nome.simbolo}${alteracao.simbolo}';
}
