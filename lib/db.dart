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
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE events (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          text TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    },
  );
  return _db!;
}
