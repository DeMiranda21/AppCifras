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

class $PreferenciasTomExecucaoTable extends PreferenciasTomExecucao
    with TableInfo<$PreferenciasTomExecucaoTable, PreferenciasTomExecucaoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenciasTomExecucaoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMusicaMeta = const VerificationMeta(
    'idMusica',
  );
  @override
  late final GeneratedColumn<String> idMusica = GeneratedColumn<String>(
    'id_musica',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES indice_musicas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nomeNotaMeta = const VerificationMeta(
    'nomeNota',
  );
  @override
  late final GeneratedColumn<String> nomeNota = GeneratedColumn<String>(
    'nome_nota',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alteracaoMeta = const VerificationMeta(
    'alteracao',
  );
  @override
  late final GeneratedColumn<String> alteracao = GeneratedColumn<String>(
    'alteracao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modoMeta = const VerificationMeta('modo');
  @override
  late final GeneratedColumn<String> modo = GeneratedColumn<String>(
    'modo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [idMusica, nomeNota, alteracao, modo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferencias_tom_execucao';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenciasTomExecucaoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_musica')) {
      context.handle(
        _idMusicaMeta,
        idMusica.isAcceptableOrUnknown(data['id_musica']!, _idMusicaMeta),
      );
    } else if (isInserting) {
      context.missing(_idMusicaMeta);
    }
    if (data.containsKey('nome_nota')) {
      context.handle(
        _nomeNotaMeta,
        nomeNota.isAcceptableOrUnknown(data['nome_nota']!, _nomeNotaMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeNotaMeta);
    }
    if (data.containsKey('alteracao')) {
      context.handle(
        _alteracaoMeta,
        alteracao.isAcceptableOrUnknown(data['alteracao']!, _alteracaoMeta),
      );
    } else if (isInserting) {
      context.missing(_alteracaoMeta);
    }
    if (data.containsKey('modo')) {
      context.handle(
        _modoMeta,
        modo.isAcceptableOrUnknown(data['modo']!, _modoMeta),
      );
    } else if (isInserting) {
      context.missing(_modoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idMusica};
  @override
  PreferenciasTomExecucaoData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenciasTomExecucaoData(
      idMusica: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_musica'],
      )!,
      nomeNota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_nota'],
      )!,
      alteracao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alteracao'],
      )!,
      modo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modo'],
      )!,
    );
  }

  @override
  $PreferenciasTomExecucaoTable createAlias(String alias) {
    return $PreferenciasTomExecucaoTable(attachedDatabase, alias);
  }
}

