// Mappers converting between Pure Dart Domain Entities and SQLite Data Models

import 'dart:convert';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/sqlite_models.dart';

class LessonMapper {
  const LessonMapper._();

  static SqliteLessonRow domainToRow(Lesson domain) {
    final sectionsJson = jsonEncode(
      domain.sections.map((sec) {
        return {
          'id': sec.id,
          'title': sec.title,
          'order': sec.order,
          'blocks': sec.blocks.map(_blockToJson).toList(),
        };
      }).toList(),
    );

    return SqliteLessonRow(
      id: domain.id,
      chapterId: domain.chapterId,
      title: domain.title,
      subtitle: domain.subtitle,
      sectionsJson: sectionsJson,
      status: domain.status.name,
      version: domain.version,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      deletedAt: domain.deletedAt?.toIso8601String(),
    );
  }

  static Lesson rowToDomain(SqliteLessonRow row) {
    final decodedSections = jsonDecode(row.sectionsJson) as List<dynamic>;
    final sections = decodedSections.map((secMap) {
      final m = secMap as Map<String, dynamic>;
      final blocksList = (m['blocks'] as List<dynamic>? ?? []).map((bMap) {
        return _jsonToBlock(Map<String, dynamic>.from(bMap as Map));
      }).toList();

      return LessonSection(
        id: m['id'] as String,
        title: m['title'] as String,
        order: m['order'] as int,
        blocks: blocksList,
      );
    }).toList();

    return Lesson(
      id: row.id,
      chapterId: row.chapterId,
      title: row.title,
      subtitle: row.subtitle,
      sections: sections,
      status: LessonStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => LessonStatus.draft,
      ),
      version: row.version,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      deletedAt: row.deletedAt != null ? DateTime.parse(row.deletedAt!) : null,
    );
  }

  static Map<String, dynamic> _blockToJson(LessonBlock b) {
    if (b is TextBlock) {
      return {
        'id': b.id,
        'type': 'text',
        'data': {'text': b.text},
      };
    } else if (b is SceneReferenceBlock) {
      return {
        'id': b.id,
        'type': 'sceneReference',
        'data': {'sceneId': b.sceneId, 'caption': b.caption},
      };
    } else if (b is MediaReferenceBlock) {
      return {
        'id': b.id,
        'type': 'mediaReference',
        'data': {'mediaAssetId': b.mediaAssetId, 'caption': b.caption},
      };
    } else if (b is TechniqueReferenceBlock) {
      return {
        'id': b.id,
        'type': 'techniqueReference',
        'data': {'techniqueId': b.techniqueId},
      };
    } else if (b is NumberSystemReferenceBlock) {
      return {
        'id': b.id,
        'type': 'numberSystemReference',
        'data': {'numberSystemId': b.numberSystemId},
      };
    } else if (b is ExerciseReferenceBlock) {
      return {
        'id': b.id,
        'type': 'exerciseReference',
        'data': {'exerciseId': b.exerciseId},
      };
    } else if (b is CustomLessonBlock) {
      return {'id': b.id, 'type': b.customType, 'data': b.data};
    }
    return {'id': b.id, 'type': b.blockType, 'data': {}};
  }

  static LessonBlock _jsonToBlock(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});

    switch (type) {
      case 'text':
        return TextBlock(id: id, text: data['text'] as String? ?? '');
      case 'sceneReference':
        return SceneReferenceBlock(
          id: id,
          sceneId: data['sceneId'] as String? ?? '',
          caption: data['caption'] as String? ?? '',
        );
      case 'mediaReference':
        return MediaReferenceBlock(
          id: id,
          mediaAssetId: data['mediaAssetId'] as String? ?? '',
          caption: data['caption'] as String? ?? '',
        );
      case 'techniqueReference':
        return TechniqueReferenceBlock(
          id: id,
          techniqueId: data['techniqueId'] as String? ?? '',
        );
      case 'numberSystemReference':
        return NumberSystemReferenceBlock(
          id: id,
          numberSystemId: data['numberSystemId'] as String? ?? '',
        );
      case 'exerciseReference':
        return ExerciseReferenceBlock(
          id: id,
          exerciseId: data['exerciseId'] as String? ?? '',
        );
      default:
        return CustomLessonBlock(id: id, customType: type, data: data);
    }
  }
}

class SceneMapper {
  const SceneMapper._();

