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

@DriftDatabase(tables: [IndiceMusicas, PreferenciasTomExecucao])
class BancoBiblioteca extends _$BancoBiblioteca {
  BancoBiblioteca(super.executor);

  factory BancoBiblioteca.local() => BancoBiblioteca(_abrirLocalmente());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(preferenciasTomExecucao);
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

  Future<PreferenciasTomExecucaoData?> obterTomExecucaoPorMusica(
    String idMusica,
  ) => (select(preferenciasTomExecucao)
        ..where((tabela) => tabela.idMusica.equals(idMusica)))
      .getSingleOrNull();

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
    await (delete(preferenciasTomExecucao)
          ..where((tabela) => tabela.idMusica.equals(idMusica)))
        .go();
  }
}

LazyDatabase _abrirLocalmente() => LazyDatabase(() async {
  final diretorio = await getApplicationSupportDirectory();
  final arquivo = File(
    '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
  );
  return NativeDatabase.createInBackground(arquivo);
});
