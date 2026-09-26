class IdListaCulto {
  IdListaCulto(this.valor) {
    if (valor.trim().isEmpty) {
      throw ArgumentError.value(
        valor,
        'valor',
        'O ID da lista de culto é obrigatório.',
      );
    }
  }

  final String valor;

  @override
  bool operator ==(Object other) =>
      other is IdListaCulto && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;
}
