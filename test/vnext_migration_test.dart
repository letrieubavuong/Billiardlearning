import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/data/database/database_migrations.dart';
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
    'Production database migration v2 -> v4 preserves legacy notes and creates vNext tables',
    () async {
      // Step 1: Initialize Database at version 2 with legacy schema & sample data
      var db = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await DatabaseMigrations.createV1(db);

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
        },
      );

      // Verify initial v2 state
      final initialNotesCount = _firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes'),
      );
      expect(initialNotesCount, 2);
      await db.close();

      // Step 2: Open file and run PRODUCTION migration to version 4
      db = await openDatabase(
        dbPath,
        version: 4,
        onUpgrade: (db, oldVersion, newVersion) async {
          await DatabaseMigrations.migrate(db, oldVersion, newVersion);
        },
      );

      // Step 3: Verify legacy data preservation
      final migratedNotesCount = _firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM notes'),
      );
      expect(migratedNotesCount, 2);

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
    },
  );

  test(
    'Production migration old-v3 -> v4 reconciles duplicate progress records and adds UNIQUE index',
    () async {
      // Step 1: Initialize Database at old v3 schema (without UNIQUE entity_id)
      var db = await openDatabase(
        dbPath,
        version: 3,
        onCreate: (db, version) async {
          await DatabaseMigrations.createV1(db);
          await DatabaseMigrations.migrate(db, 1, 3);
          await db.execute(
            'DROP INDEX IF EXISTS index_vnext_progress_entity_unique',
          );
        },
      );

      // Insert duplicate progress entries for same entity_id in old v3 DB
      await db.insert('vnext_learning_progress', {
        'id': 'p-1',
        'entity_id': 'lesson-99',
        'category': 'coban',
        'is_completed': 0,
        'completed_at': null,
      });

      await db.insert('vnext_learning_progress', {
        'id': 'p-2',
        'entity_id': 'lesson-99',
        'category': 'coban',
        'is_completed': 1,
        'completed_at': '2026-09-22T10:00:00.000Z',
      });

      final v3Count = _firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM vnext_learning_progress WHERE entity_id = ?',
          ['lesson-99'],
        ),
      );
      expect(
        v3Count,
        2,
        reason: 'Old v3 schema allowed duplicate progress entries',
      );
      await db.close();

      // Step 2: Upgrade to v4 running production migration
      db = await openDatabase(
        dbPath,
        version: 4,
        onUpgrade: (db, oldVersion, newVersion) async {
          await DatabaseMigrations.migrate(db, oldVersion, newVersion);
        },
      );

      // Verify duplicate reconciliation: only 1 row remains
      final v4Count = _firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM vnext_learning_progress WHERE entity_id = ?',
          ['lesson-99'],
        ),
      );
      expect(
        v4Count,
        1,
        reason: 'Migration v3->v4 must reconcile duplicate progress entries',
      );

      final remainingRecord = await db.query(
        'vnext_learning_progress',
        where: 'entity_id = ?',
        whereArgs: ['lesson-99'],
      );
      expect(
        remainingRecord.first['id'],
        'p-2',
        reason: 'Reconciliation policy must retain the latest entry',
      );

      // Verify UNIQUE index exists
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'index_vnext_progress_entity_unique'",
      );
      expect(indexes, isNotEmpty);

      // Verify repo write works with UPSERT on entity_id
      final progRepo = SqliteLearningProgressRepository(db);
      await progRepo.saveProgress(
        LearningProgressRecord(
          id: 'p-3',
          entityId: 'lesson-99',
          category: 'coban',
          isCompleted: true,
          completedAt: DateTime.utc(2026, 9, 22, 12, 0),
        ),
      );

      final updatedProgress = await progRepo.getByEntityId('lesson-99');
      expect(updatedProgress, isNotNull);
      expect(updatedProgress!.isCompleted, isTrue);

      await db.close();
    },
  );
}

int _firstIntValue(List<Map<String, Object?>> res) =>
    res.first.values.first as int;
