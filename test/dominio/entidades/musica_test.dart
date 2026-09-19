import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  Musica criarMusica(String id, String conteudo) =>
      Musica(id: IdMusica(id), documento: parser.interpretar(conteudo));

  group('Musica', () {
    test('obtém metadados obrigatórios do documento ChordPro', () {
      final musica = criarMusica(
        'musica-1',
        '{title:  Grande é o Senhor  }\n{artist:  Exemplo  }\n{key: F#m}',
      );

      expect(musica.titulo, 'Grande é o Senhor');
      expect(musica.artista, 'Exemplo');
      expect(
        musica.tomOriginal,
        const Tom(
          notaFundamental: Nota(
            nome: NomeNota.f,
            alteracao: AlteracaoNota.sustenido,
          ),
          modo: ModoTom.menor,
        ),
      );
    });

    test('tem identidade definida somente pelo ID', () {
      final primeira = criarMusica(
        'musica-1',
        '{title: Uma}\n{artist: Artista}\n{key: C}',
      );
      final mesmaIdentidade = criarMusica(
        'musica-1',
        '{title: Outra}\n{artist: Outro}\n{key: D}',
      );
      final outraIdentidade = criarMusica(
        'musica-2',
        '{title: Uma}\n{artist: Artista}\n{key: C}',
      );

      expect(primeira, mesmaIdentidade);
      expect(primeira, isNot(outraIdentidade));
    });

    test('aceita documento externo sem identidade própria declarada', () {
      final musica = criarMusica(
        'musica-1',
        '{title: Título}\n{artist: Artista}\n{key: C}',
      );

      expect(musica.id, IdMusica('musica-1'));
    });

    test(
      'exige que ID próprio declarado corresponda à identidade da música',
      () {
        final musica = criarMusica(
          'musica-1',
          '{appcifras_id: musica-1}\n{title: Título}\n{artist: Artista}\n{key: C}',
        );

        expect(musica.id, IdMusica('musica-1'));
        expect(
          () => criarMusica(
            'musica-2',
            '{appcifras_id: musica-1}\n{title: Título}\n{artist: Artista}\n{key: C}',
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejeita ID próprio duplicado ou inválido', () {
      expect(
        () => criarMusica(
          'musica-1',
          '{appcifras_id: musica-1}\n{appcifras_id: musica-1}\n{title: Título}\n{artist: Artista}\n{key: C}',
        ),
        throwsArgumentError,
      );
      expect(
        () => criarMusica(
          'musica-1',
          '{appcifras_id: }\n{title: Título}\n{artist: Artista}\n{key: C}',
        ),
        throwsArgumentError,
      );
    });

    for (final conteudo in [
      '{artist: Artista}\n{key: C}',
      '{title: Título}\n{key: C}',
      '{title: Título}\n{artist: Artista}',
    ]) {
      test('rejeita ausência de metadado obrigatório', () {
        expect(() => criarMusica('musica-1', conteudo), throwsArgumentError);
      });
    }

    for (final conteudo in [
      '{title: Um}\n{title: Dois}\n{artist: Artista}\n{key: C}',
      '{title: Título}\n{artist: Um}\n{artist: Dois}\n{key: C}',
      '{title: Título}\n{artist: Artista}\n{key: C}\n{key: D}',
    ]) {
      test('rejeita diretiva obrigatória repetida', () {
        expect(() => criarMusica('musica-1', conteudo), throwsArgumentError);
      });
    }

    for (final conteudo in [
      '{title:   }\n{artist: Artista}\n{key: C}',
      '{title: Título}\n{artist:   }\n{key: C}',
      '{title: Título}\n{artist: Artista}\n{key: H}',
    ]) {
      test('rejeita valor inválido de metadado obrigatório', () {
        expect(() => criarMusica('musica-1', conteudo), throwsArgumentError);
      });
    }
  });
}
