import '../objetos_de_valor/id_versao_musica.dart';

enum EstadoOrigemSincronizada { presente, ausente }

class OrigemSincronizadaVersao {
  OrigemSincronizadaVersao({
    required this.idVersaoMusica,
    required this.localizadorExterno,
    required this.hashSha256,
    required this.estado,
  }) {
    if (localizadorExterno.trim().isEmpty) {
      throw ArgumentError.value(
        localizadorExterno,
        'localizadorExterno',
        'O localizador externo é obrigatório.',
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hashSha256)) {
      throw ArgumentError.value(
        hashSha256,
        'hashSha256',
        'O hash SHA-256 deve conter 64 caracteres hexadecimais minúsculos.',
      );
    }
  }

  final IdVersaoMusica idVersaoMusica;

  /// Identificador opaco fornecido pela origem externa.
  final String localizadorExterno;
  final String hashSha256;
  final EstadoOrigemSincronizada estado;

  bool get presente => estado == EstadoOrigemSincronizada.presente;

  OrigemSincronizadaVersao copiarCom({
    String? localizadorExterno,
    String? hashSha256,
    EstadoOrigemSincronizada? estado,
  }) => OrigemSincronizadaVersao(
    idVersaoMusica: idVersaoMusica,
    localizadorExterno: localizadorExterno ?? this.localizadorExterno,
    hashSha256: hashSha256 ?? this.hashSha256,
    estado: estado ?? this.estado,
  );
}
