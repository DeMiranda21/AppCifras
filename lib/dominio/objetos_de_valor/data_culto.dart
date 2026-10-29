class DataCulto implements Comparable<DataCulto> {
  DataCulto({required this.ano, required this.mes, required this.dia}) {
    if (ano < 1 || ano > 9999) {
      throw ArgumentError.value(ano, 'ano', 'O ano deve estar entre 1 e 9999.');
    }
    if (mes < 1 || mes > 12) {
      throw ArgumentError.value(mes, 'mes', 'O mês deve estar entre 1 e 12.');
    }
    final ultimoDia = DateTime.utc(ano, mes + 1, 0).day;
    if (dia < 1 || dia > ultimoDia) {
      throw ArgumentError.value(dia, 'dia', 'O dia não é válido para o mês.');
    }
  }

  final int ano;
  final int mes;
  final int dia;

  @override
  int compareTo(DataCulto other) {
    final porAno = ano.compareTo(other.ano);
    if (porAno != 0) return porAno;
    final porMes = mes.compareTo(other.mes);
    if (porMes != 0) return porMes;
    return dia.compareTo(other.dia);
  }

  @override
  bool operator ==(Object other) =>
      other is DataCulto &&
      ano == other.ano &&
      mes == other.mes &&
      dia == other.dia;

  @override
  int get hashCode => Object.hash(ano, mes, dia);
}
