import 'package:uuid/uuid.dart';

import '../../aplicacao/portas/gerador_id_item_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_item_lista_culto.dart';

class GeradorIdItemListaCultoUuid implements GeradorIdItemListaCulto {
  GeradorIdItemListaCultoUuid({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final Uuid _uuid;

  @override
  IdItemListaCulto gerar() => IdItemListaCulto(_uuid.v4());
}
