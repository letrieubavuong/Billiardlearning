// Production Database Migration Engine for Billiardlearning

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'vnext_tables.dart';

class DatabaseMigrations {
  const DatabaseMigrations._();

  static Future<void> createV1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        blocks TEXT NOT NULL,
        date TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_notes_category_date '
      'ON notes(category, date)',
    );
  }

  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS index_notes_category_date '
        'ON notes(category, date)',
      );
    }
    if (oldVersion < 3) {
      await VNextTables.createAll(db);
    }
  }
}
