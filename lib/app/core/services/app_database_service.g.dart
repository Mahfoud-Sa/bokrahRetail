// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'app_database_service.dart';

// // ignore_for_file: type=lint
// class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
//   @override
//   final GeneratedDatabase attachedDatabase;
//   final String? _alias;
//   $ItemsTable(this.attachedDatabase, [this._alias]);
//   static const VerificationMeta _idMeta = const VerificationMeta('id');
//   @override
//   late final GeneratedColumn<int> id = GeneratedColumn<int>(
//       'id', aliasedName, false,
//       hasAutoIncrement: true,
//       type: DriftSqlType.int,
//       requiredDuringInsert: false,
//       defaultConstraints:
//           GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
//   static const VerificationMeta _nameMeta = const VerificationMeta('name');
//   @override
//   late final GeneratedColumn<String> name = GeneratedColumn<String>(
//       'name', aliasedName, false,
//       additionalChecks:
//           GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 100),
//       type: DriftSqlType.string,
//       requiredDuringInsert: true);
//   static const VerificationMeta _descriptionMeta =
//       const VerificationMeta('description');
//   @override
//   late final GeneratedColumn<String> description = GeneratedColumn<String>(
//       'description', aliasedName, false,
//       type: DriftSqlType.string, requiredDuringInsert: true);
//   @override
//   List<GeneratedColumn> get $columns => [id, name, description];
//   @override
//   String get aliasedName => _alias ?? actualTableName;
//   @override
//   String get actualTableName => $name;
//   static const String $name = 'items';
//   @override
//   VerificationContext validateIntegrity(Insertable<Item> instance,
//       {bool isInserting = false}) {
//     final context = VerificationContext();
//     final data = instance.toColumns(true);
//     if (data.containsKey('id')) {
//       context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
//     }
//     if (data.containsKey('name')) {
//       context.handle(
//           _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
//     } else if (isInserting) {
//       context.missing(_nameMeta);
//     }
//     if (data.containsKey('description')) {
//       context.handle(
//           _descriptionMeta,
//           description.isAcceptableOrUnknown(
//               data['description']!, _descriptionMeta));
//     } else if (isInserting) {
//       context.missing(_descriptionMeta);
//     }
//     return context;
//   }

//   @override
//   Set<GeneratedColumn> get $primaryKey => {id};
//   @override
//   Item map(Map<String, dynamic> data, {String? tablePrefix}) {
//     final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
//     return Item(
//       id: attachedDatabase.typeMapping
//           .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
//       name: attachedDatabase.typeMapping
//           .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
//       description: attachedDatabase.typeMapping
//           .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
//     );
//   }

//   @override
//   $ItemsTable createAlias(String alias) {
//     return $ItemsTable(attachedDatabase, alias);
//   }
// }

// class Item extends DataClass implements Insertable<Item> {
//   final int id;
//   final String name;
//   final String description;
//   const Item({required this.id, required this.name, required this.description});
//   @override
//   Map<String, Expression> toColumns(bool nullToAbsent) {
//     final map = <String, Expression>{};
//     map['id'] = Variable<int>(id);
//     map['name'] = Variable<String>(name);
//     map['description'] = Variable<String>(description);
//     return map;
//   }

//   ItemsCompanion toCompanion(bool nullToAbsent) {
//     return ItemsCompanion(
//       id: Value(id),
//       name: Value(name),
//       description: Value(description),
//     );
//   }

//   factory Item.fromJson(Map<String, dynamic> json,
//       {ValueSerializer? serializer}) {
//     serializer ??= driftRuntimeOptions.defaultSerializer;
//     return Item(
//       id: serializer.fromJson<int>(json['id']),
//       name: serializer.fromJson<String>(json['name']),
//       description: serializer.fromJson<String>(json['description']),
//     );
//   }
//   @override
//   Map<String, dynamic> toJson({ValueSerializer? serializer}) {
//     serializer ??= driftRuntimeOptions.defaultSerializer;
//     return <String, dynamic>{
//       'id': serializer.toJson<int>(id),
//       'name': serializer.toJson<String>(name),
//       'description': serializer.toJson<String>(description),
//     };
//   }

