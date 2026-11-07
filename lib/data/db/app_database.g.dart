// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets with TableInfo<$WalletsTable, Wallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IDR'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    openingBalance,
    currency,
    icon,
    color,
    isDefault,
    useCount,
    sortOrder,
    archivedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Wallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wallet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class Wallet extends DataClass implements Insertable<Wallet> {
  final String id;

  /// SPEC G-9: nama rekening harus unik. Keunikannya ditegakkan index parsial
  /// di `app_database.dart`, bukan `unique()` di sini. Alasannya hapus lunak:
  /// kalau indeksnya berlaku untuk seluruh baris, nama rekening yang sudah
  /// dihapus tidak akan pernah bisa dipakai lagi. Lihat DATA-MODEL RW-13.
  final String name;
  final String type;
  final int openingBalance;
  final String currency;
  final String? icon;
  final int? color;
  final bool isDefault;
  final int useCount;
  final int sortOrder;
  final int? archivedAt;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currency,
    this.icon,
    this.color,
    required this.isDefault,
    required this.useCount,
    required this.sortOrder,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['opening_balance'] = Variable<int>(openingBalance);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['use_count'] = Variable<int>(useCount);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      openingBalance: Value(openingBalance),
      currency: Value(currency),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isDefault: Value(isDefault),
      useCount: Value(useCount),
      sortOrder: Value(sortOrder),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Wallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wallet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      currency: serializer.fromJson<String>(json['currency']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      useCount: serializer.fromJson<int>(json['useCount']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'currency': serializer.toJson<String>(currency),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<int?>(color),
      'isDefault': serializer.toJson<bool>(isDefault),
      'useCount': serializer.toJson<int>(useCount),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    int? openingBalance,
    String? currency,
    Value<String?> icon = const Value.absent(),
    Value<int?> color = const Value.absent(),
    bool? isDefault,
    int? useCount,
    int? sortOrder,
    Value<int?> archivedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalance: openingBalance ?? this.openingBalance,
    currency: currency ?? this.currency,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    isDefault: isDefault ?? this.isDefault,
    useCount: useCount ?? this.useCount,
    sortOrder: sortOrder ?? this.sortOrder,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Wallet copyWithCompanion(WalletsCompanion data) {
    return Wallet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      currency: data.currency.present ? data.currency.value : this.currency,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wallet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currency: $currency, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('useCount: $useCount, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    openingBalance,
    currency,
    icon,
    color,
    isDefault,
    useCount,
    sortOrder,
    archivedAt,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wallet &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.openingBalance == this.openingBalance &&
          other.currency == this.currency &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isDefault == this.isDefault &&
          other.useCount == this.useCount &&
          other.sortOrder == this.sortOrder &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WalletsCompanion extends UpdateCompanion<Wallet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> openingBalance;
  final Value<String> currency;
  final Value<String?> icon;
  final Value<int?> color;
  final Value<bool> isDefault;
  final Value<int> useCount;
  final Value<int> sortOrder;
  final Value<int?> archivedAt;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.useCount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.openingBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.useCount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Wallet> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? openingBalance,
    Expression<String>? currency,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<bool>? isDefault,
    Expression<int>? useCount,
    Expression<int>? sortOrder,
    Expression<int>? archivedAt,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (currency != null) 'currency': currency,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isDefault != null) 'is_default': isDefault,
      if (useCount != null) 'use_count': useCount,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int>? openingBalance,
    Value<String>? currency,
    Value<String?>? icon,
    Value<int?>? color,
    Value<bool>? isDefault,
    Value<int>? useCount,
    Value<int>? sortOrder,
    Value<int?>? archivedAt,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      useCount: useCount ?? this.useCount,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currency: $currency, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault, ')
          ..write('useCount: $useCount, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _counterWalletIdMeta = const VerificationMeta(
    'counterWalletId',
  );
  @override
  late final GeneratedColumn<String> counterWalletId = GeneratedColumn<String>(
    'counter_wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _transferGroupIdMeta = const VerificationMeta(
    'transferGroupId',
  );
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debtEntryIdMeta = const VerificationMeta(
    'debtEntryId',
  );
  @override
  late final GeneratedColumn<String> debtEntryId = GeneratedColumn<String>(
    'debt_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    walletId,
    counterWalletId,
    transferGroupId,
    title,
    category,
    note,
    amount,
    date,
    time,
    debtEntryId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('counter_wallet_id')) {
      context.handle(
        _counterWalletIdMeta,
        counterWalletId.isAcceptableOrUnknown(
          data['counter_wallet_id']!,
          _counterWalletIdMeta,
        ),
      );
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
        _transferGroupIdMeta,
        transferGroupId.isAcceptableOrUnknown(
          data['transfer_group_id']!,
          _transferGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('debt_entry_id')) {
      context.handle(
        _debtEntryIdMeta,
        debtEntryId.isAcceptableOrUnknown(
          data['debt_entry_id']!,
          _debtEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      counterWalletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_wallet_id'],
      ),
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      ),
      debtEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_entry_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TxRow extends DataClass implements Insertable<TxRow> {
  final String id;

  /// `income` | `expense` | `transfer_out` | `transfer_in` | `correction`
  final String kind;
  final String walletId;

  /// Rekening pasangan. Hanya diisi untuk kedua jenis pindah saldo.
  final String? counterWalletId;

  /// Menyatukan pasangan baris pindah saldo. Lihat SPEC S-7.
  final String? transferGroupId;

  /// Judul. Wajib untuk pemasukan dan pengeluaran (SPEC T-1), tetapi **kosong**
  /// untuk kedua baris pindah saldo: form Pindah Saldo memang tidak punya field
  /// judul sama sekali (SPEC S-9). Lihat DATA-MODEL RW-12.
  final String? title;

  /// Kategori sebagai teks bebas, bukan kunci asing. Lihat SPEC C-1.
  final String? category;
  final String? note;

  /// Bertanda, tidak pernah 0.
  final int amount;

  /// Tanggal lokal `YYYY-MM-DD`. Lihat SPEC G-4.
  final String date;

  /// Jam `HH:MM`, opsional. Lihat SPEC G-5.
  final String? time;

  /// Diisi bila baris ini lahir dari entri hutang.
  final String? debtEntryId;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const TxRow({
    required this.id,
    required this.kind,
    required this.walletId,
    this.counterWalletId,
    this.transferGroupId,
    this.title,
    this.category,
    this.note,
    required this.amount,
    required this.date,
    this.time,
    this.debtEntryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['wallet_id'] = Variable<String>(walletId);
    if (!nullToAbsent || counterWalletId != null) {
      map['counter_wallet_id'] = Variable<String>(counterWalletId);
    }
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
    if (!nullToAbsent || debtEntryId != null) {
      map['debt_entry_id'] = Variable<String>(debtEntryId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      walletId: Value(walletId),
      counterWalletId: counterWalletId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterWalletId),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      amount: Value(amount),
      date: Value(date),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      debtEntryId: debtEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtEntryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      walletId: serializer.fromJson<String>(json['walletId']),
      counterWalletId: serializer.fromJson<String?>(json['counterWalletId']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      title: serializer.fromJson<String?>(json['title']),
      category: serializer.fromJson<String?>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      time: serializer.fromJson<String?>(json['time']),
      debtEntryId: serializer.fromJson<String?>(json['debtEntryId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'walletId': serializer.toJson<String>(walletId),
      'counterWalletId': serializer.toJson<String?>(counterWalletId),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'title': serializer.toJson<String?>(title),
      'category': serializer.toJson<String?>(category),
      'note': serializer.toJson<String?>(note),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<String>(date),
      'time': serializer.toJson<String?>(time),
      'debtEntryId': serializer.toJson<String?>(debtEntryId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  TxRow copyWith({
    String? id,
    String? kind,
    String? walletId,
    Value<String?> counterWalletId = const Value.absent(),
    Value<String?> transferGroupId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? amount,
    String? date,
    Value<String?> time = const Value.absent(),
    Value<String?> debtEntryId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => TxRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    walletId: walletId ?? this.walletId,
    counterWalletId: counterWalletId.present
        ? counterWalletId.value
        : this.counterWalletId,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
    title: title.present ? title.value : this.title,
    category: category.present ? category.value : this.category,
    note: note.present ? note.value : this.note,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    time: time.present ? time.value : this.time,
    debtEntryId: debtEntryId.present ? debtEntryId.value : this.debtEntryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TxRow copyWithCompanion(TransactionsCompanion data) {
    return TxRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      counterWalletId: data.counterWalletId.present
          ? data.counterWalletId.value
          : this.counterWalletId,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
      debtEntryId: data.debtEntryId.present
          ? data.debtEntryId.value
          : this.debtEntryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('walletId: $walletId, ')
          ..write('counterWalletId: $counterWalletId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    walletId,
    counterWalletId,
    transferGroupId,
    title,
    category,
    note,
    amount,
    date,
    time,
    debtEntryId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.walletId == this.walletId &&
          other.counterWalletId == this.counterWalletId &&
          other.transferGroupId == this.transferGroupId &&
          other.title == this.title &&
          other.category == this.category &&
          other.note == this.note &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.time == this.time &&
          other.debtEntryId == this.debtEntryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<TxRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> walletId;
  final Value<String?> counterWalletId;
  final Value<String?> transferGroupId;
  final Value<String?> title;
  final Value<String?> category;
  final Value<String?> note;
  final Value<int> amount;
  final Value<String> date;
  final Value<String?> time;
  final Value<String?> debtEntryId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.walletId = const Value.absent(),
    this.counterWalletId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.debtEntryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String kind,
    required String walletId,
    this.counterWalletId = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    required int amount,
    required String date,
    this.time = const Value.absent(),
    this.debtEntryId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       walletId = Value(walletId),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TxRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? walletId,
    Expression<String>? counterWalletId,
    Expression<String>? transferGroupId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? note,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<String>? time,
    Expression<String>? debtEntryId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (walletId != null) 'wallet_id': walletId,
      if (counterWalletId != null) 'counter_wallet_id': counterWalletId,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (debtEntryId != null) 'debt_entry_id': debtEntryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? walletId,
    Value<String?>? counterWalletId,
    Value<String?>? transferGroupId,
    Value<String?>? title,
    Value<String?>? category,
    Value<String?>? note,
    Value<int>? amount,
    Value<String>? date,
    Value<String?>? time,
    Value<String?>? debtEntryId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      walletId: walletId ?? this.walletId,
      counterWalletId: counterWalletId ?? this.counterWalletId,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      debtEntryId: debtEntryId ?? this.debtEntryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (counterWalletId.present) {
      map['counter_wallet_id'] = Variable<String>(counterWalletId.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (debtEntryId.present) {
      map['debt_entry_id'] = Variable<String>(debtEntryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('walletId: $walletId, ')
          ..write('counterWalletId: $counterWalletId, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('debtEntryId: $debtEntryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuggestionsTable extends Suggestions
    with TableInfo<$SuggestionsTable, Suggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    kind,
    useCount,
    lastUsedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Suggestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {type, name, kind},
  ];
  @override
  Suggestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Suggestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SuggestionsTable createAlias(String alias) {
    return $SuggestionsTable(attachedDatabase, alias);
  }
}

class Suggestion extends DataClass implements Insertable<Suggestion> {
  final String id;

  /// `title` | `category`
  final String type;
  final String name;

  /// `income` | `expense`. Judul dan kategori dipisah per jenis (SPEC C-3).
  final String kind;
  final int useCount;
  final int? lastUsedAt;
  final int createdAt;
  final int updatedAt;
  const Suggestion({
    required this.id,
    required this.type,
    required this.name,
    required this.kind,
    required this.useCount,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<int>(lastUsedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SuggestionsCompanion toCompanion(bool nullToAbsent) {
    return SuggestionsCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      kind: Value(kind),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Suggestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Suggestion(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<int?>(json['lastUsedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<int?>(lastUsedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Suggestion copyWith({
    String? id,
    String? type,
    String? name,
    String? kind,
    int? useCount,
    Value<int?> lastUsedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Suggestion(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Suggestion copyWithCompanion(SuggestionsCompanion data) {
    return Suggestion(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Suggestion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    kind,
    useCount,
    lastUsedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Suggestion &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SuggestionsCompanion extends UpdateCompanion<Suggestion> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> useCount;
  final Value<int?> lastUsedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SuggestionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuggestionsCompanion.insert({
    required String id,
    required String type,
    required String name,
    required String kind,
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       kind = Value(kind),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Suggestion> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? useCount,
    Expression<int>? lastUsedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuggestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? useCount,
    Value<int?>? lastUsedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SuggestionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtsTable extends Debts with TableInfo<$DebtsTable, Debt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDirectionMeta = const VerificationMeta(
    'targetDirection',
  );
  @override
  late final GeneratedColumn<String> targetDirection = GeneratedColumn<String>(
    'target_direction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidOpeningMeta = const VerificationMeta(
    'paidOpening',
  );
  @override
  late final GeneratedColumn<int> paidOpening = GeneratedColumn<int>(
    'paid_opening',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    partyName,
    phone,
    date,
    note,
    targetAmount,
    targetDirection,
    paidOpening,
    isSettled,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Debt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_partyNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    }
    if (data.containsKey('target_direction')) {
      context.handle(
        _targetDirectionMeta,
        targetDirection.isAcceptableOrUnknown(
          data['target_direction']!,
          _targetDirectionMeta,
        ),
      );
    }
    if (data.containsKey('paid_opening')) {
      context.handle(
        _paidOpeningMeta,
        paidOpening.isAcceptableOrUnknown(
          data['paid_opening']!,
          _paidOpeningMeta,
        ),
      );
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Debt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Debt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      ),
      targetDirection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_direction'],
      ),
      paidOpening: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_opening'],
      )!,
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DebtsTable createAlias(String alias) {
    return $DebtsTable(attachedDatabase, alias);
  }
}

class Debt extends DataClass implements Insertable<Debt> {
  final String id;

  /// Nama orang atau keperluan. Sepran memakai kolom `nama`. Lihat SPEC H-5.
  final String partyName;
  final String? phone;
  final String date;
  final String? note;

  /// Pokok/target catatan. `NULL` atau 0 = catatan biasa tanpa target.
  /// Target adalah metadata, bukan pergerakan uang.
  final int? targetAmount;

  /// `owe` | `owed`. Wajib `NULL` bila [targetAmount] `NULL`.
  final String? targetDirection;

  /// Jumlah yang sudah dibayar sebelum aplikasi dipakai. Bukan entri dan tidak
  /// pernah menyentuh saldo maupun Rekap.
  final int paidOpening;
  final bool isSettled;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const Debt({
    required this.id,
    required this.partyName,
    this.phone,
    required this.date,
    this.note,
    this.targetAmount,
    this.targetDirection,
    required this.paidOpening,
    required this.isSettled,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['party_name'] = Variable<String>(partyName);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<int>(targetAmount);
    }
    if (!nullToAbsent || targetDirection != null) {
      map['target_direction'] = Variable<String>(targetDirection);
    }
    map['paid_opening'] = Variable<int>(paidOpening);
    map['is_settled'] = Variable<bool>(isSettled);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DebtsCompanion toCompanion(bool nullToAbsent) {
    return DebtsCompanion(
      id: Value(id),
      partyName: Value(partyName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      targetDirection: targetDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDirection),
      paidOpening: Value(paidOpening),
      isSettled: Value(isSettled),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Debt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Debt(
      id: serializer.fromJson<String>(json['id']),
      partyName: serializer.fromJson<String>(json['partyName']),
      phone: serializer.fromJson<String?>(json['phone']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      targetAmount: serializer.fromJson<int?>(json['targetAmount']),
      targetDirection: serializer.fromJson<String?>(json['targetDirection']),
      paidOpening: serializer.fromJson<int>(json['paidOpening']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partyName': serializer.toJson<String>(partyName),
      'phone': serializer.toJson<String?>(phone),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String?>(note),
      'targetAmount': serializer.toJson<int?>(targetAmount),
      'targetDirection': serializer.toJson<String?>(targetDirection),
      'paidOpening': serializer.toJson<int>(paidOpening),
      'isSettled': serializer.toJson<bool>(isSettled),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Debt copyWith({
    String? id,
    String? partyName,
    Value<String?> phone = const Value.absent(),
    String? date,
    Value<String?> note = const Value.absent(),
    Value<int?> targetAmount = const Value.absent(),
    Value<String?> targetDirection = const Value.absent(),
    int? paidOpening,
    bool? isSettled,
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Debt(
    id: id ?? this.id,
    partyName: partyName ?? this.partyName,
    phone: phone.present ? phone.value : this.phone,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    targetDirection: targetDirection.present
        ? targetDirection.value
        : this.targetDirection,
    paidOpening: paidOpening ?? this.paidOpening,
    isSettled: isSettled ?? this.isSettled,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Debt copyWithCompanion(DebtsCompanion data) {
    return Debt(
      id: data.id.present ? data.id.value : this.id,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      phone: data.phone.present ? data.phone.value : this.phone,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      targetDirection: data.targetDirection.present
          ? data.targetDirection.value
          : this.targetDirection,
      paidOpening: data.paidOpening.present
          ? data.paidOpening.value
          : this.paidOpening,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Debt(')
          ..write('id: $id, ')
          ..write('partyName: $partyName, ')
          ..write('phone: $phone, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDirection: $targetDirection, ')
          ..write('paidOpening: $paidOpening, ')
          ..write('isSettled: $isSettled, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    partyName,
    phone,
    date,
    note,
    targetAmount,
    targetDirection,
    paidOpening,
    isSettled,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Debt &&
          other.id == this.id &&
          other.partyName == this.partyName &&
          other.phone == this.phone &&
          other.date == this.date &&
          other.note == this.note &&
          other.targetAmount == this.targetAmount &&
          other.targetDirection == this.targetDirection &&
          other.paidOpening == this.paidOpening &&
          other.isSettled == this.isSettled &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DebtsCompanion extends UpdateCompanion<Debt> {
  final Value<String> id;
  final Value<String> partyName;
  final Value<String?> phone;
  final Value<String> date;
  final Value<String?> note;
  final Value<int?> targetAmount;
  final Value<String?> targetDirection;
  final Value<int> paidOpening;
  final Value<bool> isSettled;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DebtsCompanion({
    this.id = const Value.absent(),
    this.partyName = const Value.absent(),
    this.phone = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetDirection = const Value.absent(),
    this.paidOpening = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtsCompanion.insert({
    required String id,
    required String partyName,
    this.phone = const Value.absent(),
    required String date,
    this.note = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetDirection = const Value.absent(),
    this.paidOpening = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       partyName = Value(partyName),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Debt> custom({
    Expression<String>? id,
    Expression<String>? partyName,
    Expression<String>? phone,
    Expression<String>? date,
    Expression<String>? note,
    Expression<int>? targetAmount,
    Expression<String>? targetDirection,
    Expression<int>? paidOpening,
    Expression<bool>? isSettled,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partyName != null) 'party_name': partyName,
      if (phone != null) 'phone': phone,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetDirection != null) 'target_direction': targetDirection,
      if (paidOpening != null) 'paid_opening': paidOpening,
      if (isSettled != null) 'is_settled': isSettled,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtsCompanion copyWith({
    Value<String>? id,
    Value<String>? partyName,
    Value<String?>? phone,
    Value<String>? date,
    Value<String?>? note,
    Value<int?>? targetAmount,
    Value<String?>? targetDirection,
    Value<int>? paidOpening,
    Value<bool>? isSettled,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DebtsCompanion(
      id: id ?? this.id,
      partyName: partyName ?? this.partyName,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      note: note ?? this.note,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDirection: targetDirection ?? this.targetDirection,
      paidOpening: paidOpening ?? this.paidOpening,
      isSettled: isSettled ?? this.isSettled,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (targetDirection.present) {
      map['target_direction'] = Variable<String>(targetDirection.value);
    }
    if (paidOpening.present) {
      map['paid_opening'] = Variable<int>(paidOpening.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtsCompanion(')
          ..write('id: $id, ')
          ..write('partyName: $partyName, ')
          ..write('phone: $phone, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDirection: $targetDirection, ')
          ..write('paidOpening: $paidOpening, ')
          ..write('isSettled: $isSettled, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtEntriesTable extends DebtEntries
    with TableInfo<$DebtEntriesTable, DebtEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES debts (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    debtId,
    amount,
    date,
    time,
    walletId,
    note,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      ),
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DebtEntriesTable createAlias(String alias) {
    return $DebtEntriesTable(attachedDatabase, alias);
  }
}

class DebtEntry extends DataClass implements Insertable<DebtEntry> {
  final String id;
  final String debtId;
  final int amount;
  final String date;
  final String? time;

  /// Opsional. Bila kosong, entri tidak memengaruhi saldo mana pun (SPEC M-4).
  final String? walletId;
  final String? note;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const DebtEntry({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.time,
    this.walletId,
    this.note,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debt_id'] = Variable<String>(debtId);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<String>(walletId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DebtEntriesCompanion toCompanion(bool nullToAbsent) {
    return DebtEntriesCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amount: Value(amount),
      date: Value(date),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DebtEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtEntry(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      time: serializer.fromJson<String?>(json['time']),
      walletId: serializer.fromJson<String?>(json['walletId']),
      note: serializer.fromJson<String?>(json['note']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<String>(date),
      'time': serializer.toJson<String?>(time),
      'walletId': serializer.toJson<String?>(walletId),
      'note': serializer.toJson<String?>(note),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DebtEntry copyWith({
    String? id,
    String? debtId,
    int? amount,
    String? date,
    Value<String?> time = const Value.absent(),
    Value<String?> walletId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => DebtEntry(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    time: time.present ? time.value : this.time,
    walletId: walletId.present ? walletId.value : this.walletId,
    note: note.present ? note.value : this.note,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DebtEntry copyWithCompanion(DebtEntriesCompanion data) {
    return DebtEntry(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      note: data.note.present ? data.note.value : this.note,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtEntry(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('walletId: $walletId, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    debtId,
    amount,
    date,
    time,
    walletId,
    note,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtEntry &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.time == this.time &&
          other.walletId == this.walletId &&
          other.note == this.note &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DebtEntriesCompanion extends UpdateCompanion<DebtEntry> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<int> amount;
  final Value<String> date;
  final Value<String?> time;
  final Value<String?> walletId;
  final Value<String?> note;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DebtEntriesCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.walletId = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtEntriesCompanion.insert({
    required String id,
    required String debtId,
    required int amount,
    required String date,
    this.time = const Value.absent(),
    this.walletId = const Value.absent(),
    this.note = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debtId = Value(debtId),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DebtEntry> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<String>? time,
    Expression<String>? walletId,
    Expression<String>? note,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (walletId != null) 'wallet_id': walletId,
      if (note != null) 'note': note,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? debtId,
    Value<int>? amount,
    Value<String>? date,
    Value<String?>? time,
    Value<String?>? walletId,
    Value<String?>? note,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DebtEntriesCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtEntriesCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('walletId: $walletId, ')
          ..write('note: $note, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warnPercentMeta = const VerificationMeta(
    'warnPercent',
  );
  @override
  late final GeneratedColumn<int> warnPercent = GeneratedColumn<int>(
    'warn_percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(80),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    period,
    amount,
    warnPercent,
    startDate,
    endDate,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('warn_percent')) {
      context.handle(
        _warnPercentMeta,
        warnPercent.isAcceptableOrUnknown(
          data['warn_percent']!,
          _warnPercentMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      warnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warn_percent'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;

  /// Nama kategori sebagai teks, selaras dengan `transactions.category`.
  final String category;

  /// `monthly` | `weekly`
  final String period;
  final int amount;
  final int warnPercent;
  final String? startDate;
  final String? endDate;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const Budget({
    required this.id,
    required this.category,
    required this.period,
    required this.amount,
    required this.warnPercent,
    this.startDate,
    this.endDate,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['period'] = Variable<String>(period);
    map['amount'] = Variable<int>(amount);
    map['warn_percent'] = Variable<int>(warnPercent);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      category: Value(category),
      period: Value(period),
      amount: Value(amount),
      warnPercent: Value(warnPercent),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      period: serializer.fromJson<String>(json['period']),
      amount: serializer.fromJson<int>(json['amount']),
      warnPercent: serializer.fromJson<int>(json['warnPercent']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'period': serializer.toJson<String>(period),
      'amount': serializer.toJson<int>(amount),
      'warnPercent': serializer.toJson<int>(warnPercent),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Budget copyWith({
    String? id,
    String? category,
    String? period,
    int? amount,
    int? warnPercent,
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    category: category ?? this.category,
    period: period ?? this.period,
    amount: amount ?? this.amount,
    warnPercent: warnPercent ?? this.warnPercent,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      period: data.period.present ? data.period.value : this.period,
      amount: data.amount.present ? data.amount.value : this.amount,
      warnPercent: data.warnPercent.present
          ? data.warnPercent.value
          : this.warnPercent,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('warnPercent: $warnPercent, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    period,
    amount,
    warnPercent,
    startDate,
    endDate,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.category == this.category &&
          other.period == this.period &&
          other.amount == this.amount &&
          other.warnPercent == this.warnPercent &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> period;
  final Value<int> amount;
  final Value<int> warnPercent;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.period = const Value.absent(),
    this.amount = const Value.absent(),
    this.warnPercent = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String category,
    required String period,
    required int amount,
    this.warnPercent = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       period = Value(period),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? period,
    Expression<int>? amount,
    Expression<int>? warnPercent,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (period != null) 'period': period,
      if (amount != null) 'amount': amount,
      if (warnPercent != null) 'warn_percent': warnPercent,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? period,
    Value<int>? amount,
    Value<int>? warnPercent,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      period: period ?? this.period,
      amount: amount ?? this.amount,
      warnPercent: warnPercent ?? this.warnPercent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (warnPercent.present) {
      map['warn_percent'] = Variable<int>(warnPercent.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('warnPercent: $warnPercent, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomReportsTable extends CustomReports
    with TableInfo<$CustomReportsTable, CustomReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    endDate,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomReportsTable createAlias(String alias) {
    return $CustomReportsTable(attachedDatabase, alias);
  }
}

class CustomReport extends DataClass implements Insertable<CustomReport> {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const CustomReport({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CustomReportsCompanion toCompanion(bool nullToAbsent) {
    return CustomReportsCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomReport(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CustomReport copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => CustomReport(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomReport copyWithCompanion(CustomReportsCompanion data) {
    return CustomReport(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomReport(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    endDate,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomReport &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomReportsCompanion extends UpdateCompanion<CustomReport> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CustomReportsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomReportsCompanion.insert({
    required String id,
    required String name,
    required String startDate,
    required String endDate,
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomReport> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomReportsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomReportsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemaMigrationsTable extends SchemaMigrations
    with TableInfo<$SchemaMigrationsTable, SchemaMigration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMigrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<int> appliedAt = GeneratedColumn<int>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [version, appliedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_migrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMigration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {version},
  ];
  @override
  SchemaMigration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMigration(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $SchemaMigrationsTable createAlias(String alias) {
    return $SchemaMigrationsTable(attachedDatabase, alias);
  }
}

class SchemaMigration extends DataClass implements Insertable<SchemaMigration> {
  final int version;
  final int appliedAt;
  const SchemaMigration({required this.version, required this.appliedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    map['applied_at'] = Variable<int>(appliedAt);
    return map;
  }

  SchemaMigrationsCompanion toCompanion(bool nullToAbsent) {
    return SchemaMigrationsCompanion(
      version: Value(version),
      appliedAt: Value(appliedAt),
    );
  }

  factory SchemaMigration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMigration(
      version: serializer.fromJson<int>(json['version']),
      appliedAt: serializer.fromJson<int>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'appliedAt': serializer.toJson<int>(appliedAt),
    };
  }

  SchemaMigration copyWith({int? version, int? appliedAt}) => SchemaMigration(
    version: version ?? this.version,
    appliedAt: appliedAt ?? this.appliedAt,
  );
  SchemaMigration copyWithCompanion(SchemaMigrationsCompanion data) {
    return SchemaMigration(
      version: data.version.present ? data.version.value : this.version,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigration(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMigration &&
          other.version == this.version &&
          other.appliedAt == this.appliedAt);
}

class SchemaMigrationsCompanion extends UpdateCompanion<SchemaMigration> {
  final Value<int> version;
  final Value<int> appliedAt;
  final Value<int> rowid;
  const SchemaMigrationsCompanion({
    this.version = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemaMigrationsCompanion.insert({
    required int version,
    required int appliedAt,
    this.rowid = const Value.absent(),
  }) : version = Value(version),
       appliedAt = Value(appliedAt);
  static Insertable<SchemaMigration> custom({
    Expression<int>? version,
    Expression<int>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemaMigrationsCompanion copyWith({
    Value<int>? version,
    Value<int>? appliedAt,
    Value<int>? rowid,
  }) {
    return SchemaMigrationsCompanion(
      version: version ?? this.version,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(appliedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigrationsCompanion(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationDraftsTable extends NotificationDrafts
    with TableInfo<$NotificationDraftsTable, NotificationDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTitleMeta = const VerificationMeta(
    'rawTitle',
  );
  @override
  late final GeneratedColumn<String> rawTitle = GeneratedColumn<String>(
    'raw_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMessageMeta = const VerificationMeta(
    'rawMessage',
  );
  @override
  late final GeneratedColumn<String> rawMessage = GeneratedColumn<String>(
    'raw_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedTransactionIdMeta =
      const VerificationMeta('approvedTransactionId');
  @override
  late final GeneratedColumn<String> approvedTransactionId =
      GeneratedColumn<String>(
        'approved_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    appName,
    rawTitle,
    rawMessage,
    amount,
    type,
    walletId,
    occurredAt,
    date,
    time,
    status,
    sourceKey,
    approvedTransactionId,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('raw_title')) {
      context.handle(
        _rawTitleMeta,
        rawTitle.isAcceptableOrUnknown(data['raw_title']!, _rawTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTitleMeta);
    }
    if (data.containsKey('raw_message')) {
      context.handle(
        _rawMessageMeta,
        rawMessage.isAcceptableOrUnknown(data['raw_message']!, _rawMessageMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMessageMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('approved_transaction_id')) {
      context.handle(
        _approvedTransactionIdMeta,
        approvedTransactionId.isAcceptableOrUnknown(
          data['approved_transaction_id']!,
          _approvedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationDraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      rawTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_title'],
      )!,
      rawMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_message'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      approvedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_transaction_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotificationDraftsTable createAlias(String alias) {
    return $NotificationDraftsTable(attachedDatabase, alias);
  }
}

class NotificationDraftRow extends DataClass
    implements Insertable<NotificationDraftRow> {
  final String id;
  final String packageName;
  final String appName;
  final String rawTitle;
  final String rawMessage;

  /// Nominal rupiah utuh, selalu positif.
  final int amount;

  /// `income` | `expense`.
  final String type;

  /// Rekening hasil pemetaan paket aplikasi. Boleh kosong sampai pengguna
  /// memilih rekening di layar konfirmasi.
  final String? walletId;

  /// Waktu notifikasi muncul, epoch milidetik.
  final int occurredAt;

  /// Tanggal lokal `YYYY-MM-DD`.
  final String date;

  /// Jam lokal `HH:MM`, opsional.
  final String? time;

  /// `pending` | `approved` | `ignored`.
  final String status;

  /// Kunci idempoten agar notifikasi yang diposting ulang tidak menjadi dua
  /// draft.
  final String sourceKey;

  /// Terisi setelah draft disetujui.
  final String? approvedTransactionId;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const NotificationDraftRow({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.rawTitle,
    required this.rawMessage,
    required this.amount,
    required this.type,
    this.walletId,
    required this.occurredAt,
    required this.date,
    this.time,
    required this.status,
    required this.sourceKey,
    this.approvedTransactionId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['raw_title'] = Variable<String>(rawTitle);
    map['raw_message'] = Variable<String>(rawMessage);
    map['amount'] = Variable<int>(amount);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<String>(walletId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
    map['status'] = Variable<String>(status);
    map['source_key'] = Variable<String>(sourceKey);
    if (!nullToAbsent || approvedTransactionId != null) {
      map['approved_transaction_id'] = Variable<String>(approvedTransactionId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotificationDraftsCompanion toCompanion(bool nullToAbsent) {
    return NotificationDraftsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      appName: Value(appName),
      rawTitle: Value(rawTitle),
      rawMessage: Value(rawMessage),
      amount: Value(amount),
      type: Value(type),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      occurredAt: Value(occurredAt),
      date: Value(date),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      status: Value(status),
      sourceKey: Value(sourceKey),
      approvedTransactionId: approvedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedTransactionId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotificationDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationDraftRow(
      id: serializer.fromJson<String>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      rawTitle: serializer.fromJson<String>(json['rawTitle']),
      rawMessage: serializer.fromJson<String>(json['rawMessage']),
      amount: serializer.fromJson<int>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      walletId: serializer.fromJson<String?>(json['walletId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      date: serializer.fromJson<String>(json['date']),
      time: serializer.fromJson<String?>(json['time']),
      status: serializer.fromJson<String>(json['status']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      approvedTransactionId: serializer.fromJson<String?>(
        json['approvedTransactionId'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'rawTitle': serializer.toJson<String>(rawTitle),
      'rawMessage': serializer.toJson<String>(rawMessage),
      'amount': serializer.toJson<int>(amount),
      'type': serializer.toJson<String>(type),
      'walletId': serializer.toJson<String?>(walletId),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'date': serializer.toJson<String>(date),
      'time': serializer.toJson<String?>(time),
      'status': serializer.toJson<String>(status),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'approvedTransactionId': serializer.toJson<String?>(
        approvedTransactionId,
      ),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotificationDraftRow copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? rawTitle,
    String? rawMessage,
    int? amount,
    String? type,
    Value<String?> walletId = const Value.absent(),
    int? occurredAt,
    String? date,
    Value<String?> time = const Value.absent(),
    String? status,
    String? sourceKey,
    Value<String?> approvedTransactionId = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => NotificationDraftRow(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    rawTitle: rawTitle ?? this.rawTitle,
    rawMessage: rawMessage ?? this.rawMessage,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    walletId: walletId.present ? walletId.value : this.walletId,
    occurredAt: occurredAt ?? this.occurredAt,
    date: date ?? this.date,
    time: time.present ? time.value : this.time,
    status: status ?? this.status,
    sourceKey: sourceKey ?? this.sourceKey,
    approvedTransactionId: approvedTransactionId.present
        ? approvedTransactionId.value
        : this.approvedTransactionId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotificationDraftRow copyWithCompanion(NotificationDraftsCompanion data) {
    return NotificationDraftRow(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      rawTitle: data.rawTitle.present ? data.rawTitle.value : this.rawTitle,
      rawMessage: data.rawMessage.present
          ? data.rawMessage.value
          : this.rawMessage,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
      status: data.status.present ? data.status.value : this.status,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      approvedTransactionId: data.approvedTransactionId.present
          ? data.approvedTransactionId.value
          : this.approvedTransactionId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDraftRow(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('rawTitle: $rawTitle, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('walletId: $walletId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('status: $status, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('approvedTransactionId: $approvedTransactionId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    appName,
    rawTitle,
    rawMessage,
    amount,
    type,
    walletId,
    occurredAt,
    date,
    time,
    status,
    sourceKey,
    approvedTransactionId,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationDraftRow &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.rawTitle == this.rawTitle &&
          other.rawMessage == this.rawMessage &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.walletId == this.walletId &&
          other.occurredAt == this.occurredAt &&
          other.date == this.date &&
          other.time == this.time &&
          other.status == this.status &&
          other.sourceKey == this.sourceKey &&
          other.approvedTransactionId == this.approvedTransactionId &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotificationDraftsCompanion
    extends UpdateCompanion<NotificationDraftRow> {
  final Value<String> id;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String> rawTitle;
  final Value<String> rawMessage;
  final Value<int> amount;
  final Value<String> type;
  final Value<String?> walletId;
  final Value<int> occurredAt;
  final Value<String> date;
  final Value<String?> time;
  final Value<String> status;
  final Value<String> sourceKey;
  final Value<String?> approvedTransactionId;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const NotificationDraftsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.rawTitle = const Value.absent(),
    this.rawMessage = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.walletId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.approvedTransactionId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationDraftsCompanion.insert({
    required String id,
    required String packageName,
    required String appName,
    required String rawTitle,
    required String rawMessage,
    required int amount,
    required String type,
    this.walletId = const Value.absent(),
    required int occurredAt,
    required String date,
    this.time = const Value.absent(),
    this.status = const Value.absent(),
    required String sourceKey,
    this.approvedTransactionId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageName = Value(packageName),
       appName = Value(appName),
       rawTitle = Value(rawTitle),
       rawMessage = Value(rawMessage),
       amount = Value(amount),
       type = Value(type),
       occurredAt = Value(occurredAt),
       date = Value(date),
       sourceKey = Value(sourceKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotificationDraftRow> custom({
    Expression<String>? id,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? rawTitle,
    Expression<String>? rawMessage,
    Expression<int>? amount,
    Expression<String>? type,
    Expression<String>? walletId,
    Expression<int>? occurredAt,
    Expression<String>? date,
    Expression<String>? time,
    Expression<String>? status,
    Expression<String>? sourceKey,
    Expression<String>? approvedTransactionId,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (rawTitle != null) 'raw_title': rawTitle,
      if (rawMessage != null) 'raw_message': rawMessage,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (walletId != null) 'wallet_id': walletId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (status != null) 'status': status,
      if (sourceKey != null) 'source_key': sourceKey,
      if (approvedTransactionId != null)
        'approved_transaction_id': approvedTransactionId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? packageName,
    Value<String>? appName,
    Value<String>? rawTitle,
    Value<String>? rawMessage,
    Value<int>? amount,
    Value<String>? type,
    Value<String?>? walletId,
    Value<int>? occurredAt,
    Value<String>? date,
    Value<String?>? time,
    Value<String>? status,
    Value<String>? sourceKey,
    Value<String?>? approvedTransactionId,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotificationDraftsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      rawTitle: rawTitle ?? this.rawTitle,
      rawMessage: rawMessage ?? this.rawMessage,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      occurredAt: occurredAt ?? this.occurredAt,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      sourceKey: sourceKey ?? this.sourceKey,
      approvedTransactionId:
          approvedTransactionId ?? this.approvedTransactionId,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (rawTitle.present) {
      map['raw_title'] = Variable<String>(rawTitle.value);
    }
    if (rawMessage.present) {
      map['raw_message'] = Variable<String>(rawMessage.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (approvedTransactionId.present) {
      map['approved_transaction_id'] = Variable<String>(
        approvedTransactionId.value,
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationDraftsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('rawTitle: $rawTitle, ')
          ..write('rawMessage: $rawMessage, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('walletId: $walletId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('status: $status, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('approvedTransactionId: $approvedTransactionId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountNotificationMappingsTable extends AccountNotificationMappings
    with
        TableInfo<
          $AccountNotificationMappingsTable,
          AccountNotificationMappingRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountNotificationMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    walletId,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_notification_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountNotificationMappingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountNotificationMappingRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountNotificationMappingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountNotificationMappingsTable createAlias(String alias) {
    return $AccountNotificationMappingsTable(attachedDatabase, alias);
  }
}

class AccountNotificationMappingRow extends DataClass
    implements Insertable<AccountNotificationMappingRow> {
  final String id;
  final String packageName;
  final String walletId;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const AccountNotificationMappingRow({
    required this.id,
    required this.packageName,
    required this.walletId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_name'] = Variable<String>(packageName);
    map['wallet_id'] = Variable<String>(walletId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AccountNotificationMappingsCompanion toCompanion(bool nullToAbsent) {
    return AccountNotificationMappingsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      walletId: Value(walletId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountNotificationMappingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountNotificationMappingRow(
      id: serializer.fromJson<String>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      walletId: serializer.fromJson<String>(json['walletId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageName': serializer.toJson<String>(packageName),
      'walletId': serializer.toJson<String>(walletId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AccountNotificationMappingRow copyWith({
    String? id,
    String? packageName,
    String? walletId,
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => AccountNotificationMappingRow(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    walletId: walletId ?? this.walletId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountNotificationMappingRow copyWithCompanion(
    AccountNotificationMappingsCompanion data,
  ) {
    return AccountNotificationMappingRow(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountNotificationMappingRow(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('walletId: $walletId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, packageName, walletId, deletedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountNotificationMappingRow &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.walletId == this.walletId &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountNotificationMappingsCompanion
    extends UpdateCompanion<AccountNotificationMappingRow> {
  final Value<String> id;
  final Value<String> packageName;
  final Value<String> walletId;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AccountNotificationMappingsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.walletId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountNotificationMappingsCompanion.insert({
    required String id,
    required String packageName,
    required String walletId,
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageName = Value(packageName),
       walletId = Value(walletId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountNotificationMappingRow> custom({
    Expression<String>? id,
    Expression<String>? packageName,
    Expression<String>? walletId,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (walletId != null) 'wallet_id': walletId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountNotificationMappingsCompanion copyWith({
    Value<String>? id,
    Value<String>? packageName,
    Value<String>? walletId,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountNotificationMappingsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      walletId: walletId ?? this.walletId,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountNotificationMappingsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('walletId: $walletId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SuggestionsTable suggestions = $SuggestionsTable(this);
  late final $DebtsTable debts = $DebtsTable(this);
  late final $DebtEntriesTable debtEntries = $DebtEntriesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $CustomReportsTable customReports = $CustomReportsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SchemaMigrationsTable schemaMigrations = $SchemaMigrationsTable(
    this,
  );
  late final $NotificationDraftsTable notificationDrafts =
      $NotificationDraftsTable(this);
  late final $AccountNotificationMappingsTable accountNotificationMappings =
      $AccountNotificationMappingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wallets,
    transactions,
    suggestions,
    debts,
    debtEntries,
    budgets,
    customReports,
    appSettings,
    schemaMigrations,
    notificationDrafts,
    accountNotificationMappings,
  ];
}

typedef $$WalletsTableCreateCompanionBuilder = WalletsCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<int> openingBalance,
  Value<String> currency,
  Value<String?> icon,
  Value<int?> color,
  Value<bool> isDefault,
  Value<int> useCount,
  Value<int> sortOrder,
  Value<int?> archivedAt,
  Value<int?> deletedAt,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$WalletsTableUpdateCompanionBuilder = WalletsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<int> openingBalance,
  Value<String> currency,
  Value<String?> icon,
  Value<int?> color,
  Value<bool> isDefault,
  Value<int> useCount,
  Value<int> sortOrder,
  Value<int?> archivedAt,
  Value<int?> deletedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$WalletsTableReferences
    extends BaseReferences<_$AppDatabase, $WalletsTable, Wallet> {
  $$WalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TxRow>>
  _walletTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'wallets__id__transactions__wallet_id',
  );

  $$TransactionsTableProcessedTableManager get walletTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_walletTransactionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TxRow>>
  _counterWalletTransactionsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactions,
        aliasName: 'wallets__id__transactions__counter_wallet_id',
      );

  $$TransactionsTableProcessedTableManager get counterWalletTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.counterWalletId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _counterWalletTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DebtEntriesTable, List<DebtEntry>>
  _debtEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.debtEntries,
    aliasName: 'wallets__id__debt_entries__wallet_id',
  );

  $$DebtEntriesTableProcessedTableManager get debtEntriesRefs {
    final manager = $$DebtEntriesTableTableManager(
      $_db,
      $_db.debtEntries,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $NotificationDraftsTable,
    List<NotificationDraftRow>
  >
  _notificationDraftsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.notificationDrafts,
        aliasName: 'wallets__id__notification_drafts__wallet_id',
      );

  $$NotificationDraftsTableProcessedTableManager get notificationDraftsRefs {
    final manager = $$NotificationDraftsTableTableManager(
      $_db,
      $_db.notificationDrafts,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _notificationDraftsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AccountNotificationMappingsTable,
    List<AccountNotificationMappingRow>
  >
  _accountNotificationMappingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountNotificationMappings,
        aliasName: 'wallets__id__account_notification_mappings__wallet_id',
      );

  $$AccountNotificationMappingsTableProcessedTableManager
  get accountNotificationMappingsRefs {
    final manager = $$AccountNotificationMappingsTableTableManager(
      $_db,
      $_db.accountNotificationMappings,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountNotificationMappingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> walletTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> counterWalletTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.counterWalletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> debtEntriesRefs(
    Expression<bool> Function($$DebtEntriesTableFilterComposer f) f,
  ) {
    final $$DebtEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtEntries,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtEntriesTableFilterComposer(
            $db: $db,
            $table: $db.debtEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notificationDraftsRefs(
    Expression<bool> Function($$NotificationDraftsTableFilterComposer f) f,
  ) {
    final $$NotificationDraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notificationDrafts,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotificationDraftsTableFilterComposer(
            $db: $db,
            $table: $db.notificationDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountNotificationMappingsRefs(
    Expression<bool> Function(
      $$AccountNotificationMappingsTableFilterComposer f,
    )
    f,
  ) {
    final $$AccountNotificationMappingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountNotificationMappings,
          getReferencedColumn: (t) => t.walletId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountNotificationMappingsTableFilterComposer(
                $db: $db,
                $table: $db.accountNotificationMappings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> walletTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> counterWalletTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.counterWalletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> debtEntriesRefs<T extends Object>(
    Expression<T> Function($$DebtEntriesTableAnnotationComposer a) f,
  ) {
    final $$DebtEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtEntries,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.debtEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notificationDraftsRefs<T extends Object>(
    Expression<T> Function($$NotificationDraftsTableAnnotationComposer a) f,
  ) {
    final $$NotificationDraftsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.notificationDrafts,
          getReferencedColumn: (t) => t.walletId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NotificationDraftsTableAnnotationComposer(
                $db: $db,
                $table: $db.notificationDrafts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> accountNotificationMappingsRefs<T extends Object>(
    Expression<T> Function(
      $$AccountNotificationMappingsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AccountNotificationMappingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountNotificationMappings,
          getReferencedColumn: (t) => t.walletId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountNotificationMappingsTableAnnotationComposer(
                $db: $db,
                $table: $db.accountNotificationMappings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          Wallet,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (Wallet, $$WalletsTableReferences),
          Wallet,
          PrefetchHooks Function({
            bool walletTransactions,
            bool counterWalletTransactions,
            bool debtEntriesRefs,
            bool notificationDraftsRefs,
            bool accountNotificationMappingsRefs,
          })
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                type: type,
                openingBalance: openingBalance,
                currency: currency,
                icon: icon,
                color: color,
                isDefault: isDefault,
                useCount: useCount,
                sortOrder: sortOrder,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                Value<int> openingBalance = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                type: type,
                openingBalance: openingBalance,
                currency: currency,
                icon: icon,
                color: color,
                isDefault: isDefault,
                useCount: useCount,
                sortOrder: sortOrder,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WalletsTable, Wallet>(table),
                  $$WalletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                walletTransactions = false,
                counterWalletTransactions = false,
                debtEntriesRefs = false,
                notificationDraftsRefs = false,
                accountNotificationMappingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (walletTransactions) db.transactions,
                    if (counterWalletTransactions) db.transactions,
                    if (debtEntriesRefs) db.debtEntries,
                    if (notificationDraftsRefs) db.notificationDrafts,
                    if (accountNotificationMappingsRefs)
                      db.accountNotificationMappings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (walletTransactions)
                        await $_getPrefetchedDataByColumns<
                          Wallet,
                          $WalletsTable,
                          TxRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._walletTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).walletTransactions,
                          currentColumn: 'id',
                          referencedColumn: 'wallet_id',
                          typedResults: items,
                        ),
                      if (counterWalletTransactions)
                        await $_getPrefetchedDataByColumns<
                          Wallet,
                          $WalletsTable,
                          TxRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._counterWalletTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).counterWalletTransactions,
                          currentColumn: 'id',
                          referencedColumn: 'counter_wallet_id',
                          typedResults: items,
                        ),
                      if (debtEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Wallet,
                          $WalletsTable,
                          DebtEntry,
                          $DebtEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._debtEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).debtEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'wallet_id',
                          typedResults: items,
                        ),
                      if (notificationDraftsRefs)
                        await $_getPrefetchedDataByColumns<
                          Wallet,
                          $WalletsTable,
                          NotificationDraftRow,
                          $NotificationDraftsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._notificationDraftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).notificationDraftsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'wallet_id',
                          typedResults: items,
                        ),
                      if (accountNotificationMappingsRefs)
                        await $_getPrefetchedDataByColumns<
                          Wallet,
                          $WalletsTable,
                          AccountNotificationMappingRow,
                          $AccountNotificationMappingsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._accountNotificationMappingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountNotificationMappingsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'wallet_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      Wallet,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (Wallet, $$WalletsTableReferences),
      Wallet,
      PrefetchHooks Function({
        bool walletTransactions,
        bool counterWalletTransactions,
        bool debtEntriesRefs,
        bool notificationDraftsRefs,
        bool accountNotificationMappingsRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String kind,
      required String walletId,
      Value<String?> counterWalletId,
      Value<String?> transferGroupId,
      Value<String?> title,
      Value<String?> category,
      Value<String?> note,
      required int amount,
      required String date,
      Value<String?> time,
      Value<String?> debtEntryId,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> walletId,
      Value<String?> counterWalletId,
      Value<String?> transferGroupId,
      Value<String?> title,
      Value<String?> category,
      Value<String?> note,
      Value<int> amount,
      Value<String> date,
      Value<String?> time,
      Value<String?> debtEntryId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TxRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('transactions__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<String>('wallet_id')!;

    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WalletsTable _counterWalletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('transactions__counter_wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get counterWalletId {
    final $_column = $_itemColumn<String>('counter_wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterWalletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableFilterComposer get counterWalletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterWalletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableOrderingComposer get counterWalletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterWalletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get debtEntryId => $composableBuilder(
    column: $table.debtEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableAnnotationComposer get counterWalletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterWalletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TxRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TxRow, $$TransactionsTableReferences),
          TxRow,
          PrefetchHooks Function({bool walletId, bool counterWalletId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<String?> counterWalletId = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
                Value<String?> debtEntryId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                kind: kind,
                walletId: walletId,
                counterWalletId: counterWalletId,
                transferGroupId: transferGroupId,
                title: title,
                category: category,
                note: note,
                amount: amount,
                date: date,
                time: time,
                debtEntryId: debtEntryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String walletId,
                Value<String?> counterWalletId = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int amount,
                required String date,
                Value<String?> time = const Value.absent(),
                Value<String?> debtEntryId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                kind: kind,
                walletId: walletId,
                counterWalletId: counterWalletId,
                transferGroupId: transferGroupId,
                title: title,
                category: category,
                note: note,
                amount: amount,
                date: date,
                time: time,
                debtEntryId: debtEntryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TxRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false, counterWalletId = false}) {
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
                    if (walletId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.walletId,
                        referencedTable: $$TransactionsTableReferences
                            ._walletIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._walletIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (counterWalletId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.counterWalletId,
                        referencedTable: $$TransactionsTableReferences
                            ._counterWalletIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._counterWalletIdTable(db)
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

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TxRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TxRow, $$TransactionsTableReferences),
      TxRow,
      PrefetchHooks Function({bool walletId, bool counterWalletId})
    >;
typedef $$SuggestionsTableCreateCompanionBuilder =
    SuggestionsCompanion Function({
      required String id,
      required String type,
      required String name,
      required String kind,
      Value<int> useCount,
      Value<int?> lastUsedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SuggestionsTableUpdateCompanionBuilder =
    SuggestionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> name,
      Value<String> kind,
      Value<int> useCount,
      Value<int?> lastUsedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SuggestionsTableFilterComposer
    extends Composer<_$AppDatabase, $SuggestionsTable> {
  $$SuggestionsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SuggestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SuggestionsTable> {
  $$SuggestionsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuggestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuggestionsTable> {
  $$SuggestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SuggestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuggestionsTable,
          Suggestion,
          $$SuggestionsTableFilterComposer,
          $$SuggestionsTableOrderingComposer,
          $$SuggestionsTableAnnotationComposer,
          $$SuggestionsTableCreateCompanionBuilder,
          $$SuggestionsTableUpdateCompanionBuilder,
          (
            Suggestion,
            BaseReferences<_$AppDatabase, $SuggestionsTable, Suggestion>,
          ),
          Suggestion,
          PrefetchHooks Function()
        > {
  $$SuggestionsTableTableManager(_$AppDatabase db, $SuggestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuggestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuggestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuggestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuggestionsCompanion(
                id: id,
                type: type,
                name: name,
                kind: kind,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String name,
                required String kind,
                Value<int> useCount = const Value.absent(),
                Value<int?> lastUsedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SuggestionsCompanion.insert(
                id: id,
                type: type,
                name: name,
                kind: kind,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SuggestionsTable, Suggestion>(table),
                  BaseReferences<_$AppDatabase, $SuggestionsTable, Suggestion>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuggestionsTable,
      Suggestion,
      $$SuggestionsTableFilterComposer,
      $$SuggestionsTableOrderingComposer,
      $$SuggestionsTableAnnotationComposer,
      $$SuggestionsTableCreateCompanionBuilder,
      $$SuggestionsTableUpdateCompanionBuilder,
      (
        Suggestion,
        BaseReferences<_$AppDatabase, $SuggestionsTable, Suggestion>,
      ),
      Suggestion,
      PrefetchHooks Function()
    >;
typedef $$DebtsTableCreateCompanionBuilder = DebtsCompanion Function({
  required String id,
  required String partyName,
  Value<String?> phone,
  required String date,
  Value<String?> note,
  Value<int?> targetAmount,
  Value<String?> targetDirection,
  Value<int> paidOpening,
  Value<bool> isSettled,
  Value<int?> deletedAt,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$DebtsTableUpdateCompanionBuilder = DebtsCompanion Function({
  Value<String> id,
  Value<String> partyName,
  Value<String?> phone,
  Value<String> date,
  Value<String?> note,
  Value<int?> targetAmount,
  Value<String?> targetDirection,
  Value<int> paidOpening,
  Value<bool> isSettled,
  Value<int?> deletedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$DebtsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtsTable, Debt> {
  $$DebtsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DebtEntriesTable, List<DebtEntry>>
  _debtEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.debtEntries,
    aliasName: 'debts__id__debt_entries__debt_id',
  );

  $$DebtEntriesTableProcessedTableManager get debtEntriesRefs {
    final manager = $$DebtEntriesTableTableManager(
      $_db,
      $_db.debtEntries,
    ).filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DebtsTableFilterComposer extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableFilterComposer({
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

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDirection => $composableBuilder(
    column: $table.targetDirection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidOpening => $composableBuilder(
    column: $table.paidOpening,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> debtEntriesRefs(
    Expression<bool> Function($$DebtEntriesTableFilterComposer f) f,
  ) {
    final $$DebtEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtEntries,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtEntriesTableFilterComposer(
            $db: $db,
            $table: $db.debtEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableOrderingComposer({
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

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDirection => $composableBuilder(
    column: $table.targetDirection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidOpening => $composableBuilder(
    column: $table.paidOpening,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDirection => $composableBuilder(
    column: $table.targetDirection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidOpening => $composableBuilder(
    column: $table.paidOpening,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> debtEntriesRefs<T extends Object>(
    Expression<T> Function($$DebtEntriesTableAnnotationComposer a) f,
  ) {
    final $$DebtEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtEntries,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.debtEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtsTable,
          Debt,
          $$DebtsTableFilterComposer,
          $$DebtsTableOrderingComposer,
          $$DebtsTableAnnotationComposer,
          $$DebtsTableCreateCompanionBuilder,
          $$DebtsTableUpdateCompanionBuilder,
          (Debt, $$DebtsTableReferences),
          Debt,
          PrefetchHooks Function({bool debtEntriesRefs})
        > {
  $$DebtsTableTableManager(_$AppDatabase db, $DebtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> partyName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> targetAmount = const Value.absent(),
                Value<String?> targetDirection = const Value.absent(),
                Value<int> paidOpening = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtsCompanion(
                id: id,
                partyName: partyName,
                phone: phone,
                date: date,
                note: note,
                targetAmount: targetAmount,
                targetDirection: targetDirection,
                paidOpening: paidOpening,
                isSettled: isSettled,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String partyName,
                Value<String?> phone = const Value.absent(),
                required String date,
                Value<String?> note = const Value.absent(),
                Value<int?> targetAmount = const Value.absent(),
                Value<String?> targetDirection = const Value.absent(),
                Value<int> paidOpening = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DebtsCompanion.insert(
                id: id,
                partyName: partyName,
                phone: phone,
                date: date,
                note: note,
                targetAmount: targetAmount,
                targetDirection: targetDirection,
                paidOpening: paidOpening,
                isSettled: isSettled,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DebtsTable, Debt>(table),
                  $$DebtsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (debtEntriesRefs) db.debtEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      Debt,
                      $DebtsTable,
                      DebtEntry,
                      $DebtEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$DebtsTableReferences
                          ._debtEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DebtsTableReferences(db, table, p0).debtEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'debt_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DebtsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtsTable,
      Debt,
      $$DebtsTableFilterComposer,
      $$DebtsTableOrderingComposer,
      $$DebtsTableAnnotationComposer,
      $$DebtsTableCreateCompanionBuilder,
      $$DebtsTableUpdateCompanionBuilder,
      (Debt, $$DebtsTableReferences),
      Debt,
      PrefetchHooks Function({bool debtEntriesRefs})
    >;
typedef $$DebtEntriesTableCreateCompanionBuilder =
    DebtEntriesCompanion Function({
      required String id,
      required String debtId,
      required int amount,
      required String date,
      Value<String?> time,
      Value<String?> walletId,
      Value<String?> note,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DebtEntriesTableUpdateCompanionBuilder =
    DebtEntriesCompanion Function({
      Value<String> id,
      Value<String> debtId,
      Value<int> amount,
      Value<String> date,
      Value<String?> time,
      Value<String?> walletId,
      Value<String?> note,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DebtEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $DebtEntriesTable, DebtEntry> {
  $$DebtEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('debt_entries__debt_id__debts__id');

  $$DebtsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<String>('debt_id')!;

    final manager = $$DebtsTableTableManager(
      $_db,
      $_db.debts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('debt_entries__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<String>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DebtEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableFilterComposer({
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

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableFilterComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableOrderingComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtEntriesTable> {
  $$DebtEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableAnnotationComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtEntriesTable,
          DebtEntry,
          $$DebtEntriesTableFilterComposer,
          $$DebtEntriesTableOrderingComposer,
          $$DebtEntriesTableAnnotationComposer,
          $$DebtEntriesTableCreateCompanionBuilder,
          $$DebtEntriesTableUpdateCompanionBuilder,
          (DebtEntry, $$DebtEntriesTableReferences),
          DebtEntry,
          PrefetchHooks Function({bool debtId, bool walletId})
        > {
  $$DebtEntriesTableTableManager(_$AppDatabase db, $DebtEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> debtId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
                Value<String?> walletId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtEntriesCompanion(
                id: id,
                debtId: debtId,
                amount: amount,
                date: date,
                time: time,
                walletId: walletId,
                note: note,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String debtId,
                required int amount,
                required String date,
                Value<String?> time = const Value.absent(),
                Value<String?> walletId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DebtEntriesCompanion.insert(
                id: id,
                debtId: debtId,
                amount: amount,
                date: date,
                time: time,
                walletId: walletId,
                note: note,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DebtEntriesTable, DebtEntry>(table),
                  $$DebtEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtId = false, walletId = false}) {
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
                    if (debtId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.debtId,
                        referencedTable: $$DebtEntriesTableReferences
                            ._debtIdTable(db),
                        referencedColumn: $$DebtEntriesTableReferences
                            ._debtIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (walletId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.walletId,
                        referencedTable: $$DebtEntriesTableReferences
                            ._walletIdTable(db),
                        referencedColumn: $$DebtEntriesTableReferences
                            ._walletIdTable(db)
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

typedef $$DebtEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtEntriesTable,
      DebtEntry,
      $$DebtEntriesTableFilterComposer,
      $$DebtEntriesTableOrderingComposer,
      $$DebtEntriesTableAnnotationComposer,
      $$DebtEntriesTableCreateCompanionBuilder,
      $$DebtEntriesTableUpdateCompanionBuilder,
      (DebtEntry, $$DebtEntriesTableReferences),
      DebtEntry,
      PrefetchHooks Function({bool debtId, bool walletId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String id,
  required String category,
  required String period,
  required int amount,
  Value<int> warnPercent,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<int?> deletedAt,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> category,
  Value<String> period,
  Value<int> amount,
  Value<int> warnPercent,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<int?> deletedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warnPercent => $composableBuilder(
    column: $table.warnPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warnPercent => $composableBuilder(
    column: $table.warnPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get warnPercent => $composableBuilder(
    column: $table.warnPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
          Budget,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> warnPercent = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                category: category,
                period: period,
                amount: amount,
                warnPercent: warnPercent,
                startDate: startDate,
                endDate: endDate,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String period,
                required int amount,
                Value<int> warnPercent = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                category: category,
                period: period,
                amount: amount,
                warnPercent: warnPercent,
                startDate: startDate,
                endDate: endDate,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  BaseReferences<_$AppDatabase, $BudgetsTable, Budget>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
      Budget,
      PrefetchHooks Function()
    >;
typedef $$CustomReportsTableCreateCompanionBuilder =
    CustomReportsCompanion Function({
      required String id,
      required String name,
      required String startDate,
      required String endDate,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CustomReportsTableUpdateCompanionBuilder =
    CustomReportsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> startDate,
      Value<String> endDate,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CustomReportsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomReportsTable> {
  $$CustomReportsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomReportsTable> {
  $$CustomReportsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomReportsTable> {
  $$CustomReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomReportsTable,
          CustomReport,
          $$CustomReportsTableFilterComposer,
          $$CustomReportsTableOrderingComposer,
          $$CustomReportsTableAnnotationComposer,
          $$CustomReportsTableCreateCompanionBuilder,
          $$CustomReportsTableUpdateCompanionBuilder,
          (
            CustomReport,
            BaseReferences<_$AppDatabase, $CustomReportsTable, CustomReport>,
          ),
          CustomReport,
          PrefetchHooks Function()
        > {
  $$CustomReportsTableTableManager(_$AppDatabase db, $CustomReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomReportsCompanion(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String startDate,
                required String endDate,
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomReportsCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomReportsTable, CustomReport>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomReportsTable,
                    CustomReport
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomReportsTable,
      CustomReport,
      $$CustomReportsTableFilterComposer,
      $$CustomReportsTableOrderingComposer,
      $$CustomReportsTableAnnotationComposer,
      $$CustomReportsTableCreateCompanionBuilder,
      $$CustomReportsTableUpdateCompanionBuilder,
      (
        CustomReport,
        BaseReferences<_$AppDatabase, $CustomReportsTable, CustomReport>,
      ),
      CustomReport,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SchemaMigrationsTableCreateCompanionBuilder =
    SchemaMigrationsCompanion Function({
      required int version,
      required int appliedAt,
      Value<int> rowid,
    });
typedef $$SchemaMigrationsTableUpdateCompanionBuilder =
    SchemaMigrationsCompanion Function({
      Value<int> version,
      Value<int> appliedAt,
      Value<int> rowid,
    });

class $$SchemaMigrationsTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMigrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMigrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$SchemaMigrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMigrationsTable,
          SchemaMigration,
          $$SchemaMigrationsTableFilterComposer,
          $$SchemaMigrationsTableOrderingComposer,
          $$SchemaMigrationsTableAnnotationComposer,
          $$SchemaMigrationsTableCreateCompanionBuilder,
          $$SchemaMigrationsTableUpdateCompanionBuilder,
          (
            SchemaMigration,
            BaseReferences<
              _$AppDatabase,
              $SchemaMigrationsTable,
              SchemaMigration
            >,
          ),
          SchemaMigration,
          PrefetchHooks Function()
        > {
  $$SchemaMigrationsTableTableManager(
    _$AppDatabase db,
    $SchemaMigrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMigrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaMigrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaMigrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchemaMigrationsCompanion(
                version: version,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int version,
                required int appliedAt,
                Value<int> rowid = const Value.absent(),
              }) => SchemaMigrationsCompanion.insert(
                version: version,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchemaMigrationsTable, SchemaMigration>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SchemaMigrationsTable,
                    SchemaMigration
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMigrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMigrationsTable,
      SchemaMigration,
      $$SchemaMigrationsTableFilterComposer,
      $$SchemaMigrationsTableOrderingComposer,
      $$SchemaMigrationsTableAnnotationComposer,
      $$SchemaMigrationsTableCreateCompanionBuilder,
      $$SchemaMigrationsTableUpdateCompanionBuilder,
      (
        SchemaMigration,
        BaseReferences<_$AppDatabase, $SchemaMigrationsTable, SchemaMigration>,
      ),
      SchemaMigration,
      PrefetchHooks Function()
    >;
typedef $$NotificationDraftsTableCreateCompanionBuilder =
    NotificationDraftsCompanion Function({
      required String id,
      required String packageName,
      required String appName,
      required String rawTitle,
      required String rawMessage,
      required int amount,
      required String type,
      Value<String?> walletId,
      required int occurredAt,
      required String date,
      Value<String?> time,
      Value<String> status,
      required String sourceKey,
      Value<String?> approvedTransactionId,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$NotificationDraftsTableUpdateCompanionBuilder =
    NotificationDraftsCompanion Function({
      Value<String> id,
      Value<String> packageName,
      Value<String> appName,
      Value<String> rawTitle,
      Value<String> rawMessage,
      Value<int> amount,
      Value<String> type,
      Value<String?> walletId,
      Value<int> occurredAt,
      Value<String> date,
      Value<String?> time,
      Value<String> status,
      Value<String> sourceKey,
      Value<String?> approvedTransactionId,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$NotificationDraftsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NotificationDraftsTable,
          NotificationDraftRow
        > {
  $$NotificationDraftsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('notification_drafts__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<String>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotificationDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationDraftsTable> {
  $$NotificationDraftsTableFilterComposer({
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

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawTitle => $composableBuilder(
    column: $table.rawTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedTransactionId => $composableBuilder(
    column: $table.approvedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationDraftsTable> {
  $$NotificationDraftsTableOrderingComposer({
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

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawTitle => $composableBuilder(
    column: $table.rawTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedTransactionId => $composableBuilder(
    column: $table.approvedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationDraftsTable> {
  $$NotificationDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get rawTitle =>
      $composableBuilder(column: $table.rawTitle, builder: (column) => column);

  GeneratedColumn<String> get rawMessage => $composableBuilder(
    column: $table.rawMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get approvedTransactionId => $composableBuilder(
    column: $table.approvedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationDraftsTable,
          NotificationDraftRow,
          $$NotificationDraftsTableFilterComposer,
          $$NotificationDraftsTableOrderingComposer,
          $$NotificationDraftsTableAnnotationComposer,
          $$NotificationDraftsTableCreateCompanionBuilder,
          $$NotificationDraftsTableUpdateCompanionBuilder,
          (NotificationDraftRow, $$NotificationDraftsTableReferences),
          NotificationDraftRow,
          PrefetchHooks Function({bool walletId})
        > {
  $$NotificationDraftsTableTableManager(
    _$AppDatabase db,
    $NotificationDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationDraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> rawTitle = const Value.absent(),
                Value<String> rawMessage = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> walletId = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String?> approvedTransactionId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationDraftsCompanion(
                id: id,
                packageName: packageName,
                appName: appName,
                rawTitle: rawTitle,
                rawMessage: rawMessage,
                amount: amount,
                type: type,
                walletId: walletId,
                occurredAt: occurredAt,
                date: date,
                time: time,
                status: status,
                sourceKey: sourceKey,
                approvedTransactionId: approvedTransactionId,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageName,
                required String appName,
                required String rawTitle,
                required String rawMessage,
                required int amount,
                required String type,
                Value<String?> walletId = const Value.absent(),
                required int occurredAt,
                required String date,
                Value<String?> time = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String sourceKey,
                Value<String?> approvedTransactionId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationDraftsCompanion.insert(
                id: id,
                packageName: packageName,
                appName: appName,
                rawTitle: rawTitle,
                rawMessage: rawMessage,
                amount: amount,
                type: type,
                walletId: walletId,
                occurredAt: occurredAt,
                date: date,
                time: time,
                status: status,
                sourceKey: sourceKey,
                approvedTransactionId: approvedTransactionId,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationDraftsTable, NotificationDraftRow>(
                    table,
                  ),
                  $$NotificationDraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false}) {
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
                    if (walletId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.walletId,
                        referencedTable: $$NotificationDraftsTableReferences
                            ._walletIdTable(db),
                        referencedColumn: $$NotificationDraftsTableReferences
                            ._walletIdTable(db)
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

typedef $$NotificationDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationDraftsTable,
      NotificationDraftRow,
      $$NotificationDraftsTableFilterComposer,
      $$NotificationDraftsTableOrderingComposer,
      $$NotificationDraftsTableAnnotationComposer,
      $$NotificationDraftsTableCreateCompanionBuilder,
      $$NotificationDraftsTableUpdateCompanionBuilder,
      (NotificationDraftRow, $$NotificationDraftsTableReferences),
      NotificationDraftRow,
      PrefetchHooks Function({bool walletId})
    >;
typedef $$AccountNotificationMappingsTableCreateCompanionBuilder =
    AccountNotificationMappingsCompanion Function({
      required String id,
      required String packageName,
      required String walletId,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AccountNotificationMappingsTableUpdateCompanionBuilder =
    AccountNotificationMappingsCompanion Function({
      Value<String> id,
      Value<String> packageName,
      Value<String> walletId,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$AccountNotificationMappingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccountNotificationMappingsTable,
          AccountNotificationMappingRow
        > {
  $$AccountNotificationMappingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WalletsTable _walletIdTable(_$AppDatabase db) => db.wallets
      .createAlias('account_notification_mappings__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<String>('wallet_id')!;

    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountNotificationMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountNotificationMappingsTable> {
  $$AccountNotificationMappingsTableFilterComposer({
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

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNotificationMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountNotificationMappingsTable> {
  $$AccountNotificationMappingsTableOrderingComposer({
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

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNotificationMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountNotificationMappingsTable> {
  $$AccountNotificationMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountNotificationMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountNotificationMappingsTable,
          AccountNotificationMappingRow,
          $$AccountNotificationMappingsTableFilterComposer,
          $$AccountNotificationMappingsTableOrderingComposer,
          $$AccountNotificationMappingsTableAnnotationComposer,
          $$AccountNotificationMappingsTableCreateCompanionBuilder,
          $$AccountNotificationMappingsTableUpdateCompanionBuilder,
          (
            AccountNotificationMappingRow,
            $$AccountNotificationMappingsTableReferences,
          ),
          AccountNotificationMappingRow,
          PrefetchHooks Function({bool walletId})
        > {
  $$AccountNotificationMappingsTableTableManager(
    _$AppDatabase db,
    $AccountNotificationMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountNotificationMappingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AccountNotificationMappingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AccountNotificationMappingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountNotificationMappingsCompanion(
                id: id,
                packageName: packageName,
                walletId: walletId,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageName,
                required String walletId,
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountNotificationMappingsCompanion.insert(
                id: id,
                packageName: packageName,
                walletId: walletId,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AccountNotificationMappingsTable,
                    AccountNotificationMappingRow
                  >(table),
                  $$AccountNotificationMappingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false}) {
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
                    if (walletId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.walletId,
                        referencedTable:
                            $$AccountNotificationMappingsTableReferences
                                ._walletIdTable(db),
                        referencedColumn:
                            $$AccountNotificationMappingsTableReferences
                                ._walletIdTable(db)
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

typedef $$AccountNotificationMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountNotificationMappingsTable,
      AccountNotificationMappingRow,
      $$AccountNotificationMappingsTableFilterComposer,
      $$AccountNotificationMappingsTableOrderingComposer,
      $$AccountNotificationMappingsTableAnnotationComposer,
      $$AccountNotificationMappingsTableCreateCompanionBuilder,
      $$AccountNotificationMappingsTableUpdateCompanionBuilder,
      (
        AccountNotificationMappingRow,
        $$AccountNotificationMappingsTableReferences,
      ),
      AccountNotificationMappingRow,
      PrefetchHooks Function({bool walletId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SuggestionsTableTableManager get suggestions =>
      $$SuggestionsTableTableManager(_db, _db.suggestions);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db, _db.debts);
  $$DebtEntriesTableTableManager get debtEntries =>
      $$DebtEntriesTableTableManager(_db, _db.debtEntries);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$CustomReportsTableTableManager get customReports =>
      $$CustomReportsTableTableManager(_db, _db.customReports);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SchemaMigrationsTableTableManager get schemaMigrations =>
      $$SchemaMigrationsTableTableManager(_db, _db.schemaMigrations);
  $$NotificationDraftsTableTableManager get notificationDrafts =>
      $$NotificationDraftsTableTableManager(_db, _db.notificationDrafts);
  $$AccountNotificationMappingsTableTableManager
  get accountNotificationMappings =>
      $$AccountNotificationMappingsTableTableManager(
        _db,
        _db.accountNotificationMappings,
      );
}
