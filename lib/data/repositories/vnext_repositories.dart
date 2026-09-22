// SQLite Implementations of vNext Repository Contracts

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
  Future<Lesson?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_lessons',
      where: 'id = ?',
      whereArgs: [id],
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
    await db.insert(
      'vnext_lessons',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_lessons',
      {
        'status': LessonStatus.deleted.name,
        'deleted_at': now,
        'updated_at': now,
      },
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
      {
        'status': LessonStatus.draft.name,
        'deleted_at': null,
        'updated_at': now,
      },
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
  Future<BilliardScene?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'vnext_scenes',
      where: 'id = ?',
      whereArgs: [id],
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
    await db.insert(
      'vnext_scenes',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'vnext_scenes',
      {
        'status': SceneStatus.deleted.name,
        'deleted_at': now,
        'updated_at': now,
      },
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
      {
        'status': SceneStatus.active.name,
        'deleted_at': null,
        'updated_at': now,
      },
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
    await db.insert(
      'vnext_techniques',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.insert(
      'vnext_number_systems',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.insert(
      'vnext_exercises',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.insert(
      'vnext_media_assets',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.insert(
      'vnext_learning_progress',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.insert(
      'vnext_simulation_profiles',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
