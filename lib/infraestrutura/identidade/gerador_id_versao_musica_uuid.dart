import 'package:uuid/uuid.dart';

import '../../aplicacao/portas/gerador_id_versao_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';

class GeradorIdVersaoMusicaUuid implements GeradorIdVersaoMusica {
  GeradorIdVersaoMusicaUuid({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  final Uuid _uuid;

  @override
  IdVersaoMusica gerar() => IdVersaoMusica(_uuid.v4());
}
