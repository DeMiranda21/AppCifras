// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banco_biblioteca.dart';

// ignore_for_file: type=lint
class $IndiceMusicasTable extends IndiceMusicas
    with TableInfo<$IndiceMusicasTable, IndiceMusica> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndiceMusicasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistaMeta = const VerificationMeta(
    'artista',
  );
  @override
  late final GeneratedColumn<String> artista = GeneratedColumn<String>(
    'artista',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arquivoMeta = const VerificationMeta(
    'arquivo',
  );
  @override
  late final GeneratedColumn<String> arquivo = GeneratedColumn<String>(
    'arquivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, titulo, artista, arquivo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indice_musicas';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndiceMusica> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('artista')) {
      context.handle(
        _artistaMeta,
        artista.isAcceptableOrUnknown(data['artista']!, _artistaMeta),
      );
    } else if (isInserting) {
      context.missing(_artistaMeta);
    }
    if (data.containsKey('arquivo')) {
      context.handle(
        _arquivoMeta,
        arquivo.isAcceptableOrUnknown(data['arquivo']!, _arquivoMeta),
      );
    } else if (isInserting) {
      context.missing(_arquivoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndiceMusica map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndiceMusica(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      artista: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artista'],
      )!,
      arquivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arquivo'],
      )!,
    );
  }

  @override
  $IndiceMusicasTable createAlias(String alias) {
    return $IndiceMusicasTable(attachedDatabase, alias);
  }
}

