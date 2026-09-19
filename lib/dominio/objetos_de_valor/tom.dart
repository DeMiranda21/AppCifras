import 'nota.dart';

/// Os modos tonais suportados pelo MVP.
enum ModoTom { maior, menor }

/// A tonalidade de referência de uma música ou execução.
class Tom {
  const Tom({required this.notaFundamental, required this.modo});

  final Nota notaFundamental;
  final ModoTom modo;

  @override
  bool operator ==(Object other) =>
      other is Tom &&
      notaFundamental == other.notaFundamental &&
      modo == other.modo;

  @override
  int get hashCode => Object.hash(notaFundamental, modo);
}
