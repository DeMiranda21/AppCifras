/// Estado de apresentação para o tamanho da cifra durante uma visualização.
class EscalaVisualizacaoCifra {
  const EscalaVisualizacaoCifra._(this.valor);

  static const padrao = EscalaVisualizacaoCifra._(1);
  static const minimo = 0.75;
  static const maximo = 1.8;

  factory EscalaVisualizacaoCifra(double valor) =>
      EscalaVisualizacaoCifra._(valor.clamp(minimo, maximo).toDouble());

  final double valor;

  EscalaVisualizacaoCifra aplicarFator(double fator) =>
      EscalaVisualizacaoCifra(valor * fator);

  @override
  bool operator ==(Object other) =>
      other is EscalaVisualizacaoCifra && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;
}
