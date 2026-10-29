import '../objetos_de_valor/data_culto.dart';
import '../objetos_de_valor/id_lista_culto.dart';
import '../objetos_de_valor/id_ministrante.dart';

class ListaCulto {
  ListaCulto({
    required this.id,
    required String nome,
    this.data,
    this.idMinistrante,
    DateTime? criadaEm,
  }) : nome = _validarNome(nome),
       criadaEm = criadaEm?.toUtc();

  final IdListaCulto id;
  final String nome;
  final DataCulto? data;
  final IdMinistrante? idMinistrante;
  final DateTime? criadaEm;

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
