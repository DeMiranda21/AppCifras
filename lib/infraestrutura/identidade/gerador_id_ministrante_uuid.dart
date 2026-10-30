import 'package:uuid/uuid.dart';

import '../../aplicacao/portas/gerador_id_ministrante.dart';
import '../../dominio/objetos_de_valor/id_ministrante.dart';

class GeradorIdMinistranteUuid implements GeradorIdMinistrante {
  GeradorIdMinistranteUuid({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final Uuid _uuid;

  @override
  IdMinistrante gerar() => IdMinistrante(_uuid.v4());
}
