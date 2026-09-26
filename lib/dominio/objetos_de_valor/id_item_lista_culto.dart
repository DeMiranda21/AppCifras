class IdItemListaCulto {
  IdItemListaCulto(this.valor) {
    if (valor.trim().isEmpty) {
      throw ArgumentError.value(
        valor,
        'valor',
        'O ID do item da lista de culto é obrigatório.',
      );
    }
  }

  final String valor;

  @override
  bool operator ==(Object other) =>
      other is IdItemListaCulto && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;
}
