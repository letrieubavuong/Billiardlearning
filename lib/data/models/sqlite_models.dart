// SQLite Data Models for Billiardlearning vNext Tables

class SqliteLessonRow {
  final String id;
  final String? chapterId;
  final String title;
  final String subtitle;
  final String sectionsJson;
  final String status;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const SqliteLessonRow({
    required this.id,
    this.chapterId,
    required this.title,
    required this.subtitle,
    required this.sectionsJson,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'chapter_id': chapterId,
    'title': title,
    'subtitle': subtitle,
    'sections_json': sectionsJson,
    'status': status,
    'version': version,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };

  factory SqliteLessonRow.fromMap(Map<String, dynamic> map) => SqliteLessonRow(
    id: map['id'] as String,
    chapterId: map['chapter_id'] as String?,
    title: map['title'] as String,
    subtitle: map['subtitle'] as String? ?? '',
    sectionsJson: map['sections_json'] as String,
    status: map['status'] as String,
    version: map['version'] as int,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
    deletedAt: map['deleted_at'] as String?,
  );
}

class SqliteSceneRow {
  final String id;
  final String name;
  final String tableConfigJson;
  final String ballsJson;
  final String trajectoriesJson;
  final String annotationsJson;
  final String? cueInstructionJson;
  final String? teachingTimelineJson;
  final String source;
  final String status;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const SqliteSceneRow({
    required this.id,
    required this.name,
    required this.tableConfigJson,
    required this.ballsJson,
    required this.trajectoriesJson,
    required this.annotationsJson,
    this.cueInstructionJson,
    this.teachingTimelineJson,
    required this.source,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'table_config_json': tableConfigJson,
    'balls_json': ballsJson,
    'trajectories_json': trajectoriesJson,
    'annotations_json': annotationsJson,
    'cue_instruction_json': cueInstructionJson,
    'teaching_timeline_json': teachingTimelineJson,
    'source': source,
    'status': status,
    'version': version,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };

  factory SqliteSceneRow.fromMap(Map<String, dynamic> map) => SqliteSceneRow(
    id: map['id'] as String,
    name: map['name'] as String,
    tableConfigJson: map['table_config_json'] as String,
    ballsJson: map['balls_json'] as String,
    trajectoriesJson: map['trajectories_json'] as String,
    annotationsJson: map['annotations_json'] as String,
    cueInstructionJson: map['cue_instruction_json'] as String?,
    teachingTimelineJson: map['teaching_timeline_json'] as String?,
    source: map['source'] as String,
    status: map['status'] as String,
    version: map['version'] as int,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
    deletedAt: map['deleted_at'] as String?,
  );
}

class SqliteTechniqueRow {
  final String id;
  final String name;
  final String groupName;
  final String difficulty;
  final String tagsJson;
  final String content;
  final String sceneIdsJson;
  final String recommendedCueInstructions;
  final String createdAt;
  final String updatedAt;