  static SqliteSceneRow domainToRow(BilliardScene domain) {
    final tableConfigMap = {
      'type': domain.tableConfig.type,
      'widthMeters': domain.tableConfig.widthMeters,
      'lengthMeters': domain.tableConfig.lengthMeters,
    };

    final ballsList = domain.balls
        .map(
          (b) => {
            'id': b.id,
            'ballType': b.ballType,
            'position': {'u': b.position.u, 'v': b.position.v},
          },
        )
        .toList();

    final trajectoriesList = domain.trajectories
        .map(
          (t) => {
            'id': t.id,
            'colorHex': t.colorHex,
            'points': t.points.map((p) => {'u': p.u, 'v': p.v}).toList(),
          },
        )
        .toList();

    final annotationsList = domain.annotations
        .map(
          (a) => {
            'id': a.id,
            'text': a.text,
            'position': {'u': a.position.u, 'v': a.position.v},
          },
        )
        .toList();

    final cueInstructionMap = domain.cueInstruction != null
        ? {
            'power': domain.cueInstruction!.power,
            'directionRadians': domain.cueInstruction!.direction.radians,
            'tipOffset': {
              'x': domain.cueInstruction!.tipOffset.x,
              'y': domain.cueInstruction!.tipOffset.y,
            },
          }
        : null;

    return SqliteSceneRow(
      id: domain.id,
      name: domain.name,
      tableConfigJson: jsonEncode(tableConfigMap),
      ballsJson: jsonEncode(ballsList),
      trajectoriesJson: jsonEncode(trajectoriesList),
      annotationsJson: jsonEncode(annotationsList),
      cueInstructionJson: cueInstructionMap != null
          ? jsonEncode(cueInstructionMap)
          : null,
      teachingTimelineJson: domain.teachingTimeline != null
          ? jsonEncode(domain.teachingTimeline)
          : null,
      source: domain.source.name,
      status: domain.status.name,
      version: domain.version,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      deletedAt: domain.deletedAt?.toIso8601String(),
    );
  }

  static BilliardScene rowToDomain(SqliteSceneRow row) {
    final tcMap = Map<String, dynamic>.from(
      jsonDecode(row.tableConfigJson) as Map,
    );
    final tableConfig = TableConfig(
      type: tcMap['type'] as String? ?? 'carom_3c',
      widthMeters: (tcMap['widthMeters'] as num?)?.toDouble() ?? 1.42,
      lengthMeters: (tcMap['lengthMeters'] as num?)?.toDouble() ?? 2.84,
    );

    final ballsList = (jsonDecode(row.ballsJson) as List<dynamic>).map((b) {
      final bm = Map<String, dynamic>.from(b as Map);
      final pos = Map<String, dynamic>.from(bm['position'] as Map);
      return BallPosition(
        id: bm['id'] as String,
        ballType: bm['ballType'] as String,
        position: TablePoint(
          (pos['u'] as num).toDouble(),
          (pos['v'] as num).toDouble(),
        ),
      );
    }).toList();

    final trajectoriesList = (jsonDecode(row.trajectoriesJson) as List<dynamic>)
        .map((t) {
          final tm = Map<String, dynamic>.from(t as Map);
          final pts = (tm['points'] as List<dynamic>).map((p) {
            final pm = Map<String, dynamic>.from(p as Map);
            return TablePoint(
              (pm['u'] as num).toDouble(),
              (pm['v'] as num).toDouble(),
            );
          }).toList();

          return TrajectoryLine(
            id: tm['id'] as String,
            colorHex: tm['colorHex'] as String? ?? '#FFFFFF',
            points: pts,
          );
        })
        .toList();

    final annotationsList = (jsonDecode(row.annotationsJson) as List<dynamic>)
        .map((a) {
          final am = Map<String, dynamic>.from(a as Map);
          final pos = Map<String, dynamic>.from(am['position'] as Map);
          return SceneAnnotation(
            id: am['id'] as String,
            text: am['text'] as String,
            position: TablePoint(
              (pos['u'] as num).toDouble(),
              (pos['v'] as num).toDouble(),
            ),
          );
        })
        .toList();

    CueInstruction? cueInstruction;
    if (row.cueInstructionJson != null) {
      final cm = Map<String, dynamic>.from(
        jsonDecode(row.cueInstructionJson!) as Map,
      );
      final tip = Map<String, dynamic>.from(cm['tipOffset'] as Map);
      cueInstruction = CueInstruction(
        power: (cm['power'] as num).toDouble(),
        direction: Angle.fromRadians(
          (cm['directionRadians'] as num).toDouble(),
        ),
        tipOffset: Vec2(
          (tip['x'] as num).toDouble(),
          (tip['y'] as num).toDouble(),
        ),
      );
    }

    return BilliardScene(
      id: row.id,
      name: row.name,
      tableConfig: tableConfig,
      balls: ballsList,
      trajectories: trajectoriesList,
      annotations: annotationsList,
      cueInstruction: cueInstruction,
      teachingTimeline: row.teachingTimelineJson != null
          ? Map<String, dynamic>.from(
              jsonDecode(row.teachingTimelineJson!) as Map,
            )
          : null,
      source: SceneSource.values.firstWhere(
        (e) => e.name == row.source,
        orElse: () => SceneSource.manual,
      ),
      status: SceneStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => SceneStatus.active,
      ),
      version: row.version,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      deletedAt: row.deletedAt != null ? DateTime.parse(row.deletedAt!) : null,
    );
  }
}

class TechniqueMapper {
  const TechniqueMapper._();

  static SqliteTechniqueRow domainToRow(Technique domain) {
    return SqliteTechniqueRow(
      id: domain.id,
      name: domain.name,
      groupName: domain.groupName,
      difficulty: domain.difficulty,
      tagsJson: jsonEncode(domain.tags),
      content: domain.content,
      sceneIdsJson: jsonEncode(domain.sceneIds),
      recommendedCueInstructions: domain.recommendedCueInstructions,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
    );
  }

