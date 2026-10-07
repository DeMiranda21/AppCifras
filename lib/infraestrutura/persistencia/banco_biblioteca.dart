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

class PreferenciasTomExecucao extends Table {
  TextColumn get idMusica =>
      text().references(IndiceMusicas, #id, onDelete: KeyAction.cascade)();

  TextColumn get nomeNota => text()();

  TextColumn get alteracao => text()();

  TextColumn get modo => text()();

  @override
  Set<Column> get primaryKey => {idMusica};
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

  IntColumn get posicao => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    IndiceMusicas,
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _criarIndiceItensListaCulto();
      await _criarIndiceTagsMusicas();
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

  Future<void> excluirMusicaEItensListaCulto(String idMusica) =>
      transaction(() async {
        final listasAfetadas = await (select(
          itensListaCulto,
        )..where((tabela) => tabela.idMusica.equals(idMusica))).get();
        await (delete(
          itensListaCulto,
        )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
        for (final idLista
            in listasAfetadas.map((item) => item.idLista).toSet()) {
          await _normalizarPosicoesItensListaCulto(idLista);
        }
        await excluirPorId(idMusica);
      });

  Future<PreferenciasTomExecucaoData?> obterTomExecucaoPorMusica(
    String idMusica,
  ) => (select(
    preferenciasTomExecucao,
  )..where((tabela) => tabela.idMusica.equals(idMusica))).getSingleOrNull();

  Future<void> salvarTomExecucao({
    required String idMusica,
    required String nomeNota,
    required String alteracao,
    required String modo,
  }) => into(preferenciasTomExecucao).insertOnConflictUpdate(
    PreferenciasTomExecucaoCompanion.insert(
      idMusica: idMusica,
      nomeNota: nomeNota,
      alteracao: alteracao,
      modo: modo,
    ),
  );

  Future<void> removerTomExecucao(String idMusica) async {
    await (delete(
      preferenciasTomExecucao,
    )..where((tabela) => tabela.idMusica.equals(idMusica))).go();
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
    required int posicao,
  }) => into(itensListaCulto).insert(
    ItensListaCultoCompanion.insert(
      id: id,
      idLista: idLista,
      idMusica: idMusica,
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
}

LazyDatabase _abrirLocalmente() => LazyDatabase(() async {
  final diretorio = await getApplicationSupportDirectory();
  final arquivo = File(
    '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
  );
  return NativeDatabase.createInBackground(arquivo);
});
