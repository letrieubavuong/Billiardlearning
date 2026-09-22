// Pure Dart Domain Entities for Billiardlearning vNext Architecture

import '../value_objects/value_objects.dart';

enum SceneSource { manual, camera, importSource, generated }

enum SceneStatus { active, archived, deleted }

enum LessonStatus { draft, ready, published, archived, deleted }

enum MediaType { image, video, audio }

// --- SCENE SKELETON TYPED CLASSES ---

class TableConfig {
  final String type;
  final double widthMeters;
  final double lengthMeters;

  const TableConfig({
    this.type = 'carom_3c',
    this.widthMeters = 1.42,
    this.lengthMeters = 2.84,
  });
}

class BallPosition {
  final String id;
  final String ballType;
  final TablePoint position;

  const BallPosition({
    required this.id,
    required this.ballType,
    required this.position,
  });
}

class TrajectoryLine {
  final String id;
  final String colorHex;
  final List<TablePoint> points;

  const TrajectoryLine({
    required this.id,
    this.colorHex = '#FFFFFF',
    this.points = const [],
  });
}

class SceneAnnotation {
  final String id;
  final String text;
  final TablePoint position;

  const SceneAnnotation({
    required this.id,
    required this.text,
    required this.position,
  });
}

class CueInstruction {
  final double power;
  final Angle direction;
  final Vec2 tipOffset;

  const CueInstruction({
    this.power = 0.0,
    this.direction = const Angle.fromRadians(0.0),
    this.tipOffset = Vec2.zero,
  });
}

