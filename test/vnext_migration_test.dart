import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/data/database/vnext_tables.dart';
import 'package:libre2026/data/repositories/vnext_repositories.dart';
import 'package:libre2026/domain/entities/entities.dart';

void main() {
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbPath = join(
      Directory.systemTemp.path,
      'vnext_migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final file = File(dbPath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  });

  tearDown(() async {
    final file = File(dbPath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  });

  test(
    'Database migration v2 -> v3 preserves legacy notes and creates vNext tables',
    () async {
      // Step 1: Initialize Database at version 2 with legacy schema & sample data
      var db = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
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
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');

          // Seed legacy notes
          await db.insert('notes', {
            'category': 'coban',
            'title': 'Bài học cơ bản 1',
            'subtitle': 'Khái niệm',
            'blocks': '[{"content":"Nội dung cơ bản","type":0}]',
            'date': '2026-01-01T00:00:00.000Z',
            'color': 4283215696,
          });

          await db.insert('notes', {
            'category': 'boso',
            'title': 'Bộ số 50-30-20',
            'subtitle': 'Công thức',
            'blocks':
                '[{"content":"Target = Origin - ThirdCushion","type":16}]',
            'date': '2026-01-02T00:00:00.000Z',
            'color': 4283215696,
          });

          await db.insert('notes', {
            'category': 'gombi',
            'title': 'Kỹ thuật gom bi',
            'subtitle': 'Tập trung bi',
            'blocks': '[{"content":"Tạo góc tam giác","type":0}]',
            'date': '2026-01-03T00:00:00.000Z',
            'color': 4283215696,
          });
        },
      );

      // Verify initial v2 state
      final initialNotesCount = _firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes'),
      );
      expect(initialNotesCount, 3);
      await db.close();

      // Step 2: Open file and upgrade to version 3
      db = await openDatabase(
        dbPath,
        version: 3,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await VNextTables.createAll(db);
          }
        },
      );

      // Step 3: Verify legacy data preservation
      final migratedNotesCount = _firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes'),
      );
      expect(
        migratedNotesCount,
        3,
        reason: 'Legacy notes table data must remain intact',
      );

      final cobanNote = await db.query(
        'notes',
        where: 'category = ?',
        whereArgs: ['coban'],
      );
      expect(cobanNote.first['title'], 'Bài học cơ bản 1');

      // Step 4: Verify vNext tables exist and repositories operate cleanly
      final vNextLessonRepo = SqliteLessonRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      await vNextLessonRepo.save(
        Lesson(
          id: 'vnext-lesson-1',
          title: 'vNext Lesson Title',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final fetchedLesson = await vNextLessonRepo.getById('vnext-lesson-1');
      expect(fetchedLesson, isNotNull);
      expect(fetchedLesson!.title, 'vNext Lesson Title');

      await db.close();

      // Step 5: Reopen to verify migration idempotency
      db = await openDatabase(
        dbPath,
        version: 3,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await VNextTables.createAll(db);
          }
        },
      );

      final reopenedNotesCount = _firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes'),
      );
      expect(reopenedNotesCount, 3);

      final reopenedLessonRepo = SqliteLessonRepository(db);
      final reopenedLesson = await reopenedLessonRepo.getById('vnext-lesson-1');
      expect(reopenedLesson, isNotNull);

      await db.close();
    },
  );
}

int _firstIntValue(List<Map<String, Object?>> res) =>
    res.first.values.first as int;
