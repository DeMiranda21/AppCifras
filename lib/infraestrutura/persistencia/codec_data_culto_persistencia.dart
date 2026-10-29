import '../../dominio/objetos_de_valor/data_culto.dart';

class CodecDataCultoPersistencia {
  const CodecDataCultoPersistencia();

  int codificar(DataCulto data) => data.ano * 10000 + data.mes * 100 + data.dia;

  DataCulto decodificar(int valor) {
    final ano = valor ~/ 10000;
    final mes = (valor % 10000) ~/ 100;
    final dia = valor % 100;
    try {
      final data = DataCulto(ano: ano, mes: mes, dia: dia);
      if (codificar(data) != valor) throw const FormatException();
      return data;
    } on ArgumentError {
      throw FormatException('DataCulto persistida inválida: $valor.');
    } on FormatException {
      throw FormatException('DataCulto persistida inválida: $valor.');
    }
  }
}
