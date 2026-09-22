import 'package:appcifras/aplicacao/casos_de_uso/musicas.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_musica.dart';
import 'package:appcifras/aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/erros/id_musica_ja_existente.dart';
import 'package:appcifras/dominio/erros/musica_nao_encontrada.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/objetos_de_valor/tom.dart';
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

  AtualizarMusica atualizador(_RepositorioMusicasFake repositorio) =>
      AtualizarMusica(repositorio: repositorio, parserDocumento: parser);

  DadosAtualizacaoMusica dadosAtualizacao({
    required String id,
    required String conteudo,
    String titulo = 'Título',
    String artista = 'Artista',
    String tom = 'C',
  }) => DadosAtualizacaoMusica(
    id: IdMusica(id),
    conteudoChordPro: conteudo,
    revisaoMetadados: RevisaoMetadadosChordPro(
      titulo: titulo,
      artista: artista,
      tom: tom,
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

    test('rejeita exclusão de música inexistente', () async {
      final repositorio = _RepositorioMusicasFake();

      await expectLater(
        ExcluirMusica(repositorio)
            .executar(IdMusica('inexistente'), confirmada: true),
        throwsA(isA<MusicaNaoEncontrada>()),
      );
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

    test(
      'aceita tons válidos independentemente do conteúdo não conflitante',
      () async {
        const tons = <String, Tom>{
          'C': Tom(
            notaFundamental: Nota(nome: NomeNota.c),
            modo: ModoTom.maior,
          ),
          'G': Tom(
            notaFundamental: Nota(nome: NomeNota.g),
            modo: ModoTom.maior,
          ),
          'F#': Tom(
            notaFundamental: Nota(
              nome: NomeNota.f,
              alteracao: AlteracaoNota.sustenido,
            ),
            modo: ModoTom.maior,
          ),
          'Bb': Tom(
            notaFundamental: Nota(
              nome: NomeNota.b,
              alteracao: AlteracaoNota.bemol,
            ),
            modo: ModoTom.maior,
          ),
          'Am': Tom(
            notaFundamental: Nota(nome: NomeNota.a),
            modo: ModoTom.menor,
          ),
          'F#m': Tom(
            notaFundamental: Nota(
              nome: NomeNota.f,
              alteracao: AlteracaoNota.sustenido,
            ),
            modo: ModoTom.menor,
          ),
          'Bbm': Tom(
            notaFundamental: Nota(
              nome: NomeNota.b,
              alteracao: AlteracaoNota.bemol,
            ),
            modo: ModoTom.menor,
          ),
        };
        const metadados = [
          ('Título comum', 'Artista comum'),
          ('  Canção com espaços  ', 'Ministério Ágape'),
        ];
        const conteudos = [
          'Texto puro',
          '[G]Cifra simples',
          '[C]Vários [G]acordes [Am]na linha',
          'Primeira linha\n\nÚltima linha',
          '{start_of_chorus}\n[G]Refrão\n{end_of_chorus}',
          '{comment: anotação}\nLetra',
          '[C]Interpretável [H7]não interpretável',
          '{linha quebrada\nAcorde [G',
        ];

        for (final entradaTom in tons.entries) {
          for (final metadado in metadados) {
            for (final conteudo in conteudos) {
              final repositorio = _RepositorioMusicasFake();
              final cadastro = CadastrarMusica(
                repositorio: repositorio,
                parserDocumento: parser,
                geradorId: _GeradorIdMusicaFake(IdMusica('musica-gerada')),
              );

              final musicaCadastrada = await cadastro.executar(
                DadosCadastroMusica(
                  titulo: metadado.$1,
                  artista: metadado.$2,
                  tomOriginal: entradaTom.key,
                  conteudoChordPro: conteudo,
                ),
              );

              expect(
                musicaCadastrada.tomOriginal,
                entradaTom.value,
                reason: 'tom ${entradaTom.key} com conteúdo "$conteudo"',
              );
              expect(await repositorio.listar(), hasLength(1));
            }
          }
        }
      },
    );

    test('rejeita conteúdo vazio como erro de conteúdo', () async {
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
            tomOriginal: 'G',
            conteudoChordPro: '',
          ),
        ),
        throwsA(
          isA<CadastroMusicaInvalido>().having(
            (erro) => erro.campo,
            'campo',
            CampoCadastroMusica.conteudo,
          ),
        ),
      );
      expect(await repositorio.listar(), isEmpty);
    });

    test(
      'classifica diretivas obrigatórias no conteúdo como erro de conteúdo',
      () async {
        const conflitos = [
          '{title: Outro título}',
          '{artist: Outro artista}',
          '{key: D}',
          '{key: H}',
        ];

        for (final conflito in conflitos) {
          final repositorio = _RepositorioMusicasFake();
          final cadastro = CadastrarMusica(
            repositorio: repositorio,
            parserDocumento: parser,
            geradorId: _GeradorIdMusicaFake(IdMusica('musica-gerada')),
          );

          await expectLater(
            cadastro.executar(
              DadosCadastroMusica(
                titulo: 'Título',
                artista: 'Artista',
                tomOriginal: 'G',
                conteudoChordPro: '$conflito\nLetra',
              ),
            ),
            throwsA(
              isA<CadastroMusicaInvalido>().having(
                (erro) => erro.campo,
                'campo',
                CampoCadastroMusica.conteudo,
              ),
            ),
            reason: 'conflito "$conflito"',
          );
          expect(await repositorio.listar(), isEmpty);
        }
      },
    );

    test(
      'parser preserva key duplicada e Musica a rejeita como metadado ambíguo',
      () {
        final documento = parser.interpretar(
          '{title: Título}\n'
          '{artist: Artista}\n'
          '{key: G}\n'
          '{key: D}\n'
          'Letra',
        );

        expect(
          documento.elementos.whereType<DiretivaTomChordPro>(),
          hasLength(2),
        );
        expect(
          () => Musica(id: IdMusica('musica-gerada'), documento: documento),
          throwsArgumentError,
        );
      },
    );

    test(
      'edita título mantendo ID, conteúdo e quantidade de músicas',
      () async {
        final repositorio = _RepositorioMusicasFake();
        final original = Musica(
          id: IdMusica('musica-1'),
          documento: parser.interpretar(
            '{appcifras_schema: 1}\n'
            '{appcifras_id: musica-1}\n'
            '{title: Título}\n{artist: Artista}\n{key: C}\n'
            '{comment: preservar}\n\n[C]Letra',
          ),
        );
        final outra = musica('musica-2');
        await repositorio.salvar(original);
        await repositorio.salvar(outra);

        final atualizada = await atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'musica-1',
            titulo: 'Título revisado',
            conteudo: original.documento.conteudoOriginal,
          ),
        );

        expect(atualizada.id, original.id);
        expect(atualizada.titulo, 'Título revisado');
        expect(await repositorio.listar(), hasLength(2));
        expect((await repositorio.obterPorId(outra.id))!.titulo, outra.titulo);
        expect(
          atualizada.documento.conteudoOriginal,
          contains('{comment: preservar}\n\n[C]Letra'),
        );
        expect(
          atualizada.documento.conteudoOriginal,
          contains('{appcifras_id: musica-1}'),
        );
      },
    );

    test('edita artista e tom sem duplicar as diretivas', () async {
      final repositorio = _RepositorioMusicasFake();
      final original = musica('musica-1');
      await repositorio.salvar(original);

      final atualizada = await atualizador(repositorio).executar(
        dadosAtualizacao(
          id: 'musica-1',
          artista: 'Artista revisado',
          tom: 'Am',
          conteudo: original.documento.conteudoOriginal,
        ),
      );

      expect(atualizada.artista, 'Artista revisado');
      expect(atualizada.tomOriginal.modo, ModoTom.menor);
      expect(
        atualizada.documento.elementos.whereType<DiretivaArtistaChordPro>(),
        hasLength(1),
      );
      expect(
        atualizada.documento.elementos.whereType<DiretivaTomChordPro>(),
        hasLength(1),
      );
    });

    test(
      'edita o conteúdo ChordPro e preserva os metadados revisados',
      () async {
        final repositorio = _RepositorioMusicasFake();
        final original = musica('musica-1');
        await repositorio.salvar(original);

        final atualizada = await atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'musica-1',
            titulo: 'Novo título',
            artista: 'Novo artista',
            tom: 'G',
            conteudo: '{title: Título}\n{artist: Artista}\n{key: C}\n[G]Novo conteúdo\n{desconhecida: manter}',
          ),
        );

        expect(atualizada.id, original.id);
        expect(atualizada.titulo, 'Novo título');
        expect(atualizada.artista, 'Novo artista');
        expect(
          atualizada.documento.conteudoOriginal,
          contains('[G]Novo conteúdo'),
        );
        expect(
          atualizada.documento.conteudoOriginal,
          contains('{desconhecida: manter}'),
        );
      },
    );

    test(
      'preserva documento integralmente quando não há revisão de metadados',
      () async {
        final repositorio = _RepositorioMusicasFake();
        const conteudo =
            '{appcifras_schema: 1}\r\n'
            '{appcifras_id: musica-1}\r\n'
            '{title: Título}\r\n'
            '{artist: Artista}\r\n'
            '{key: C}\r\n'
            '\r\n'
            '{diretiva_desconhecida: manter}\r\n'
            '[H7]Acorde não interpretável';
        await repositorio.salvar(
          Musica(
            id: IdMusica('musica-1'),
            documento: parser.interpretar(conteudo),
          ),
        );

        final atualizada = await atualizador(repositorio).executar(
          DadosAtualizacaoMusica(
            id: IdMusica('musica-1'),
            conteudoChordPro: conteudo,
            revisaoMetadados: const RevisaoMetadadosChordPro(),
          ),
        );

        expect(atualizada.documento.conteudoOriginal, conteudo);
      },
    );

    test('rejeita atualização de música inexistente', () async {
      final repositorio = _RepositorioMusicasFake();

      await expectLater(
        atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'inexistente',
            conteudo: '{title: Título}\n{artist: Artista}\n{key: C}',
          ),
        ),
        throwsA(isA<MusicaNaoEncontrada>()),
      );
    });

    test('ignora diretivas internas inseridas no conteúdo editável', () async {
      final repositorio = _RepositorioMusicasFake();
      await repositorio.salvar(musica('musica-1'));

      final atualizada = await atualizador(repositorio).executar(
        dadosAtualizacao(
          id: 'musica-1',
          conteudo:
              '{appcifras_schema: 99}\n'
              '{appcifras_id: outro-id}\n'
              '{title: Título}\n{artist: Artista}\n{key: C}\n[C]Letra',
        ),
      );

      expect(atualizada.id, IdMusica('musica-1'));
      expect(
        atualizada.documento.elementos.whereType<DiretivaIdAppCifras>(),
        isEmpty,
      );
      expect(
        atualizada.documento.elementos.whereType<DiretivaSchemaAppCifras>(),
        isEmpty,
      );
    });

    test('rejeita documento com metadados obrigatórios duplicados', () async {
      final repositorio = _RepositorioMusicasFake();
      await repositorio.salvar(musica('musica-1'));

      await expectLater(
        atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'musica-1',
            conteudo: '{title: Um}\n{title: Dois}\n{artist: Artista}\n{key: C}',
          ),
        ),
        throwsA(isA<RascunhoNaoPodeSerFinalizado>()),
      );
    });

    test('rejeita tom inválido sem substituir a música existente', () async {
      final repositorio = _RepositorioMusicasFake();
      final original = musica('musica-1');
      await repositorio.salvar(original);

      await expectLater(
        atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'musica-1',
            tom: 'H',
            conteudo: original.documento.conteudoOriginal,
          ),
        ),
        throwsArgumentError,
      );
      expect(await repositorio.obterPorId(original.id), original);
    });

    test('propaga falha de persistência sem criar outra música', () async {
      final repositorio = _RepositorioMusicasFake()
        ..erroAtualizar = StateError('falha');
      final original = musica('musica-1');
      await repositorio.salvar(original);

      await expectLater(
        atualizador(repositorio).executar(
          dadosAtualizacao(
            id: 'musica-1',
            conteudo: original.documento.conteudoOriginal,
          ),
        ),
        throwsStateError,
      );
      expect(await repositorio.listar(), [original]);
    });
  });
}

class _RepositorioMusicasFake implements RepositorioMusicas {
  final Map<IdMusica, Musica> _musicas = {};
  Object? erroAtualizar;

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

  @override
  Future<void> atualizar(Musica musica) async {
    if (erroAtualizar != null) {
      throw erroAtualizar!;
    }
    if (!_musicas.containsKey(musica.id)) {
      throw StateError('Música não encontrada.');
    }
    _musicas[musica.id] = musica;
  }
}

class _GeradorIdMusicaFake implements GeradorIdMusica {
  const _GeradorIdMusicaFake(this._id);
  final IdMusica _id;

  @override
  IdMusica gerar() => _id;
}
