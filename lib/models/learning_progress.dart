import 'package:shared_preferences/shared_preferences.dart';

class LearningProgress {
  const LearningProgress._();

  static const _storageKey = 'completed_learning_notes';
  static final Set<String> _completed = {};

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _completed
      ..clear()
      ..addAll(prefs.getStringList(_storageKey) ?? const []);
  }

  static bool isCompleted(String category, int? id) =>
      id != null && _completed.contains('$category:$id');

  static Future<bool> toggle(String category, int? id) async {
    if (id == null) return false;
    final key = '$category:$id';
    final completed = !_completed.remove(key);
    if (completed) _completed.add(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _completed.toList()..sort());
    return completed;
  }
}
