import '../objetos_de_valor/id_lista_culto.dart';

class ListaCulto {
  ListaCulto({required this.id, required String nome})
    : nome = _validarNome(nome);

  final IdListaCulto id;
  final String nome;

  static String _validarNome(String nome) {
    final nomeNormalizado = nome.trim();
    if (nomeNormalizado.isEmpty) {
      throw ArgumentError.value(nome, 'nome', 'O nome da lista é obrigatório.');
    }
    return nomeNormalizado;
  }

  @override
  bool operator ==(Object other) => other is ListaCulto && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