class PreferenciasTomExecucaoData extends DataClass
    implements Insertable<PreferenciasTomExecucaoData> {
  final String idMusica;
  final String nomeNota;
  final String alteracao;
  final String modo;
  const PreferenciasTomExecucaoData({
    required this.idMusica,
    required this.nomeNota,
    required this.alteracao,
    required this.modo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_musica'] = Variable<String>(idMusica);
    map['nome_nota'] = Variable<String>(nomeNota);
    map['alteracao'] = Variable<String>(alteracao);
    map['modo'] = Variable<String>(modo);
    return map;
  }

  PreferenciasTomExecucaoCompanion toCompanion(bool nullToAbsent) {
    return PreferenciasTomExecucaoCompanion(
      idMusica: Value(idMusica),
      nomeNota: Value(nomeNota),
      alteracao: Value(alteracao),
      modo: Value(modo),
    );
  }

  factory PreferenciasTomExecucaoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenciasTomExecucaoData(
      idMusica: serializer.fromJson<String>(json['idMusica']),
      nomeNota: serializer.fromJson<String>(json['nomeNota']),
      alteracao: serializer.fromJson<String>(json['alteracao']),
      modo: serializer.fromJson<String>(json['modo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idMusica': serializer.toJson<String>(idMusica),
      'nomeNota': serializer.toJson<String>(nomeNota),
      'alteracao': serializer.toJson<String>(alteracao),
      'modo': serializer.toJson<String>(modo),
    };
  }

  PreferenciasTomExecucaoData copyWith({
    String? idMusica,
    String? nomeNota,
    String? alteracao,
    String? modo,
  }) => PreferenciasTomExecucaoData(
    idMusica: idMusica ?? this.idMusica,
    nomeNota: nomeNota ?? this.nomeNota,
    alteracao: alteracao ?? this.alteracao,
    modo: modo ?? this.modo,
  );
  PreferenciasTomExecucaoData copyWithCompanion(
    PreferenciasTomExecucaoCompanion data,
  ) {
    return PreferenciasTomExecucaoData(
      idMusica: data.idMusica.present ? data.idMusica.value : this.idMusica,
      nomeNota: data.nomeNota.present ? data.nomeNota.value : this.nomeNota,
      alteracao: data.alteracao.present ? data.alteracao.value : this.alteracao,
      modo: data.modo.present ? data.modo.value : this.modo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenciasTomExecucaoData(')
          ..write('idMusica: $idMusica, ')
          ..write('nomeNota: $nomeNota, ')
          ..write('alteracao: $alteracao, ')
          ..write('modo: $modo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idMusica, nomeNota, alteracao, modo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenciasTomExecucaoData &&
          other.idMusica == this.idMusica &&
          other.nomeNota == this.nomeNota &&
          other.alteracao == this.alteracao &&
          other.modo == this.modo);
}

class PreferenciasTomExecucaoCompanion
    extends UpdateCompanion<PreferenciasTomExecucaoData> {
  final Value<String> idMusica;
  final Value<String> nomeNota;
  final Value<String> alteracao;
  final Value<String> modo;
  final Value<int> rowid;
  const PreferenciasTomExecucaoCompanion({
    this.idMusica = const Value.absent(),
    this.nomeNota = const Value.absent(),
    this.alteracao = const Value.absent(),
    this.modo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferenciasTomExecucaoCompanion.insert({
    required String idMusica,
    required String nomeNota,
    required String alteracao,
    required String modo,
    this.rowid = const Value.absent(),
  }) : idMusica = Value(idMusica),
       nomeNota = Value(nomeNota),
       alteracao = Value(alteracao),
       modo = Value(modo);
  static Insertable<PreferenciasTomExecucaoData> custom({
    Expression<String>? idMusica,
    Expression<String>? nomeNota,
    Expression<String>? alteracao,
    Expression<String>? modo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idMusica != null) 'id_musica': idMusica,
      if (nomeNota != null) 'nome_nota': nomeNota,
      if (alteracao != null) 'alteracao': alteracao,
      if (modo != null) 'modo': modo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferenciasTomExecucaoCompanion copyWith({
    Value<String>? idMusica,
    Value<String>? nomeNota,
    Value<String>? alteracao,
    Value<String>? modo,
    Value<int>? rowid,
  }) {
    return PreferenciasTomExecucaoCompanion(
      idMusica: idMusica ?? this.idMusica,
      nomeNota: nomeNota ?? this.nomeNota,
      alteracao: alteracao ?? this.alteracao,
      modo: modo ?? this.modo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idMusica.present) {
      map['id_musica'] = Variable<String>(idMusica.value);
    }
    if (nomeNota.present) {
      map['nome_nota'] = Variable<String>(nomeNota.value);
    }
    if (alteracao.present) {
      map['alteracao'] = Variable<String>(alteracao.value);
    }
    if (modo.present) {
      map['modo'] = Variable<String>(modo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenciasTomExecucaoCompanion(')
          ..write('idMusica: $idMusica, ')
          ..write('nomeNota: $nomeNota, ')
          ..write('alteracao: $alteracao, ')
          ..write('modo: $modo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListasCultoTable extends ListasCulto
    with TableInfo<$ListasCultoTable, ListasCultoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListasCultoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listas_culto';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListasCultoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListasCultoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListasCultoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
    );
  }

  @override
  $ListasCultoTable createAlias(String alias) {
    return $ListasCultoTable(attachedDatabase, alias);
  }
}

class ListasCultoData extends DataClass implements Insertable<ListasCultoData> {
  final String id;
  final String nome;
  const ListasCultoData({required this.id, required this.nome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    return map;
  }

  ListasCultoCompanion toCompanion(bool nullToAbsent) {
    return ListasCultoCompanion(id: Value(id), nome: Value(nome));
  }

  factory ListasCultoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListasCultoData(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
    };
  }

  ListasCultoData copyWith({String? id, String? nome}) =>
      ListasCultoData(id: id ?? this.id, nome: nome ?? this.nome);
  ListasCultoData copyWithCompanion(ListasCultoCompanion data) {
    return ListasCultoData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListasCultoData(')
          ..write('id: $id, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListasCultoData &&
          other.id == this.id &&
          other.nome == this.nome);
}

class ListasCultoCompanion extends UpdateCompanion<ListasCultoData> {
  final Value<String> id;
  final Value<String> nome;
  final Value<int> rowid;
  const ListasCultoCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListasCultoCompanion.insert({
    required String id,
    required String nome,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome);
  static Insertable<ListasCultoData> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListasCultoCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<int>? rowid,
  }) {
    return ListasCultoCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListasCultoCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItensListaCultoTable extends ItensListaCulto
    with TableInfo<$ItensListaCultoTable, ItensListaCultoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensListaCultoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idListaMeta = const VerificationMeta(
    'idLista',
  );
  @override
  late final GeneratedColumn<String> idLista = GeneratedColumn<String>(
    'id_lista',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES listas_culto (id)',
    ),
  );
  static const VerificationMeta _idMusicaMeta = const VerificationMeta(
    'idMusica',
  );
  @override
  late final GeneratedColumn<String> idMusica = GeneratedColumn<String>(
    'id_musica',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES indice_musicas (id)',
    ),
  );
  static const VerificationMeta _posicaoMeta = const VerificationMeta(
    'posicao',
  );
  @override
  late final GeneratedColumn<int> posicao = GeneratedColumn<int>(
    'posicao',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, idLista, idMusica, posicao];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_lista_culto';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItensListaCultoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('id_lista')) {
      context.handle(
        _idListaMeta,
        idLista.isAcceptableOrUnknown(data['id_lista']!, _idListaMeta),
      );
    } else if (isInserting) {
      context.missing(_idListaMeta);
    }
    if (data.containsKey('id_musica')) {
      context.handle(
        _idMusicaMeta,
        idMusica.isAcceptableOrUnknown(data['id_musica']!, _idMusicaMeta),
      );
    } else if (isInserting) {
      context.missing(_idMusicaMeta);
    }
    if (data.containsKey('posicao')) {
      context.handle(
        _posicaoMeta,
        posicao.isAcceptableOrUnknown(data['posicao']!, _posicaoMeta),
      );
    } else if (isInserting) {
      context.missing(_posicaoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensListaCultoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensListaCultoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idLista: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_lista'],
      )!,
      idMusica: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_musica'],
      )!,
      posicao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posicao'],
      )!,
    );
  }

  @override
  $ItensListaCultoTable createAlias(String alias) {
    return $ItensListaCultoTable(attachedDatabase, alias);
  }
}

class ItensListaCultoData extends DataClass
    implements Insertable<ItensListaCultoData> {
  final String id;
  final String idLista;
  final String idMusica;
  final int posicao;
  const ItensListaCultoData({
    required this.id,
    required this.idLista,
    required this.idMusica,
    required this.posicao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['id_lista'] = Variable<String>(idLista);
    map['id_musica'] = Variable<String>(idMusica);
    map['posicao'] = Variable<int>(posicao);
    return map;
  }

  ItensListaCultoCompanion toCompanion(bool nullToAbsent) {
    return ItensListaCultoCompanion(
      id: Value(id),
      idLista: Value(idLista),
      idMusica: Value(idMusica),
      posicao: Value(posicao),
    );
  }

  factory ItensListaCultoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensListaCultoData(
      id: serializer.fromJson<String>(json['id']),
      idLista: serializer.fromJson<String>(json['idLista']),
      idMusica: serializer.fromJson<String>(json['idMusica']),
      posicao: serializer.fromJson<int>(json['posicao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idLista': serializer.toJson<String>(idLista),
      'idMusica': serializer.toJson<String>(idMusica),
      'posicao': serializer.toJson<int>(posicao),
    };
  }

  ItensListaCultoData copyWith({
    String? id,
    String? idLista,
    String? idMusica,
    int? posicao,
  }) => ItensListaCultoData(
    id: id ?? this.id,
    idLista: idLista ?? this.idLista,
    idMusica: idMusica ?? this.idMusica,
    posicao: posicao ?? this.posicao,
  );
  ItensListaCultoData copyWithCompanion(ItensListaCultoCompanion data) {
    return ItensListaCultoData(
      id: data.id.present ? data.id.value : this.id,
      idLista: data.idLista.present ? data.idLista.value : this.idLista,
      idMusica: data.idMusica.present ? data.idMusica.value : this.idMusica,
      posicao: data.posicao.present ? data.posicao.value : this.posicao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensListaCultoData(')
          ..write('id: $id, ')
          ..write('idLista: $idLista, ')
          ..write('idMusica: $idMusica, ')
          ..write('posicao: $posicao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, idLista, idMusica, posicao);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensListaCultoData &&
          other.id == this.id &&
          other.idLista == this.idLista &&
          other.idMusica == this.idMusica &&
          other.posicao == this.posicao);
}

class ItensListaCultoCompanion extends UpdateCompanion<ItensListaCultoData> {
  final Value<String> id;
  final Value<String> idLista;
  final Value<String> idMusica;
  final Value<int> posicao;
  final Value<int> rowid;
  const ItensListaCultoCompanion({
    this.id = const Value.absent(),
    this.idLista = const Value.absent(),
    this.idMusica = const Value.absent(),
    this.posicao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItensListaCultoCompanion.insert({
    required String id,
    required String idLista,
    required String idMusica,
    required int posicao,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idLista = Value(idLista),
       idMusica = Value(idMusica),
       posicao = Value(posicao);
  static Insertable<ItensListaCultoData> custom({
    Expression<String>? id,
    Expression<String>? idLista,
    Expression<String>? idMusica,
    Expression<int>? posicao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idLista != null) 'id_lista': idLista,
      if (idMusica != null) 'id_musica': idMusica,
      if (posicao != null) 'posicao': posicao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItensListaCultoCompanion copyWith({
    Value<String>? id,
    Value<String>? idLista,
    Value<String>? idMusica,
    Value<int>? posicao,
    Value<int>? rowid,
  }) {
    return ItensListaCultoCompanion(
      id: id ?? this.id,
      idLista: idLista ?? this.idLista,
      idMusica: idMusica ?? this.idMusica,
      posicao: posicao ?? this.posicao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idLista.present) {
      map['id_lista'] = Variable<String>(idLista.value);
    }
    if (idMusica.present) {
      map['id_musica'] = Variable<String>(idMusica.value);
    }
    if (posicao.present) {
      map['posicao'] = Variable<int>(posicao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensListaCultoCompanion(')
          ..write('id: $id, ')
          ..write('idLista: $idLista, ')
          ..write('idMusica: $idMusica, ')
          ..write('posicao: $posicao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BancoBiblioteca extends GeneratedDatabase {
  _$BancoBiblioteca(QueryExecutor e) : super(e);
  $BancoBibliotecaManager get managers => $BancoBibliotecaManager(this);
  late final $IndiceMusicasTable indiceMusicas = $IndiceMusicasTable(this);
  late final $PreferenciasTomExecucaoTable preferenciasTomExecucao =
      $PreferenciasTomExecucaoTable(this);
  late final $ListasCultoTable listasCulto = $ListasCultoTable(this);
  late final $ItensListaCultoTable itensListaCulto = $ItensListaCultoTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    indiceMusicas,
    preferenciasTomExecucao,
    listasCulto,
    itensListaCulto,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'indice_musicas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('preferencias_tom_execucao', kind: UpdateKind.delete),
      ],
    ),
  ]);
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

final class $$IndiceMusicasTableReferences
    extends
        BaseReferences<_$BancoBiblioteca, $IndiceMusicasTable, IndiceMusica> {
  $$IndiceMusicasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PreferenciasTomExecucaoTable,
    List<PreferenciasTomExecucaoData>
  >
  _preferenciasTomExecucaoRefsTable(_$BancoBiblioteca db) =>
      MultiTypedResultKey.fromTable(
        db.preferenciasTomExecucao,
        aliasName: 'indice_musicas__id__preferencias_tom_execucao__id_musica',
      );

  $$PreferenciasTomExecucaoTableProcessedTableManager
  get preferenciasTomExecucaoRefs {
    final manager = $$PreferenciasTomExecucaoTableTableManager(
      $_db,
      $_db.preferenciasTomExecucao,
    ).filter((f) => f.idMusica.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _preferenciasTomExecucaoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItensListaCultoTable, List<ItensListaCultoData>>
  _itensListaCultoRefsTable(_$BancoBiblioteca db) =>
      MultiTypedResultKey.fromTable(
        db.itensListaCulto,
        aliasName: 'indice_musicas__id__itens_lista_culto__id_musica',
      );

  $$ItensListaCultoTableProcessedTableManager get itensListaCultoRefs {
    final manager = $$ItensListaCultoTableTableManager(
      $_db,
      $_db.itensListaCulto,
    ).filter((f) => f.idMusica.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itensListaCultoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  Expression<bool> preferenciasTomExecucaoRefs(
    Expression<bool> Function($$PreferenciasTomExecucaoTableFilterComposer f) f,
  ) {
    final $$PreferenciasTomExecucaoTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.preferenciasTomExecucao,
          getReferencedColumn: (t) => t.idMusica,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PreferenciasTomExecucaoTableFilterComposer(
                $db: $db,
                $table: $db.preferenciasTomExecucao,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> itensListaCultoRefs(
    Expression<bool> Function($$ItensListaCultoTableFilterComposer f) f,
  ) {
    final $$ItensListaCultoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itensListaCulto,
      getReferencedColumn: (t) => t.idMusica,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItensListaCultoTableFilterComposer(
            $db: $db,
            $table: $db.itensListaCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  Expression<T> preferenciasTomExecucaoRefs<T extends Object>(
    Expression<T> Function($$PreferenciasTomExecucaoTableAnnotationComposer a)
    f,
  ) {
    final $$PreferenciasTomExecucaoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.preferenciasTomExecucao,
          getReferencedColumn: (t) => t.idMusica,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PreferenciasTomExecucaoTableAnnotationComposer(
                $db: $db,
                $table: $db.preferenciasTomExecucao,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> itensListaCultoRefs<T extends Object>(
    Expression<T> Function($$ItensListaCultoTableAnnotationComposer a) f,
  ) {
    final $$ItensListaCultoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itensListaCulto,
      getReferencedColumn: (t) => t.idMusica,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItensListaCultoTableAnnotationComposer(
            $db: $db,
            $table: $db.itensListaCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (IndiceMusica, $$IndiceMusicasTableReferences),
          IndiceMusica,
          PrefetchHooks Function({
            bool preferenciasTomExecucaoRefs,
            bool itensListaCultoRefs,
          })
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
                  $$IndiceMusicasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                preferenciasTomExecucaoRefs = false,
                itensListaCultoRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (preferenciasTomExecucaoRefs) db.preferenciasTomExecucao,
                    if (itensListaCultoRefs) db.itensListaCulto,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (preferenciasTomExecucaoRefs)
                        await $_getPrefetchedData<
                          IndiceMusica,
                          $IndiceMusicasTable,
                          PreferenciasTomExecucaoData
                        >(
                          currentTable: table,
                          referencedTable: $$IndiceMusicasTableReferences
                              ._preferenciasTomExecucaoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IndiceMusicasTableReferences(
                                db,
                                table,
                                p0,
                              ).preferenciasTomExecucaoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.idMusica == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itensListaCultoRefs)
                        await $_getPrefetchedData<
                          IndiceMusica,
                          $IndiceMusicasTable,
                          ItensListaCultoData
                        >(
                          currentTable: table,
                          referencedTable: $$IndiceMusicasTableReferences
                              ._itensListaCultoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IndiceMusicasTableReferences(
                                db,
                                table,
                                p0,
                              ).itensListaCultoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.idMusica == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (IndiceMusica, $$IndiceMusicasTableReferences),
      IndiceMusica,
      PrefetchHooks Function({
        bool preferenciasTomExecucaoRefs,
        bool itensListaCultoRefs,
      })
    >;
typedef $$PreferenciasTomExecucaoTableCreateCompanionBuilder =
    PreferenciasTomExecucaoCompanion Function({
      required String idMusica,
      required String nomeNota,
      required String alteracao,
      required String modo,
      Value<int> rowid,
    });
typedef $$PreferenciasTomExecucaoTableUpdateCompanionBuilder =
    PreferenciasTomExecucaoCompanion Function({
      Value<String> idMusica,
      Value<String> nomeNota,
      Value<String> alteracao,
      Value<String> modo,
      Value<int> rowid,
    });

final class $$PreferenciasTomExecucaoTableReferences
    extends
        BaseReferences<
          _$BancoBiblioteca,
          $PreferenciasTomExecucaoTable,
          PreferenciasTomExecucaoData
        > {
  $$PreferenciasTomExecucaoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IndiceMusicasTable _idMusicaTable(_$BancoBiblioteca db) => db
      .indiceMusicas
      .createAlias('preferencias_tom_execucao__id_musica__indice_musicas__id');

  $$IndiceMusicasTableProcessedTableManager get idMusica {
    final $_column = $_itemColumn<String>('id_musica')!;

    final manager = $$IndiceMusicasTableTableManager(
      $_db,
      $_db.indiceMusicas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idMusicaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PreferenciasTomExecucaoTableFilterComposer
    extends Composer<_$BancoBiblioteca, $PreferenciasTomExecucaoTable> {
  $$PreferenciasTomExecucaoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nomeNota => $composableBuilder(
    column: $table.nomeNota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alteracao => $composableBuilder(
    column: $table.alteracao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modo => $composableBuilder(
    column: $table.modo,
    builder: (column) => ColumnFilters(column),
  );

  $$IndiceMusicasTableFilterComposer get idMusica {
    final $$IndiceMusicasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableFilterComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreferenciasTomExecucaoTableOrderingComposer
    extends Composer<_$BancoBiblioteca, $PreferenciasTomExecucaoTable> {
  $$PreferenciasTomExecucaoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nomeNota => $composableBuilder(
    column: $table.nomeNota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alteracao => $composableBuilder(
    column: $table.alteracao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modo => $composableBuilder(
    column: $table.modo,
    builder: (column) => ColumnOrderings(column),
  );

  $$IndiceMusicasTableOrderingComposer get idMusica {
    final $$IndiceMusicasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableOrderingComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreferenciasTomExecucaoTableAnnotationComposer
    extends Composer<_$BancoBiblioteca, $PreferenciasTomExecucaoTable> {
  $$PreferenciasTomExecucaoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nomeNota =>
      $composableBuilder(column: $table.nomeNota, builder: (column) => column);

  GeneratedColumn<String> get alteracao =>
      $composableBuilder(column: $table.alteracao, builder: (column) => column);

  GeneratedColumn<String> get modo =>
      $composableBuilder(column: $table.modo, builder: (column) => column);

  $$IndiceMusicasTableAnnotationComposer get idMusica {
    final $$IndiceMusicasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableAnnotationComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PreferenciasTomExecucaoTableTableManager
    extends
        RootTableManager<
          _$BancoBiblioteca,
          $PreferenciasTomExecucaoTable,
          PreferenciasTomExecucaoData,
          $$PreferenciasTomExecucaoTableFilterComposer,
          $$PreferenciasTomExecucaoTableOrderingComposer,
          $$PreferenciasTomExecucaoTableAnnotationComposer,
          $$PreferenciasTomExecucaoTableCreateCompanionBuilder,
          $$PreferenciasTomExecucaoTableUpdateCompanionBuilder,
          (
            PreferenciasTomExecucaoData,
            $$PreferenciasTomExecucaoTableReferences,
          ),
          PreferenciasTomExecucaoData,
          PrefetchHooks Function({bool idMusica})
        > {
  $$PreferenciasTomExecucaoTableTableManager(
    _$BancoBiblioteca db,
    $PreferenciasTomExecucaoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenciasTomExecucaoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PreferenciasTomExecucaoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PreferenciasTomExecucaoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> idMusica = const Value.absent(),
                Value<String> nomeNota = const Value.absent(),
                Value<String> alteracao = const Value.absent(),
                Value<String> modo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenciasTomExecucaoCompanion(
                idMusica: idMusica,
                nomeNota: nomeNota,
                alteracao: alteracao,
                modo: modo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idMusica,
                required String nomeNota,
                required String alteracao,
                required String modo,
                Value<int> rowid = const Value.absent(),
              }) => PreferenciasTomExecucaoCompanion.insert(
                idMusica: idMusica,
                nomeNota: nomeNota,
                alteracao: alteracao,
                modo: modo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PreferenciasTomExecucaoTable,
                    PreferenciasTomExecucaoData
                  >(table),
                  $$PreferenciasTomExecucaoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({idMusica = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (idMusica) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.idMusica,
                        referencedTable:
                            $$PreferenciasTomExecucaoTableReferences
                                ._idMusicaTable(db),
                        referencedColumn:
                            $$PreferenciasTomExecucaoTableReferences
                                ._idMusicaTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PreferenciasTomExecucaoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoBiblioteca,
      $PreferenciasTomExecucaoTable,
      PreferenciasTomExecucaoData,
      $$PreferenciasTomExecucaoTableFilterComposer,
      $$PreferenciasTomExecucaoTableOrderingComposer,
      $$PreferenciasTomExecucaoTableAnnotationComposer,
      $$PreferenciasTomExecucaoTableCreateCompanionBuilder,
      $$PreferenciasTomExecucaoTableUpdateCompanionBuilder,
      (PreferenciasTomExecucaoData, $$PreferenciasTomExecucaoTableReferences),
      PreferenciasTomExecucaoData,
      PrefetchHooks Function({bool idMusica})
    >;
typedef $$ListasCultoTableCreateCompanionBuilder =
    ListasCultoCompanion Function({
      required String id,
      required String nome,
      Value<int> rowid,
    });
typedef $$ListasCultoTableUpdateCompanionBuilder =
    ListasCultoCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<int> rowid,
    });

final class $$ListasCultoTableReferences
    extends
        BaseReferences<_$BancoBiblioteca, $ListasCultoTable, ListasCultoData> {
  $$ListasCultoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItensListaCultoTable, List<ItensListaCultoData>>
  _itensListaCultoRefsTable(_$BancoBiblioteca db) =>
      MultiTypedResultKey.fromTable(
        db.itensListaCulto,
        aliasName: 'listas_culto__id__itens_lista_culto__id_lista',
      );

  $$ItensListaCultoTableProcessedTableManager get itensListaCultoRefs {
    final manager = $$ItensListaCultoTableTableManager(
      $_db,
      $_db.itensListaCulto,
    ).filter((f) => f.idLista.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itensListaCultoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ListasCultoTableFilterComposer
    extends Composer<_$BancoBiblioteca, $ListasCultoTable> {
  $$ListasCultoTableFilterComposer({
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

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itensListaCultoRefs(
    Expression<bool> Function($$ItensListaCultoTableFilterComposer f) f,
  ) {
    final $$ItensListaCultoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itensListaCulto,
      getReferencedColumn: (t) => t.idLista,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItensListaCultoTableFilterComposer(
            $db: $db,
            $table: $db.itensListaCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListasCultoTableOrderingComposer
    extends Composer<_$BancoBiblioteca, $ListasCultoTable> {
  $$ListasCultoTableOrderingComposer({
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

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListasCultoTableAnnotationComposer
    extends Composer<_$BancoBiblioteca, $ListasCultoTable> {
  $$ListasCultoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  Expression<T> itensListaCultoRefs<T extends Object>(
    Expression<T> Function($$ItensListaCultoTableAnnotationComposer a) f,
  ) {
    final $$ItensListaCultoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itensListaCulto,
      getReferencedColumn: (t) => t.idLista,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItensListaCultoTableAnnotationComposer(
            $db: $db,
            $table: $db.itensListaCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListasCultoTableTableManager
    extends
        RootTableManager<
          _$BancoBiblioteca,
          $ListasCultoTable,
          ListasCultoData,
          $$ListasCultoTableFilterComposer,
          $$ListasCultoTableOrderingComposer,
          $$ListasCultoTableAnnotationComposer,
          $$ListasCultoTableCreateCompanionBuilder,
          $$ListasCultoTableUpdateCompanionBuilder,
          (ListasCultoData, $$ListasCultoTableReferences),
          ListasCultoData,
          PrefetchHooks Function({bool itensListaCultoRefs})
        > {
  $$ListasCultoTableTableManager(_$BancoBiblioteca db, $ListasCultoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListasCultoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListasCultoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListasCultoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ListasCultoCompanion(id: id, nome: nome, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String nome,
            Value<int> rowid = const Value.absent(),
          }) => ListasCultoCompanion.insert(id: id, nome: nome, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListasCultoTable, ListasCultoData>(table),
                  $$ListasCultoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itensListaCultoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itensListaCultoRefs) db.itensListaCulto,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itensListaCultoRefs)
                    await $_getPrefetchedData<
                      ListasCultoData,
                      $ListasCultoTable,
                      ItensListaCultoData
                    >(
                      currentTable: table,
                      referencedTable: $$ListasCultoTableReferences
                          ._itensListaCultoRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ListasCultoTableReferences(
                            db,
                            table,
                            p0,
                          ).itensListaCultoRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.idLista == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ListasCultoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoBiblioteca,
      $ListasCultoTable,
      ListasCultoData,
      $$ListasCultoTableFilterComposer,
      $$ListasCultoTableOrderingComposer,
      $$ListasCultoTableAnnotationComposer,
      $$ListasCultoTableCreateCompanionBuilder,
      $$ListasCultoTableUpdateCompanionBuilder,
      (ListasCultoData, $$ListasCultoTableReferences),
      ListasCultoData,
      PrefetchHooks Function({bool itensListaCultoRefs})
    >;
typedef $$ItensListaCultoTableCreateCompanionBuilder =
    ItensListaCultoCompanion Function({
      required String id,
      required String idLista,
      required String idMusica,
      required int posicao,
      Value<int> rowid,
    });
typedef $$ItensListaCultoTableUpdateCompanionBuilder =
    ItensListaCultoCompanion Function({
      Value<String> id,
      Value<String> idLista,
      Value<String> idMusica,
      Value<int> posicao,
      Value<int> rowid,
    });

final class $$ItensListaCultoTableReferences
    extends
        BaseReferences<
          _$BancoBiblioteca,
          $ItensListaCultoTable,
          ItensListaCultoData
        > {
  $$ItensListaCultoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ListasCultoTable _idListaTable(_$BancoBiblioteca db) => db.listasCulto
      .createAlias('itens_lista_culto__id_lista__listas_culto__id');

  $$ListasCultoTableProcessedTableManager get idLista {
    final $_column = $_itemColumn<String>('id_lista')!;

    final manager = $$ListasCultoTableTableManager(
      $_db,
      $_db.listasCulto,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idListaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $IndiceMusicasTable _idMusicaTable(_$BancoBiblioteca db) => db
      .indiceMusicas
      .createAlias('itens_lista_culto__id_musica__indice_musicas__id');

  $$IndiceMusicasTableProcessedTableManager get idMusica {
    final $_column = $_itemColumn<String>('id_musica')!;

    final manager = $$IndiceMusicasTableTableManager(
      $_db,
      $_db.indiceMusicas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idMusicaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItensListaCultoTableFilterComposer
    extends Composer<_$BancoBiblioteca, $ItensListaCultoTable> {
  $$ItensListaCultoTableFilterComposer({
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

  ColumnFilters<int> get posicao => $composableBuilder(
    column: $table.posicao,
    builder: (column) => ColumnFilters(column),
  );

  $$ListasCultoTableFilterComposer get idLista {
    final $$ListasCultoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idLista,
      referencedTable: $db.listasCulto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCultoTableFilterComposer(
            $db: $db,
            $table: $db.listasCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IndiceMusicasTableFilterComposer get idMusica {
    final $$IndiceMusicasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableFilterComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItensListaCultoTableOrderingComposer
    extends Composer<_$BancoBiblioteca, $ItensListaCultoTable> {
  $$ItensListaCultoTableOrderingComposer({
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

  ColumnOrderings<int> get posicao => $composableBuilder(
    column: $table.posicao,
    builder: (column) => ColumnOrderings(column),
  );

  $$ListasCultoTableOrderingComposer get idLista {
    final $$ListasCultoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idLista,
      referencedTable: $db.listasCulto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCultoTableOrderingComposer(
            $db: $db,
            $table: $db.listasCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IndiceMusicasTableOrderingComposer get idMusica {
    final $$IndiceMusicasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableOrderingComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItensListaCultoTableAnnotationComposer
    extends Composer<_$BancoBiblioteca, $ItensListaCultoTable> {
  $$ItensListaCultoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get posicao =>
      $composableBuilder(column: $table.posicao, builder: (column) => column);

  $$ListasCultoTableAnnotationComposer get idLista {
    final $$ListasCultoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idLista,
      referencedTable: $db.listasCulto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListasCultoTableAnnotationComposer(
            $db: $db,
            $table: $db.listasCulto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IndiceMusicasTableAnnotationComposer get idMusica {
    final $$IndiceMusicasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idMusica,
      referencedTable: $db.indiceMusicas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndiceMusicasTableAnnotationComposer(
            $db: $db,
            $table: $db.indiceMusicas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItensListaCultoTableTableManager
    extends
        RootTableManager<
          _$BancoBiblioteca,
          $ItensListaCultoTable,
          ItensListaCultoData,
          $$ItensListaCultoTableFilterComposer,
          $$ItensListaCultoTableOrderingComposer,
          $$ItensListaCultoTableAnnotationComposer,
          $$ItensListaCultoTableCreateCompanionBuilder,
          $$ItensListaCultoTableUpdateCompanionBuilder,
          (ItensListaCultoData, $$ItensListaCultoTableReferences),
          ItensListaCultoData,
          PrefetchHooks Function({bool idLista, bool idMusica})
        > {
  $$ItensListaCultoTableTableManager(
    _$BancoBiblioteca db,
    $ItensListaCultoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItensListaCultoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItensListaCultoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItensListaCultoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idLista = const Value.absent(),
                Value<String> idMusica = const Value.absent(),
                Value<int> posicao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItensListaCultoCompanion(
                id: id,
                idLista: idLista,
                idMusica: idMusica,
                posicao: posicao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idLista,
                required String idMusica,
                required int posicao,
                Value<int> rowid = const Value.absent(),
              }) => ItensListaCultoCompanion.insert(
                id: id,
                idLista: idLista,
                idMusica: idMusica,
                posicao: posicao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItensListaCultoTable, ItensListaCultoData>(
                    table,
                  ),
                  $$ItensListaCultoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({idLista = false, idMusica = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (idLista) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.idLista,
                        referencedTable: $$ItensListaCultoTableReferences
                            ._idListaTable(db),
                        referencedColumn: $$ItensListaCultoTableReferences
                            ._idListaTable(db)
                            .id,
                      ) as T;
                    }
                    if (idMusica) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.idMusica,
                        referencedTable: $$ItensListaCultoTableReferences
                            ._idMusicaTable(db),
                        referencedColumn: $$ItensListaCultoTableReferences
                            ._idMusicaTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItensListaCultoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoBiblioteca,
      $ItensListaCultoTable,
      ItensListaCultoData,
      $$ItensListaCultoTableFilterComposer,
      $$ItensListaCultoTableOrderingComposer,
      $$ItensListaCultoTableAnnotationComposer,
      $$ItensListaCultoTableCreateCompanionBuilder,
      $$ItensListaCultoTableUpdateCompanionBuilder,
      (ItensListaCultoData, $$ItensListaCultoTableReferences),
      ItensListaCultoData,
      PrefetchHooks Function({bool idLista, bool idMusica})
    >;

class $BancoBibliotecaManager {
  final _$BancoBiblioteca _db;
  $BancoBibliotecaManager(this._db);
  $$IndiceMusicasTableTableManager get indiceMusicas =>
      $$IndiceMusicasTableTableManager(_db, _db.indiceMusicas);
  $$PreferenciasTomExecucaoTableTableManager get preferenciasTomExecucao =>
      $$PreferenciasTomExecucaoTableTableManager(
        _db,
        _db.preferenciasTomExecucao,
      );
  $$ListasCultoTableTableManager get listasCulto =>
      $$ListasCultoTableTableManager(_db, _db.listasCulto);
  $$ItensListaCultoTableTableManager get itensListaCulto =>
      $$ItensListaCultoTableTableManager(_db, _db.itensListaCulto);
}
