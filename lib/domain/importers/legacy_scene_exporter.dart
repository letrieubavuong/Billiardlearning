// Pure Dart Legacy Scene Exporter for Billiardlearning Phase 4C
// Converts vNext [BilliardScene] back to legacy diagram JSON payload map.

import '../entities/entities.dart';
import '../value_objects/value_objects.dart';

/// Pure Dart exporter converting vNext [BilliardScene] into legacy diagram JSON map payload.
class LegacySceneExporter {
  /// Converts #AARRGGBB hex color string into 32-bit ARGB integer.
  static int hexToColorInt(String? hex, int defaultColor) {
    if (hex == null || hex.isEmpty) return defaultColor;
    var cleanHex = hex.trim();
    if (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final val = int.tryParse(cleanHex, radix: 16);
      if (val != null) return val;
    }
    return defaultColor;
  }

  /// Converts normalized TablePoint(u, v) to legacy diamond coordinate [x, y] where x=u*4, y=v*8.
  static List<double> pointToDiamondList(TablePoint point) {
    return [(point.u * 4.0), (point.v * 8.0)];
  }

  /// Exports a vNext [BilliardScene] to a legacy diagram payload map.
  static Map<String, dynamic> exportJsonMap(BilliardScene scene) {
    final map = <String, dynamic>{'schemaVersion': 1};

    TablePoint? whitePos;
    TablePoint? yellowPos;
    TablePoint? redPos;

    final ghosts = <Map<String, dynamic>>[];
    final extraBalls = <Map<String, dynamic>>[];

    // 1. Process Balls
    for (final ball in scene.balls) {
      final x = ball.position.u * 4.0;
      final y = ball.position.v * 8.0;

      if (ball.ballType == 'white' || ball.id == 'ball_white') {
        whitePos = ball.position;
        map['white'] = [x, y];
      } else if (ball.ballType == 'yellow' || ball.id == 'ball_yellow') {
        yellowPos = ball.position;
        map['yellow'] = [x, y];
      } else if (ball.ballType == 'red' || ball.id == 'ball_red') {
        redPos = ball.position;
        map['red'] = [x, y];
      } else if (ball.ballType == 'ghost') {
        ghosts.add({
          'x': x,
          'y': y,
          'color': hexToColorInt(ball.colorHex, 0xFFFFFFFF),
          'type': ball.legacyType ?? 0,
          'rotation': ball.rotation ?? 0.0,
          'number': ball.label ?? '',
        });
      } else if (ball.ballType == 'extra') {
        extraBalls.add({
          'x': x,
          'y': y,
          'color': hexToColorInt(ball.colorHex, 0xFF2196F3),
          'number': ball.label ?? '',
        });
      }
    }

    if (ghosts.isNotEmpty) {
      map['ghosts'] = ghosts;
    }
    if (extraBalls.isNotEmpty) {
      map['extraBalls'] = extraBalls;
    }

    // 2. Process Trajectories
    final paths = <String, dynamic>{};
    final legacyColors = scene.presentationConfig?.legacyPathColors;
    final pathColors = <String, dynamic>{
      'white': hexToColorInt(legacyColors?['white'], 0xB3FFFFFF),
      'yellow': hexToColorInt(legacyColors?['yellow'], 0xFFFFEB3B),
      'red': hexToColorInt(legacyColors?['red'], 0xFFF44336),
      'free': hexToColorInt(legacyColors?['free'], 0xFF2196F3),
    };
    final freePathColors = <int>[];
    final freePathsList = <List<List<double>>>[];

    for (final traj in scene.trajectories) {
      final isWhite = traj.id == 'traj_white' || traj.id == 'white';
      final isYellow = traj.id == 'traj_yellow' || traj.id == 'yellow';
      final isRed = traj.id == 'traj_red' || traj.id == 'red';

      if (isWhite) {
        pathColors['white'] = hexToColorInt(traj.colorHex, 0xB3FFFFFF);
        // Exclude prepended white ball position if present to prevent duplication
        var pts = traj.points;
        if (pts.isNotEmpty && whitePos != null && pts.first == whitePos) {
          pts = pts.sublist(1);
        }
        paths['white'] = pts.map(pointToDiamondList).toList();
      } else if (isYellow) {
        pathColors['yellow'] = hexToColorInt(traj.colorHex, 0xFFFFEB3B);
        var pts = traj.points;
        if (pts.isNotEmpty && yellowPos != null && pts.first == yellowPos) {
          pts = pts.sublist(1);
        }
        paths['yellow'] = pts.map(pointToDiamondList).toList();
      } else if (isRed) {
        pathColors['red'] = hexToColorInt(traj.colorHex, 0xFFF44336);
        var pts = traj.points;
        if (pts.isNotEmpty && redPos != null && pts.first == redPos) {
          pts = pts.sublist(1);
        }
        paths['red'] = pts.map(pointToDiamondList).toList();
      } else {
        // Free path
        freePathColors.add(hexToColorInt(traj.colorHex, 0xFF2196F3));
        freePathsList.add(traj.points.map(pointToDiamondList).toList());
      }
    }

    if (freePathsList.isNotEmpty) {
      paths['free'] = freePathsList;
      map['freePathColors'] = freePathColors;
    }

    if (paths.isNotEmpty) {
      map['paths'] = paths;
    }
    if (pathColors.isNotEmpty) {
      map['pathColors'] = pathColors;
    }

    // 3. Process Annotations
    final labels = <Map<String, dynamic>>[];
    final cushionNumbers = <Map<String, dynamic>>[];

    for (final ann in scene.annotations) {
      final x = ann.position.u * 4.0;
      final y = ann.position.v * 8.0;
      final colorInt = hexToColorInt(ann.colorHex, 0xFFFFFF00);

      if (ann.role == 'cushionNumber' || ann.cushionSide != null) {
        cushionNumbers.add({
          'x': x,
          'y': y,
          'text': ann.text,
          'color': colorInt,
          'rotation': ann.rotation ?? 0.0,
          'cushionSide': ann.cushionSide,
        });
      } else {
        labels.add({
          'x': x,
          'y': y,
          'text': ann.text,
          'color': colorInt,
          'rotation': ann.rotation ?? 0.0,
          if (ann.role != null) 'role': ann.role,
        });
      }
    }

    if (labels.isNotEmpty) {
      map['labels'] = labels;
    }
    if (cushionNumbers.isNotEmpty) {
      map['cushionNumbers'] = cushionNumbers;
    }

    // 4. Cue Instruction / Effet
    Map<String, dynamic>? effetMap;
    if (scene.presentationConfig?.rawEffetData != null) {
      effetMap = Map<String, dynamic>.from(
        scene.presentationConfig!.rawEffetData!,
      );
    }
    if (scene.cueInstruction != null) {
      effetMap ??= <String, dynamic>{};
      effetMap['effet'] = [
        scene.cueInstruction!.tipOffset.x,
        scene.cueInstruction!.tipOffset.y,
      ];
    }
    if (effetMap != null && effetMap.isNotEmpty) {
      map['effet'] = effetMap;
    }

    // 5. Presentation Config
    if (scene.presentationConfig != null) {
      map['system'] = scene.presentationConfig!.legacySystemIndex;
      map['viewType'] = scene.presentationConfig!.legacyViewTypeIndex;
      if (scene.presentationConfig!.labelFontSize != null) {
        map['labelFontSize'] = scene.presentationConfig!.labelFontSize;
      }
    }

    return map;
  }
}
