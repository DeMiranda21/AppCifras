class TagMusica {
  TagMusica(String valor) : valor = valor.trim() {
    if (this.valor.isEmpty) {
      throw ArgumentError.value(valor, 'valor', 'A tag não pode ser vazia.');
    }
  }

  final String valor;
  String get chaveNormalizada => valor.toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is TagMusica && chaveNormalizada == other.chaveNormalizada;

  @override
  int get hashCode => chaveNormalizada.hashCode;
}
