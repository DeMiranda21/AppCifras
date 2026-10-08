import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  VersaoMusica versao({
    String id = 'versao-1',
    String idMusica = 'musica-1',
    bool principal = true,
    bool arquivada = false,
  }) => VersaoMusica(
    id: IdVersaoMusica(id),
    idMusica: IdMusica(idMusica),
    nome: 'Principal',
    documento: parser.interpretar(
      '{appcifras_id: $idMusica}\n'
      '{title: Título}\n'
      '{artist: Artista}\n'
      '{key: C}\n'
      '[C]Letra',
    ),
    principal: principal,
    arquivada: arquivada,
  );

  test('IdVersaoMusica identifica valor válido e rejeita vazio', () {
    expect(IdVersaoMusica('versao-1'), IdVersaoMusica('versao-1'));
    expect(() => IdVersaoMusica('  '), throwsArgumentError);
  });

  test('Musica exige versão principal da própria música', () {
    final principal = versao();
    final musica = Musica(
      id: IdMusica('musica-1'),
      titulo: 'Título',
      artista: 'Artista',
      versaoPrincipal: principal,
    );

    expect(musica.versaoPrincipal, principal);
    expect(musica.tomOriginal, principal.tomOriginal);
    expect(
      () => Musica(
        id: IdMusica('outra-musica'),
        titulo: 'Título',
        artista: 'Artista',
        versaoPrincipal: principal,
      ),
      throwsArgumentError,
    );
  });

  test('versão principal arquivada é inválida', () {
    expect(() => versao(arquivada: true), throwsArgumentError);
  });

  test('appcifras_id da versão permanece associado à música, não à versão', () {
    expect(
      () => VersaoMusica(
        id: IdVersaoMusica('versao-1'),
        idMusica: IdMusica('musica-1'),
        nome: 'Principal',
        documento: parser.interpretar(
          '{appcifras_id: outra-musica}\n'
          '{title: Título}\n'
          '{artist: Artista}\n'
          '{key: C}',
        ),
        principal: true,
        arquivada: false,
      ),
      throwsArgumentError,
    );
  });
}
