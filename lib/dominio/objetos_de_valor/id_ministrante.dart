class IdMinistrante {
  IdMinistrante(this.valor) {
    if (valor.trim().isEmpty) {
      throw ArgumentError.value(
        valor,
        'valor',
        'O ID do ministrante é obrigatório.',
      );
    }
  }

  final String valor;

  @override
  bool operator ==(Object other) =>
      other is IdMinistrante && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;
}
