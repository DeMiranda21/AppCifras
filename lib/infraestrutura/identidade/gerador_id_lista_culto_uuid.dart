import 'package:uuid/uuid.dart';

import '../../aplicacao/portas/gerador_id_lista_culto.dart';
import '../../dominio/objetos_de_valor/id_lista_culto.dart';

class GeradorIdListaCultoUuid implements GeradorIdListaCulto {
  GeradorIdListaCultoUuid({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final Uuid _uuid;

  @override
  IdListaCulto gerar() => IdListaCulto(_uuid.v4());
}
