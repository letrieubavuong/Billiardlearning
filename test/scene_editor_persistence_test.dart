// Phase 4C Persistence Tests for SceneEditorPersistenceCoordinator & SqliteSceneRepository

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_persistence_coordinator.dart';
import 'package:libre2026/data/repositories/vnext_repositories.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/repositories/repositories.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

class ControllableFailingSceneRepository implements VNextSceneRepository {
  final Map<String, BilliardScene> storage = {};
  Completer<void>? saveCompleter;
  bool shouldFailSave = false;

  @override
  Future<BilliardScene?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    return storage[id];
  }

  @override
  Future<List<BilliardScene>> list({bool includeDeleted = false}) async {
    return storage.values.toList();
  }

  @override
  Future<void> save(BilliardScene scene) async {
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    if (shouldFailSave) {
      throw Exception('Simulated Database Write Failure');
    }
    storage[scene.id] = scene;
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> purge(String id) async {}
}

void main() {
  late ControllableFailingSceneRepository repo;
  late SceneEditorController controller;
  late SceneEditorPersistenceCoordinator coordinator;

  setUp(() {
    repo = ControllableFailingSceneRepository();
    controller = SceneEditorController();
    coordinator = SceneEditorPersistenceCoordinator(
      repository: repo,
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
      presentationConfig: ScenePresentationConfig(),
      source: SceneSource.manual,
      status: SceneStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    await repo.save(originalScene);
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
    final savedInRepo = await repo.getById(sceneId);
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

      repo.shouldFailSave = true;

      await expectLater(coordinator.save(), throwsA(isA<Exception>()));

      expect(controller.state.isDirty, isTrue);
      expect(coordinator.lastError, isNotNull);
    },
  );

  test(
    'manual save race test: edit C while save B is blocked -> isDirty remains TRUE after B completes',
    () async {
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.2, 0.2),
      );
      // Baseline is empty scene. Current state is edit B.
      repo.saveCompleter = Completer<void>();

      // Call save for edit B (now blocked in repository)
      final saveFuture = coordinator.save();

      // While blocked, user performs edit C
      controller.addBall(
        ballType: 'yellow',
        position: const TablePoint(0.4, 0.4),
      );
      expect(controller.state.isDirty, isTrue);

      // Unblock save for B
      repo.saveCompleter!.complete();
      repo.saveCompleter = null;
      await saveFuture;

      // Persisted baseline is B. Current controller scene is C.
      // controller MUST remain dirty!
      expect(controller.state.isDirty, isTrue);

      // Now save C
      await coordinator.save();
      expect(controller.state.isDirty, isFalse);
      expect(repo.storage[controller.currentScene.id]?.balls.length, equals(2));
    },
  );

  test('true load-during-in-flight save session safety', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.2, 0.2));

    repo.saveCompleter = Completer<void>();
    final oldSaveFuture = coordinator.save();

    // Save of old scene A is now in flight and blocked in repository
    expect(repo.saveCompleter, isNotNull);

    // Prepare scene X in repository
    final sceneX = BilliardScene(
      id: 'scene_X',
      name: 'Scene X',
      tableConfig: const TableConfig(),
      balls: const [],
      trajectories: const [],
      annotations: const [],
      cueInstruction: null,
      presentationConfig: ScenePresentationConfig(),
      source: SceneSource.manual,
      status: SceneStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    repo.storage['scene_X'] = sceneX;

    // NOW call loadScene('scene_X') WHILE save A is STILL in flight
    await coordinator.loadScene('scene_X');
    expect(controller.currentScene.id, equals('scene_X'));
    expect(controller.state.isDirty, isFalse);

    // User makes edit Y on scene X
    controller.addBall(ballType: 'red', position: const TablePoint(0.8, 0.8));
    expect(controller.state.isDirty, isTrue);

    // NOW unblock the old save A
    repo.saveCompleter!.complete();
    repo.saveCompleter = null;
    await oldSaveFuture;

    // Verify after old save completion:
    // 1. Current scene remains X
    // 2. Current edit Y on scene X remains DIRTY (not falsely marked clean by old save completion)
    expect(controller.currentScene.id, equals('scene_X'));
    expect(controller.state.isDirty, isTrue);

    // Now save Y and verify repository persisted Y
    await coordinator.save();
    expect(controller.state.isDirty, isFalse);
    expect(repo.storage['scene_X']?.balls.length, equals(1));
  });

  test(
    'same-ID session reload while save in-flight retains dirty state of new session',
    () async {
      final originalScene = controller.currentScene;
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.1, 0.1),
      );
      expect(controller.state.isDirty, isTrue);

      // Store baseline in repo
      repo.storage[originalScene.id] = originalScene;

      repo.saveCompleter = Completer<void>();
      final oldSaveFuture = coordinator.save(); // Save of snapshot A1 in flight

      // Reload the SAME scene ID into coordinator (simulates reloading clean baseline A0)
      await coordinator.loadScene(originalScene.id);
      expect(controller.state.isDirty, isFalse);

      // Make new edit A2 on fresh session
      controller.addBall(
        ballType: 'yellow',
        position: const TablePoint(0.9, 0.9),
      );
      expect(controller.state.isDirty, isTrue);

      // Complete old save A1
      repo.saveCompleter!.complete();
      repo.saveCompleter = null;
      await oldSaveFuture;

      // Old completion MUST NOT mark new session A2 clean or replace baseline
      expect(controller.state.isDirty, isTrue);
      expect(controller.currentScene.balls.length, equals(1));
      expect(controller.currentScene.balls.first.ballType, equals('yellow'));
    },
  );

  group('SQLite FFI Rich Integration Tests', () {
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

    test(
      'SQLite repository rich semantic round trip: all domain fields survive database persistence',
      () async {
        final sceneId = StableId.generate();
        final scene = BilliardScene(
          id: sceneId,
          name: 'SQLite Rich Test Scene',
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
              label: 'W',
              colorHex: '#FFFFFF',
              rotation: 45.0,
              legacyType: 0,
            ),
            BallPosition(
              id: 'b2',
              ballType: 'ghost',
              position: const TablePoint(0.5, 0.5),
              label: 'G1',
              colorHex: '#80FFFFFF',
              rotation: 30.0,
              legacyType: 1,
            ),
          ],
          trajectories: [
            TrajectoryLine(
              id: 't1',
              colorHex: '#FF0000',
              points: const [
                TablePoint(0.25, 0.5),
                TablePoint(0.5, 0.5),
                TablePoint(0.75, 0.5),
              ],
            ),
          ],
          annotations: [
            SceneAnnotation(
              id: 'a1',
              text: 'Target 50',
              position: const TablePoint(0.5, 0.5),
              colorHex: '#FFFF00',
              rotation: 90.0,
              role: 'cushionNumber',
              cushionSide: 'left',
            ),
          ],
          cueInstruction: const CueInstruction(
            power: 0.75,
            direction: Angle.fromRadians(1.5),
            tipOffset: Vec2(0.2, -0.3),
            powerIsResolved: true,
          ),
          presentationConfig: ScenePresentationConfig(
            legacySystemIndex: 1,
            legacyViewTypeIndex: 2,
            labelFontSize: 14.0,
            rawEffetData: const {
              'spots': [
                {'x': 0.2, 'y': -0.3, 'number': '1', 'color': 4294967295},
              ],
              'showHitBall': true,
              'hitThickness': 4,
              'hitSide': 'left',
              'spotSize': 30.0,
            },
            legacyPathColors: const {
              'white': '#B3FFFFFF',
              'yellow': '#FFFFEB3B',
              'red': '#FFF44336',
              'free': '#FF2196F3',
            },
          ),
          teachingTimeline: const {
            'steps': [
              {'index': 1, 'text': 'Intro step', 'duration': 2.0},
            ],
          },
          source: SceneSource.importSource,
          status: SceneStatus.active,
          version: 2,
          createdAt: DateTime.utc(2026, 1, 15, 10, 0, 0),
          updatedAt: DateTime.utc(2026, 1, 15, 11, 0, 0),
        );

        await sqliteRepo.save(scene);

        final reloaded = await sqliteRepo.getById(sceneId);
        expect(reloaded, isNotNull);
        expect(reloaded!.id, equals(scene.id));
        expect(reloaded.name, equals(scene.name));
        expect(reloaded.version, equals(2));
        expect(reloaded.source, equals(SceneSource.importSource));
        expect(reloaded.status, equals(SceneStatus.active));
        expect(reloaded.createdAt, equals(DateTime.utc(2026, 1, 15, 10, 0, 0)));
        expect(reloaded.updatedAt, equals(DateTime.utc(2026, 1, 15, 11, 0, 0)));

        // Balls
        expect(reloaded.balls.length, equals(2));
        expect(reloaded.balls[0].label, equals('W'));
        expect(reloaded.balls[0].colorHex, equals('#FFFFFF'));
        expect(reloaded.balls[0].rotation, equals(45.0));
        expect(reloaded.balls[0].legacyType, equals(0));
        expect(reloaded.balls[1].ballType, equals('ghost'));
        expect(reloaded.balls[1].label, equals('G1'));
        expect(reloaded.balls[1].colorHex, equals('#80FFFFFF'));
        expect(reloaded.balls[1].rotation, equals(30.0));
        expect(reloaded.balls[1].legacyType, equals(1));

        // Trajectories
        expect(reloaded.trajectories.length, equals(1));
        expect(reloaded.trajectories[0].id, equals('t1'));
        expect(reloaded.trajectories[0].colorHex, equals('#FF0000'));
        expect(reloaded.trajectories[0].points.length, equals(3));
        expect(
          reloaded.trajectories[0].points[0],
          equals(const TablePoint(0.25, 0.5)),
        );
        expect(
          reloaded.trajectories[0].points[1],
          equals(const TablePoint(0.5, 0.5)),
        );
        expect(
          reloaded.trajectories[0].points[2],
          equals(const TablePoint(0.75, 0.5)),
        );

        // Annotations
        expect(reloaded.annotations.length, equals(1));
        expect(reloaded.annotations[0].id, equals('a1'));
        expect(reloaded.annotations[0].text, equals('Target 50'));
        expect(reloaded.annotations[0].colorHex, equals('#FFFF00'));
        expect(reloaded.annotations[0].rotation, equals(90.0));
        expect(reloaded.annotations[0].role, equals('cushionNumber'));
        expect(reloaded.annotations[0].cushionSide, equals('left'));

        // Cue Instruction
        expect(reloaded.cueInstruction, isNotNull);
        expect(reloaded.cueInstruction!.power, equals(0.75));
        expect(
          reloaded.cueInstruction!.direction.radians,
          closeTo(1.5, 0.0001),
        );
        expect(reloaded.cueInstruction!.tipOffset.x, equals(0.2));
        expect(reloaded.cueInstruction!.tipOffset.y, equals(-0.3));
        expect(reloaded.cueInstruction!.powerIsResolved, isTrue);

        // Presentation Config & Raw Effet Data
        expect(reloaded.presentationConfig, isNotNull);
        expect(reloaded.presentationConfig!.legacySystemIndex, equals(1));
        expect(reloaded.presentationConfig!.legacyViewTypeIndex, equals(2));
        expect(reloaded.presentationConfig!.labelFontSize, equals(14.0));
        expect(reloaded.presentationConfig!.rawEffetData, isNotNull);
        expect(
          reloaded.presentationConfig!.rawEffetData!['showHitBall'],
          isTrue,
        );
        expect(
          reloaded.presentationConfig!.rawEffetData!['hitThickness'],
          equals(4),
        );
        expect(
          reloaded.presentationConfig!.rawEffetData!['hitSide'],
          equals('left'),
        );
        expect(
          reloaded.presentationConfig!.rawEffetData!['spotSize'],
          equals(30.0),
        );
        expect(
          reloaded.presentationConfig!.rawEffetData!['spots'],
          isA<List>(),
        );
        final spotsList =
            reloaded.presentationConfig!.rawEffetData!['spots'] as List;
        expect(spotsList.length, equals(1));
        expect(spotsList[0]['number'], equals('1'));
        expect(spotsList[0]['color'], equals(4294967295));

        expect(reloaded.presentationConfig!.legacyPathColors, isNotNull);
        expect(
          reloaded.presentationConfig!.legacyPathColors!['white'],
          equals('#B3FFFFFF'),
        );
        expect(
          reloaded.presentationConfig!.legacyPathColors!['yellow'],
          equals('#FFFFEB3B'),
        );
        expect(
          reloaded.presentationConfig!.legacyPathColors!['red'],
          equals('#FFF44336'),
        );
        expect(
          reloaded.presentationConfig!.legacyPathColors!['free'],
          equals('#FF2196F3'),
        );

        // Teaching Timeline preservation
        expect(reloaded.teachingTimeline, isNotNull);
        final stepsList = reloaded.teachingTimeline!['steps'] as List;
        expect(stepsList.length, equals(1));
        expect(stepsList[0]['index'], equals(1));
        expect(stepsList[0]['text'], equals('Intro step'));
        expect(stepsList[0]['duration'], equals(2.0));
      },
    );
  });
}
