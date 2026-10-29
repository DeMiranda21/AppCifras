import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'banco_biblioteca.g.dart';

class IndiceMusicas extends Table {
  TextColumn get id => text()();

  TextColumn get titulo => text()();

  TextColumn get artista => text()();

  TextColumn get arquivo => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class IndicesPesquisaMusicas extends Table {
  TextColumn get idMusica =>
      text().references(IndiceMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get idVersaoMusica =>
      text().references(VersoesMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get conteudoVisivel => text()();

  TextColumn get tituloNormalizado => text().nullable()();

  TextColumn get textoNormalizado => text().nullable()();

  @override
  Set<Column> get primaryKey => {idMusica};
}

class RegistroItemBiblioteca {
  const RegistroItemBiblioteca({
    required this.idMusica,
    required this.idVersaoPrincipal,
    required this.titulo,
    required this.artista,
    required this.conteudoVisivel,
    required this.tituloNormalizado,
    required this.textoNormalizado,
  });

  final String idMusica;
  final String? idVersaoPrincipal;
  final String titulo;
  final String artista;
  final String? conteudoVisivel;
  final String? tituloNormalizado;
  final String? textoNormalizado;
}

class RegistroIndicePesquisaMusica {
  const RegistroIndicePesquisaMusica({
    required this.idMusica,
    required this.idVersaoMusica,
    required this.conteudoVisivel,
    required this.tituloNormalizado,
    required this.textoNormalizado,
  });

  final String idMusica;
  final String idVersaoMusica;
  final String conteudoVisivel;
  final String tituloNormalizado;
  final String textoNormalizado;
}

class VersoesMusicas extends Table {
  TextColumn get id => text()();

  TextColumn get idMusica =>
      text().references(IndiceMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get nome => text()();

  TextColumn get arquivo => text()();

  BoolColumn get principal => boolean()();

  BoolColumn get arquivada => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrigemSincronizadaVersaoRegistro')
class OrigensSincronizadasVersoes extends Table {
  TextColumn get idVersaoMusica =>
      text().references(VersoesMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get localizadorExterno => text()();

  TextColumn get hashSha256 => text()();

  BoolColumn get presente => boolean()();

  @override
  Set<Column> get primaryKey => {idVersaoMusica};
}

@DataClassName('ConfiguracaoPastaSincronizadaRegistro')
class ConfiguracoesPastaSincronizada extends Table {
  IntColumn get id => integer().customConstraint('NOT NULL CHECK (id = 1)')();

  TextColumn get uriArvore => text()();

  BoolColumn get autorizacaoPersistente => boolean()();

  TextColumn get nomeLegivel => text().nullable()();

  DateTimeColumn get ultimaSincronizacaoConcluida => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EstadoBibliotecaOficialRegistro')
class EstadosBibliotecaOficial extends Table {
  IntColumn get id => integer().customConstraint('NOT NULL CHECK (id = 1)')();

  TextColumn get ultimaGeracao => text()();

  DateTimeColumn get ultimaAtualizacao => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PreferenciasTomExecucao extends Table {
  TextColumn get idVersaoMusica =>
      text().references(VersoesMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get nomeNota => text()();

  TextColumn get alteracao => text()();

  TextColumn get modo => text()();

  @override
  Set<Column> get primaryKey => {idVersaoMusica};
}

class EnergiasMusicas extends Table {
  TextColumn get idMusica =>
      text().references(IndiceMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get energia => text()();

  @override
  Set<Column> get primaryKey => {idMusica};
}

class TagsMusicas extends Table {
  TextColumn get idMusica =>
      text().references(IndiceMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get chave => text()();

  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {idMusica, chave};
}

@DataClassName('MinistranteRegistro')
class Ministrantes extends Table {
  TextColumn get id => text()();

  TextColumn get nome => text()();

  BoolColumn get arquivado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ListasCulto extends Table {
  TextColumn get id => text()();

  TextColumn get nome => text()();

  IntColumn get data => integer().nullable()();

  TextColumn get idMinistrante => text().nullable().references(
    Ministrantes,
    #id,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get criadaEm => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ItensListaCulto extends Table {
  TextColumn get id => text()();

  TextColumn get idLista => text().references(ListasCulto, #id)();

  TextColumn get idMusica => text().references(IndiceMusicas, #id)();

  TextColumn get idVersaoMusica => text().references(VersoesMusicas, #id)();

  IntColumn get posicao => integer()();

  TextColumn get tom => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    IndiceMusicas,
    VersoesMusicas,
    IndicesPesquisaMusicas,
    OrigensSincronizadasVersoes,
    ConfiguracoesPastaSincronizada,
    EstadosBibliotecaOficial,
    PreferenciasTomExecucao,
    EnergiasMusicas,
    TagsMusicas,
    Ministrantes,
    ListasCulto,
    ItensListaCulto,
  ],
)
class BancoBiblioteca extends _$BancoBiblioteca {
  BancoBiblioteca(super.executor);

  factory BancoBiblioteca.local() => BancoBiblioteca(_abrirLocalmente());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _criarIndiceItensListaCulto();
      await _criarIndiceItensListaCultoVersaoLista();
      await _criarIndiceTagsMusicas();
      await _criarIndicesVersoesMusicas();
      await _criarIndiceMinistrantesArquivadaNome();
      await _criarIndiceListasCultoMinistranteData();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(preferenciasTomExecucao);
      }
      if (from < 3) {
        await migrator.createTable(listasCulto);
        await migrator.createTable(itensListaCulto);
        await _criarIndiceItensListaCulto();
      }
      if (from < 4) {
        await migrator.createTable(energiasMusicas);
        await migrator.createTable(tagsMusicas);
        await _criarIndiceTagsMusicas();
      }
      if (from < 5) {
        await migrator.createTable(versoesMusicas);
        await customStatement(
          "INSERT INTO versoes_musicas "
          "(id, id_musica, nome, arquivo, principal, arquivada) "
          "SELECT id, id, 'Principal', arquivo, 1, 0 FROM indice_musicas",
        );
        await customStatement(
          'ALTER TABLE preferencias_tom_execucao '
          'RENAME TO preferencias_tom_execucao_legado',
        );
        await migrator.createTable(preferenciasTomExecucao);
        await customStatement(
          'INSERT INTO preferencias_tom_execucao '
          '(id_versao_musica, nome_nota, alteracao, modo) '
          'SELECT id_musica, nome_nota, alteracao, modo '
          'FROM preferencias_tom_execucao_legado',
        );
        await customStatement('DROP TABLE preferencias_tom_execucao_legado');
        await customStatement(
          'ALTER TABLE itens_lista_culto RENAME TO itens_lista_culto_legado',
        );
        await migrator.createTable(itensListaCulto);
        await customStatement(
          'INSERT INTO itens_lista_culto '
          '(id, id_lista, id_musica, id_versao_musica, posicao) '
          'SELECT id, id_lista, id_musica, id_musica, posicao '
          'FROM itens_lista_culto_legado',
        );
        await customStatement('DROP TABLE itens_lista_culto_legado');
        await _criarIndiceItensListaCulto();
        await _criarIndicesVersoesMusicas();
      }
      if (from < 6) {
        await migrator.createTable(origensSincronizadasVersoes);
        await migrator.createTable(configuracoesPastaSincronizada);
      }
      if (from < 7) {
        await migrator.createTable(estadosBibliotecaOficial);
      }
      if (from < 8) {
        await migrator.createTable(ministrantes);
        if (from >= 3) {
          await migrator.addColumn(listasCulto, listasCulto.data);
          await migrator.addColumn(listasCulto, listasCulto.idMinistrante);
          await migrator.addColumn(listasCulto, listasCulto.criadaEm);
        }
        if (from >= 5) {
          await migrator.addColumn(itensListaCulto, itensListaCulto.tom);
        }
        await _criarIndiceItensListaCultoVersaoLista();
        await _criarIndiceMinistrantesArquivadaNome();
        await _criarIndiceListasCultoMinistranteData();
      }
      if (from < 9) {
        await migrator.createTable(indicesPesquisaMusicas);
      }
      if (from >= 9 && from < 10) {
        await migrator.addColumn(
          indicesPesquisaMusicas,
          indicesPesquisaMusicas.tituloNormalizado,
        );
        await migrator.addColumn(
          indicesPesquisaMusicas,
          indicesPesquisaMusicas.textoNormalizado,
        );
      }
    },
  );

  Future<void> inicializar() async {
    await customSelect('SELECT 1').get();
  }

  Future<IndiceMusica?> obterPorId(String id) => (select(
    indiceMusicas,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<List<IndiceMusica>> listar() => select(indiceMusicas).get();

  Future<List<RegistroItemBiblioteca>> listarItensBiblioteca() async {
    final linhas = await customSelect(
      'SELECT m.id, m.titulo, m.artista, v.id AS id_versao_principal, '
      'p.conteudo_visivel, p.titulo_normalizado, p.texto_normalizado '
      'FROM indice_musicas m '
      'LEFT JOIN versoes_musicas v '
      'ON v.id_musica = m.id AND v.principal = 1 '
      'LEFT JOIN indices_pesquisa_musicas p '
      'ON p.id_musica = m.id AND p.id_versao_musica = v.id',
      readsFrom: {indiceMusicas, versoesMusicas, indicesPesquisaMusicas},
    ).get();
    return [
      for (final linha in linhas)
        RegistroItemBiblioteca(
          idMusica: linha.read<String>('id'),
          idVersaoPrincipal: linha.readNullable<String>('id_versao_principal'),
          titulo: linha.read<String>('titulo'),
          artista: linha.read<String>('artista'),
          conteudoVisivel: linha.readNullable<String>('conteudo_visivel'),
          tituloNormalizado: linha.readNullable<String>('titulo_normalizado'),
          textoNormalizado: linha.readNullable<String>('texto_normalizado'),
        ),
    ];
  }

  Future<void> salvarIndicePesquisaMusica({
    required String idMusica,
    required String idVersaoMusica,
    required String conteudoVisivel,
    required String tituloNormalizado,
    required String textoNormalizado,
  }) => into(indicesPesquisaMusicas).insertOnConflictUpdate(
    IndicesPesquisaMusicasCompanion.insert(
      idMusica: idMusica,
      idVersaoMusica: idVersaoMusica,
      conteudoVisivel: conteudoVisivel,
      tituloNormalizado: Value(tituloNormalizado),
      textoNormalizado: Value(textoNormalizado),
    ),
  );

  Future<void> salvarIndicesPesquisaMusicas(
    Iterable<RegistroIndicePesquisaMusica> registros,
  ) => batch((lote) {
    lote.insertAllOnConflictUpdate(indicesPesquisaMusicas, [
      for (final registro in registros)
        IndicesPesquisaMusicasCompanion.insert(
          idMusica: registro.idMusica,
          idVersaoMusica: registro.idVersaoMusica,
          conteudoVisivel: registro.conteudoVisivel,
          tituloNormalizado: Value(registro.tituloNormalizado),
          textoNormalizado: Value(registro.textoNormalizado),
        ),
    ]);
  });

  Future<List<IndiceMusica>> listarMusicasPorIds(Iterable<String> ids) {
    final idsUnicos = ids.toSet();
    if (idsUnicos.isEmpty) return Future.value(const []);
    return (select(
      indiceMusicas,
    )..where((tabela) => tabela.id.isIn(idsUnicos))).get();
  }

  Future<void> inserir({
    required String id,
    required String titulo,
    required String artista,
    required String arquivo,
  }) async {
    await into(indiceMusicas).insert(
      IndiceMusicasCompanion.insert(
        id: id,
        titulo: titulo,
        artista: artista,
        arquivo: arquivo,
      ),
    );
  }

  Future<int> atualizar({
    required String id,
    required String titulo,
    required String artista,
  }) => (update(indiceMusicas)..where((tabela) => tabela.id.equals(id))).write(
    IndiceMusicasCompanion(titulo: Value(titulo), artista: Value(artista)),
  );

  Future<void> excluirPorId(String id) async {
    await (delete(indiceMusicas)..where((tabela) => tabela.id.equals(id))).go();
  }

  Future<VersoesMusica?> obterVersaoPrincipalPorMusica(String idMusica) =>
      (select(versoesMusicas)..where(
            (tabela) =>
                tabela.idMusica.equals(idMusica) &
                tabela.principal.equals(true),
          ))
          .getSingleOrNull();

  Future<VersoesMusica?> obterVersaoPorId(String id) => (select(
    versoesMusicas,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<List<VersoesMusica>> listarVersoesPorIds(Iterable<String> ids) {
    final idsUnicos = ids.toSet();
    if (idsUnicos.isEmpty) return Future.value(const []);
    return (select(
      versoesMusicas,
    )..where((tabela) => tabela.id.isIn(idsUnicos))).get();
  }

  Future<List<VersoesMusica>> listarVersoesMusica(String idMusica) =>
      (select(versoesMusicas)
            ..where((tabela) => tabela.idMusica.equals(idMusica))
            ..orderBy([
              (tabela) => OrderingTerm.desc(tabela.principal),
              (tabela) => OrderingTerm.asc(tabela.nome),
            ]))
          .get();

  Future<void> inserirVersaoMusica({
    required String id,
    required String idMusica,
    required String nome,
    required String arquivo,
    required bool principal,
    required bool arquivada,
  }) => into(versoesMusicas).insert(
    VersoesMusicasCompanion.insert(
      id: id,
      idMusica: idMusica,
      nome: nome,
      arquivo: arquivo,
      principal: principal,
      arquivada: arquivada,
    ),
  );

  Future<bool> possuiItemListaParaVersao(String idVersaoMusica) async {
    final resultado = await customSelect(
      'SELECT 1 FROM itens_lista_culto WHERE id_versao_musica = ? LIMIT 1',
      variables: [Variable.withString(idVersaoMusica)],
    ).get();
    return resultado.isNotEmpty;
  }

  Future<void> renomearVersaoMusica(String id, String nome) async {
    await (update(versoesMusicas)..where((tabela) => tabela.id.equals(id)))
        .write(VersoesMusicasCompanion(nome: Value(nome)));
  }

  Future<void> definirVersaoPrincipal(String idMusica, String id) =>
      transaction(() async {
        await (update(versoesMusicas)
              ..where((tabela) => tabela.idMusica.equals(idMusica)))
            .write(const VersoesMusicasCompanion(principal: Value(false)));
        await (update(versoesMusicas)..where((tabela) => tabela.id.equals(id)))
            .write(const VersoesMusicasCompanion(principal: Value(true)));
      });

  Future<void> definirArquivadaVersao(String id, bool arquivada) async {
    await (update(versoesMusicas)..where((tabela) => tabela.id.equals(id)))
        .write(VersoesMusicasCompanion(arquivada: Value(arquivada)));
  }

  Future<void> excluirVersaoMusica(String id) => transaction(() async {
    await (delete(
      origensSincronizadasVersoes,
    )..where((tabela) => tabela.idVersaoMusica.equals(id))).go();
    await (delete(
      preferenciasTomExecucao,
    )..where((tabela) => tabela.idVersaoMusica.equals(id))).go();
    await (delete(
      versoesMusicas,
    )..where((tabela) => tabela.id.equals(id))).go();
  });

  Future<OrigemSincronizadaVersaoRegistro?> obterOrigemSincronizadaVersao(
    String idVersaoMusica,
  ) =>
      (select(origensSincronizadasVersoes)
            ..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica)))
          .getSingleOrNull();

  Future<List<OrigemSincronizadaVersaoRegistro>>
  listarOrigensSincronizadasVersoes() =>
      select(origensSincronizadasVersoes).get();

  Future<List<OrigemSincronizadaVersaoRegistro>>
  listarOrigensSincronizadasVersoesPorIds(Set<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (select(
      origensSincronizadasVersoes,
    )..where((tabela) => tabela.idVersaoMusica.isIn(ids))).get();
  }

  Future<T> executarEmTransacao<T>(Future<T> Function() acao) =>
      transaction(acao);

  Future<void> salvarOrigemSincronizadaVersao({
    required String idVersaoMusica,
    required String localizadorExterno,
    required String hashSha256,
    required bool presente,
  }) => into(origensSincronizadasVersoes).insertOnConflictUpdate(
    OrigensSincronizadasVersoesCompanion.insert(
      idVersaoMusica: idVersaoMusica,
      localizadorExterno: localizadorExterno,
      hashSha256: hashSha256,
      presente: presente,
    ),
  );

  Future<int> marcarOrigemSincronizadaAusente(String idVersaoMusica) =>
      (update(
        origensSincronizadasVersoes,
      )..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica))).write(
        const OrigensSincronizadasVersoesCompanion(presente: Value(false)),
      );

  Future<int> marcarOrigemSincronizadaPresente({
    required String idVersaoMusica,
    required String localizadorExterno,
    required String hashSha256,
  }) =>
      (update(
        origensSincronizadasVersoes,
      )..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica))).write(
        OrigensSincronizadasVersoesCompanion(
          localizadorExterno: Value(localizadorExterno),
          hashSha256: Value(hashSha256),
          presente: const Value(true),
        ),
      );

  Future<void> removerOrigemSincronizadaVersao(String idVersaoMusica) async {
    await (delete(
      origensSincronizadasVersoes,
    )..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica))).go();
  }

  Future<EstadoBibliotecaOficialRegistro?> obterEstadoBibliotecaOficial() =>
      (select(
        estadosBibliotecaOficial,
      )..where((tabela) => tabela.id.equals(1))).getSingleOrNull();

  Future<void> salvarEstadoBibliotecaOficial({
    required String ultimaGeracao,
    required DateTime ultimaAtualizacao,
  }) => into(estadosBibliotecaOficial).insertOnConflictUpdate(
    EstadosBibliotecaOficialCompanion.insert(
      id: const Value(1),
      ultimaGeracao: ultimaGeracao,
      ultimaAtualizacao: ultimaAtualizacao,
    ),
  );

  Future<bool> possuiItemListaParaMusica(String idMusica) async {
    final resultado = await customSelect(
      'SELECT 1 FROM itens_lista_culto '
      'WHERE id_musica = ? LIMIT 1',
      variables: [Variable.withString(idMusica)],
    ).get();
    return resultado.isNotEmpty;
  }

  Future<PreferenciasTomExecucaoData?> obterTomExecucaoPorVersao(
    String idVersaoMusica,
  ) =>
      (select(preferenciasTomExecucao)
            ..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica)))
          .getSingleOrNull();

  Future<void> salvarTomExecucao({
    required String idVersaoMusica,
    required String nomeNota,
    required String alteracao,
    required String modo,
  }) => into(preferenciasTomExecucao).insertOnConflictUpdate(
    PreferenciasTomExecucaoCompanion.insert(
      idVersaoMusica: idVersaoMusica,
      nomeNota: nomeNota,
      alteracao: alteracao,
      modo: modo,
    ),
  );

  Future<void> removerTomExecucao(String idVersaoMusica) async {
    await (delete(
      preferenciasTomExecucao,
    )..where((tabela) => tabela.idVersaoMusica.equals(idVersaoMusica))).go();
  }

  Future<EnergiasMusica?> obterEnergiaMusica(String idMusica) => (select(
    energiasMusicas,
  )..where((tabela) => tabela.idMusica.equals(idMusica))).getSingleOrNull();

  Future<List<EnergiasMusica>> listarEnergiasMusicas() =>
      select(energiasMusicas).get();

  Future<void> definirEnergiaMusica(String idMusica, String? energia) async {
    if (energia == null) {
      await (delete(
        energiasMusicas,
      )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
      return;
    }
    await into(energiasMusicas).insertOnConflictUpdate(
      EnergiasMusicasCompanion.insert(idMusica: idMusica, energia: energia),
    );
  }

  Future<List<TagsMusica>> listarTagsMusica(String idMusica) =>
      (select(tagsMusicas)
            ..where((tabela) => tabela.idMusica.equals(idMusica))
            ..orderBy([(tabela) => OrderingTerm.asc(tabela.valor)]))
          .get();

  Future<List<TagsMusica>> listarTodasTagsMusicas() =>
      (select(tagsMusicas)..orderBy([
            (tabela) => OrderingTerm.asc(tabela.idMusica),
            (tabela) => OrderingTerm.asc(tabela.valor),
          ]))
          .get();

  Future<void> substituirTagsMusica(
    String idMusica,
    Iterable<({String valor, String chave})> tags,
  ) => transaction(() async {
    await (delete(
      tagsMusicas,
    )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
    for (final tag in tags) {
      await into(tagsMusicas).insert(
        TagsMusicasCompanion.insert(
          idMusica: idMusica,
          chave: tag.chave,
          valor: tag.valor,
        ),
      );
    }
  });

  Future<void> removerClassificacaoMusica(String idMusica) =>
      transaction(() async {
        await (delete(
          energiasMusicas,
        )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
        await (delete(
          tagsMusicas,
        )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
      });

  Future<void> inserirMinistrante({
    required String id,
    required String nome,
    required bool arquivado,
  }) => into(ministrantes).insert(
    MinistrantesCompanion.insert(
      id: id,
      nome: nome,
      arquivado: Value(arquivado),
    ),
  );

  Future<MinistranteRegistro?> obterMinistrantePorId(String id) => (select(
    ministrantes,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<List<MinistranteRegistro>> listarMinistrantes({
    required bool incluirArquivados,
  }) {
    final consulta = select(ministrantes)
      ..orderBy([
        (tabela) => OrderingTerm.asc(tabela.arquivado),
        (tabela) => OrderingTerm.asc(tabela.nome),
        (tabela) => OrderingTerm.asc(tabela.id),
      ]);
    if (!incluirArquivados) {
      consulta.where((tabela) => tabela.arquivado.equals(false));
    }
    return consulta.get();
  }

  Future<int> renomearMinistrante({required String id, required String nome}) =>
      (update(ministrantes)..where((tabela) => tabela.id.equals(id))).write(
        MinistrantesCompanion(nome: Value(nome)),
      );

  Future<int> definirMinistranteArquivado({
    required String id,
    required bool arquivado,
  }) => (update(ministrantes)..where((tabela) => tabela.id.equals(id))).write(
    MinistrantesCompanion(arquivado: Value(arquivado)),
  );

  Future<void> inserirListaCulto({
    required String id,
    required String nome,
    int? data,
    String? idMinistrante,
    DateTime? criadaEm,
  }) => into(listasCulto).insert(
    ListasCultoCompanion.insert(
      id: id,
      nome: nome,
      data: Value(data),
      idMinistrante: Value(idMinistrante),
      criadaEm: Value(criadaEm),
    ),
  );

  Future<ListasCultoData?> obterListaCultoPorId(String id) => (select(
    listasCulto,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<List<ListasCultoData>> listarListasCulto() => (select(
    listasCulto,
  )..orderBy([(tabela) => OrderingTerm.asc(tabela.nome)])).get();

  Future<int> renomearListaCulto({required String id, required String nome}) =>
      (update(listasCulto)..where((tabela) => tabela.id.equals(id))).write(
        ListasCultoCompanion(nome: Value(nome)),
      );

  Future<int> excluirListaCulto(String id) => transaction(() async {
    await (delete(
      itensListaCulto,
    )..where((tabela) => tabela.idLista.equals(id))).go();
    return (delete(listasCulto)..where((tabela) => tabela.id.equals(id))).go();
  });

  Future<List<ItensListaCultoData>> listarItensListaCulto(String idLista) =>
      (select(itensListaCulto)
            ..where((tabela) => tabela.idLista.equals(idLista))
            ..orderBy([
              (tabela) => OrderingTerm.asc(tabela.posicao),
              (tabela) => OrderingTerm.asc(tabela.id),
            ]))
          .get();

  Future<ItensListaCultoData?> obterItemListaCultoPorId(String id) => (select(
    itensListaCulto,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<void> inserirItemListaCulto({
    required String id,
    required String idLista,
    required String idMusica,
    required String idVersaoMusica,
    required int posicao,
    String? tom,
  }) => into(itensListaCulto).insert(
    ItensListaCultoCompanion.insert(
      id: id,
      idLista: idLista,
      idMusica: idMusica,
      idVersaoMusica: idVersaoMusica,
      posicao: posicao,
      tom: Value(tom),
    ),
  );

  Future<int> removerItemListaCulto({
    required String idLista,
    required String idItem,
  }) => transaction(() async {
    final removidos =
        await (delete(itensListaCulto)..where(
              (tabela) =>
                  tabela.id.equals(idItem) & tabela.idLista.equals(idLista),
            ))
            .go();
    if (removidos == 1) {
      await _normalizarPosicoesItensListaCulto(idLista);
    }
    return removidos;
  });

  Future<int> atualizarVersaoItemListaCulto({
    required String idLista,
    required String idItem,
    required String idVersaoMusica,
  }) =>
      (update(itensListaCulto)..where(
            (tabela) =>
                tabela.id.equals(idItem) & tabela.idLista.equals(idLista),
          ))
          .write(
            ItensListaCultoCompanion(idVersaoMusica: Value(idVersaoMusica)),
          );

  Future<void> reordenarItensListaCulto({
    required String idLista,
    required List<String> idsNaOrdem,
  }) => transaction(() async {
    for (var posicao = 0; posicao < idsNaOrdem.length; posicao++) {
      await (update(itensListaCulto)..where(
            (tabela) =>
                tabela.id.equals(idsNaOrdem[posicao]) &
                tabela.idLista.equals(idLista),
          ))
          .write(ItensListaCultoCompanion(posicao: Value(posicao)));
    }
  });

  Future<void> _normalizarPosicoesItensListaCulto(String idLista) async {
    final itens = await listarItensListaCulto(idLista);
    for (var posicao = 0; posicao < itens.length; posicao++) {
      await (update(itensListaCulto)
            ..where((tabela) => tabela.id.equals(itens[posicao].id)))
          .write(ItensListaCultoCompanion(posicao: Value(posicao)));
    }
  }

  Future<void> _criarIndiceItensListaCulto() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_itens_lista_culto_lista_posicao '
    'ON itens_lista_culto (id_lista, posicao)',
  );

  Future<void> _criarIndiceItensListaCultoVersaoLista() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_itens_lista_culto_versao_lista '
    'ON itens_lista_culto (id_versao_musica, id_lista)',
  );

  Future<void> _criarIndiceTagsMusicas() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_tags_musicas_chave ON tags_musicas (chave)',
  );

  Future<void> _criarIndiceMinistrantesArquivadaNome() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_ministrantes_arquivado_nome '
    'ON ministrantes (arquivado, nome)',
  );

  Future<void> _criarIndiceListasCultoMinistranteData() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_listas_culto_ministrante_data '
    'ON listas_culto (id_ministrante, data)',
  );

  Future<void> _criarIndicesVersoesMusicas() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_versoes_musicas_musica '
      'ON versoes_musicas (id_musica)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_versoes_musicas_principal '
      'ON versoes_musicas (id_musica) WHERE principal = 1',
    );
  }
}

LazyDatabase _abrirLocalmente() => LazyDatabase(() async {
  final diretorio = await getApplicationSupportDirectory();
  final arquivo = File(
    '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
  );
  return NativeDatabase.createInBackground(arquivo);
});
