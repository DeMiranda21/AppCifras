import 'package:uuid/uuid.dart';

import '../../aplicacao/portas/gerador_id_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';

class GeradorIdMusicaUuid implements GeradorIdMusica {
  GeradorIdMusicaUuid({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final Uuid _uuid;

  @override
  IdMusica gerar() => IdMusica(_uuid.v4());
}