class IndiceMusica extends DataClass implements Insertable<IndiceMusica> {
  final String id;
  final String titulo;
  final String artista;
  final String arquivo;
  const IndiceMusica({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.arquivo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['titulo'] = Variable<String>(titulo);
    map['artista'] = Variable<String>(artista);
    map['arquivo'] = Variable<String>(arquivo);
    return map;
  }

  IndiceMusicasCompanion toCompanion(bool nullToAbsent) {
    return IndiceMusicasCompanion(
      id: Value(id),
      titulo: Value(titulo),
      artista: Value(artista),
      arquivo: Value(arquivo),
    );
  }

  factory IndiceMusica.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndiceMusica(
      id: serializer.fromJson<String>(json['id']),
      titulo: serializer.fromJson<String>(json['titulo']),
      artista: serializer.fromJson<String>(json['artista']),
      arquivo: serializer.fromJson<String>(json['arquivo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'titulo': serializer.toJson<String>(titulo),
      'artista': serializer.toJson<String>(artista),
      'arquivo': serializer.toJson<String>(arquivo),
    };
  }

  IndiceMusica copyWith({
    String? id,
    String? titulo,
    String? artista,
    String? arquivo,
  }) => IndiceMusica(
    id: id ?? this.id,
    titulo: titulo ?? this.titulo,
    artista: artista ?? this.artista,
    arquivo: arquivo ?? this.arquivo,
  );
  IndiceMusica copyWithCompanion(IndiceMusicasCompanion data) {
    return IndiceMusica(
      id: data.id.present ? data.id.value : this.id,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      artista: data.artista.present ? data.artista.value : this.artista,
      arquivo: data.arquivo.present ? data.arquivo.value : this.arquivo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndiceMusica(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('artista: $artista, ')
          ..write('arquivo: $arquivo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, titulo, artista, arquivo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndiceMusica &&
          other.id == this.id &&
          other.titulo == this.titulo &&
          other.artista == this.artista &&
          other.arquivo == this.arquivo);
}

class IndiceMusicasCompanion extends UpdateCompanion<IndiceMusica> {
  final Value<String> id;
  final Value<String> titulo;
  final Value<String> artista;
  final Value<String> arquivo;
  final Value<int> rowid;
  const IndiceMusicasCompanion({
    this.id = const Value.absent(),
    this.titulo = const Value.absent(),
    this.artista = const Value.absent(),
    this.arquivo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IndiceMusicasCompanion.insert({
    required String id,
    required String titulo,
    required String artista,
    required String arquivo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titulo = Value(titulo),
       artista = Value(artista),
       arquivo = Value(arquivo);
  static Insertable<IndiceMusica> custom({
    Expression<String>? id,
    Expression<String>? titulo,
    Expression<String>? artista,
    Expression<String>? arquivo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titulo != null) 'titulo': titulo,
      if (artista != null) 'artista': artista,
      if (arquivo != null) 'arquivo': arquivo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IndiceMusicasCompanion copyWith({
    Value<String>? id,
    Value<String>? titulo,
    Value<String>? artista,
    Value<String>? arquivo,
    Value<int>? rowid,
  }) {
    return IndiceMusicasCompanion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      artista: artista ?? this.artista,
      arquivo: arquivo ?? this.arquivo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (artista.present) {
      map['artista'] = Variable<String>(artista.value);
    }
    if (arquivo.present) {
      map['arquivo'] = Variable<String>(arquivo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndiceMusicasCompanion(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('artista: $artista, ')
          ..write('arquivo: $arquivo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BancoBiblioteca extends GeneratedDatabase {
  _$BancoBiblioteca(QueryExecutor e) : super(e);
  $BancoBibliotecaManager get managers => $BancoBibliotecaManager(this);
  late final $IndiceMusicasTable indiceMusicas = $IndiceMusicasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [indiceMusicas];
}

typedef $$IndiceMusicasTableCreateCompanionBuilder =
    IndiceMusicasCompanion Function({
      required String id,
      required String titulo,
      required String artista,
      required String arquivo,
      Value<int> rowid,
    });
typedef $$IndiceMusicasTableUpdateCompanionBuilder =
    IndiceMusicasCompanion Function({
      Value<String> id,
      Value<String> titulo,
      Value<String> artista,
      Value<String> arquivo,
      Value<int> rowid,
    });

class $$IndiceMusicasTableFilterComposer
    extends Composer<_$BancoBiblioteca, $IndiceMusicasTable> {
  $$IndiceMusicasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artista => $composableBuilder(
    column: $table.artista,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arquivo => $composableBuilder(
    column: $table.arquivo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndiceMusicasTableOrderingComposer
    extends Composer<_$BancoBiblioteca, $IndiceMusicasTable> {
  $$IndiceMusicasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artista => $composableBuilder(
    column: $table.artista,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arquivo => $composableBuilder(
    column: $table.arquivo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndiceMusicasTableAnnotationComposer
    extends Composer<_$BancoBiblioteca, $IndiceMusicasTable> {
  $$IndiceMusicasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get artista =>
      $composableBuilder(column: $table.artista, builder: (column) => column);

  GeneratedColumn<String> get arquivo =>
      $composableBuilder(column: $table.arquivo, builder: (column) => column);
}

class $$IndiceMusicasTableTableManager
    extends
        RootTableManager<
          _$BancoBiblioteca,
          $IndiceMusicasTable,
          IndiceMusica,
          $$IndiceMusicasTableFilterComposer,
          $$IndiceMusicasTableOrderingComposer,
          $$IndiceMusicasTableAnnotationComposer,
          $$IndiceMusicasTableCreateCompanionBuilder,
          $$IndiceMusicasTableUpdateCompanionBuilder,
          (
            IndiceMusica,
            BaseReferences<
              _$BancoBiblioteca,
              $IndiceMusicasTable,
              IndiceMusica
            >,
          ),
          IndiceMusica,
          PrefetchHooks Function()
        > {
  $$IndiceMusicasTableTableManager(
    _$BancoBiblioteca db,
    $IndiceMusicasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndiceMusicasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndiceMusicasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndiceMusicasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String> artista = const Value.absent(),
                Value<String> arquivo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IndiceMusicasCompanion(
                id: id,
                titulo: titulo,
                artista: artista,
                arquivo: arquivo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String titulo,
                required String artista,
                required String arquivo,
                Value<int> rowid = const Value.absent(),
              }) => IndiceMusicasCompanion.insert(
                id: id,
                titulo: titulo,
                artista: artista,
                arquivo: arquivo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IndiceMusicasTable, IndiceMusica>(table),
                  BaseReferences<
                    _$BancoBiblioteca,
                    $IndiceMusicasTable,
                    IndiceMusica
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndiceMusicasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoBiblioteca,
      $IndiceMusicasTable,
      IndiceMusica,
      $$IndiceMusicasTableFilterComposer,
      $$IndiceMusicasTableOrderingComposer,
      $$IndiceMusicasTableAnnotationComposer,
      $$IndiceMusicasTableCreateCompanionBuilder,
      $$IndiceMusicasTableUpdateCompanionBuilder,
      (
        IndiceMusica,
        BaseReferences<_$BancoBiblioteca, $IndiceMusicasTable, IndiceMusica>,
      ),
      IndiceMusica,
      PrefetchHooks Function()
    >;

class $BancoBibliotecaManager {
  final _$BancoBiblioteca _db;
  $BancoBibliotecaManager(this._db);
  $$IndiceMusicasTableTableManager get indiceMusicas =>
      $$IndiceMusicasTableTableManager(_db, _db.indiceMusicas);
}
