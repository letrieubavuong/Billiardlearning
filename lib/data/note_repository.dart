import '../models/database_helper.dart';
import '../models/note_model.dart';

abstract interface class NoteRepository {
  Future<List<Note>> getByCategory(String category);
  Future<Note> insert(String category, Note note);
  Future<int> update(Note note);
  Future<int> delete(int id);
  Future<void> resetCategory(String category, List<Note> defaults);
  Future<void> resetAllDefaults();
  Future<void> backup(String targetPath);
  Future<void> restore(String sourcePath);
}

class SqliteNoteRepository implements NoteRepository {
  const SqliteNoteRepository();

  DatabaseHelper get _database => DatabaseHelper.instance;

  @override
  Future<List<Note>> getByCategory(String category) =>
      _database.getNotesByCategory(category);

  @override
  Future<Note> insert(String category, Note note) =>
      _database.insertNote(category, note);

  @override
  Future<int> update(Note note) => _database.updateNote(note);

  @override
  Future<int> delete(int id) => _database.deleteNote(id);

  @override
  Future<void> resetCategory(String category, List<Note> defaults) =>
      _database.resetCategoryToDefault(category, defaults);

  @override
  Future<void> resetAllDefaults() => _database.resetAllDefaults();

  @override
  Future<void> backup(String targetPath) =>
      _database.backupDatabase(targetPath);

  @override
  Future<void> restore(String sourcePath) =>
      _database.restoreDatabase(sourcePath);
}
