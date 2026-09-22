// Mappers converting between Pure Dart Domain Entities and SQLite Data Models

import 'dart:convert';
import '../../domain/entities/entities.dart';
import '../models/sqlite_models.dart';

class LessonMapper {
  const LessonMapper._();

  static SqliteLessonRow domainToRow(Lesson domain) {
    final sectionsJson = jsonEncode(
      domain.sections
          .map(
            (sec) => {
              'id': sec.id,
              'title': sec.title,
              'order': sec.order,
              'blocks': sec.blocks
                  .map((b) => {'id': b.id, 'type': b.type, 'data': b.data})
                  .toList(),
            },
          )
          .toList(),
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
        final bm = bMap as Map<String, dynamic>;
        return LessonBlock(
          id: bm['id'] as String,
          type: bm['type'] as String,
          data: Map<String, dynamic>.from(bm['data'] as Map? ?? {}),
        );
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
}

class SceneMapper {
  const SceneMapper._();

  static SqliteSceneRow domainToRow(BilliardScene domain) {
    return SqliteSceneRow(
      id: domain.id,
      name: domain.name,
      tableConfigJson: jsonEncode(domain.tableConfig),
      ballsJson: jsonEncode(domain.balls),
      trajectoriesJson: jsonEncode(domain.trajectories),
      annotationsJson: jsonEncode(domain.annotations),
      cueInstructionJson: domain.cueInstruction != null
          ? jsonEncode(domain.cueInstruction)
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
    return BilliardScene(
      id: row.id,
      name: row.name,
      tableConfig: Map<String, dynamic>.from(
        jsonDecode(row.tableConfigJson) as Map? ?? {},
      ),
      balls: (jsonDecode(row.ballsJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      trajectories: (jsonDecode(row.trajectoriesJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      annotations: (jsonDecode(row.annotationsJson) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      cueInstruction: row.cueInstructionJson != null
          ? Map<String, dynamic>.from(
              jsonDecode(row.cueInstructionJson!) as Map,
            )
          : null,
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