  static Technique rowToDomain(SqliteTechniqueRow row) {
    return Technique(
      id: row.id,
      name: row.name,
      groupName: row.groupName,
      difficulty: row.difficulty,
      tags: List<String>.from(jsonDecode(row.tagsJson) as List),
      content: row.content,
      sceneIds: List<String>.from(jsonDecode(row.sceneIdsJson) as List),
      recommendedCueInstructions: row.recommendedCueInstructions,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}

class NumberSystemMapper {
  const NumberSystemMapper._();

  static SqliteNumberSystemRow domainToRow(NumberSystem domain) {
    return SqliteNumberSystemRow(
      id: domain.id,
      name: domain.name,
      description: domain.description,
      variablesJson: jsonEncode(domain.variables),
      expression: domain.expression,
      mappingsJson: jsonEncode(domain.mappings),
      conditionsJson: jsonEncode(domain.conditions),
      exampleSceneIdsJson: jsonEncode(domain.exampleSceneIds),
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
    );
  }

  static NumberSystem rowToDomain(SqliteNumberSystemRow row) {
    return NumberSystem(
      id: row.id,
      name: row.name,
      description: row.description,
      variables: Map<String, dynamic>.from(
        jsonDecode(row.variablesJson) as Map? ?? {},
      ),
      expression: row.expression,
      mappings: (jsonDecode(row.mappingsJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      conditions: (jsonDecode(row.conditionsJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      exampleSceneIds: List<String>.from(
        jsonDecode(row.exampleSceneIdsJson) as List,
      ),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}

class ExerciseMapper {
  const ExerciseMapper._();

  static SqliteExerciseRow domainToRow(Exercise domain) {
    return SqliteExerciseRow(
      id: domain.id,
      prompt: domain.prompt,
      sceneId: domain.sceneId,
      expectedSolutionJson: jsonEncode(domain.expectedSolution),
      evaluationRulesJson: jsonEncode(domain.evaluationRules),
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
    );
  }

  static Exercise rowToDomain(SqliteExerciseRow row) {
    return Exercise(
      id: row.id,
      prompt: row.prompt,
      sceneId: row.sceneId,
      expectedSolution: Map<String, dynamic>.from(
        jsonDecode(row.expectedSolutionJson) as Map? ?? {},
      ),
      evaluationRules: Map<String, dynamic>.from(
        jsonDecode(row.evaluationRulesJson) as Map? ?? {},
      ),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}

class MediaAssetMapper {
  const MediaAssetMapper._();

  static SqliteMediaAssetRow domainToRow(MediaAsset domain) {
    return SqliteMediaAssetRow(
      id: domain.id,
      type: domain.type.name,
      localPath: domain.localPath,
      mimeType: domain.mimeType,
      sizeBytes: domain.sizeBytes,
      checksum: domain.checksum,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
    );
  }

  static MediaAsset rowToDomain(SqliteMediaAssetRow row) {
    return MediaAsset(
      id: row.id,
      type: MediaType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => MediaType.image,
      ),
      localPath: row.localPath,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      checksum: row.checksum,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}

class LearningProgressMapper {
  const LearningProgressMapper._();

  static SqliteLearningProgressRow domainToRow(LearningProgressRecord domain) {
    return SqliteLearningProgressRow(
      id: domain.id,
      entityId: domain.entityId,
      category: domain.category,
      isCompleted: domain.isCompleted ? 1 : 0,
      completedAt: domain.completedAt?.toIso8601String(),
    );
  }

  static LearningProgressRecord rowToDomain(SqliteLearningProgressRow row) {
    return LearningProgressRecord(
      id: row.id,
      entityId: row.entityId,
      category: row.category,
      isCompleted: row.isCompleted == 1,
      completedAt: row.completedAt != null
          ? DateTime.parse(row.completedAt!)
          : null,
    );
  }
}

class SimulationProfileMapper {
  const SimulationProfileMapper._();

  static SqliteSimulationProfileRow domainToRow(SimulationProfile domain) {
    return SqliteSimulationProfileRow(
      id: domain.id,
      name: domain.name,
      tableProfileJson: jsonEncode(domain.tableProfile),
      frictionModelJson: jsonEncode(domain.frictionModel),
      cueProfileJson: jsonEncode(domain.cueProfile),
      isDefault: domain.isDefault ? 1 : 0,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
    );
  }

  static SimulationProfile rowToDomain(SqliteSimulationProfileRow row) {
    return SimulationProfile(
      id: row.id,
      name: row.name,
      tableProfile: Map<String, dynamic>.from(
        jsonDecode(row.tableProfileJson) as Map? ?? {},
      ),
      frictionModel: Map<String, dynamic>.from(
        jsonDecode(row.frictionModelJson) as Map? ?? {},
      ),
      cueProfile: Map<String, dynamic>.from(
        jsonDecode(row.cueProfileJson) as Map? ?? {},
      ),
      isDefault: row.isDefault == 1,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}
