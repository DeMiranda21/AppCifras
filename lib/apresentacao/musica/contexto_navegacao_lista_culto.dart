import '../../dominio/entidades/item_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';

class ContextoNavegacaoListaCulto {
  ContextoNavegacaoListaCulto({
    required this.idLista,
    required List<ItemListaCulto> itens,
    required this.indiceAtual,
  }) : itens = List.unmodifiable(itens) {
    if (itens.isEmpty) {
      throw ArgumentError.value(itens, 'itens', 'A lista deve possuir itens.');
    }
    if (indiceAtual < 0 || indiceAtual >= itens.length) {
      throw ArgumentError.value(
        indiceAtual,
        'indiceAtual',
        'O índice atual deve pertencer à lista.',
      );
    }
  }

  final IdListaCulto idLista;
  final List<ItemListaCulto> itens;
  final int indiceAtual;

  ItemListaCulto get itemAtual => itens[indiceAtual];
  bool get possuiAnterior => indiceAtual > 0;
  bool get possuiProximo => indiceAtual < itens.length - 1;

  ContextoNavegacaoListaCulto comIndice(int indice) =>
      ContextoNavegacaoListaCulto(
        idLista: idLista,
        itens: itens,
        indiceAtual: indice,
      );
}
