class IdMusica {
  IdMusica(this.valor) {
    if (valor.trim().isEmpty) {
      throw ArgumentError.value(
        valor,
        'valor',
        'O ID da música é obrigatório.',
      );
    }
  }

  final String valor;

  @override
  bool operator ==(Object other) => other is IdMusica && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;
}
