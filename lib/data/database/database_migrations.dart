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
    if (oldVersion < 4) {
      // Ensure vNext tables exist if migrating from older versions
      await VNextTables.createTables(db);

      // Deterministic Reconciliation Policy for duplicate progress records:
      // Keep the most recent entry per entity_id and delete older duplicate rows.
      await db.execute('''
        DELETE FROM vnext_learning_progress
        WHERE id NOT IN (
          SELECT t1.id
          FROM vnext_learning_progress t1
          WHERE t1.id = (
            SELECT t2.id
            FROM vnext_learning_progress t2
            WHERE t2.entity_id = t1.entity_id
            ORDER BY CASE WHEN t2.completed_at IS NOT NULL THEN 1 ELSE 0 END DESC, t2.completed_at DESC, t2.id DESC
            LIMIT 1
          )
        )
      ''');

      // Create all indexes including UNIQUE index enforcing single progress entry per entity_id
      await VNextTables.createIndexes(db);
    }
  }
}
