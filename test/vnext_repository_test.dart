import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
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

  group('vNext Schema & Index Verification', () {
    test('creates all 8 vNext tables', () async {
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

    test('verifies all required vNext indexes exist in sqlite_master', () async {
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'index_vnext_%'",
      );
      final indexNames = indexes.map((i) => i['name'] as String).toSet();

      expect(
        indexNames,
        containsAll([
          'index_vnext_lessons_status_deleted',
          'index_vnext_scenes_status_deleted',
          'index_vnext_techniques_group',
          'index_vnext_exercises_scene',
          'index_vnext_progress_entity_unique',
        ]),
      );
    });
  });

  group('Mappers Round-Trip Tests', () {
    test('LessonMapper round-trips domain entity with type-safe blocks', () {
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
              TextBlock(id: 'b-1', text: 'Ví dụ văn bản'),
              SceneReferenceBlock(
                id: 'b-2',
                sceneId: 'scene-123',
                caption: 'Hình minh họa thế bi',
              ),
            ],
          ),
        ],
        status: LessonStatus.published,
        version: 2,
        createdAt: now,
        updatedAt: now,
      );

      final row = LessonMapper.domainToRow(lesson);
      final restored = LessonMapper.rowToDomain(row);

      expect(restored.id, lesson.id);
      expect(restored.chapterId, lesson.chapterId);
      expect(restored.title, lesson.title);
      expect(restored.status, LessonStatus.published);
      expect(restored.sections.length, 1);

      final firstBlock = restored.sections.first.blocks[0];
      expect(firstBlock, isA<TextBlock>());
      expect((firstBlock as TextBlock).text, 'Ví dụ văn bản');

      final secondBlock = restored.sections.first.blocks[1];
      expect(secondBlock, isA<SceneReferenceBlock>());
      expect((secondBlock as SceneReferenceBlock).sceneId, 'scene-123');
    });

    test('SceneMapper round-trips typed BilliardScene entity', () {
      final now = DateTime.utc(2026, 9, 22, 10, 0, 0);
      final scene = BilliardScene(
        id: 'scene-uuid-1',
        name: 'Thế bi 3 băng nút số',
        tableConfig: const TableConfig(
          type: 'carom_3c',
          widthMeters: 1.42,
          lengthMeters: 2.84,
        ),
        balls: const [
          BallPosition(
            id: 'cue',
            ballType: 'white',
            position: TablePoint(0.2, 0.5),
          ),
        ],
        trajectories: const [
          TrajectoryLine(
            id: 'traj-1',
            colorHex: '#FF0000',
            points: [TablePoint(0.2, 0.5), TablePoint(0.8, 0.5)],
          ),
        ],
        annotations: const [
          SceneAnnotation(
            id: 'ann-1',
            text: 'Chạm mỏng 1/4 bi',
            position: TablePoint(0.5, 0.5),
          ),
        ],
        cueInstruction: CueInstruction(
          power: 75.0,
          direction: Angle.fromDegrees(45.0),
          tipOffset: const Vec2(0.1, -0.2),
        ),
        source: SceneSource.manual,
        status: SceneStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final row = SceneMapper.domainToRow(scene);
      final restored = SceneMapper.rowToDomain(row);

      expect(restored.id, scene.id);
      expect(restored.name, scene.name);
      expect(restored.tableConfig.type, 'carom_3c');
      expect(restored.balls.length, 1);
      expect(restored.balls.first.position, const TablePoint(0.2, 0.5));
      expect(restored.trajectories.first.colorHex, '#FF0000');
      expect(restored.cueInstruction!.power, 75.0);
    });
  });

  group('VNextLessonRepository Soft Delete Contract & Status Preservation', () {
    test(
      'getById defaults to null for deleted items, includeDeleted retrieves them while preserving status',
      () async {
        final repo = SqliteLessonRepository(db);
        final now = DateTime.utc(2026, 9, 22);

        final lesson = Lesson(
          id: 'lesson-101',
          title: 'Bài học 1',
          status: LessonStatus.published,
          createdAt: now,
          updatedAt: now,
        );

        await repo.save(lesson);

        // Verify active read
        final active = await repo.getById('lesson-101');
        expect(active, isNotNull);
        expect(active!.status, LessonStatus.published);

        // Soft delete
        await repo.softDelete('lesson-101');

        // Default getById returns NULL for deleted item
        final deletedDefault = await repo.getById('lesson-101');
        expect(deletedDefault, isNull);

        // getById with includeDeleted retrieves it and retains original PUBLISHED status
        final deletedExplicit = await repo.getById(
          'lesson-101',
          includeDeleted: true,
        );
        expect(deletedExplicit, isNotNull);
        expect(deletedExplicit!.isDeleted, isTrue);
        expect(
          deletedExplicit.status,
          LessonStatus.published,
          reason: 'Status PUBLISHED must be preserved across soft delete',
        );

        // Restore
        await repo.restore('lesson-101');
        final restored = await repo.getById('lesson-101');
        expect(restored, isNotNull);
        expect(restored!.isDeleted, isFalse);
        expect(
          restored.status,
          LessonStatus.published,
          reason: 'Status PUBLISHED must remain intact after restore',
        );
      },
    );

    test('supports real update CRUD operation', () async {
      final repo = SqliteLessonRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      final lesson = Lesson(
        id: 'lesson-202',
        title: 'Tiêu đề ban đầu',
        status: LessonStatus.draft,
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(lesson);

      final updatedLesson = lesson.copyWith(
        title: 'Tiêu đề đã chỉnh sửa',
        status: LessonStatus.published,
        updatedAt: DateTime.utc(2026, 9, 23),
      );

      await repo.save(updatedLesson);

      final fetched = await repo.getById('lesson-202');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Tiêu đề đã chỉnh sửa');
      expect(fetched.status, LessonStatus.published);
    });
  });

  group('VNextSceneRepository CRUD & Soft Delete', () {
    test(
      'soft delete preserves status and getById supports includeDeleted',
      () async {
        final repo = SqliteSceneRepository(db);
        final now = DateTime.utc(2026, 9, 22);

        final scene = BilliardScene(
          id: 'scene-201',
          name: 'Thế bi mẫu',
          status: SceneStatus.active,
          createdAt: now,
          updatedAt: now,
        );

        await repo.save(scene);
        await repo.softDelete('scene-201');

        expect(await repo.getById('scene-201'), isNull);

        final deletedScene = await repo.getById(
          'scene-201',
          includeDeleted: true,
        );
        expect(deletedScene, isNotNull);
        expect(deletedScene!.status, SceneStatus.active);

        await repo.restore('scene-201');
        final restoredScene = await repo.getById('scene-201');
        expect(restoredScene, isNotNull);
        expect(restoredScene!.name, 'Thế bi mẫu');
      },
    );

    test('supports real update CRUD operation', () async {
      final repo = SqliteSceneRepository(db);
      final now = DateTime.utc(2026, 9, 22);

      final scene = BilliardScene(
        id: 'scene-303',
        name: 'Tên ban đầu',
        createdAt: now,
        updatedAt: now,
      );

      await repo.save(scene);

      final updatedScene = scene.copyWith(name: 'Tên mới đã sửa');
      await repo.save(updatedScene);

      final fetched = await repo.getById('scene-303');
      expect(fetched!.name, 'Tên mới đã sửa');
    });
  });

  group('All vNext Repositories Real Update CRUD Operations', () {
    test(
      'Technique, NumberSystem, Exercise, Media, Progress & Profile update CRUD',
      () async {
        final techRepo = SqliteTechniqueRepository(db);
        final numRepo = SqliteNumberSystemRepository(db);
        final exRepo = SqliteExerciseRepository(db);
        final mediaRepo = SqliteMediaRepository(db);
        final progRepo = SqliteLearningProgressRepository(db);
        final profRepo = SqliteSimulationProfileRepository(db);
        final now = DateTime.utc(2026, 9, 22);

        // Technique Update
        await techRepo.save(
          Technique(
            id: 't-1',
            name: 'Cú trô bi',
            groupName: 'Cơ bản',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await techRepo.save(
          Technique(
            id: 't-1',
            name: 'Cú trô bi nâng cao',
            groupName: 'Nâng cao',
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect((await techRepo.getById('t-1'))!.name, 'Cú trô bi nâng cao');

        // NumberSystem Update
        await numRepo.save(
          NumberSystem(
            id: 'ns-1',
            name: 'Bộ 50-30',
            expression: 'T = A - B',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await numRepo.save(
          NumberSystem(
            id: 'ns-1',
            name: 'Bộ 50-30 Hiệu chỉnh',
            expression: 'T = A - B + C',
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect((await numRepo.getById('ns-1'))!.expression, 'T = A - B + C');

        // Exercise Update
        await exRepo.save(
          Exercise(
            id: 'ex-1',
            prompt: 'Đánh trúng bi',
            sceneId: 'sc-1',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await exRepo.save(
          Exercise(
            id: 'ex-1',
            prompt: 'Đánh trúng 3 băng',
            sceneId: 'sc-1',
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect((await exRepo.getById('ex-1'))!.prompt, 'Đánh trúng 3 băng');

        // Media Asset Update
        await mediaRepo.save(
          MediaAsset(
            id: 'm-1',
            type: MediaType.image,
            localPath: '/img/1.png',
            mimeType: 'image/png',
            sizeBytes: 100,
            checksum: 'hash1',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await mediaRepo.save(
          MediaAsset(
            id: 'm-1',
            type: MediaType.image,
            localPath: '/img/1_updated.png',
            mimeType: 'image/png',
            sizeBytes: 200,
            checksum: 'hash2',
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect(
          (await mediaRepo.getById('m-1'))!.localPath,
          '/img/1_updated.png',
        );

        // Learning Progress Uniqueness & Update
        await progRepo.saveProgress(
          LearningProgressRecord(
            id: 'pr-1',
            entityId: 'entity-99',
            category: 'coban',
            isCompleted: false,
          ),
        );
        await progRepo.saveProgress(
          LearningProgressRecord(
            id: 'pr-1',
            entityId: 'entity-99',
            category: 'coban',
            isCompleted: true,
            completedAt: now,
          ),
        );
        final progressList = await progRepo.listAll();
        expect(
          progressList.length,
          1,
          reason:
              'Duplicate progress entries for entity_id must be prevented by UNIQUE constraint',
        );
        expect(progressList.first.isCompleted, isTrue);

        // Simulation Profile Update
        await profRepo.save(
          SimulationProfile(
            id: 'sp-1',
            name: 'Table 1',
            isDefault: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await profRepo.save(
          SimulationProfile(
            id: 'sp-1',
            name: 'Table Standard',
            isDefault: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect((await profRepo.getDefault())!.name, 'Table Standard');
      },
    );
  });
}
