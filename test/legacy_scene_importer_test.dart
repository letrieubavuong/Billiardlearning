import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/importers/legacy_scene_importer.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('LegacySceneImporter (Phase 2)', () {
    test(
      'imports real legacy diagram JSON payload with correct x/4, y/8 coordinate mapping',
      () {
        const rawJson = '''
      {
        "schemaVersion": 1,
        "system": 1,
        "viewType": 0,
        "white": [2.0, 6.0],
        "yellow": [1.0, 4.0],
        "red": [3.0, 2.0],
        "extraBalls": [[0.0, 0.0]],
        "ghosts": [[4.0, 8.0]],
        "paths": {
          "white": [[2.0, 6.0], [1.0, 0.0]],
          "yellow": [],
          "red": [],
          "free": [[[0.0, 0.0], [4.0, 8.0]]]
        },
        "labels": [
          {"x": 2.0, "y": 6.0, "text": "Bi chủ chạm 1/2 bi", "color": 4294967295, "rotation": 0.0}
        ],
        "cushionNumbers": [
          {"x": 0.0, "y": 4.0, "text": "50"}
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

        // Verify ball position transformations: x_diamond / 4, y_diamond / 8
        expect(scene.balls.length, equals(5));

        final whiteBall = scene.balls.firstWhere((b) => b.ballType == 'white');
        expect(
          whiteBall.position,
          equals(const TablePoint(0.5, 0.75)),
        ); // x=2.0->0.5, y=6.0->0.75

        final yellowBall = scene.balls.firstWhere(
          (b) => b.ballType == 'yellow',
        );
        expect(
          yellowBall.position,
          equals(const TablePoint(0.25, 0.5)),
        ); // x=1.0->0.25, y=4.0->0.5

        final redBall = scene.balls.firstWhere((b) => b.ballType == 'red');
        expect(
          redBall.position,
          equals(const TablePoint(0.75, 0.25)),
        ); // x=3.0->0.75, y=2.0->0.25

        final extraBall = scene.balls.firstWhere((b) => b.ballType == 'extra');
        expect(extraBall.position, equals(const TablePoint(0.0, 0.0)));

        final ghostBall = scene.balls.firstWhere((b) => b.ballType == 'ghost');
        expect(ghostBall.position, equals(const TablePoint(1.0, 1.0)));

        // Verify trajectories
        expect(scene.trajectories.length, equals(2));
        final whiteTraj = scene.trajectories.firstWhere(
          (t) => t.id == 'traj_white',
        );
        expect(
          whiteTraj.points,
          equals(const [TablePoint(0.5, 0.75), TablePoint(0.25, 0.0)]),
        );

        // Verify annotations
        expect(scene.annotations.length, equals(2));
        expect(scene.annotations[0].text, equals('Bi chủ chạm 1/2 bi'));
        expect(
          scene.annotations[0].position,
          equals(const TablePoint(0.5, 0.75)),
        );

        // Verify cue instruction tip offset
        expect(scene.cueInstruction, isNotNull);
        expect(scene.cueInstruction!.tipOffset, equals(const Vec2(0.0, 0.5)));
        expect(
          scene.cueInstruction!.power,
          equals(0.5),
        ); // Default normalized power

        // Verify deferred warnings
        expect(result.hasWarnings, isTrue);
        final warningCodes = result.warnings.map((w) => w.code).toList();
        expect(warningCodes, contains('DEFERRED_FIELD_FORCE_IMAGE'));
        expect(warningCodes, contains('DEFERRED_FIELD_CUE_ANGLE'));
        expect(warningCodes, contains('DEFERRED_FIELD_THICKNESS'));
      },
    );

    test('out-of-bounds legacy coordinates emit diagnostic warning', () {
      final jsonMap = <String, dynamic>{
        'white': [5.0, 10.0], // x=5.0 -> u=1.25, y=10.0 -> v=1.25
      };

      final result = LegacySceneImporter.importJsonMap(jsonMap);

      expect(result.scene.balls.length, equals(1));
      expect(result.scene.balls.first.position.isWithinTable, isFalse);

      expect(result.hasWarnings, isTrue);
      final outOfBoundsWarning = result.warnings.firstWhere(
        (w) => w.code == 'OUT_OF_BOUNDS_COORDINATE',
      );
      expect(outOfBoundsWarning.field, equals('white_ball'));
    });
  });
}
