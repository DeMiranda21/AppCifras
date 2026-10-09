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

class ListasCulto extends Table {
  TextColumn get id => text()();

  TextColumn get nome => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ItensListaCulto extends Table {
  TextColumn get id => text()();

  TextColumn get idLista => text().references(ListasCulto, #id)();

  TextColumn get idMusica => text().references(IndiceMusicas, #id)();

  TextColumn get idVersaoMusica => text().references(VersoesMusicas, #id)();

  IntColumn get posicao => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    IndiceMusicas,
    VersoesMusicas,
    PreferenciasTomExecucao,
    EnergiasMusicas,
    TagsMusicas,
    ListasCulto,
    ItensListaCulto,
  ],
)
class BancoBiblioteca extends _$BancoBiblioteca {
  BancoBiblioteca(super.executor);

  factory BancoBiblioteca.local() => BancoBiblioteca(_abrirLocalmente());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _criarIndiceItensListaCulto();
      await _criarIndiceTagsMusicas();
      await _criarIndicesVersoesMusicas();
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
    },
  );

  Future<void> inicializar() async {
    await customSelect('SELECT 1').get();
  }

  Future<IndiceMusica?> obterPorId(String id) => (select(
    indiceMusicas,
  )..where((tabela) => tabela.id.equals(id))).getSingleOrNull();

  Future<List<IndiceMusica>> listar() => select(indiceMusicas).get();

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
      preferenciasTomExecucao,
    )..where((tabela) => tabela.idVersaoMusica.equals(id))).go();
    await (delete(
      versoesMusicas,
    )..where((tabela) => tabela.id.equals(id))).go();
  });
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

  Future<void> inserirListaCulto({required String id, required String nome}) =>
      into(listasCulto).insert(ListasCultoCompanion.insert(id: id, nome: nome));

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
  }) => into(itensListaCulto).insert(
    ItensListaCultoCompanion.insert(
      id: id,
      idLista: idLista,
      idMusica: idMusica,
      idVersaoMusica: idVersaoMusica,
      posicao: posicao,
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

  Future<void> _criarIndiceTagsMusicas() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_tags_musicas_chave ON tags_musicas (chave)',
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
