import 'package:appcifras/aplicacao/casos_de_uso/salvar_rascunho_chordpro.dart';
import 'package:appcifras/aplicacao/entrada/analisador_entrada_musica.dart';
import 'package:appcifras/aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  RascunhoDocumentoChordPro rascunho(String conteudo) =>
      RascunhoDocumentoChordPro.criar(
        conteudoChordPro: conteudo,
        parserDocumento: parser,
      );

  SalvarRascunhoChordPro salvador(
    _RepositorioMusicasFake repositorio, {
    String id = 'musica-gerada',
  }) => SalvarRascunhoChordPro(
    repositorio: repositorio,
    parserDocumento: parser,
    geradorId: _GeradorIdFake(IdMusica(id)),
  );

  group('RascunhoDocumentoChordPro', () {
    test('salva ChordPro completo sem duplicar metadados', () async {
      const conteudo =
          '{title: Grande é o Senhor}\n'
          '{artist: Exemplo}\n'
          '{key: G}\n'
          '\n'
          '{comment: ensaio}\n'
          '[G]Grande é o [H7]Senhor';
      final repositorio = _RepositorioMusicasFake();

      final analise = AnalisadorEntradaMusica().analisar(conteudo);
      final musica = await salvador(repositorio).executar(
        RascunhoDocumentoChordPro.aPartirDaAnalise(
          analise: analise,
          parserDocumento: parser,
        ),
      );

      expect(musica.id, IdMusica('musica-gerada'));
      expect(musica.documento.conteudoOriginal, conteudo);
      expect(
        musica.documento.elementos.whereType<DiretivaTituloChordPro>(),
        hasLength(1),
      );
      expect(
        musica.documento.elementos.whereType<DiretivaArtistaChordPro>(),
        hasLength(1),
      );
      expect(
        musica.documento.elementos.whereType<DiretivaTomChordPro>(),
        hasLength(1),
      );
      expect(await repositorio.obterPorId(musica.id), musica);
    });

    test('insere título ausente como prefixo determinístico', () {
      const conteudo = '{artist: Artista}\n{key: C}\n[C]Letra';

      final finalizado = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(titulo: 'Título'))
          .produzirConteudoFinal();

      expect(finalizado, '{title: Título}\n$conteudo');
    });

    test('insere artista ausente como prefixo determinístico', () {
      const conteudo = '{title: Título}\n{key: C}\n[C]Letra';

      final finalizado = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(artista: 'Artista'))
          .produzirConteudoFinal();

      expect(finalizado, '{artist: Artista}\n$conteudo');
    });

    test('insere tom ausente como prefixo determinístico', () {
      const conteudo = '{title: Título}\n{artist: Artista}\n[C]Letra';

      final finalizado = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(tom: 'C'))
          .produzirConteudoFinal();

      expect(finalizado, '{key: C}\n$conteudo');
    });

    test('altera explicitamente apenas a diretiva revisada', () {
      const conteudo =
          '{title: Nome antigo}\r\n'
          '{artist: Artista}\r\n'
          '{key: E}\r\n'
          '\r\n'
          '{comment: manter}\r\n'
          '[E]Letra [H7]preservada';

      final titulo = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(titulo: 'Nome novo'))
          .produzirConteudoFinal();
      final artista = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(artista: 'Outro artista'))
          .produzirConteudoFinal();
      final tom = rascunho(conteudo)
          .comRevisao(const RevisaoMetadadosChordPro(tom: 'F#'))
          .produzirConteudoFinal();

      expect(
        titulo,
        conteudo.replaceFirst('{title: Nome antigo}', '{title: Nome novo}'),
      );
      expect(
        artista,
        conteudo.replaceFirst('{artist: Artista}', '{artist: Outro artista}'),
      );
      expect(tom, conteudo.replaceFirst('{key: E}', '{key: F#}'));
    });

    test('bloqueia diretiva obrigatória duplicada mesmo com revisão', () async {
      const conteudo =
          '{title: Primeiro}\n'
          '{title: Segundo}\n'
          '{artist: Artista}\n'
          '{key: C}\n'
          '[C]Letra';
      final revisado = rascunho(
        conteudo,
      ).comRevisao(const RevisaoMetadadosChordPro(titulo: 'Título confirmado'));
      final repositorio = _RepositorioMusicasFake();

      expect(revisado.conflitos, {CampoMetadadoRascunho.titulo});
      expect(
        () => revisado.produzirConteudoFinal(),
        throwsA(isA<RascunhoNaoPodeSerFinalizado>()),
      );
      await expectLater(
        salvador(repositorio).executar(revisado),
        throwsA(isA<RascunhoNaoPodeSerFinalizado>()),
      );
      expect(await repositorio.listar(), isEmpty);
    });

    test('exige revisão explícita para tom inválido', () async {
      const conteudo = '{title: Título}\n{artist: Artista}\n{key: H}\n[H]Letra';
      final original = rascunho(conteudo);
      final repositorio = _RepositorioMusicasFake();

      expect(original.tomDetectado, isNull);
      expect(
        () => original.produzirConteudoFinal(),
        throwsA(isA<RascunhoNaoPodeSerFinalizado>()),
      );

      final musica = await salvador(
        repositorio,
      ).executar(original.comRevisao(const RevisaoMetadadosChordPro(tom: 'E')));
      expect(musica.tomOriginal.notaFundamental.nome.simbolo, 'E');
      expect(musica.documento.conteudoOriginal, contains('{key: E}'));
    });

    test('bloqueia tom revisado que continua inválido', () async {
      const conteudo = '{title: Título}\n{artist: Artista}\n{key: C}';
      final repositorio = _RepositorioMusicasFake();

      await expectLater(
        salvador(repositorio).executar(
          rascunho(conteudo)
              .comRevisao(const RevisaoMetadadosChordPro(tom: 'H')),
        ),
        throwsArgumentError,
      );
      expect(await repositorio.listar(), isEmpty);
    });

    test('reutiliza appcifras_id válido já presente no documento', () async {
      const conteudo =
          '{appcifras_id: musica-de-origem}\n'
          '{title: Título}\n'
          '{artist: Artista}\n'
          '{key: C}\n'
          '[C]Letra';
      final repositorio = _RepositorioMusicasFake();

      final musica = await salvador(
        repositorio,
        id: 'id-não-usado',
      ).executar(rascunho(conteudo));

      expect(musica.id, IdMusica('musica-de-origem'));
      expect(musica.documento.conteudoOriginal, conteudo);
    });
  });
}

class _RepositorioMusicasFake implements RepositorioMusicas {
  final Map<IdMusica, Musica> _musicas = {};

  @override
  Future<void> excluir(IdMusica id) async {
    _musicas.remove(id);
  }

  @override
  Future<List<Musica>> listar() async => _musicas.values.toList();

  @override
  Future<Musica?> obterPorId(IdMusica id) async => _musicas[id];

  @override
  Future<void> salvar(Musica musica) async {
    _musicas[musica.id] = musica;
  }

  @override
  Future<void> atualizar(Musica musica) async {
    _musicas[musica.id] = musica;
  }
}

class _GeradorIdFake implements GeradorIdMusica {
  _GeradorIdFake(this._id);

  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}