//   Item copyWith({int? id, String? name, String? description}) => Item(
//         id: id ?? this.id,
//         name: name ?? this.name,
//         description: description ?? this.description,
//       );
//   @override
//   String toString() {
//     return (StringBuffer('Item(')
//           ..write('id: $id, ')
//           ..write('name: $name, ')
//           ..write('description: $description')
//           ..write(')'))
//         .toString();
//   }

//   @override
//   int get hashCode => Object.hash(id, name, description);
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       (other is Item &&
//           other.id == this.id &&
//           other.name == this.name &&
//           other.description == this.description);
// }

// class ItemsCompanion extends UpdateCompanion<Item> {
//   final Value<int> id;
//   final Value<String> name;
//   final Value<String> description;
//   const ItemsCompanion({
//     this.id = const Value.absent(),
//     this.name = const Value.absent(),
//     this.description = const Value.absent(),
//   });
//   ItemsCompanion.insert({
//     this.id = const Value.absent(),
//     required String name,
//     required String description,
//   })  : name = Value(name),
//         description = Value(description);
//   static Insertable<Item> custom({
//     Expression<int>? id,
//     Expression<String>? name,
//     Expression<String>? description,
//   }) {
//     return RawValuesInsertable({
//       if (id != null) 'id': id,
//       if (name != null) 'name': name,
//       if (description != null) 'description': description,
//     });
//   }

//   ItemsCompanion copyWith(
//       {Value<int>? id, Value<String>? name, Value<String>? description}) {
//     return ItemsCompanion(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//     );
//   }

//   @override
//   Map<String, Expression> toColumns(bool nullToAbsent) {
//     final map = <String, Expression>{};
//     if (id.present) {
//       map['id'] = Variable<int>(id.value);
//     }
//     if (name.present) {
//       map['name'] = Variable<String>(name.value);
//     }
//     if (description.present) {
//       map['description'] = Variable<String>(description.value);
//     }
//     return map;
//   }

//   @override
//   String toString() {
//     return (StringBuffer('ItemsCompanion(')
//           ..write('id: $id, ')
//           ..write('name: $name, ')
//           ..write('description: $description')
//           ..write(')'))
//         .toString();
//   }
// }

// class $BarcodesTable extends Barcodes with TableInfo<$BarcodesTable, Barcode> {
//   @override
//   final GeneratedDatabase attachedDatabase;
//   final String? _alias;
//   $BarcodesTable(this.attachedDatabase, [this._alias]);
//   static const VerificationMeta _idMeta = const VerificationMeta('id');
//   @override
//   late final GeneratedColumn<int> id = GeneratedColumn<int>(
//       'id', aliasedName, false,
//       hasAutoIncrement: true,
//       type: DriftSqlType.int,
//       requiredDuringInsert: false,
//       defaultConstraints:
//           GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
//   static const VerificationMeta _dataMeta = const VerificationMeta('data');
//   @override
//   late final GeneratedColumn<int> data = GeneratedColumn<int>(
//       'data', aliasedName, false,
//       type: DriftSqlType.int,
//       requiredDuringInsert: true,
//       defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
//   @override
//   List<GeneratedColumn> get $columns => [id, data];
//   @override
//   String get aliasedName => _alias ?? actualTableName;
//   @override
//   String get actualTableName => $name;
//   static const String $name = 'barcodes';
//   @override
//   VerificationContext validateIntegrity(Insertable<Barcode> instance,
//       {bool isInserting = false}) {
//     final context = VerificationContext();
//     final data = instance.toColumns(true);
//     if (data.containsKey('id')) {
//       context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
//     }
//     if (data.containsKey('data')) {
//       context.handle(
//           _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
//     } else if (isInserting) {
//       context.missing(_dataMeta);
//     }
//     return context;
//   }

//   @override
//   Set<GeneratedColumn> get $primaryKey => {id};
//   @override
//   Barcode map(Map<String, dynamic> data, {String? tablePrefix}) {
//     final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
//     return Barcode(
//       id: attachedDatabase.typeMapping
//           .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
//       data: attachedDatabase.typeMapping
//           .read(DriftSqlType.int, data['${effectivePrefix}data'])!,
//     );
//   }

//   @override
//   $BarcodesTable createAlias(String alias) {
//     return $BarcodesTable(attachedDatabase, alias);
//   }
// }

// class Barcode extends DataClass implements Insertable<Barcode> {
//   final int id;
//   final int data;
//   const Barcode({required this.id, required this.data});
//   @override
//   Map<String, Expression> toColumns(bool nullToAbsent) {
//     final map = <String, Expression>{};
//     map['id'] = Variable<int>(id);
//     map['data'] = Variable<int>(data);
//     return map;
//   }

//   BarcodesCompanion toCompanion(bool nullToAbsent) {
//     return BarcodesCompanion(
//       id: Value(id),
//       data: Value(data),
//     );
//   }

//   factory Barcode.fromJson(Map<String, dynamic> json,
//       {ValueSerializer? serializer}) {
//     serializer ??= driftRuntimeOptions.defaultSerializer;
//     return Barcode(
//       id: serializer.fromJson<int>(json['id']),
//       data: serializer.fromJson<int>(json['data']),
//     );
//   }
//   @override
//   Map<String, dynamic> toJson({ValueSerializer? serializer}) {
//     serializer ??= driftRuntimeOptions.defaultSerializer;
//     return <String, dynamic>{
//       'id': serializer.toJson<int>(id),
//       'data': serializer.toJson<int>(data),
//     };
//   }

//   Barcode copyWith({int? id, int? data}) => Barcode(
//         id: id ?? this.id,
//         data: data ?? this.data,
//       );
//   @override
//   String toString() {
//     return (StringBuffer('Barcode(')
//           ..write('id: $id, ')
//           ..write('data: $data')
//           ..write(')'))
//         .toString();
//   }

//   @override
//   int get hashCode => Object.hash(id, data);
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       (other is Barcode && other.id == this.id && other.data == this.data);
// }

// class BarcodesCompanion extends UpdateCompanion<Barcode> {
//   final Value<int> id;
//   final Value<int> data;
//   const BarcodesCompanion({
//     this.id = const Value.absent(),
//     this.data = const Value.absent(),
//   });
//   BarcodesCompanion.insert({
//     this.id = const Value.absent(),
//     required int data,
//   }) : data = Value(data);
//   static Insertable<Barcode> custom({
//     Expression<int>? id,
//     Expression<int>? data,
//   }) {
//     return RawValuesInsertable({
//       if (id != null) 'id': id,
//       if (data != null) 'data': data,
//     });
//   }

//   BarcodesCompanion copyWith({Value<int>? id, Value<int>? data}) {
//     return BarcodesCompanion(
//       id: id ?? this.id,
//       data: data ?? this.data,
//     );
//   }

//   @override
//   Map<String, Expression> toColumns(bool nullToAbsent) {
//     final map = <String, Expression>{};
//     if (id.present) {
//       map['id'] = Variable<int>(id.value);
//     }
//     if (data.present) {
//       map['data'] = Variable<int>(data.value);
//     }
//     return map;
//   }

//   @override
//   String toString() {
//     return (StringBuffer('BarcodesCompanion(')
//           ..write('id: $id, ')
//           ..write('data: $data')
//           ..write(')'))
//         .toString();
//   }
// }

// abstract class _$AppDataBaseServices extends GeneratedDatabase {
//   _$AppDataBaseServices(QueryExecutor e) : super(e);
//   late final $ItemsTable items = $ItemsTable(this);
//   late final $BarcodesTable barcodes = $BarcodesTable(this);
//   @override
//   Iterable<TableInfo<Table, Object?>> get allTables =>
//       allSchemaEntities.whereType<TableInfo<Table, Object?>>();
//   @override
//   List<DatabaseSchemaEntity> get allSchemaEntities => [items, barcodes];
// }
