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
  /// Safe helper extracting integer from dynamic value without throwing CastError.
  static int? parseOptionalInt(
    dynamic value,
    String fieldName,
    List<LegacyImportWarning> warnings,
  ) {
    if (value == null) return null;
    if (value is num) {
      return value.toInt();
    }
    warnings.add(
      LegacyImportWarning(
        code: 'INVALID_FIELD_TYPE',
        message:
            'Expected numeric integer for $fieldName, got ${value.runtimeType} ($value)',
        field: fieldName,
      ),
    );
    return null;
  }

  /// Safe helper extracting double from dynamic value without throwing CastError.
  static double? parseOptionalDouble(
    dynamic value,
    String fieldName,
    List<LegacyImportWarning> warnings,
  ) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble();
    }
    warnings.add(
      LegacyImportWarning(
        code: 'INVALID_FIELD_TYPE',
        message:
            'Expected number for $fieldName, got ${value.runtimeType} ($value)',
        field: fieldName,
      ),
    );
    return null;
  }

  /// Converts ARGB integer (e.g. 4294967295) or String to #AARRGGBB hex color format.
  static String? parseColorHex(
    dynamic value,
    String fieldName,
    List<LegacyImportWarning> warnings,
  ) {
    if (value == null) return null;
    if (value is int) {
      final hex = value.toRadixString(16).padLeft(8, '0').toUpperCase();
      return '#$hex';
    }
    if (value is String) {
      if (value.startsWith('#')) return value.toUpperCase();
      final parsed = int.tryParse(value);
      if (parsed != null) {
        final hex = parsed.toRadixString(16).padLeft(8, '0').toUpperCase();
        return '#$hex';
      }
    }
    warnings.add(
      LegacyImportWarning(
        code: 'INVALID_FIELD_TYPE',
        message: 'Expected color int or string, got ${value.runtimeType}',
        field: fieldName,
      ),
    );
    return null;
  }

  /// Helper: converts legacy diamond point list [x, y] to normalized TablePoint(x/4, y/8).
  static TablePoint? parsePointFromList(
    dynamic item,
    String context,
    List<LegacyImportWarning> warnings,
  ) {
    if (item is! List) {
      warnings.add(
        LegacyImportWarning(
          code: 'INVALID_POINT_SHAPE',
          message: 'Expected List for coordinates, got ${item.runtimeType}',
          field: context,
        ),
      );
      return null;
    }
    if (item.length < 2) {
      warnings.add(
        LegacyImportWarning(
          code: 'INVALID_POINT_SHAPE',
          message: 'Coordinate list has length ${item.length}, expected >= 2',
          field: context,
        ),
      );
      return null;
    }
    final xNum = item[0];
    final yNum = item[1];
    if (xNum is! num || yNum is! num) {
      warnings.add(
        LegacyImportWarning(
          code: 'INVALID_POINT_SHAPE',
          message: 'Coordinates contain non-numeric values: ($xNum, $yNum)',
          field: context,
        ),
      );
      return null;
    }
    final u = xNum.toDouble() / 4.0;
    final v = yNum.toDouble() / 8.0;
    final pt = TablePoint(u, v);
    if (!pt.isWithinTable) {
      warnings.add(
        LegacyImportWarning(
          code: 'OUT_OF_BOUNDS_COORDINATE',
          message:
              'Point (${xNum.toDouble()}, ${yNum.toDouble()}) mapped to TablePoint(${u.toStringAsFixed(2)}, ${v.toStringAsFixed(2)}) is outside [0,1]^2 bounds',
          field: context,
        ),
      );
    }
    return pt;
  }

  /// Helper: converts legacy diamond map {"x": x, "y": y} to normalized TablePoint(x/4, y/8).
  static TablePoint? parsePointFromMap(
    Map map,
    String context,
    List<LegacyImportWarning> warnings,
  ) {
    final xNum = map['x'];
    final yNum = map['y'];
    if (xNum == null || yNum == null) {
      warnings.add(
        LegacyImportWarning(
          code: 'MISSING_REQUIRED_COORDINATE',
          message: 'Map missing required x or y coordinate',
          field: context,
        ),
      );
      return null;
    }
    if (xNum is! num || yNum is! num) {
      warnings.add(
        LegacyImportWarning(
          code: 'INVALID_FIELD_TYPE',
          message: 'x or y coordinate is non-numeric: x=$xNum, y=$yNum',
          field: context,
        ),
      );
      return null;
    }
    final u = xNum.toDouble() / 4.0;
    final v = yNum.toDouble() / 8.0;
    final pt = TablePoint(u, v);
    if (!pt.isWithinTable) {
      warnings.add(
        LegacyImportWarning(
          code: 'OUT_OF_BOUNDS_COORDINATE',
          message:
              'Point (${xNum.toDouble()}, ${yNum.toDouble()}) mapped to TablePoint(${u.toStringAsFixed(2)}, ${v.toStringAsFixed(2)}) is outside [0,1]^2 bounds',
          field: context,
        ),
      );
    }
    return pt;
  }

  /// Converts a legacy diagram JSON payload map into a vNext [BilliardScene] candidate.
  ///
  /// Maps legacy diamond coordinates (x in 0..4, y in 0..8) to normalized [TablePoint] (u=x/4, v=y/8).
  static LegacySceneImportResult importJsonMap(
    Map<String, dynamic> json, {
    String? sceneName,
  }) {
    final warnings = <LegacyImportWarning>[];

    // 1. Schema version validation
    int schemaVersion = 1;
    if (json.containsKey('schemaVersion')) {
      final parsedVersion = parseOptionalInt(
        json['schemaVersion'],
        'schemaVersion',
        warnings,
      );
      if (parsedVersion != null) {
        schemaVersion = parsedVersion;
      }
    }

    if (schemaVersion != 1) {
      warnings.add(
        LegacyImportWarning(
          code: 'UNSUPPORTED_SCHEMA_VERSION',
          message: 'Schema version $schemaVersion differs from baseline 1',
          field: 'schemaVersion',
        ),
      );
    }

    // 2. Ball positions
    final balls = <BallPosition>[];
    TablePoint? whitePos;
    TablePoint? yellowPos;
    TablePoint? redPos;

    // Main balls: white, yellow, red
    if (json.containsKey('white')) {
      final raw = json['white'];
      final pt = parsePointFromList(raw, 'white', warnings);
      if (pt != null) {
        whitePos = pt;
        balls.add(
          BallPosition(id: 'ball_white', ballType: 'white', position: pt),
        );
      }
    }

    if (json.containsKey('yellow')) {
      final raw = json['yellow'];
      final pt = parsePointFromList(raw, 'yellow', warnings);
      if (pt != null) {
        yellowPos = pt;
        balls.add(
          BallPosition(id: 'ball_yellow', ballType: 'yellow', position: pt),
        );
      }
    }

    if (json.containsKey('red')) {
      final raw = json['red'];
      final pt = parsePointFromList(raw, 'red', warnings);
      if (pt != null) {
        redPos = pt;
        balls.add(BallPosition(id: 'ball_red', ballType: 'red', position: pt));
      }
    }

    // Extra balls (Map format: {"x": 1.5, "y": 3.0, "color": ..., "number": ...})
    if (json.containsKey('extraBalls')) {
      final rawExtra = json['extraBalls'];
      if (rawExtra is List) {
        for (var i = 0; i < rawExtra.length; i++) {
          final item = rawExtra[i];
          final context = 'extraBalls[$i]';
          if (item is Map) {
            final pt = parsePointFromMap(item, context, warnings);
            if (pt != null) {
              final colorHex = parseColorHex(
                item['color'],
                '$context.color',
                warnings,
              );
              final number = item['number']?.toString();
              balls.add(
                BallPosition(
                  id: 'extra_$i',
                  ballType: 'extra',
                  position: pt,
                  label: number,
                  colorHex: colorHex,
                ),
              );
            }
          } else if (item is List) {
            final pt = parsePointFromList(item, context, warnings);
            if (pt != null) {
              balls.add(
                BallPosition(id: 'extra_$i', ballType: 'extra', position: pt),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_BALL',
                message:
                    'Expected Map or List for extra ball, got ${item.runtimeType}',
                field: context,
              ),
            );
          }
        }
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message:
                'Expected List for extraBalls, got ${rawExtra.runtimeType}',
            field: 'extraBalls',
          ),
        );
      }
    }

    // Ghosts (Map format: {"x": 2.0, "y": 4.0, "color": ..., "type": 0, "rotation": 20.0, "number": "1"})
    if (json.containsKey('ghosts')) {
      final rawGhosts = json['ghosts'];
      if (rawGhosts is List) {
        for (var i = 0; i < rawGhosts.length; i++) {
          final item = rawGhosts[i];
          final context = 'ghosts[$i]';
          if (item is Map) {
            final pt = parsePointFromMap(item, context, warnings);
            if (pt != null) {
              final colorHex = parseColorHex(
                item['color'],
                '$context.color',
                warnings,
              );
              final number = item['number']?.toString();
              final rotation = parseOptionalDouble(
                item['rotation'],
                '$context.rotation',
                warnings,
              );
              final legacyType = parseOptionalInt(
                item['type'],
                '$context.type',
                warnings,
              );
              balls.add(
                BallPosition(
                  id: 'ghost_$i',
                  ballType: 'ghost',
                  position: pt,
                  label: number,
                  colorHex: colorHex,
                  rotation: rotation,
                  legacyType: legacyType,
                ),
              );
            }
          } else if (item is List) {
            final pt = parsePointFromList(item, context, warnings);
            if (pt != null) {
              balls.add(
                BallPosition(id: 'ghost_$i', ballType: 'ghost', position: pt),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_BALL',
                message:
                    'Expected Map or List for ghost, got ${item.runtimeType}',
                field: context,
              ),
            );
          }
        }
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message: 'Expected List for ghosts, got ${rawGhosts.runtimeType}',
            field: 'ghosts',
          ),
        );
      }
    }

    // 3. Trajectories
    final trajectories = <TrajectoryLine>[];
    if (json.containsKey('paths')) {
      final rawPaths = json['paths'];
      if (rawPaths is Map) {
        final pathsMap = rawPaths;

        // Path colors lookup
        Map? pathColorsMap;
        if (json.containsKey('pathColors')) {
          final rawPathColors = json['pathColors'];
          if (rawPathColors is Map) {
            pathColorsMap = rawPathColors;
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_FIELD_TYPE',
                message:
                    'Expected Map for pathColors, got ${rawPathColors.runtimeType}',
                field: 'pathColors',
              ),
            );
          }
        }

        List? freePathColorsList;
        if (json.containsKey('freePathColors')) {
          final rawFreeColors = json['freePathColors'];
          if (rawFreeColors is List) {
            freePathColorsList = rawFreeColors;
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_FIELD_TYPE',
                message:
                    'Expected List for freePathColors, got ${rawFreeColors.runtimeType}',
                field: 'freePathColors',
              ),
            );
          }
        }

        // Trajectory waypoints parser helper
        List<TablePoint> parsePolyline(List rawPoints, String pathKey) {
          final pts = <TablePoint>[];
          for (var i = 0; i < rawPoints.length; i++) {
            final item = rawPoints[i];
            final pt = parsePointFromList(item, 'paths.$pathKey[$i]', warnings);
            if (pt != null) {
              pts.add(pt);
            }
          }
          return pts;
        }

        if (pathsMap.containsKey('white')) {
          final raw = pathsMap['white'];
          if (raw is List) {
            final pts = parsePolyline(raw, 'white');
            if (pts.isNotEmpty) {
              final finalPts = whitePos != null ? [whitePos, ...pts] : pts;
              final colorHex =
                  parseColorHex(
                    pathColorsMap?['white'],
                    'pathColors.white',
                    warnings,
                  ) ??
                  '#FFFFFF';
              trajectories.add(
                TrajectoryLine(
                  id: 'traj_white',
                  colorHex: colorHex,
                  points: finalPts,
                ),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_PATH',
                message:
                    'Expected List for paths.white, got ${raw.runtimeType}',
                field: 'paths.white',
              ),
            );
          }
        }

        if (pathsMap.containsKey('yellow')) {
          final raw = pathsMap['yellow'];
          if (raw is List) {
            final pts = parsePolyline(raw, 'yellow');
            if (pts.isNotEmpty) {
              final finalPts = yellowPos != null ? [yellowPos, ...pts] : pts;
              final colorHex =
                  parseColorHex(
                    pathColorsMap?['yellow'],
                    'pathColors.yellow',
                    warnings,
                  ) ??
                  '#FFEB3B';
              trajectories.add(
                TrajectoryLine(
                  id: 'traj_yellow',
                  colorHex: colorHex,
                  points: finalPts,
                ),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_PATH',
                message:
                    'Expected List for paths.yellow, got ${raw.runtimeType}',
                field: 'paths.yellow',
              ),
            );
          }
        }

        if (pathsMap.containsKey('red')) {
          final raw = pathsMap['red'];
          if (raw is List) {
            final pts = parsePolyline(raw, 'red');
            if (pts.isNotEmpty) {
              final finalPts = redPos != null ? [redPos, ...pts] : pts;
              final colorHex =
                  parseColorHex(
                    pathColorsMap?['red'],
                    'pathColors.red',
                    warnings,
                  ) ??
                  '#F44336';
              trajectories.add(
                TrajectoryLine(
                  id: 'traj_red',
                  colorHex: colorHex,
                  points: finalPts,
                ),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_PATH',
                message: 'Expected List for paths.red, got ${raw.runtimeType}',
                field: 'paths.red',
              ),
            );
          }
        }

        if (pathsMap.containsKey('free')) {
          final freeList = pathsMap['free'];
          if (freeList is List) {
            for (var i = 0; i < freeList.length; i++) {
              final item = freeList[i];
              if (item is List) {
                final pts = parsePolyline(item, 'free[$i]');
                if (pts.isNotEmpty) {
                  dynamic freeColorRaw;
                  if (freePathColorsList != null &&
                      i < freePathColorsList.length) {
                    freeColorRaw = freePathColorsList[i];
                  } else {
                    freeColorRaw = pathColorsMap?['free'];
                  }
                  final colorHex =
                      parseColorHex(
                        freeColorRaw,
                        'freePathColors[$i]',
                        warnings,
                      ) ??
                      '#2196F3';
                  trajectories.add(
                    TrajectoryLine(
                      id: 'traj_free_$i',
                      colorHex: colorHex,
                      points: pts,
                    ),
                  );
                }
              } else {
                warnings.add(
                  LegacyImportWarning(
                    code: 'INVALID_LEGACY_PATH',
                    message:
                        'Expected List for paths.free[$i], got ${item.runtimeType}',
                    field: 'paths.free[$i]',
                  ),
                );
              }
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_LEGACY_PATH',
                message:
                    'Expected List for paths.free, got ${freeList.runtimeType}',
                field: 'paths.free',
              ),
            );
          }
        }
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message: 'Expected Map for paths, got ${rawPaths.runtimeType}',
            field: 'paths',
          ),
        );
      }
    }

    // 4. Annotations (labels and cushion numbers)
    final annotations = <SceneAnnotation>[];

    if (json.containsKey('labels')) {
      final rawLabels = json['labels'];
      if (rawLabels is List) {
        for (var i = 0; i < rawLabels.length; i++) {
          final item = rawLabels[i];
          final context = 'labels[$i]';
          if (item is Map) {
            final pt = parsePointFromMap(item, context, warnings);
            if (pt != null) {
              final text = item['text']?.toString() ?? '';
              final colorHex = parseColorHex(
                item['color'],
                '$context.color',
                warnings,
              );
              final rotation = parseOptionalDouble(
                item['rotation'],
                '$context.rotation',
                warnings,
              );
              final role = item['role']?.toString();
              annotations.add(
                SceneAnnotation(
                  id: 'label_$i',
                  text: text,
                  position: pt,
                  colorHex: colorHex,
                  rotation: rotation,
                  role: role,
                ),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_FIELD_TYPE',
                message: 'Expected Map for label, got ${item.runtimeType}',
                field: context,
              ),
            );
          }
        }
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message: 'Expected List for labels, got ${rawLabels.runtimeType}',
            field: 'labels',
          ),
        );
      }
    }

    if (json.containsKey('cushionNumbers')) {
      final rawCushions = json['cushionNumbers'];
      if (rawCushions is List) {
        for (var i = 0; i < rawCushions.length; i++) {
          final item = rawCushions[i];
          final context = 'cushionNumbers[$i]';
          if (item is Map) {
            final pt = parsePointFromMap(item, context, warnings);
            if (pt != null) {
              final text = item['text']?.toString() ?? '';
              final colorHex = parseColorHex(
                item['color'],
                '$context.color',
                warnings,
              );
              final rotation = parseOptionalDouble(
                item['rotation'],
                '$context.rotation',
                warnings,
              );
              final cushionSide = item['cushionSide']?.toString();
              annotations.add(
                SceneAnnotation(
                  id: 'cushion_$i',
                  text: text,
                  position: pt,
                  colorHex: colorHex,
                  rotation: rotation,
                  role: 'cushionNumber',
                  cushionSide: cushionSide,
                ),
              );
            }
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_FIELD_TYPE',
                message:
                    'Expected Map for cushion number, got ${item.runtimeType}',
                field: context,
              ),
            );
          }
        }
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message:
                'Expected List for cushionNumbers, got ${rawCushions.runtimeType}',
            field: 'cushionNumbers',
          ),
        );
      }
    }

    // 5. Cue Instruction & Deferred Effet Fields
    CueInstruction? cueInstruction;
    if (json.containsKey('effet')) {
      final rawEffet = json['effet'];
      if (rawEffet is Map) {
        final effetMap = rawEffet;

        Vec2 tipOffset = Vec2.zero;
        if (effetMap.containsKey('effet')) {
          final offsetList = effetMap['effet'];
          if (offsetList is List &&
              offsetList.length >= 2 &&
              offsetList[0] is num &&
              offsetList[1] is num) {
            tipOffset = Vec2(
              (offsetList[0] as num).toDouble(),
              (offsetList[1] as num).toDouble(),
            );
          } else {
            warnings.add(
              LegacyImportWarning(
                code: 'INVALID_FIELD_TYPE',
                message: 'Expected List with 2 numeric values for effet offset',
                field: 'effet.effet',
              ),
            );
          }
        }

        // Power is unresolved because legacy format stores forceImage asset path, not normalized power
        cueInstruction = CueInstruction(
          power: 0.0,
          direction: const Angle.fromRadians(0.0),
          tipOffset: tipOffset,
          powerIsResolved: false,
        );

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
      } else {
        warnings.add(
          LegacyImportWarning(
            code: 'INVALID_FIELD_TYPE',
            message: 'Expected Map for effet, got ${rawEffet.runtimeType}',
            field: 'effet',
          ),
        );
      }
    }

    // 6. Visual presentation metadata
    int systemIndex = 0;
    if (json.containsKey('system')) {
      systemIndex = parseOptionalInt(json['system'], 'system', warnings) ?? 0;
    }

    int viewTypeIndex = 0;
    if (json.containsKey('viewType')) {
      viewTypeIndex =
          parseOptionalInt(json['viewType'], 'viewType', warnings) ?? 0;
    }

    if (systemIndex < 0 || systemIndex > 5) {
      warnings.add(
        LegacyImportWarning(
          code: 'UNKNOWN_LEGACY_SYSTEM_INDEX',
          message:
              'System index $systemIndex out of legacy DiagramSystem range [0..5]',
          field: 'system',
        ),
      );
    }

    if (viewTypeIndex < 0 || viewTypeIndex > 7) {
      warnings.add(
        LegacyImportWarning(
          code: 'UNKNOWN_LEGACY_VIEW_TYPE_INDEX',
          message:
              'ViewType index $viewTypeIndex out of legacy TableViewType range [0..7]',
          field: 'viewType',
        ),
      );
    }

    double? labelFontSize;
    if (json.containsKey('labelFontSize')) {
      labelFontSize = parseOptionalDouble(
        json['labelFontSize'],
        'labelFontSize',
        warnings,
      );
    }

    final presentationConfig = ScenePresentationConfig(
      legacySystemIndex: systemIndex,
      legacyViewTypeIndex: viewTypeIndex,
      labelFontSize: labelFontSize,
    );

    final now = DateTime.now();

    final scene = BilliardScene(
      id: StableId.generate(),
      name: sceneName ?? 'Imported Legacy Scene',
      tableConfig: const TableConfig(
        type: 'carom_3c',
        widthMeters: 1.42,
        lengthMeters: 2.84,
      ),
      balls: balls,
      trajectories: trajectories,
      annotations: annotations,
      cueInstruction: cueInstruction,
      presentationConfig: presentationConfig,
      teachingTimeline:
          null, // Legacy static diagram does not have teaching timeline
      source: SceneSource.importSource,
      status: SceneStatus.active,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );

    return LegacySceneImportResult(scene: scene, warnings: warnings);
  }
}
