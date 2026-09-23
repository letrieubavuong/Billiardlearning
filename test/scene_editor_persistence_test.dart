// Phase 4C Persistence Tests for SceneEditorPersistenceCoordinator & SqliteSceneRepository

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_persistence_coordinator.dart';
import 'package:libre2026/data/repositories/vnext_repositories.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/repositories/repositories.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

class FakeFailingSceneRepository implements VNextSceneRepository {
  final Map<String, BilliardScene> _storage = {};
  bool shouldFailSave = false;

  @override
  Future<BilliardScene?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    return _storage[id];
  }

  @override
  Future<List<BilliardScene>> list({bool includeDeleted = false}) async {
    return _storage.values.toList();
  }

  @override
  Future<void> save(BilliardScene scene) async {
    if (shouldFailSave) {
      throw Exception('Simulated Database Write Failure');
    }
    _storage[scene.id] = scene;
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> purge(String id) async {}
}

void main() {
  late FakeFailingSceneRepository fakeRepo;
  late SceneEditorController controller;
  late SceneEditorPersistenceCoordinator coordinator;

  setUp(() {
    fakeRepo = FakeFailingSceneRepository();
    controller = SceneEditorController();
    coordinator = SceneEditorPersistenceCoordinator(
      repository: fakeRepo,
      controller: controller,
      debounceDuration: const Duration(milliseconds: 50),
    );
  });

  tearDown(() {
    coordinator.dispose();
  });

  test('load existing scene -> editor state loaded clean', () async {
    final originalScene = BilliardScene(
      id: 'scene_123',
      name: 'Test Scene',
      tableConfig: const TableConfig(),
      balls: [
        BallPosition(
          id: 'ball_w',
          ballType: 'white',
          position: const TablePoint(0.25, 0.5),
        ),
      ],
      trajectories: const [],
      annotations: const [],
      cueInstruction: null,
      presentationConfig: const ScenePresentationConfig(),
      source: SceneSource.manual,
      status: SceneStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    await fakeRepo.save(originalScene);
    final loaded = await coordinator.loadScene('scene_123');

    expect(loaded.id, equals('scene_123'));
    expect(controller.currentScene.id, equals('scene_123'));
    expect(controller.state.isDirty, isFalse);
    expect(controller.state.canUndo, isFalse);
    expect(controller.state.canRedo, isFalse);
  });

  test(
    'load missing scene -> throws explicit StateError without fallback',
    () async {
      expect(
        () => coordinator.loadScene('non_existent_id'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('edit scene -> manual save succeeds -> becomes clean', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    expect(controller.state.isDirty, isTrue);
    final sceneId = controller.currentScene.id;

    await coordinator.save();

    expect(controller.state.isDirty, isFalse);
    final savedInRepo = await fakeRepo.getById(sceneId);
    expect(savedInRepo, isNotNull);
    expect(savedInRepo!.id, equals(sceneId));
  });

  test(
    'edit scene -> manual save fails -> remains dirty and surfaces error',
    () async {
      controller.addBall(
        ballType: 'yellow',
        position: const TablePoint(0.3, 0.3),
      );
      expect(controller.state.isDirty, isTrue);

      fakeRepo.shouldFailSave = true;

      expect(() => coordinator.save(), throwsA(isA<Exception>()));

      expect(controller.state.isDirty, isTrue);
    },
  );

  test(
    'save -> new edit -> dirty -> undo back to saved baseline -> clean',
    () async {
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.5, 0.5),
      );
      await coordinator.save();
      expect(controller.state.isDirty, isFalse);

      // New edit
      controller.addBall(ballType: 'red', position: const TablePoint(0.7, 0.7));
      expect(controller.state.isDirty, isTrue);

      // Undo back to saved baseline
      controller.undo();
      expect(controller.state.isDirty, isFalse);
    },
  );

  test('new scene retains same stable ID across multiple saves', () async {
    final initialId = controller.currentScene.id;

    controller.addBall(ballType: 'white', position: const TablePoint(0.2, 0.2));
    await coordinator.save();
    expect(controller.currentScene.id, equals(initialId));

    controller.addBall(
      ballType: 'yellow',
      position: const TablePoint(0.4, 0.4),
    );
    await coordinator.save();
    expect(controller.currentScene.id, equals(initialId));
  });

  group('SQLite FFI Integration Tests', () {
    late Database db;
    late SqliteSceneRepository sqliteRepo;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE vnext_scenes (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              table_config_json TEXT NOT NULL,
              balls_json TEXT NOT NULL,
              trajectories_json TEXT NOT NULL,
              annotations_json TEXT NOT NULL,
              cue_instruction_json TEXT,
              teaching_timeline_json TEXT,
              source TEXT NOT NULL,
              status TEXT NOT NULL,
              version INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
        },
      );
      sqliteRepo = SqliteSceneRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('SQLite repository save -> reload -> semantic parity', () async {
      final sceneId = StableId.generate();
      final scene = BilliardScene(
        id: sceneId,
        name: 'SQLite Test Scene',
        tableConfig: const TableConfig(
          type: 'carom_3c',
          widthMeters: 1.42,
          lengthMeters: 2.84,
        ),
        balls: [
          BallPosition(
            id: 'b1',
            ballType: 'white',
            position: const TablePoint(0.25, 0.5),
          ),
          BallPosition(
            id: 'b2',
            ballType: 'yellow',
            position: const TablePoint(0.5, 0.5),
          ),
        ],
        trajectories: [
          TrajectoryLine(
            id: 't1',
            colorHex: '#FFFFFF',
            points: const [TablePoint(0.25, 0.5), TablePoint(0.5, 0.5)],
          ),
        ],
        annotations: [
          SceneAnnotation(
            id: 'a1',
            text: 'Target',
            position: const TablePoint(0.5, 0.5),
            colorHex: '#FFFF00',
          ),
        ],
        cueInstruction: const CueInstruction(
          power: 0.5,
          direction: Angle.fromRadians(1.0),
        ),
        presentationConfig: const ScenePresentationConfig(
          legacySystemIndex: 1,
          legacyViewTypeIndex: 0,
        ),
        source: SceneSource.manual,
        status: SceneStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      await sqliteRepo.save(scene);

      final reloaded = await sqliteRepo.getById(sceneId);
      expect(reloaded, isNotNull);
      expect(reloaded!.id, equals(scene.id));
      expect(reloaded.name, equals(scene.name));
      expect(reloaded.balls.length, equals(2));
      expect(
        reloaded.balls.first.position,
        equals(const TablePoint(0.25, 0.5)),
      );
      expect(reloaded.trajectories.length, equals(1));
      expect(reloaded.annotations.length, equals(1));
      expect(reloaded.presentationConfig?.legacySystemIndex, equals(1));
    });
  });
}
