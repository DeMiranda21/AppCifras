import '../objetos_de_valor/id_ministrante.dart';

class Ministrante {
  Ministrante({
    required this.id,
    required String nome,
    required this.arquivado,
  }) : nome = _validarNome(nome);

  final IdMinistrante id;
  final String nome;
  final bool arquivado;

  Ministrante renomear(String novoNome) => Ministrante(
    id: id,
    nome: novoNome,
    arquivado: arquivado,
  );

  Ministrante arquivar() => Ministrante(id: id, nome: nome, arquivado: true);

  Ministrante restaurar() => Ministrante(id: id, nome: nome, arquivado: false);

  static String _validarNome(String nome) {
    final normalizado = nome.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError.value(
        nome,
        'nome',
        'O nome do ministrante é obrigatório.',
      );
    }
    return normalizado;
  }

  @override
  bool operator ==(Object other) => other is Ministrante && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
