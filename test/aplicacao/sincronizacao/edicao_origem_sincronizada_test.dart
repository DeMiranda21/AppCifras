import 'dart:io';

import 'package:appcifras/aplicacao/casos_de_uso/ciclo_vida_versoes_musicas.dart';
import 'package:appcifras/aplicacao/casos_de_uso/classificacao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/editar_versao_musica.dart';
import 'package:appcifras/aplicacao/casos_de_uso/versoes_musicas.dart';
import 'package:appcifras/aplicacao/entrada/conteudo_chordpro_editavel.dart';
import 'package:appcifras/aplicacao/entrada/rascunho_documento_chordpro.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_versao_musica.dart';
import 'package:appcifras/dominio/entidades/musica.dart';
import 'package:appcifras/dominio/entidades/origem_sincronizada_versao.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/chordpro/documento_chordpro.dart';
import 'package:appcifras/dominio/objetos_de_valor/energia_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/tag_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:appcifras/infraestrutura/arquivos/armazenamento_arquivos_chordpro.dart';
import 'package:appcifras/infraestrutura/persistencia/banco_biblioteca.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_classificacao_musica_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_musicas_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_sincronizacao_local.dart';
import 'package:appcifras/infraestrutura/persistencia/repositorio_tom_execucao_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  late Directory diretorio;
  late BancoBiblioteca banco;
  late ArmazenamentoArquivosChordPro armazenamento;
  late RepositorioMusicasLocal musicas;
  late RepositorioSincronizacaoLocal sincronizacao;
  late RepositorioTomExecucaoLocal tons;
  late RepositorioClassificacaoMusicaLocal classificacao;
  late CriarVersaoMusica criar;
  late EditarVersaoMusica editar;
  late VersaoMusica principal;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('appcifras_s2_edicao_');
    banco = BancoBiblioteca(NativeDatabase.memory());
    armazenamento = ArmazenamentoArquivosChordPro(diretorio);
    musicas = RepositorioMusicasLocal(
      banco: banco,
      armazenamentoArquivos: armazenamento,
    );
    sincronizacao = RepositorioSincronizacaoLocal(banco);
    tons = RepositorioTomExecucaoLocal(banco);
    classificacao = RepositorioClassificacaoMusicaLocal(banco);
    criar = CriarVersaoMusica(repositorio: musicas, geradorId: _GeradorId());
    editar = EditarVersaoMusica(
      repositorio: musicas,
      repositorioMusicas: musicas,
      criarVersao: criar,
      avaliarPolitica: AvaliarPoliticaEdicaoVersao(
        musicas,
        repositorioOrigens: sincronizacao,
      ),
      repositorioTom: tons,
      repositorioOrigens: sincronizacao,
    );
    await musicas.salvar(
      Musica(
        id: IdMusica('musica'),
        documento: ParserDocumentoChordPro().interpretar(
          '{title: T}\n{artist: A}\n{key: C}\n[C]Original',
        ),
      ),
    );
    principal = (await musicas.obterPrincipalPorMusica(IdMusica('musica')))!;
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  VersaoMusica alterada(VersaoMusica origem) => editar.preparar(
    origem,
    ConteudoChordProEditavel.extrair(origem.documento.conteudoOriginal)
        .replaceAll('[C]Original', '[D]Alterada'),
    const RevisaoMetadadosChordPro(tom: 'D'),
  );

  Future<void> vincular(EstadoOrigemSincronizada estado) =>
      sincronizacao.salvarOrigem(
        OrigemSincronizadaVersao(
          idVersaoMusica: principal.id,
          localizadorExterno: 'content://drive/document/principal',
          hashSha256: hash,
          estado: estado,
        ),
      );

  for (final estado in EstadoOrigemSincronizada.values) {
    test('origem ${estado.name} bloqueia sobrescrita musical direta', () async {
      await vincular(estado);

      await expectLater(
        AtualizarConteudoVersaoMusica(
          musicas,
          repositorioTom: tons,
          repositorioOrigens: sincronizacao,
        ).executar(alterada(principal)),
        throwsStateError,
      );

      expect(
        (await musicas.obterVersaoPorId(principal.id))!
            .documento
            .conteudoOriginal,
        principal.documento.conteudoOriginal,
      );
    });
  }

  for (final estado in EstadoOrigemSincronizada.values) {
    test(
      'edição de origem ${estado.name} cria versão local sem vínculo',
      () async {
        await vincular(estado);
        await tons.salvarUltimoTom(principal.id, principal.tomOriginal);

        final criada = await editar.executar(
          origem: principal,
          editada: alterada(principal),
          nomeNovaVersao: 'Local',
        );

        expect(criada.id, isNot(principal.id));
        expect(criada.idMusica, principal.idMusica);
        expect(criada.nome, 'Local');
        expect(await sincronizacao.obterPorVersao(criada.id), isNull);
        expect(await tons.obterUltimoTom(criada.id), isNull);
        expect(await tons.obterUltimoTom(principal.id), isNotNull);
        expect(
          (await musicas.obterVersaoPorId(principal.id))!
              .documento
              .conteudoOriginal,
          principal.documento.conteudoOriginal,
        );
      },
    );
  }

  test('versão local mantém sobrescrita C2 e classificação local', () async {
    final local = await criar.executar(origem: principal, nome: 'Local');
    final resultado = await editar.executar(
      origem: local,
      editada: alterada(local),
    );
    await SalvarClassificacaoMusica(classificacao).executar(
      principal.idMusica,
      energia: EnergiaMusica.animada,
      tags: [TagMusica('Celebração')],
    );

    expect(resultado.id, local.id);
    expect((await musicas.listarPorMusica(principal.idMusica)), hasLength(2));
    final salva = await classificacao.obter(principal.idMusica);
    expect(salva.energia, EnergiaMusica.animada);
    expect(salva.tags.single.valor, 'Celebração');
  });

  test('título e artista continuam editáveis sem criar versão', () async {
    await armazenamento.substituir(
      principal.id,
      '{appcifras_schema:2}\n'
      '{appcifras_id:musica}\n'
      '{appcifras_version_id:${principal.id.valor}}\n'
      '{appcifras_version_name:Principal}\n'
      '{appcifras_primary:true}\n'
      '{title:T}\n{artist:A}\n{key:C}\n[C]Original',
    );
    await vincular(EstadoOrigemSincronizada.presente);
    principal = (await musicas.obterVersaoPorId(principal.id))!;
    final editada = editar.preparar(
      principal,
      ConteudoChordProEditavel.extrair(principal.documento.conteudoOriginal),
      const RevisaoMetadadosChordPro(
        titulo: 'Novo título',
        artista: 'Novo artista',
      ),
    );

    final salva = await editar.executar(origem: principal, editada: editada);

    expect(salva.id, principal.id);
    expect((await musicas.listarPorMusica(principal.idMusica)), hasLength(1));
    final catalogo = (await musicas.obterPorId(principal.idMusica))!;
    expect(catalogo.titulo, 'Novo título');
    expect(catalogo.artista, 'Novo artista');
    expect(
      salva.documento.elementos
          .whereType<DiretivaSchemaAppCifras>()
          .single
          .versao,
      2,
    );
  });

  test('cópia local de schema 2 recebe identidade local coerente', () async {
    final sincronizada = VersaoMusica(
      id: IdVersaoMusica('sincronizada'),
      idMusica: principal.idMusica,
      nome: 'Sincronizada',
      documento: ParserDocumentoChordPro().interpretar(
        '{appcifras_schema:2}\r\n'
        '{appcifras_id:musica}\r\n'
        '{appcifras_version_id:sincronizada}\r\n'
        '{appcifras_version_name:Sincronizada}\r\n'
        '{appcifras_primary:false}\r\n'
        '{title:T}\r\n{artist:A}\r\n{key:C}\r\n[C]Original',
      ),
      principal: false,
      arquivada: false,
    );
    await musicas.salvarVersao(sincronizada);
    await sincronizacao.salvarOrigem(
      OrigemSincronizadaVersao(
        idVersaoMusica: sincronizada.id,
        localizadorExterno: 'opaque-document-id',
        hashSha256: hash,
        estado: EstadoOrigemSincronizada.presente,
      ),
    );
    final carregada = (await musicas.obterVersaoPorId(sincronizada.id))!;

    final local = await editar.executar(
      origem: carregada,
      editada: alterada(carregada),
      nomeNovaVersao: 'Cópia local',
    );

    expect(local.id, isNot(sincronizada.id));
    expect(await sincronizacao.obterPorVersao(local.id), isNull);
    expect(
      local.documento.elementos
          .whereType<DiretivaSchemaAppCifras>()
          .single
          .versao,
      1,
    );
    expect(
      local.documento.elementos.whereType<DiretivaIdVersaoAppCifras>(),
      isEmpty,
    );
    expect(
      local.documento.elementos.whereType<DiretivaNomeVersaoAppCifras>(),
      isEmpty,
    );
    expect(
      local.documento.elementos.whereType<DiretivaPrincipalAppCifras>(),
      isEmpty,
    );
    expect(local.documento.conteudoOriginal, contains('[D]Alterada'));
    expect(local.documento.conteudoOriginal, contains('\r\n'));
  });
}

class _GeradorId implements GeradorIdVersaoMusica {
  var proximo = 0;

  @override
  IdVersaoMusica gerar() => IdVersaoMusica('local-${++proximo}');
}
