// Phase 4C Legacy Bridge Round-Trip Parity Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/importers/legacy_scene_bridge.dart';
import 'package:libre2026/domain/importers/legacy_scene_exporter.dart';
import 'package:libre2026/domain/importers/legacy_scene_importer.dart';

void main() {
  final Map<String, dynamic> sampleLegacyPayload = {
    'schemaVersion': 1,
    'white': [1.0, 2.0], // u=0.25, v=0.25
    'yellow': [2.0, 4.0], // u=0.5, v=0.5
    'red': [3.0, 6.0], // u=0.75, v=0.75
    'viewType': 1, // half
    'system': 2, // short3Cushion
    'labelFontSize': 12.0,
    'paths': {
      'white': [
        [1.5, 3.0],
        [2.0, 4.0],
      ],
      'yellow': [
        [2.5, 5.0],
      ],
      'red': [
        [3.5, 7.0],
      ],
      'free': [
        [
          [0.5, 1.0],
          [1.0, 2.0],
        ],
      ],
    },
    'pathColors': {
      'white': 0xB3FFFFFF,
      'yellow': 0xFFFFEB3B,
      'red': 0xFFF44336,
      'free': 0xFF2196F3,
    },
    'freePathColors': [0xFF00FFFF],
    'labels': [
      {
        'x': 1.0,
        'y': 2.0,
        'text': 'Start',
        'color': 0xFFFFFF00,
        'rotation': 45.0,
        'role': 'note',
      },
    ],
    'cushionNumbers': [
      {
        'x': 0.0,
        'y': 2.0,
        'text': '50',
        'color': 0xFF00FF00,
        'rotation': 90.0,
        'cushionSide': 'left',
      },
    ],
    'ghosts': [
      {
        'x': 2.0,
        'y': 2.0,
        'color': 0xFFFFFFFF,
        'type': 1,
        'rotation': 30.0,
        'number': 'G1',
      },
    ],
    'extraBalls': [
      {'x': 3.0, 'y': 3.0, 'color': 0xFF0000FF, 'number': '8'},
    ],
    'effet': {
      'effet': [0.5, -0.2],
      'spots': [
        {'x': 0.5, 'y': -0.2, 'number': '1', 'color': 4294967295},
      ],
      'showHitBall': true,
      'hitThickness': 4,
      'hitSide': 'left',
      'spotSize': 30.0,
    },
  };

  test(
    'legacy payload -> canonical BilliardScene -> legacy payload round trip parity',
    () {
      final importResult = LegacySceneImporter.importJsonMap(
        sampleLegacyPayload,
      );
      final scene = importResult.scene;

      expect(
        scene.balls.length,
        equals(5),
      ); // white, yellow, red, 1 ghost, 1 extra
      expect(
        scene.trajectories.length,
        equals(4),
      ); // white, yellow, red, 1 free
      expect(scene.annotations.length, equals(2)); // 1 label, 1 cushion number
      expect(scene.presentationConfig?.legacyViewTypeIndex, equals(1));
      expect(scene.presentationConfig?.legacySystemIndex, equals(2));
      expect(scene.presentationConfig?.labelFontSize, equals(12.0));

      // Export back to legacy payload
      final exportedPayload = LegacySceneExporter.exportJsonMap(scene);

      expect(exportedPayload['white'], equals([1.0, 2.0]));
      expect(exportedPayload['yellow'], equals([2.0, 4.0]));
      expect(exportedPayload['red'], equals([3.0, 6.0]));

      expect(exportedPayload['viewType'], equals(1));
      expect(exportedPayload['system'], equals(2));
      expect(exportedPayload['labelFontSize'], equals(12.0));

      // Verify main ball path first-point rule (does not duplicate whitePos [1.0, 2.0])
      final exportedWhitePath =
          (exportedPayload['paths'] as Map)['white'] as List;
      expect(exportedWhitePath.length, equals(2));
      expect(exportedWhitePath[0], equals([1.5, 3.0]));
      expect(exportedWhitePath[1], equals([2.0, 4.0]));

      // Verify free paths
      final exportedFreePaths =
          (exportedPayload['paths'] as Map)['free'] as List;
      expect(exportedFreePaths.length, equals(1));
      expect(
        exportedFreePaths[0],
        equals([
          [0.5, 1.0],
          [1.0, 2.0],
        ]),
      );

      // Verify pathColors map including free
      final exportedPathColors = exportedPayload['pathColors'] as Map;
      expect(exportedPathColors['white'], equals(0xB3FFFFFF));
      expect(exportedPathColors['yellow'], equals(0xFFFFEB3B));
      expect(exportedPathColors['red'], equals(0xFFF44336));
      expect(exportedPathColors['free'], equals(0xFF2196F3));

      // Verify ghosts and extra balls
      final exportedGhosts = exportedPayload['ghosts'] as List;
      expect(exportedGhosts.length, equals(1));
      expect(exportedGhosts[0]['x'], equals(2.0));
      expect(exportedGhosts[0]['number'], equals('G1'));

      final exportedExtra = exportedPayload['extraBalls'] as List;
      expect(exportedExtra.length, equals(1));
      expect(exportedExtra[0]['x'], equals(3.0));
      expect(exportedExtra[0]['number'], equals('8'));

      // Verify current legacy effet format (spots, showHitBall, hitThickness, hitSide, spotSize)
      final exportedEffet = exportedPayload['effet'] as Map;
      expect(exportedEffet['effet'], equals([0.5, -0.2]));
      expect(exportedEffet['showHitBall'], isTrue);
      expect(exportedEffet['hitThickness'], equals(4));
      expect(exportedEffet['hitSide'], equals('left'));
      expect(exportedEffet['spotSize'], equals(30.0));
      expect(exportedEffet['spots'], isNotNull);
    },
  );

  test('pathColors preserved even when paths are empty', () {
    final Map<String, dynamic> emptyPathsPayload = {
      'schemaVersion': 1,
      'white': [1.0, 2.0],
      'pathColors': {
        'white': 0xFF112233,
        'yellow': 0xFF445566,
        'red': 0xFF778899,
        'free': 0xFFAABBCC,
      },
    };

    final scene = LegacySceneImporter.importJsonMap(emptyPathsPayload).scene;
    expect(scene.trajectories, isEmpty);

    final exported = LegacySceneExporter.exportJsonMap(scene);
    final pathColors = exported['pathColors'] as Map;
    expect(pathColors['white'], equals(0xFF112233));
    expect(pathColors['yellow'], equals(0xFF445566));
    expect(pathColors['red'], equals(0xFF778899));
    expect(pathColors['free'], equals(0xFFAABBCC));
  });

  test(
    'LegacySceneBridge initialDataToScene & sceneToLegacyJson string round trip',
    () {
      final jsonStr = LegacySceneBridge.sceneToLegacyJson(
        LegacySceneImporter.importJsonMap(sampleLegacyPayload).scene,
      );
      expect(jsonStr, contains('"schemaVersion":1'));

      final reconstructedScene = LegacySceneBridge.initialDataToScene(jsonStr);
      expect(reconstructedScene.balls.length, equals(5));
      expect(reconstructedScene.trajectories.length, equals(4));
    },
  );
}
