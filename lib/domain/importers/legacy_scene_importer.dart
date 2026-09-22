// Pure Dart Legacy Scene Importer for Billiardlearning Phase 2

import '../entities/entities.dart';
import '../value_objects/value_objects.dart';

/// Warning diagnostic produced during legacy diagram JSON migration.
class LegacyImportWarning {
  final String code;
  final String message;
  final String? field;

  const LegacyImportWarning({
    required this.code,
    required this.message,
    this.field,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyImportWarning &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          field == other.field;

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ field.hashCode;

  @override
  String toString() => '[$code] $message${field != null ? " ($field)" : ""}';
}

/// Container result for legacy diagram JSON import operations.
class LegacySceneImportResult {
  final BilliardScene scene;
  final List<LegacyImportWarning> warnings;

  const LegacySceneImportResult({required this.scene, required this.warnings});

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Pure Dart importer converting legacy diagram JSON maps into vNext [BilliardScene] candidates.
class LegacySceneImporter {
  /// Converts a legacy diagram JSON payload map into a vNext [BilliardScene] candidate.
  ///
  /// Maps legacy diamond coordinates (x in 0..4, y in 0..8) to normalized [TablePoint] (u=x/4, v=y/8).
  static LegacySceneImportResult importJsonMap(
    Map<String, dynamic> json, {
    String? sceneName,
  }) {
    final warnings = <LegacyImportWarning>[];

    // 1. Schema version validation
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    if (schemaVersion != 1) {
      warnings.add(
        LegacyImportWarning(
          code: 'UNSUPPORTED_SCHEMA_VERSION',
          message: 'Schema version $schemaVersion differs from baseline 1',
          field: 'schemaVersion',
        ),
      );
    }

    // Helper: convert legacy diamond (x, y) to TablePoint(x/4, y/8)
    TablePoint parseDiamondPoint(double x, double y, String pointContext) {
      final u = x / 4.0;
      final v = y / 8.0;
      final point = TablePoint(u, v);
      if (!point.isWithinTable) {
        warnings.add(
          LegacyImportWarning(
            code: 'OUT_OF_BOUNDS_COORDINATE',
            message:
                'Point ($x, $y) mapped to TablePoint(${u.toStringAsFixed(2)}, ${v.toStringAsFixed(2)}) is outside [0,1]^2 bounds',
            field: pointContext,
          ),
        );
      }
      return point;
    }

    // 2. Ball positions
    final balls = <BallPosition>[];

    // Main balls: white, yellow, red
    if (json.containsKey('white') && json['white'] is List) {
      final coords = (json['white'] as List).cast<num>();
      if (coords.length >= 2) {
        balls.add(
          BallPosition(
            id: 'ball_white',
            ballType: 'white',
            position: parseDiamondPoint(
              coords[0].toDouble(),
              coords[1].toDouble(),
              'white_ball',
            ),
          ),
        );
      }
    }

    if (json.containsKey('yellow') && json['yellow'] is List) {
      final coords = (json['yellow'] as List).cast<num>();
      if (coords.length >= 2) {
        balls.add(
          BallPosition(
            id: 'ball_yellow',
            ballType: 'yellow',
            position: parseDiamondPoint(
              coords[0].toDouble(),
              coords[1].toDouble(),
              'yellow_ball',
            ),
          ),
        );
      }
    }

    if (json.containsKey('red') && json['red'] is List) {
      final coords = (json['red'] as List).cast<num>();
      if (coords.length >= 2) {
        balls.add(
          BallPosition(
            id: 'ball_red',
            ballType: 'red',
            position: parseDiamondPoint(
              coords[0].toDouble(),
              coords[1].toDouble(),
              'red_ball',
            ),
          ),
        );
      }
    }

    // Extra balls
    if (json.containsKey('extraBalls') && json['extraBalls'] is List) {
      final extraList = json['extraBalls'] as List;
      for (var i = 0; i < extraList.length; i++) {
        final item = extraList[i];
        if (item is List && item.length >= 2) {
          final coords = item.cast<num>();
          balls.add(
            BallPosition(
              id: 'extra_$i',
              ballType: 'extra',
              position: parseDiamondPoint(
                coords[0].toDouble(),
                coords[1].toDouble(),
                'extraBalls[$i]',
              ),
            ),
          );
        }
      }
    }

    // Ghosts
    if (json.containsKey('ghosts') && json['ghosts'] is List) {
      final ghostList = json['ghosts'] as List;
      for (var i = 0; i < ghostList.length; i++) {
        final item = ghostList[i];
        if (item is List && item.length >= 2) {
          final coords = item.cast<num>();
          balls.add(
            BallPosition(
              id: 'ghost_$i',
              ballType: 'ghost',
              position: parseDiamondPoint(
                coords[0].toDouble(),
                coords[1].toDouble(),
                'ghosts[$i]',
              ),
            ),
          );
        }
      }
    }

    // 3. Trajectories
    final trajectories = <TrajectoryLine>[];
    if (json.containsKey('paths') && json['paths'] is Map) {
      final pathsMap = json['paths'] as Map;

      // Trajectory parser helper
      List<TablePoint> parsePolyline(List rawPoints, String pathKey) {
        final pts = <TablePoint>[];
        for (var i = 0; i < rawPoints.length; i++) {
          final item = rawPoints[i];
          if (item is List && item.length >= 2) {
            final coords = item.cast<num>();
            pts.add(
              parseDiamondPoint(
                coords[0].toDouble(),
                coords[1].toDouble(),
                'paths.$pathKey[$i]',
              ),
            );
          }
        }
        return pts;
      }

      if (pathsMap.containsKey('white') && pathsMap['white'] is List) {
        final pts = parsePolyline(pathsMap['white'] as List, 'white');
        if (pts.isNotEmpty) {
          trajectories.add(
            TrajectoryLine(id: 'traj_white', colorHex: '#FFFFFF', points: pts),
          );
        }
      }

      if (pathsMap.containsKey('yellow') && pathsMap['yellow'] is List) {
        final pts = parsePolyline(pathsMap['yellow'] as List, 'yellow');
        if (pts.isNotEmpty) {
          trajectories.add(
            TrajectoryLine(id: 'traj_yellow', colorHex: '#FFEB3B', points: pts),
          );
        }
      }

      if (pathsMap.containsKey('red') && pathsMap['red'] is List) {
        final pts = parsePolyline(pathsMap['red'] as List, 'red');
        if (pts.isNotEmpty) {
          trajectories.add(
            TrajectoryLine(id: 'traj_red', colorHex: '#F44336', points: pts),
          );
        }
      }

      if (pathsMap.containsKey('free') && pathsMap['free'] is List) {
        final freeList = pathsMap['free'] as List;
        for (var i = 0; i < freeList.length; i++) {
          final item = freeList[i];
          if (item is List) {
            final pts = parsePolyline(item, 'free[$i]');
            if (pts.isNotEmpty) {
              trajectories.add(
                TrajectoryLine(
                  id: 'traj_free_$i',
                  colorHex: '#2196F3',
                  points: pts,
                ),
              );
            }
          }
        }
      }
    }

    // 4. Annotations (labels and cushion numbers)
    final annotations = <SceneAnnotation>[];

    if (json.containsKey('labels') && json['labels'] is List) {
      final labelList = json['labels'] as List;
      for (var i = 0; i < labelList.length; i++) {
        final item = labelList[i];
        if (item is Map) {
          final x = (item['x'] as num?)?.toDouble() ?? 0.0;
          final y = (item['y'] as num?)?.toDouble() ?? 0.0;
          final text = item['text'] as String? ?? '';
          annotations.add(
            SceneAnnotation(
              id: 'label_$i',
              text: text,
              position: parseDiamondPoint(x, y, 'labels[$i]'),
            ),
          );
        }
      }
    }

    if (json.containsKey('cushionNumbers') && json['cushionNumbers'] is List) {
      final cushionList = json['cushionNumbers'] as List;
      for (var i = 0; i < cushionList.length; i++) {
        final item = cushionList[i];
        if (item is Map) {
          final x = (item['x'] as num?)?.toDouble() ?? 0.0;
          final y = (item['y'] as num?)?.toDouble() ?? 0.0;
          final text = item['text'] as String? ?? '';
          annotations.add(
            SceneAnnotation(
              id: 'cushion_$i',
              text: text,
              position: parseDiamondPoint(x, y, 'cushionNumbers[$i]'),
            ),
          );
        }
      }
    }

    // 5. Cue Instruction & Deferred Effet Fields
    CueInstruction? cueInstruction;
    if (json.containsKey('effet') && json['effet'] is Map) {
      final effetMap = json['effet'] as Map;

      // Spin tip offset
      Vec2 tipOffset = Vec2.zero;
      if (effetMap.containsKey('effet') && effetMap['effet'] is List) {
        final offsetList = (effetMap['effet'] as List).cast<num>();
        if (offsetList.length >= 2) {
          tipOffset = Vec2(offsetList[0].toDouble(), offsetList[1].toDouble());
        }
      }

      // Default normalized power 0.5 for imported scenes unless specified
      cueInstruction = CueInstruction(power: 0.5, tipOffset: tipOffset);

      // Deferred GAPs warnings
      if (effetMap.containsKey('forceImage')) {
        warnings.add(
          LegacyImportWarning(
            code: 'DEFERRED_FIELD_FORCE_IMAGE',
            message:
                'Asset forceImage (${effetMap['forceImage']}) deferred for Phase 15/16 physical power calibration',
            field: 'effet.forceImage',
          ),
        );
      }

      if (effetMap.containsKey('cueAngle')) {
        warnings.add(
          LegacyImportWarning(
            code: 'DEFERRED_FIELD_CUE_ANGLE',
            message:
                'Cue elevation cueAngle (${effetMap['cueAngle']}°) deferred to Phase 15 Cue Strike Model',
            field: 'effet.cueAngle',
          ),
        );
      }

      if (effetMap.containsKey('thickness')) {
        warnings.add(
          LegacyImportWarning(
            code: 'DEFERRED_FIELD_THICKNESS',
            message:
                'Contact thickness (${effetMap['thickness']}) deferred to Phase 6 Lesson Domain',
            field: 'effet.thickness',
          ),
        );
      }
    }

    // 6. Visual system metadata
    final systemIndex = json['system'] as int? ?? 0;
    final viewTypeIndex = json['viewType'] as int? ?? 0;

    final now = DateTime.now();

    final scene = BilliardScene(
      id: StableId.generate(),
      name: sceneName ?? 'Imported Legacy Scene',
      tableConfig: TableConfig(
        type: 'carom_3c',
        widthMeters: 1.42,
        lengthMeters: 2.84,
      ),
      balls: balls,
      trajectories: trajectories,
      annotations: annotations,
      cueInstruction: cueInstruction,
      teachingTimeline: {
        'legacySystemIndex': systemIndex,
        'legacyViewTypeIndex': viewTypeIndex,
      },
      source: SceneSource.importSource,
      status: SceneStatus.active,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );

    return LegacySceneImportResult(scene: scene, warnings: warnings);
  }
}
