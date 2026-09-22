// SQLite Implementations of vNext Repository Contracts with Safe UPSERT Semantics

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../models/database_helper.dart';
import '../mappers/mappers.dart';
import '../models/sqlite_models.dart';

class SqliteLessonRepository implements VNextLessonRepository {
  final DatabaseExecutor? _customDb;

  const SqliteLessonRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<Lesson?> getById(String id, {bool includeDeleted = false}) async {
    final db = await _db;
    final String where = includeDeleted
        ? 'id = ?'
        : 'id = ? AND deleted_at IS NULL AND status != ?';
    final List<Object?> whereArgs = includeDeleted
        ? [id]
        : [id, LessonStatus.deleted.name];

    final maps = await db.query(
      'vnext_lessons',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final row = SqliteLessonRow.fromMap(maps.first);
    return LessonMapper.rowToDomain(row);
  }

  @override
  Future<List<Lesson>> list({bool includeDeleted = false}) async {
    final db = await _db;
    final String? where = includeDeleted
        ? null
        : 'deleted_at IS NULL AND status != ?';
    final List<Object?>? whereArgs = includeDeleted
        ? null
        : [LessonStatus.deleted.name];

    final maps = await db.query(
      'vnext_lessons',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps
        .map((m) => LessonMapper.rowToDomain(SqliteLessonRow.fromMap(m)))
        .toList();
  }

  @override
  Future<void> save(Lesson lesson) async {
    final db = await _db;
    final row = LessonMapper.domainToRow(lesson);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_lessons (id, chapter_id, title, subtitle, sections_json, status, version, created_at, updated_at, deleted_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        chapter_id = excluded.chapter_id,
        title = excluded.title,
        subtitle = excluded.subtitle,
        sections_json = excluded.sections_json,
        status = excluded.status,
        version = excluded.version,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at
    ''',
      [
        map['id'],
        map['chapter_id'],
        map['title'],
        map['subtitle'],
        map['sections_json'],
        map['status'],
        map['version'],
        map['created_at'],
        map['updated_at'],
        map['deleted_at'],
      ],
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_lessons',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restore(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_lessons',
      {'deleted_at': null, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> purge(String id) async {
    final db = await _db;
    await db.delete('vnext_lessons', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteSceneRepository implements VNextSceneRepository {
  final DatabaseExecutor? _customDb;

  const SqliteSceneRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<BilliardScene?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final db = await _db;
    final String where = includeDeleted
        ? 'id = ?'
        : 'id = ? AND deleted_at IS NULL AND status != ?';
    final List<Object?> whereArgs = includeDeleted
        ? [id]
        : [id, SceneStatus.deleted.name];

    final maps = await db.query(
      'vnext_scenes',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final row = SqliteSceneRow.fromMap(maps.first);
    return SceneMapper.rowToDomain(row);
  }

  @override
  Future<List<BilliardScene>> list({bool includeDeleted = false}) async {
    final db = await _db;
    final String? where = includeDeleted
        ? null
        : 'deleted_at IS NULL AND status != ?';
    final List<Object?>? whereArgs = includeDeleted
        ? null
        : [SceneStatus.deleted.name];

    final maps = await db.query(
      'vnext_scenes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps
        .map((m) => SceneMapper.rowToDomain(SqliteSceneRow.fromMap(m)))
        .toList();
  }

  @override
  Future<void> save(BilliardScene scene) async {
    final db = await _db;
    final row = SceneMapper.domainToRow(scene);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_scenes (id, name, table_config_json, balls_json, trajectories_json, annotations_json, cue_instruction_json, teaching_timeline_json, source, status, version, created_at, updated_at, deleted_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        table_config_json = excluded.table_config_json,
        balls_json = excluded.balls_json,
        trajectories_json = excluded.trajectories_json,
        annotations_json = excluded.annotations_json,
        cue_instruction_json = excluded.cue_instruction_json,
        teaching_timeline_json = excluded.teaching_timeline_json,
        source = excluded.source,
        status = excluded.status,
        version = excluded.version,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at
    ''',
      [
        map['id'],
        map['name'],
        map['table_config_json'],
        map['balls_json'],
        map['trajectories_json'],
        map['annotations_json'],
        map['cue_instruction_json'],
        map['teaching_timeline_json'],
        map['source'],
        map['status'],
        map['version'],
        map['created_at'],
        map['updated_at'],
        map['deleted_at'],
      ],
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_scenes',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restore(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_scenes',
      {'deleted_at': null, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> purge(String id) async {
    final db = await _db;
    await db.delete('vnext_scenes', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteTechniqueRepository implements VNextTechniqueRepository {
  final DatabaseExecutor? _customDb;

  const SqliteTechniqueRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<Technique?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_techniques',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TechniqueMapper.rowToDomain(SqliteTechniqueRow.fromMap(maps.first));
  }

  @override
  Future<List<Technique>> list() async {
    final db = await _db;
    final maps = await db.query('vnext_techniques', orderBy: 'name ASC');
    return maps
        .map((m) => TechniqueMapper.rowToDomain(SqliteTechniqueRow.fromMap(m)))
        .toList();
  }

  @override
  Future<void> save(Technique technique) async {
    final db = await _db;
    final row = TechniqueMapper.domainToRow(technique);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_techniques (id, name, group_name, difficulty, tags_json, content, scene_ids_json, recommended_cue_instructions, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        group_name = excluded.group_name,
        difficulty = excluded.difficulty,
        tags_json = excluded.tags_json,
        content = excluded.content,
        scene_ids_json = excluded.scene_ids_json,
        recommended_cue_instructions = excluded.recommended_cue_instructions,
        updated_at = excluded.updated_at
    ''',
      [
        map['id'],
        map['name'],
        map['group_name'],
        map['difficulty'],
        map['tags_json'],
        map['content'],
        map['scene_ids_json'],
        map['recommended_cue_instructions'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vnext_techniques', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteNumberSystemRepository implements VNextNumberSystemRepository {
  final DatabaseExecutor? _customDb;

  const SqliteNumberSystemRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<NumberSystem?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_number_systems',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return NumberSystemMapper.rowToDomain(
      SqliteNumberSystemRow.fromMap(maps.first),
    );
  }

  @override
  Future<List<NumberSystem>> list() async {
    final db = await _db;
    final maps = await db.query('vnext_number_systems', orderBy: 'name ASC');
    return maps
        .map(
          (m) =>
              NumberSystemMapper.rowToDomain(SqliteNumberSystemRow.fromMap(m)),
        )
        .toList();
  }

  @override
  Future<void> save(NumberSystem system) async {
    final db = await _db;
    final row = NumberSystemMapper.domainToRow(system);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_number_systems (id, name, description, variables_json, expression, mappings_json, conditions_json, example_scene_ids_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        description = excluded.description,
        variables_json = excluded.variables_json,
        expression = excluded.expression,
        mappings_json = excluded.mappings_json,
        conditions_json = excluded.conditions_json,
        example_scene_ids_json = excluded.example_scene_ids_json,
        updated_at = excluded.updated_at
    ''',
      [
        map['id'],
        map['name'],
        map['description'],
        map['variables_json'],
        map['expression'],
        map['mappings_json'],
        map['conditions_json'],
        map['example_scene_ids_json'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vnext_number_systems', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteExerciseRepository implements VNextExerciseRepository {
  final DatabaseExecutor? _customDb;

  const SqliteExerciseRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<Exercise?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExerciseMapper.rowToDomain(SqliteExerciseRow.fromMap(maps.first));
  }

  @override
  Future<List<Exercise>> list() async {
    final db = await _db;
    final maps = await db.query('vnext_exercises', orderBy: 'created_at DESC');
    return maps
        .map((m) => ExerciseMapper.rowToDomain(SqliteExerciseRow.fromMap(m)))
        .toList();
  }

  @override
  Future<void> save(Exercise exercise) async {
    final db = await _db;
    final row = ExerciseMapper.domainToRow(exercise);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_exercises (id, prompt, scene_id, expected_solution_json, evaluation_rules_json, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        prompt = excluded.prompt,
        scene_id = excluded.scene_id,
        expected_solution_json = excluded.expected_solution_json,
        evaluation_rules_json = excluded.evaluation_rules_json,
        updated_at = excluded.updated_at
    ''',
      [
        map['id'],
        map['prompt'],
        map['scene_id'],
        map['expected_solution_json'],
        map['evaluation_rules_json'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vnext_exercises', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteMediaRepository implements VNextMediaRepository {
  final DatabaseExecutor? _customDb;

  const SqliteMediaRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<MediaAsset?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_media_assets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MediaAssetMapper.rowToDomain(
      SqliteMediaAssetRow.fromMap(maps.first),
    );
  }

  @override
  Future<List<MediaAsset>> list() async {
    final db = await _db;
    final maps = await db.query(
      'vnext_media_assets',
      orderBy: 'created_at DESC',
    );
    return maps
        .map(
          (m) => MediaAssetMapper.rowToDomain(SqliteMediaAssetRow.fromMap(m)),
        )
        .toList();
  }

  @override
  Future<void> save(MediaAsset asset) async {
    final db = await _db;
    final row = MediaAssetMapper.domainToRow(asset);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_media_assets (id, type, local_path, mime_type, size_bytes, checksum, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        type = excluded.type,
        local_path = excluded.local_path,
        mime_type = excluded.mime_type,
        size_bytes = excluded.size_bytes,
        checksum = excluded.checksum,
        updated_at = excluded.updated_at
    ''',
      [
        map['id'],
        map['type'],
        map['local_path'],
        map['mime_type'],
        map['size_bytes'],
        map['checksum'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('vnext_media_assets', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteLearningProgressRepository
    implements VNextLearningProgressRepository {
  final DatabaseExecutor? _customDb;

  const SqliteLearningProgressRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<LearningProgressRecord?> getByEntityId(String entityId) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_learning_progress',
      where: 'entity_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LearningProgressMapper.rowToDomain(
      SqliteLearningProgressRow.fromMap(maps.first),
    );
  }

  @override
  Future<List<LearningProgressRecord>> listAll() async {
    final db = await _db;
    final maps = await db.query('vnext_learning_progress');
    return maps
        .map(
          (m) => LearningProgressMapper.rowToDomain(
            SqliteLearningProgressRow.fromMap(m),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveProgress(LearningProgressRecord record) async {
    final db = await _db;
    final row = LearningProgressMapper.domainToRow(record);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_learning_progress (id, entity_id, category, is_completed, completed_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(entity_id) DO UPDATE SET
        category = excluded.category,
        is_completed = excluded.is_completed,
        completed_at = excluded.completed_at
    ''',
      [
        map['id'],
        map['entity_id'],
        map['category'],
        map['is_completed'],
        map['completed_at'],
      ],
    );
  }
}

class SqliteSimulationProfileRepository
    implements VNextSimulationProfileRepository {
  final DatabaseExecutor? _customDb;

  const SqliteSimulationProfileRepository([this._customDb]);

  Future<DatabaseExecutor> get _db async =>
      _customDb ?? await DatabaseHelper.instance.database;

  @override
  Future<SimulationProfile?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_simulation_profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SimulationProfileMapper.rowToDomain(
      SqliteSimulationProfileRow.fromMap(maps.first),
    );
  }

  @override
  Future<SimulationProfile?> getDefault() async {
    final db = await _db;
    final maps = await db.query(
      'vnext_simulation_profiles',
      where: 'is_default = 1',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SimulationProfileMapper.rowToDomain(
      SqliteSimulationProfileRow.fromMap(maps.first),
    );
  }

  @override
  Future<List<SimulationProfile>> list() async {
    final db = await _db;
    final maps = await db.query(
      'vnext_simulation_profiles',
      orderBy: 'name ASC',
    );
    return maps
        .map(
          (m) => SimulationProfileMapper.rowToDomain(
            SqliteSimulationProfileRow.fromMap(m),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(SimulationProfile profile) async {
    final db = await _db;
    final row = SimulationProfileMapper.domainToRow(profile);
    final map = row.toMap();

    await db.rawInsert(
      '''
      INSERT INTO vnext_simulation_profiles (id, name, table_profile_json, friction_model_json, cue_profile_json, is_default, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        table_profile_json = excluded.table_profile_json,
        friction_model_json = excluded.friction_model_json,
        cue_profile_json = excluded.cue_profile_json,
        is_default = excluded.is_default,
        updated_at = excluded.updated_at
    ''',
      [
        map['id'],
        map['name'],
        map['table_profile_json'],
        map['friction_model_json'],
        map['cue_profile_json'],
        map['is_default'],
        map['created_at'],
        map['updated_at'],
      ],
    );
  }
}