  const SqliteTechniqueRow({
    required this.id,
    required this.name,
    required this.groupName,
    required this.difficulty,
    required this.tagsJson,
    required this.content,
    required this.sceneIdsJson,
    required this.recommendedCueInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'group_name': groupName,
    'difficulty': difficulty,
    'tags_json': tagsJson,
    'content': content,
    'scene_ids_json': sceneIdsJson,
    'recommended_cue_instructions': recommendedCueInstructions,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SqliteTechniqueRow.fromMap(Map<String, dynamic> map) =>
      SqliteTechniqueRow(
        id: map['id'] as String,
        name: map['name'] as String,
        groupName: map['group_name'] as String,
        difficulty: map['difficulty'] as String,
        tagsJson: map['tags_json'] as String,
        content: map['content'] as String,
        sceneIdsJson: map['scene_ids_json'] as String,
        recommendedCueInstructions:
            map['recommended_cue_instructions'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );
}

class SqliteNumberSystemRow {
  final String id;
  final String name;
  final String description;
  final String variablesJson;
  final String expression;
  final String mappingsJson;
  final String conditionsJson;
  final String exampleSceneIdsJson;
  final String createdAt;
  final String updatedAt;

  const SqliteNumberSystemRow({
    required this.id,
    required this.name,
    required this.description,
    required this.variablesJson,
    required this.expression,
    required this.mappingsJson,
    required this.conditionsJson,
    required this.exampleSceneIdsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'variables_json': variablesJson,
    'expression': expression,
    'mappings_json': mappingsJson,
    'conditions_json': conditionsJson,
    'example_scene_ids_json': exampleSceneIdsJson,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SqliteNumberSystemRow.fromMap(Map<String, dynamic> map) =>
      SqliteNumberSystemRow(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        variablesJson: map['variables_json'] as String,
        expression: map['expression'] as String,
        mappingsJson: map['mappings_json'] as String,
        conditionsJson: map['conditions_json'] as String,
        exampleSceneIdsJson: map['example_scene_ids_json'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );
}

class SqliteExerciseRow {
  final String id;
  final String prompt;
  final String sceneId;
  final String expectedSolutionJson;
  final String evaluationRulesJson;
  final String createdAt;
  final String updatedAt;

  const SqliteExerciseRow({
    required this.id,
    required this.prompt,
    required this.sceneId,
    required this.expectedSolutionJson,
    required this.evaluationRulesJson,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'prompt': prompt,
    'scene_id': sceneId,
    'expected_solution_json': expectedSolutionJson,
    'evaluation_rules_json': evaluationRulesJson,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SqliteExerciseRow.fromMap(Map<String, dynamic> map) =>
      SqliteExerciseRow(
        id: map['id'] as String,
        prompt: map['prompt'] as String,
        sceneId: map['scene_id'] as String,
        expectedSolutionJson: map['expected_solution_json'] as String,
        evaluationRulesJson: map['evaluation_rules_json'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );
}

class SqliteMediaAssetRow {
  final String id;
  final String type;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final String checksum;
  final String createdAt;
  final String updatedAt;

  const SqliteMediaAssetRow({
    required this.id,
    required this.type,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksum,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'local_path': localPath,
    'mime_type': mimeType,
    'size_bytes': sizeBytes,
    'checksum': checksum,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SqliteMediaAssetRow.fromMap(Map<String, dynamic> map) =>
      SqliteMediaAssetRow(
        id: map['id'] as String,
        type: map['type'] as String,
        localPath: map['local_path'] as String,
        mimeType: map['mime_type'] as String,
        sizeBytes: map['size_bytes'] as int,
        checksum: map['checksum'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );
}

class SqliteLearningProgressRow {
  final String id;
  final String entityId;
  final String category;
  final int isCompleted;
  final String? completedAt;

  const SqliteLearningProgressRow({
    required this.id,
    required this.entityId,
    required this.category,
    required this.isCompleted,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entity_id': entityId,
    'category': category,
    'is_completed': isCompleted,
    'completed_at': completedAt,
  };

  factory SqliteLearningProgressRow.fromMap(Map<String, dynamic> map) =>
      SqliteLearningProgressRow(
        id: map['id'] as String,
        entityId: map['entity_id'] as String,
        category: map['category'] as String,
        isCompleted: map['is_completed'] as int,
        completedAt: map['completed_at'] as String?,
      );
}

class SqliteSimulationProfileRow {
  final String id;
  final String name;
  final String tableProfileJson;
  final String frictionModelJson;
  final String cueProfileJson;
  final int isDefault;
  final String createdAt;
  final String updatedAt;

  const SqliteSimulationProfileRow({
    required this.id,
    required this.name,
    required this.tableProfileJson,
    required this.frictionModelJson,
    required this.cueProfileJson,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'table_profile_json': tableProfileJson,
    'friction_model_json': frictionModelJson,
    'cue_profile_json': cueProfileJson,
    'is_default': isDefault,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SqliteSimulationProfileRow.fromMap(Map<String, dynamic> map) =>
      SqliteSimulationProfileRow(
        id: map['id'] as String,
        name: map['name'] as String,
        tableProfileJson: map['table_profile_json'] as String,
        frictionModelJson: map['friction_model_json'] as String,
        cueProfileJson: map['cue_profile_json'] as String,
        isDefault: map['is_default'] as int,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );
}
