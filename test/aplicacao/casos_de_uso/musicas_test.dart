import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/erros/id_musica_ja_existente.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  Musica musica(String id) => Musica(
    id: IdMusica(id),
    documento: parser.interpretar(
      '{title: Título}\n{artist: Artista}\n{key: C}',
    ),
  );

  group('Casos de uso de músicas', () {
    test('salva, obtém e lista músicas pelo contrato de repositório', () async {
      final repositorio = _RepositorioMusicasFake();
      final cadastro = SalvarMusica(repositorio);
      final consulta = ObterMusicaPorId(repositorio);
      final listagem = ListarMusicas(repositorio);
      final item = musica('musica-1');

      await cadastro.executar(item);

      expect(await consulta.executar(item.id), item);
      expect(await listagem.executar(), [item]);
    });

    test('exige confirmação explícita antes de excluir uma música', () async {
      final repositorio = _RepositorioMusicasFake();
      final item = musica('musica-1');
      await repositorio.salvar(item);
      final exclusao = ExcluirMusica(repositorio);

      expect(
        () => exclusao.executar(item.id, confirmada: false),
        throwsStateError,
      );

      await exclusao.executar(item.id, confirmada: true);
      expect(await repositorio.obterPorId(item.id), isNull);
    });

    test(
      'importa ChordPro externo com nova identidade e sem alterar conteúdo',
      () async {
        final repositorio = _RepositorioMusicasFake();
        final importacao = ImportarMusica(
          repositorio: repositorio,
          parserDocumento: parser,
          geradorId: _GeradorIdMusicaFake(IdMusica('musica-gerada')),
        );
        const conteudo = '{title: Título}\n{artist: Artista}\n{key: C}';

        final importada = await importacao.executar(conteudo);

        expect(importada.id, IdMusica('musica-gerada'));
        expect(importada.documento.conteudoOriginal, conteudo);
        expect(await repositorio.obterPorId(importada.id), importada);
      },
    );

    test(
      'preserva identidade própria declarada ao importar ChordPro gerenciado',
      () async {
        final repositorio = _RepositorioMusicasFake();
        final importacao = ImportarMusica(
          repositorio: repositorio,
          parserDocumento: parser,
          geradorId: _GeradorIdMusicaFake(IdMusica('não-usado')),
        );

        final importada = await importacao.executar(
          '{appcifras_id: musica-original}\n{title: Título}\n{artist: Artista}\n{key: C}',
        );

        expect(importada.id, IdMusica('musica-original'));
      },
    );

    test('rejeita schema AppCifras não suportado sem salvar a música', () async {
      final repositorio = _RepositorioMusicasFake();
      final importacao = ImportarMusica(
        repositorio: repositorio,
        parserDocumento: parser,
        geradorId: _GeradorIdMusicaFake(IdMusica('não-usado')),
      );

      await expectLater(
        importacao.executar(
          '{appcifras_schema: 2}\n{title: Título}\n{artist: Artista}\n{key: C}',
        ),
        throwsA(isA<SchemaAppCifrasNaoSuportado>()),
      );
      expect(await repositorio.listar(), isEmpty);
    });

    test('rejeita importação com ID AppCifras já existente', () async {
      final repositorio = _RepositorioMusicasFake();
      final importacao = ImportarMusica(
        repositorio: repositorio,
        parserDocumento: parser,
        geradorId: _GeradorIdMusicaFake(IdMusica('não-usado')),
      );
      const conteudo =
          '{appcifras_id: musica-original}\n{title: Título}\n{artist: Artista}\n{key: C}';

      await importacao.executar(conteudo);

      await expectLater(
        importacao.executar(conteudo),
        throwsA(isA<IdMusicaJaExistente>()),
      );
    });

    test(
      'cadastra música e cria diretivas obrigatórias sem reescrever o conteúdo',
      () async {
        final repositorio = _RepositorioMusicasFake();
        final cadastro = CadastrarMusica(
          repositorio: repositorio,
          parserDocumento: parser,
          geradorId: _GeradorIdMusicaFake(IdMusica('musica-gerada')),
        );
        const conteudo = '[G]Grande é o [D]Senhor\n[C]Digno de louvor';

        final musicaCadastrada = await cadastro.executar(
          const DadosCadastroMusica(
            titulo: 'Grande é o Senhor',
            artista: 'Exemplo',
            tomOriginal: 'G',
            conteudoChordPro: conteudo,
          ),
        );

        expect(musicaCadastrada.id, IdMusica('musica-gerada'));
        expect(
          musicaCadastrada.documento.conteudoOriginal,
          '{title: Grande é o Senhor}\n{artist: Exemplo}\n{key: G}\n$conteudo',
        );
        expect(
          await repositorio.obterPorId(musicaCadastrada.id),
          musicaCadastrada,
        );
      },
    );

    test('rejeita tom inválido sem salvar música', () async {
      final repositorio = _RepositorioMusicasFake();
      final cadastro = CadastrarMusica(
        repositorio: repositorio,
        parserDocumento: parser,
        geradorId: _GeradorIdMusicaFake(IdMusica('musica-gerada')),
      );

      await expectLater(
        cadastro.executar(
          const DadosCadastroMusica(
            titulo: 'Título',
            artista: 'Artista',
            tomOriginal: 'H',
            conteudoChordPro: '[C]Letra',
          ),
        ),
        throwsA(
          isA<CadastroMusicaInvalido>().having(
            (erro) => erro.campo,
            'campo',
            CampoCadastroMusica.tomOriginal,
          ),
        ),
      );
      expect(await repositorio.listar(), isEmpty);
    });
  });
}

class _RepositorioMusicasFake implements RepositorioMusicas {
  final Map<IdMusica, Musica> _musicas = {};

  @override
  Future<void> salvar(Musica musica) async {
    _musicas[musica.id] = musica;
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async => _musicas[id];

  @override
  Future<List<Musica>> listar() async => _musicas.values.toList();

  @override
  Future<void> excluir(IdMusica id) async {
    _musicas.remove(id);
  }
}

class _GeradorIdMusicaFake implements GeradorIdMusica {
  const _GeradorIdMusicaFake(this._id);
  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}
