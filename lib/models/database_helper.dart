import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../data/database/vnext_tables.dart';
import 'note_model.dart';
import 'system_notes.dart';

class DatabaseHelper {
  static const _databaseVersion = 3;
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('libre_billiard.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _migrateOrSeed,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        blocks TEXT NOT NULL,
        date TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await _createMetadataTable(db);
    await _createIndexes(db);
    await VNextTables.createAll(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createMetadataTable(db);
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      await VNextTables.createAll(db);
    }
  }

  Future<void> _createMetadataTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS index_notes_category_date '
      'ON notes(category, date)',
    );
  }

  Future<void> _migrateOrSeed(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final marker = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['initial_data_migrated'],
      limit: 1,
    );
    if (marker.isNotEmpty) return;

    if (prefs.getBool('sqlite_migrated') ?? false) {
      await db.insert('app_metadata', {
        'key': 'initial_data_migrated',
        'value': 'true',
      });
      return;
    }

    await db.transaction((txn) async {
      await _migrateCategory(
        txn,
        category: 'coban',
        jsonData: prefs.getString('user_coban'),
        defaults: SystemDefaultNotes.getCoBanNotes(),
      );
      await _migrateCategory(
        txn,
        category: 'boso',
        jsonData: prefs.getString('user_systems'),
        defaults: SystemDefaultNotes.getBoSoNotes(),
      );
      await _migrateCategory(
        txn,
        category: 'gombi',
        jsonData: prefs.getString('user_gombi'),
        defaults: SystemDefaultNotes.getGomBiNotes(),
      );
      final notesData = prefs.getString('user_notes');
      if (notesData != null) {
        await _insertJsonList(txn, 'general', notesData);
      }
      await txn.insert('app_metadata', {
        'key': 'initial_data_migrated',
        'value': 'true',
      });
    });

    await prefs.setBool('sqlite_migrated', true);
  }

  Future<void> _migrateCategory(
    DatabaseExecutor db, {
    required String category,
    required String? jsonData,
    required List<Note> defaults,
  }) async {
    if (jsonData == null) {
      await _seedDefaults(db, category, defaults);
    } else {
      await _insertJsonList(db, category, jsonData);
    }
  }

  Future<void> _insertJsonList(
    DatabaseExecutor db,
    String category,
    String jsonData,
  ) async {
    try {
      final decoded = jsonDecode(jsonData);
      if (decoded is! List) {
        throw const FormatException('Dữ liệu ghi chú phải là một danh sách.');
      }
      final List<dynamic> list = decoded;
      for (var item in list) {
        final note = Note.fromJson(item);
        await db.insert('notes', {
          'category': category,
          'title': note.title,
          'subtitle': note.subtitle,
          'blocks': jsonEncode(note.blocks.map((b) => b.toJson()).toList()),
          'date': note.date.toIso8601String(),
          'color': note.color.value,
        });
      }
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'Không thể chuyển đổi dữ liệu cũ của danh mục $category.',
        error,
      );
    }
  }

  Future<void> _seedDefaults(
    DatabaseExecutor db,
    String category,
    List<Note> defaults,
  ) async {
    for (var note in defaults) {
      await db.insert('notes', {
        'category': category,
        'title': note.title,
        'subtitle': note.subtitle,
        'blocks': jsonEncode(note.blocks.map((b) => b.toJson()).toList()),
        'date': note.date.toIso8601String(),
        'color': note.color.value,
      });
    }
  }

  // --- CRUD FUNCTIONS ---

  Future<List<Note>> getNotesByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date ASC',
    );

    return result.map((json) {
      final blocksList = jsonDecode(json['blocks'] as String) as List;
      final blocks = blocksList.map((b) => NoteBlock.fromJson(b)).toList();
      return Note(
        id: json['id'] as int?,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        blocks: blocks,
        date: DateTime.parse(json['date'] as String),
        color: Color(json['color'] as int),
      );
    }).toList();
  }

  Future<Note> insertNote(String category, Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', {
      'category': category,
      'title': note.title,
      'subtitle': note.subtitle,
      'blocks': jsonEncode(note.blocks.map((b) => b.toJson()).toList()),
      'date': note.date.toIso8601String(),
      'color': note.color.value,
    });
    note.id = id;
    return note;
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {
        'title': note.title,
        'subtitle': note.subtitle,
        'blocks': jsonEncode(note.blocks.map((b) => b.toJson()).toList()),
        'date': note.date.toIso8601String(),
        'color': note.color.value,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetCategoryToDefault(
    String category,
    List<Note> defaults,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('notes', where: 'category = ?', whereArgs: [category]);
      await _seedDefaults(txn, category, defaults);
    });
  }

  Future<void> resetAllDefaults() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'notes',
        where: 'category IN (?, ?, ?)',
        whereArgs: ['coban', 'boso', 'gombi'],
      );
      await _seedDefaults(txn, 'coban', SystemDefaultNotes.getCoBanNotes());
      await _seedDefaults(txn, 'boso', SystemDefaultNotes.getBoSoNotes());
      await _seedDefaults(txn, 'gombi', SystemDefaultNotes.getGomBiNotes());
    });
  }

  // --- BACKUP & RESTORE ---

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'libre_billiard.db');
  }

  Future<void> backupDatabase(String targetPath) async {
    // Flush pending writes before copying the SQLite file.
    final db = await database;
    await db.execute('PRAGMA wal_checkpoint(FULL)');
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(targetPath);
    } else {
      throw Exception('Database file does not exist');
    }
  }

  Future<void> _validateBackup(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists() || await sourceFile.length() < 100) {
      throw const FormatException(
        'Tệp sao lưu không tồn tại hoặc không hợp lệ.',
      );
    }

    Database? candidate;
    try {
      candidate = await openDatabase(
        sourcePath,
        readOnly: true,
        singleInstance: false,
      );
      final integrity = await candidate.rawQuery('PRAGMA integrity_check');
      final isHealthy =
          integrity.isNotEmpty && integrity.first.values.first == 'ok';
      final tables = await candidate.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'notes'",
      );
      final columns = await candidate.rawQuery('PRAGMA table_info(notes)');
      const requiredColumns = {
        'id',
        'category',
        'title',
        'subtitle',
        'blocks',
        'date',
        'color',
      };
      final columnNames = columns
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();

      if (!isHealthy ||
          tables.isEmpty ||
          !columnNames.containsAll(requiredColumns)) {
        throw const FormatException(
          'Tệp không phải bản sao lưu hợp lệ của Billiard Libre.',
        );
      }
    } on DatabaseException catch (_) {
      throw const FormatException('Không thể đọc tệp sao lưu SQLite.');
    } finally {
      await candidate?.close();
    }
  }

  Future<void> restoreDatabase(String sourcePath) async {
    await _validateBackup(sourcePath);

    final dbPath = await getDatabasePath();
    final safetyPath = '$dbPath.before_restore';
    final currentFile = File(dbPath);
    final safetyFile = File(safetyPath);
    if (_database != null) {
      await _database!.execute('PRAGMA wal_checkpoint(FULL)');
    }
    if (await safetyFile.exists()) {
      await safetyFile.delete();
    }
    if (await currentFile.exists()) {
      await currentFile.copy(safetyPath);
    }

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final sourceFile = File(sourcePath);
    try {
      await sourceFile.copy(dbPath);
      _database = await _initDB('libre_billiard.db');
    } catch (_) {
      if (await safetyFile.exists()) {
        await safetyFile.copy(dbPath);
        _database = await _initDB('libre_billiard.db');
      }
      rethrow;
    }
  }
}
