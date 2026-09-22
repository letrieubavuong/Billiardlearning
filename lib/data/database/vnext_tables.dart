// DDL Schema and table creation for vNext SQLite tables in Billiardlearning

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class VNextTables {
  const VNextTables._();

  static Future<void> createAll(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_lessons (
        id TEXT PRIMARY KEY,
        chapter_id TEXT,
        title TEXT NOT NULL,
        subtitle TEXT,
        sections_json TEXT NOT NULL,
        status TEXT NOT NULL,
        version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_scenes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        table_config_json TEXT NOT NULL,
        balls_json TEXT NOT NULL,
        trajectories_json TEXT NOT NULL,
        annotations_json TEXT NOT NULL,
        cue_instruction_json TEXT,
        teaching_timeline_json TEXT,
        source TEXT NOT NULL,
        status TEXT NOT NULL,
        version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_techniques (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        tags_json TEXT NOT NULL,
        content TEXT NOT NULL,
        scene_ids_json TEXT NOT NULL,
        recommended_cue_instructions TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_number_systems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        variables_json TEXT NOT NULL,
        expression TEXT NOT NULL,
        mappings_json TEXT NOT NULL,
        conditions_json TEXT NOT NULL,
        example_scene_ids_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_exercises (
        id TEXT PRIMARY KEY,
        prompt TEXT NOT NULL,
        scene_id TEXT NOT NULL,
        expected_solution_json TEXT NOT NULL,
        evaluation_rules_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_media_assets (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_learning_progress (
        id TEXT PRIMARY KEY,
        entity_id TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vnext_simulation_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        table_profile_json TEXT NOT NULL,
        friction_model_json TEXT NOT NULL,
        cue_profile_json TEXT NOT NULL,
        is_default INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for efficient querying and soft delete filtering
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_vnext_lessons_status_deleted '
      'ON vnext_lessons(status, deleted_at)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_vnext_scenes_status_deleted '
      'ON vnext_scenes(status, deleted_at)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_vnext_techniques_group '
      'ON vnext_techniques(group_name)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_vnext_exercises_scene '
      'ON vnext_exercises(scene_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_vnext_progress_entity '
      'ON vnext_learning_progress(entity_id)',
    );
  }
}
