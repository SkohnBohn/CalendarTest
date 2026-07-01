import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Database? _db;

Future<Database> getDb() async {
  if (_db != null) return _db!;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dir = await getApplicationSupportDirectory();
  final dbPath = p.join(dir.path, 'events.db');
  await Directory(dir.path).create(recursive: true);

  _db = await openDatabase(
    dbPath,
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE events (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          text TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
            'ALTER TABLE events ADD COLUMN notes TEXT NOT NULL DEFAULT ""');
      }
    },
  );
  return _db!;
}
