import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/data/database/vnext_tables.dart';
import 'package:libre2026/data/mappers/mappers.dart';
import 'package:libre2026/data/repositories/vnext_repositories.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await VNextTables.createAll(db);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('vNext Schema & Table Creation', () {
    test('creates all 8 vNext tables and required indexes', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'vnext_%'",
      );
      final names = tables.map((t) => t['name'] as String).toSet();

      expect(
        names,
        containsAll([
          'vnext_lessons',
          'vnext_scenes',
          'vnext_techniques',
          'vnext_number_systems',
          'vnext_exercises',
          'vnext_media_assets',
          'vnext_learning_progress',
          'vnext_simulation_profiles',
        ]),
      );
    });
  });

  group('Mappers Round-Trip Tests', () {
    test('LessonMapper round-trips domain entity', () {
      final now = DateTime.utc(2026, 9, 22, 10, 0, 0);
      final lesson = Lesson(
        id: 'lesson-uuid-1',
        chapterId: 'chapter-1',
        title: 'Nét chạm bi cơ bản',
        subtitle: 'Hướng dẫn góc chạm bi',
        sections: const [
          LessonSection(
            id: 'sec-1',
            title: 'Lý thuyết',
            order: 1,
            blocks: [
              LessonBlock(id: 'b-1', type: 'text', data: {'content': 'Ví dụ'}),
            ],
          ),
        ],
        status: LessonStatus.ready,
        version: 2,
        createdAt: now,
        updatedAt: now,
      );

      final row = LessonMapper.domainToRow(lesson);
      final restored = LessonMapper.rowToDomain(row);

      expect(restored.id, lesson.id);
      expect(restored.chapterId, lesson.chapterId);
      expect(restored.title, lesson.title);
      expect(restored.subtitle, lesson.subtitle);
      expect(restored.status, lesson.status);
      expect(restored.sections.length, 1);
      expect(restored.sections.first.blocks.first.data['content'], 'Ví dụ');
    });

    test('SceneMapper round-trips domain entity', () {
      final now = DateTime.utc(2026, 9, 22, 10, 0, 0);
      final scene = BilliardScene(
        id: 'scene-uuid-1',
        name: 'Thế bi 3 băng nút số',
        tableConfig: const {'type': 'carom_3c', 'width': 1.42, 'length': 2.84},
        balls: const [
          {'id': 'cue', 'x': 0.2, 'y': 0.5},
        ],
        source: SceneSource.manual,
        status: SceneStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final row = SceneMapper.domainToRow(scene);
      final restored = SceneMapper.rowToDomain(row);

      expect(restored.id, scene.id);
      expect(restored.name, scene.name);
      expect(restored.tableConfig['type'], 'carom_3c');
      expect(restored.balls.length, 1);
      expect(restored.status, SceneStatus.active);
    });
  });

  group('VNextLessonRepository CRUD & Soft Delete', () {
    test(
      'supports insert, getById, update, list, softDelete, restore, purge',
      () async {
        final repo = SqliteLessonRepository(db);
        final now = DateTime.utc(2026, 9, 22);

        final lesson = Lesson(
          id: 'lesson-101',
          title: 'Bài học 1',
          createdAt: now,
          updatedAt: now,
        );

        await repo.save(lesson);

        final fetched = await repo.getById('lesson-101');
        expect(fetched, isNotNull);
        expect(fetched!.title, 'Bài học 1');

        final activeList = await repo.list();
        expect(activeList.length, 1);

        // Soft delete
        await repo.softDelete('lesson-101');
        expect((await repo.getById('lesson-101'))?.isDeleted, isTrue);
        expect((await repo.list()).length, 0);
        expect((await repo.list(includeDeleted: true)).length, 1);

        // Restore
        await repo.restore('lesson-101');
        expect((await repo.list()).length, 1);

        // Purge
        await repo.purge('lesson-101');
        expect(await repo.getById('lesson-101'), isNull);
      },
    );
  });

  group('VNextSceneRepository CRUD & Soft Delete', () {
    test('supports insert, getById, list, softDelete, restore', () async {
      final repo = SqliteSceneRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      final scene = BilliardScene(
        id: 'scene-201',
        name: 'Thế bi mẫu',
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(scene);
      expect(await repo.getById('scene-201'), isNotNull);

      await repo.softDelete('scene-201');
      expect((await repo.list()).length, 0);
      expect((await repo.list(includeDeleted: true)).length, 1);

      await repo.restore('scene-201');
      expect((await repo.list()).length, 1);
    });
  });

  group('VNextTechniqueRepository CRUD', () {
    test('supports save, list, getById, delete', () async {
      final repo = SqliteTechniqueRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      final tech = Technique(
        id: 'tech-1',
        name: 'Cú trô bi (Draw shot)',
        groupName: 'Cơ bản',
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(tech);
      final fetched = await repo.getById('tech-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Cú trô bi (Draw shot)');

      await repo.delete('tech-1');
      expect(await repo.getById('tech-1'), isNull);
    });
  });

  group('VNextNumberSystemRepository CRUD', () {
    test('supports save, list, getById, delete', () async {
      final repo = SqliteNumberSystemRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      final sys = NumberSystem(
        id: 'num-sys-1',
        name: 'Bộ số Băng Dài (50-30-20)',
        expression: 'Target = Origin - ThirdCushion',
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(sys);
      final fetched = await repo.getById('num-sys-1');
      expect(fetched, isNotNull);
      expect(fetched!.expression, 'Target = Origin - ThirdCushion');
    });
  });

  group('VNextExercise, Media, Progress & SimulationProfile CRUD', () {
    test('Exercise, Media, Progress, Profile CRUD operations', () async {
      final exRepo = SqliteExerciseRepository(db);
      final mediaRepo = SqliteMediaRepository(db);
      final progRepo = SqliteLearningProgressRepository(db);
      final profRepo = SqliteSimulationProfileRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      await exRepo.save(
        Exercise(
          id: 'ex-1',
          prompt: 'Đánh trúng 3 băng',
          sceneId: 'scene-201',
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(await exRepo.getById('ex-1'), isNotNull);

      await mediaRepo.save(
        MediaAsset(
          id: 'media-1',
          type: MediaType.image,
          localPath: '/assets/images/shot.png',
          mimeType: 'image/png',
          sizeBytes: 1024,
          checksum: 'abc123hash',
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(await mediaRepo.getById('media-1'), isNotNull);

      await progRepo.saveProgress(
        LearningProgressRecord(
          id: 'prog-1',
          entityId: 'lesson-101',
          category: 'coban',
          isCompleted: true,
          completedAt: now,
        ),
      );
      expect(await progRepo.getByEntityId('lesson-101'), isNotNull);

      await profRepo.save(
        SimulationProfile(
          id: 'prof-1',
          name: 'Standard Carom 3C Table',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(await profRepo.getDefault(), isNotNull);
    });
  });
}
