import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/data/mappers/mappers.dart';
import 'package:libre2026/data/models/sqlite_models.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/importers/legacy_scene_importer.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('LegacySceneImporter (Phase 2 Real Legacy Fixes & Hardening)', () {
    test('imports real legacy diagram JSON payload with full fidelity', () {
      const rawJson = '''
      {
        "schemaVersion": 1,
        "system": 1,
        "viewType": 2,
        "labelFontSize": 16.0,
        "white": [2.0, 6.0],
        "yellow": [1.0, 4.0],
        "red": [3.0, 2.0],
        "extraBalls": [
          {
            "x": 1.5,
            "y": 3.0,
            "color": 4280391411,
            "number": "7"
          }
        ],
        "ghosts": [
          {
            "x": 2.0,
            "y": 4.0,
            "color": 4294967295,
            "type": 0,
            "rotation": 20.0,
            "number": "1"
          }
        ],
        "paths": {
          "white": [[1.0, 4.0], [0.0, 2.0]],
          "yellow": [],
          "red": [],
          "free": [
            [[0.0, 0.0], [4.0, 8.0]]
          ]
        },
        "pathColors": {
          "white": 4294967295,
          "yellow": 4294967040,
          "red": 4294198070,
          "free": 4280391411
        },
        "freePathColors": [
          4278190080
        ],
        "labels": [
          {
            "x": 2.0,
            "y": 6.0,
            "text": "Bi chủ chạm 1/2 bi",
            "color": 4294967295,
            "rotation": 15.0,
            "role": "cueBall"
          }
        ],
        "cushionNumbers": [
          {
            "x": 0.0,
            "y": 4.0,
            "text": "50",
            "color": 4294967295,
            "rotation": 0.0,
            "cushionSide": "left"
          }
        ],
        "effet": {
          "thickness": 0.5,
          "effet": [0.0, 0.5],
          "forceImage": "assets/images/Luc 2.png",
          "cueAngle": 15.0
        }
      }
      ''';

      final jsonMap = jsonDecode(rawJson) as Map<String, dynamic>;
      final result = LegacySceneImporter.importJsonMap(
        jsonMap,
        sceneName: 'Bài học 3 băng nút số 50',
      );

      final scene = result.scene;
      expect(scene.name, equals('Bài học 3 băng nút số 50'));
      expect(scene.source, equals(SceneSource.importSource));

      // UUID v4 check
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      expect(uuidRegex.hasMatch(scene.id), isTrue);

      // Verify ball positions
      expect(scene.balls.length, equals(5));

      final whiteBall = scene.balls.firstWhere((b) => b.ballType == 'white');
      expect(whiteBall.position, equals(const TablePoint(0.5, 0.75)));

      final yellowBall = scene.balls.firstWhere((b) => b.ballType == 'yellow');
      expect(yellowBall.position, equals(const TablePoint(0.25, 0.5)));

      final redBall = scene.balls.firstWhere((b) => b.ballType == 'red');
      expect(redBall.position, equals(const TablePoint(0.75, 0.25)));

      // Extra ball Map assertions
      final extraBall = scene.balls.firstWhere((b) => b.ballType == 'extra');
      expect(extraBall.position, equals(const TablePoint(0.375, 0.375)));
      expect(extraBall.label, equals('7'));
      expect(extraBall.colorHex, equals('#FF2196F3'));

      // Ghost Map assertions
      final ghostBall = scene.balls.firstWhere((b) => b.ballType == 'ghost');
      expect(ghostBall.position, equals(const TablePoint(0.5, 0.5)));
      expect(ghostBall.label, equals('1'));
      expect(ghostBall.colorHex, equals('#FFFFFFFF'));
      expect(ghostBall.rotation, equals(20.0));
      expect(ghostBall.legacyType, equals(0));

      // Trajectory start point fix assertions
      expect(scene.trajectories.length, equals(2));
      final whiteTraj = scene.trajectories.firstWhere(
        (t) => t.id == 'traj_white',
      );
      // Prepended white ball position (0.5, 0.75) + waypoints
      expect(
        whiteTraj.points,
        equals(const [
          TablePoint(0.5, 0.75),
          TablePoint(0.25, 0.5),
          TablePoint(0.0, 0.25),
        ]),
      );
      expect(whiteTraj.colorHex, equals('#FFFFFFFF'));

      final freeTraj = scene.trajectories.firstWhere(
        (t) => t.id == 'traj_free_0',
      );
      // Free trajectory must NOT have prepended ball position
      expect(
        freeTraj.points,
        equals(const [TablePoint(0.0, 0.0), TablePoint(1.0, 1.0)]),
      );
      expect(freeTraj.colorHex, equals('#FF000000')); // 4278190080 -> #FF000000

      // Annotations metadata assertions
      expect(scene.annotations.length, equals(2));
      final labelAnno = scene.annotations.firstWhere((a) => a.id == 'label_0');
      expect(labelAnno.text, equals('Bi chủ chạm 1/2 bi'));
      expect(labelAnno.position, equals(const TablePoint(0.5, 0.75)));
      expect(labelAnno.colorHex, equals('#FFFFFFFF'));
      expect(labelAnno.rotation, equals(15.0));
      expect(labelAnno.role, equals('cueBall'));

      final cushionAnno = scene.annotations.firstWhere(
        (a) => a.id == 'cushion_0',
      );
      expect(cushionAnno.text, equals('50'));
      expect(cushionAnno.position, equals(const TablePoint(0.0, 0.5)));
      expect(cushionAnno.colorHex, equals('#FFFFFFFF'));
      expect(cushionAnno.rotation, equals(0.0));
      expect(cushionAnno.role, equals('cushionNumber'));
      expect(cushionAnno.cushionSide, equals('left'));

      // Presentation config assertions
      expect(scene.presentationConfig, isNotNull);
      expect(scene.presentationConfig!.legacySystemIndex, equals(1));
      expect(scene.presentationConfig!.legacyViewTypeIndex, equals(2));
      expect(scene.presentationConfig!.labelFontSize, equals(16.0));
      expect(scene.teachingTimeline, isNull);

      // Cue instruction & unresolved power assertions
      expect(scene.cueInstruction, isNotNull);
      expect(scene.cueInstruction!.tipOffset, equals(const Vec2(0.0, 0.5)));
      expect(scene.cueInstruction!.power, equals(0.0));
      expect(scene.cueInstruction!.powerIsResolved, isFalse);

      // Deferred warnings assertions
      expect(result.hasWarnings, isTrue);
      final warningCodes = result.warnings.map((w) => w.code).toList();
      expect(warningCodes, contains('DEFERRED_FIELD_FORCE_IMAGE'));
      expect(warningCodes, contains('DEFERRED_FIELD_CUE_ANGLE'));
      expect(warningCodes, contains('DEFERRED_FIELD_THICKNESS'));
    });

    test('validates unknown legacy enum indices without crashing', () {
      final jsonMap = <String, dynamic>{'system': 99, 'viewType': 99};

      final result = LegacySceneImporter.importJsonMap(jsonMap);

      expect(result.scene.presentationConfig, isNotNull);
      expect(result.scene.presentationConfig!.legacySystemIndex, equals(99));
      expect(result.scene.presentationConfig!.legacyViewTypeIndex, equals(99));

      final warningCodes = result.warnings.map((w) => w.code).toList();
      expect(warningCodes, contains('UNKNOWN_LEGACY_SYSTEM_INDEX'));
      expect(warningCodes, contains('UNKNOWN_LEGACY_VIEW_TYPE_INDEX'));
    });

    test('handles malformed payload shapes with clear diagnostics', () {
      final jsonMap = <String, dynamic>{
        'white': 'bad_string',
        'extraBalls': [123],
        'ghosts': [
          {'x': 'invalid_x', 'y': 4.0},
        ],
        'paths': 'bad_paths',
        'labels': [
          {'text': 'no_coords'},
        ],
      };

      final result = LegacySceneImporter.importJsonMap(jsonMap);

      expect(result.scene.balls, isEmpty);
      expect(result.scene.trajectories, isEmpty);
      expect(result.scene.annotations, isEmpty);
      expect(result.hasWarnings, isTrue);

      final warningCodes = result.warnings.map((w) => w.code).toList();
      expect(warningCodes, contains('INVALID_POINT_SHAPE'));
      expect(warningCodes, contains('INVALID_LEGACY_BALL'));
      expect(warningCodes, contains('INVALID_FIELD_TYPE'));
      expect(warningCodes, contains('MISSING_REQUIRED_COORDINATE'));
    });

    test(
      'handles malformed metadata fields gracefully without dropping valid positional data',
      () {
        final jsonMap = <String, dynamic>{
          'schemaVersion': 'bad_version',
          'system': 'bad_system',
          'viewType': 'bad_viewtype',
          'labelFontSize': 'large',
          'white': [2.0, 4.0],
          'ghosts': [
            {
              'x': 2.0,
              'y': 4.0,
              'rotation': 'bad_rotation',
              'type': 'bad_type',
              'color': 4294967295,
              'number': '1',
            },
          ],
          'labels': [
            {'x': 1.0, 'y': 2.0, 'text': 'A', 'rotation': 'bad_rotation'},
          ],
          'pathColors': 'bad_path_colors',
          'freePathColors': 'bad_free_path_colors',
          'effet': 'bad_effet',
        };

        final result = LegacySceneImporter.importJsonMap(jsonMap);

        // Positional objects white & ghost are imported
        expect(result.scene.balls.length, equals(2));
        final ghost = result.scene.balls.firstWhere(
          (b) => b.ballType == 'ghost',
        );
        expect(ghost.position, equals(const TablePoint(0.5, 0.5)));
        expect(ghost.rotation, isNull);
        expect(ghost.legacyType, isNull);
        expect(ghost.label, equals('1'));

        // Annotation text + position is imported
        expect(result.scene.annotations.length, equals(1));
        final labelAnno = result.scene.annotations.first;
        expect(labelAnno.text, equals('A'));
        expect(labelAnno.position, equals(const TablePoint(0.25, 0.25)));
        expect(labelAnno.rotation, isNull);

        final warningCodes = result.warnings.map((w) => w.code).toList();
        expect(warningCodes, contains('INVALID_FIELD_TYPE'));
      },
    );

    test('out-of-bounds legacy coordinates emit diagnostic warning', () {
      final jsonMap = <String, dynamic>{
        'white': [5.0, 10.0],
      };

      final result = LegacySceneImporter.importJsonMap(jsonMap);

      expect(result.scene.balls.length, equals(1));
      expect(result.scene.balls.first.position.isWithinTable, isFalse);

      expect(result.hasWarnings, isTrue);
      final outOfBoundsWarning = result.warnings.firstWhere(
        (w) => w.code == 'OUT_OF_BOUNDS_COORDINATE',
      );
      expect(outOfBoundsWarning.field, equals('white'));
    });

    group('SceneMapper Phase 2 Extended Roundtrip & Backward Compatibility', () {
      test(
        'SceneMapper round-trips all Phase 2 extended fields completely',
        () {
          final now = DateTime.utc(2026, 9, 22, 10, 0, 0);
          final scene = BilliardScene(
            id: 'scene-uuid-full-phase2',
            name: 'Thế bi đầy đủ metadata Phase 2',
            tableConfig: const TableConfig(
              type: 'carom_3c',
              widthMeters: 1.42,
              lengthMeters: 2.84,
            ),
            balls: const [
              BallPosition(
                id: 'ball-1',
                ballType: 'ghost',
                position: TablePoint(0.5, 0.5),
                label: '1',
                colorHex: '#FFFFFFFF',
                rotation: 25.0,
                legacyType: 0,
              ),
              BallPosition(
                id: 'ball-2',
                ballType: 'extra',
                position: TablePoint(0.375, 0.375),
                label: '7',
                colorHex: '#FF2196F3',
              ),
            ],
            trajectories: const [
              TrajectoryLine(
                id: 'traj-1',
                colorHex: '#FF000000',
                points: [TablePoint(0.5, 0.5), TablePoint(0.0, 0.0)],
              ),
            ],
            annotations: const [
              SceneAnnotation(
                id: 'anno-1',
                text: 'Bi chủ chạm 1/2 bi',
                position: TablePoint(0.5, 0.75),
                colorHex: '#FFFFFFFF',
                rotation: 15.0,
                role: 'cueBall',
              ),
              SceneAnnotation(
                id: 'anno-2',
                text: '50',
                position: TablePoint(0.0, 0.5),
                colorHex: '#FFFFFFFF',
                rotation: 0.0,
                role: 'cushionNumber',
                cushionSide: 'left',
              ),
            ],
            cueInstruction: CueInstruction(
              power: 0.0,
              direction: Angle.fromRadians(0.0),
              tipOffset: const Vec2(0.1, -0.2),
              powerIsResolved: false,
            ),
            presentationConfig: const ScenePresentationConfig(
              legacySystemIndex: 2,
              legacyViewTypeIndex: 3,
              labelFontSize: 16.5,
            ),
            teachingTimeline: null,
            source: SceneSource.importSource,
            status: SceneStatus.active,
            version: 1,
            createdAt: now,
            updatedAt: now,
          );

          final row = SceneMapper.domainToRow(scene);
          final restored = SceneMapper.rowToDomain(row);

          expect(restored.id, equals(scene.id));
          expect(restored.name, equals(scene.name));
          expect(restored.teachingTimeline, isNull);

          // Assert BallPosition Phase 2 fields
          expect(restored.balls.length, equals(2));
          final b1 = restored.balls.firstWhere((b) => b.id == 'ball-1');
          expect(b1.ballType, equals('ghost'));
          expect(b1.position, equals(const TablePoint(0.5, 0.5)));
          expect(b1.label, equals('1'));
          expect(b1.colorHex, equals('#FFFFFFFF'));
          expect(b1.rotation, equals(25.0));
          expect(b1.legacyType, equals(0));

          final b2 = restored.balls.firstWhere((b) => b.id == 'ball-2');
          expect(b2.ballType, equals('extra'));
          expect(b2.label, equals('7'));
          expect(b2.colorHex, equals('#FF2196F3'));

          // Assert SceneAnnotation Phase 2 fields
          expect(restored.annotations.length, equals(2));
          final a1 = restored.annotations.firstWhere((a) => a.id == 'anno-1');
          expect(a1.text, equals('Bi chủ chạm 1/2 bi'));
          expect(a1.colorHex, equals('#FFFFFFFF'));
          expect(a1.rotation, equals(15.0));
          expect(a1.role, equals('cueBall'));

          final a2 = restored.annotations.firstWhere((a) => a.id == 'anno-2');
          expect(a2.text, equals('50'));
          expect(a2.role, equals('cushionNumber'));
          expect(a2.cushionSide, equals('left'));

          // Assert CueInstruction Phase 2 fields
          expect(restored.cueInstruction, isNotNull);
          expect(restored.cueInstruction!.power, equals(0.0));
          expect(restored.cueInstruction!.powerIsResolved, isFalse);
          expect(
            restored.cueInstruction!.tipOffset,
            equals(const Vec2(0.1, -0.2)),
          );

          // Assert ScenePresentationConfig Phase 2 fields
          expect(restored.presentationConfig, isNotNull);
          expect(restored.presentationConfig!.legacySystemIndex, equals(2));
          expect(restored.presentationConfig!.legacyViewTypeIndex, equals(3));
          expect(restored.presentationConfig!.labelFontSize, equals(16.5));
        },
      );

      test(
        'SceneMapper deserializes old legacy row missing Phase 2 fields with backward compatibility',
        () {
          final oldRow = SqliteSceneRow(
            id: 'old-scene-1',
            name: 'Sơ đồ cũ Phase 1',
            tableConfigJson: jsonEncode({
              'type': 'carom_3c',
              'widthMeters': 1.42,
              'lengthMeters': 2.84,
            }),
            ballsJson: jsonEncode([
              {
                'id': 'b-1',
                'ballType': 'white',
                'position': {'u': 0.5, 'v': 0.5},
              },
            ]),
            trajectoriesJson: jsonEncode([
              {
                'id': 't-1',
                'colorHex': '#FFFFFF',
                'points': [
                  {'u': 0.5, 'v': 0.5},
                ],
              },
            ]),
            annotationsJson: jsonEncode([
              {
                'id': 'a-1',
                'text': 'Chú thích cũ',
                'position': {'u': 0.5, 'v': 0.5},
              },
            ]),
            cueInstructionJson: jsonEncode({
              'power': 0.5,
              'directionRadians': 0.0,
              'tipOffset': {'x': 0.0, 'y': 0.0},
            }),
            teachingTimelineJson: null,
            source: 'manual',
            status: 'active',
            version: 1,
            createdAt: '2026-09-22T10:00:00.000Z',
            updatedAt: '2026-09-22T10:00:00.000Z',
          );

          final restored = SceneMapper.rowToDomain(oldRow);

          expect(restored.id, equals('old-scene-1'));
          expect(restored.presentationConfig, isNull);
          expect(restored.balls.first.label, isNull);
          expect(restored.balls.first.colorHex, isNull);
          expect(restored.balls.first.rotation, isNull);
          expect(restored.balls.first.legacyType, isNull);
          expect(restored.annotations.first.colorHex, isNull);
          expect(restored.annotations.first.rotation, isNull);
          expect(restored.annotations.first.role, isNull);
          expect(restored.annotations.first.cushionSide, isNull);
          expect(restored.cueInstruction!.powerIsResolved, isTrue);
        },
      );
    });
  });
}
