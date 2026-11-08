// import 'package:drift/drift.dart';
// import 'dart:io';

// import 'package:drift/native.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:sqlite3/sqlite3.dart';
// import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// part 'app_database_service.g.dart';

// class Items extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   TextColumn get name => text().withLength(min: 6, max: 100)();
//   TextColumn get description => text()();
//   // IntColumn get category => integer().nullable()();
// }

// class Barcodes extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   IntColumn get data => integer().unique()();
//   // TextColumn get  => text()();
//   // IntColumn get category => integer().nullable()();
// }

// @DriftDatabase(tables: [Items, Barcodes])
// class AppDataBaseServices extends _$AppDataBaseServices {
//   AppDataBaseServices() : super(_openConnection());

//   @override
//   int get schemaVersion => 1;

// //   @override
// // MigrationStrategy get migration {
// //   return MigrationStrategy(
// //     onCreate: (Migrator m) async {
// //       await m.createAll();
// //     },
// //     onUpgrade: (Migrator m, int from, int to) async {
// //       if (from < 2) {
// //         // we added the dueDate property in the change from version 1 to
// //         // version 2
// //         await m.addColumn(items, items.dueDate);
// //       }
// //       if (from < 3) {
// //         // we added the priority property in the change from version 1 or 2
// //         // to version 3
// //         await m.addColumn(items, todos.priority);
// //       }
// //     },
// //   );
// // }
// }

// LazyDatabase _openConnection() {
//   // the LazyDatabase util lets us find the right location for the file async.
//   return LazyDatabase(() async {
//     // put the database file, called db.sqlite here, into the documents folder
//     // for your app.
//     final dbFolder = await getApplicationDocumentsDirectory();
//     final file = File(p.join(dbFolder.path, 'db.sqlite'));
//     // print(dbFolder);
//     // Also work around limitations on old Android versions
//     if (Platform.isAndroid) {
//       await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
//     }

// //     // Make sqlite3 pick a more suitable location for temporary files - the
// //     // one from the system may be inaccessible due to sandboxing.
//     final cachebase = (await getTemporaryDirectory()).path;
// //     // We can't access /tmp on Android, which sqlite3 would try by default.
// //     // Explicitly tell it about the correct temporary directory.
//     sqlite3.tempDirectory = cachebase;

//     return NativeDatabase.createInBackground(file);
//   });
// }