class BilliardScene {
  final String id;
  final String name;
  final TableConfig tableConfig;
  final List<BallPosition> balls;
  final List<TrajectoryLine> trajectories;
  final List<SceneAnnotation> annotations;
  final CueInstruction? cueInstruction;
  final Map<String, dynamic>? teachingTimeline;
  final SceneSource source;
  final SceneStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BilliardScene({
    required this.id,
    required this.name,
    this.tableConfig = const TableConfig(),
    this.balls = const [],
    this.trajectories = const [],
    this.annotations = const [],
    this.cueInstruction,
    this.teachingTimeline,
    this.source = SceneSource.manual,
    this.status = SceneStatus.active,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => status == SceneStatus.deleted || deletedAt != null;

  BilliardScene copyWith({
    String? id,
    String? name,
    TableConfig? tableConfig,
    List<BallPosition>? balls,
    List<TrajectoryLine>? trajectories,
    List<SceneAnnotation>? annotations,
    CueInstruction? cueInstruction,
    Map<String, dynamic>? teachingTimeline,
    SceneSource? source,
    SceneStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BilliardScene(
      id: id ?? this.id,
      name: name ?? this.name,
      tableConfig: tableConfig ?? this.tableConfig,
      balls: balls ?? this.balls,
      trajectories: trajectories ?? this.trajectories,
      annotations: annotations ?? this.annotations,
      cueInstruction: cueInstruction ?? this.cueInstruction,
      teachingTimeline: teachingTimeline ?? this.teachingTimeline,
      source: source ?? this.source,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

// --- TYPE-SAFE LESSON BLOCK HIERARCHY ---

abstract class LessonBlock {
  final String id;

  const LessonBlock({required this.id});

  String get blockType;
}

class TextBlock extends LessonBlock {
  final String text;

  const TextBlock({required String id, required this.text}) : super(id: id);

  @override
  String get blockType => 'text';
}

class SceneReferenceBlock extends LessonBlock {
  final String sceneId;
  final String caption;

  const SceneReferenceBlock({
    required String id,
    required this.sceneId,
    this.caption = '',
  }) : super(id: id);

  @override
  String get blockType => 'sceneReference';
}

class MediaReferenceBlock extends LessonBlock {
  final String mediaAssetId;
  final String caption;

  const MediaReferenceBlock({
    required String id,
    required this.mediaAssetId,
    this.caption = '',
  }) : super(id: id);

  @override
  String get blockType => 'mediaReference';
}

class TechniqueReferenceBlock extends LessonBlock {
  final String techniqueId;

  const TechniqueReferenceBlock({required String id, required this.techniqueId})
    : super(id: id);

  @override
  String get blockType => 'techniqueReference';
}

class NumberSystemReferenceBlock extends LessonBlock {
  final String numberSystemId;

  const NumberSystemReferenceBlock({
    required String id,
    required this.numberSystemId,
  }) : super(id: id);

  @override
  String get blockType => 'numberSystemReference';
}

class ExerciseReferenceBlock extends LessonBlock {
  final String exerciseId;

  const ExerciseReferenceBlock({required String id, required this.exerciseId})
    : super(id: id);

  @override
  String get blockType => 'exerciseReference';
}

class CustomLessonBlock extends LessonBlock {
  final String customType;
  final Map<String, dynamic> data;

  const CustomLessonBlock({
    required String id,
    required this.customType,
    this.data = const {},
  }) : super(id: id);

  @override
  String get blockType => customType;
}

class LessonSection {
  final String id;
  final String title;
  final int order;
  final List<LessonBlock> blocks;

  const LessonSection({
    required this.id,
    required this.title,
    required this.order,
    this.blocks = const [],
  });
}

class Lesson {
  final String id;
  final String? chapterId;
  final String title;
  final String subtitle;
  final List<LessonSection> sections;
  final LessonStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Lesson({
    required this.id,
    this.chapterId,
    required this.title,
    this.subtitle = '',
    this.sections = const [],
    this.status = LessonStatus.draft,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => status == LessonStatus.deleted || deletedAt != null;

  Lesson copyWith({
    String? id,
    String? chapterId,
    String? title,
    String? subtitle,
    List<LessonSection>? sections,
    LessonStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sections: sections ?? this.sections,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class Technique {
  final String id;
  final String name;
  final String groupName;
  final String difficulty;
  final List<String> tags;
  final String content;
  final List<String> sceneIds;
  final String recommendedCueInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Technique({
    required this.id,
    required this.name,
    required this.groupName,
    this.difficulty = 'medium',
    this.tags = const [],
    this.content = '',
    this.sceneIds = const [],
    this.recommendedCueInstructions = '',
    required this.createdAt,
    required this.updatedAt,
  });
}

class NumberSystem {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> variables;
  final String expression;
  final List<Map<String, dynamic>> mappings;
  final List<Map<String, dynamic>> conditions;
  final List<String> exampleSceneIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NumberSystem({
    required this.id,
    required this.name,
    this.description = '',
    this.variables = const {},
    this.expression = '',
    this.mappings = const [],
    this.conditions = const [],
    this.exampleSceneIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });
}

class Exercise {
  final String id;
  final String prompt;
  final String sceneId;
  final Map<String, dynamic> expectedSolution;
  final Map<String, dynamic> evaluationRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Exercise({
    required this.id,
    required this.prompt,
    required this.sceneId,
    this.expectedSolution = const {},
    this.evaluationRules = const {},
    required this.createdAt,
    required this.updatedAt,
  });
}

class MediaAsset {
  final String id;
  final MediaType type;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final String checksum;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaAsset({
    required this.id,
    required this.type,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksum,
    required this.createdAt,
    required this.updatedAt,
  });
}

class LearningProgressRecord {
  final String id;
  final String entityId;
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;

  const LearningProgressRecord({
    required this.id,
    required this.entityId,
    required this.category,
    required this.isCompleted,
    this.completedAt,
  });
}

class SimulationProfile {
  final String id;
  final String name;
  final Map<String, dynamic> tableProfile;
  final Map<String, dynamic> frictionModel;
  final Map<String, dynamic> cueProfile;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SimulationProfile({
    required this.id,
    required this.name,
    this.tableProfile = const {},
    this.frictionModel = const {},
    this.cueProfile = const {},
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
