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

@DriftDatabase(tables: [IndiceMusicas])
class BancoBiblioteca extends _$BancoBiblioteca {
  BancoBiblioteca(super.executor);

  factory BancoBiblioteca.local() => BancoBiblioteca(_abrirLocalmente());

  @override
  int get schemaVersion => 1;

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

  Future<void> excluirPorId(String id) async {
    await (delete(indiceMusicas)..where((tabela) => tabela.id.equals(id))).go();
  }
}

LazyDatabase _abrirLocalmente() => LazyDatabase(() async {
  final diretorio = await getApplicationSupportDirectory();
  final arquivo = File(
    '${diretorio.path}${Platform.pathSeparator}biblioteca.sqlite',
  );
  return NativeDatabase.createInBackground(arquivo);
});
