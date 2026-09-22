import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/note_model.dart';
import '../models/learning_progress.dart';

mixin CategoryNotesState<T extends StatefulWidget> on State<T> {
  NoteRepository get noteRepository;
  String get noteCategory;

  final List<Note> categoryNotes = [];
  final List<ExpansionTileController> expansionControllers = [];
  bool isLoadingNotes = true;
  Object? notesLoadError;
  String notesQuery = '';

  List<Note> get filteredCategoryNotes {
    final query = notesQuery.trim().toLowerCase();
    if (query.isEmpty) return categoryNotes;
    return categoryNotes
        .where((note) {
          final searchable = [
            note.title,
            note.subtitle,
            ...note.blocks.map((block) => block.content),
          ].join('\n').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  void updateNotesQuery(String value) {
    setState(() => notesQuery = value);
  }

  bool isNoteCompleted(Note note) =>
      LearningProgress.isCompleted(noteCategory, note.id);

  Future<void> toggleNoteCompleted(Note note) async {
    await LearningProgress.toggle(noteCategory, note.id);
    if (mounted) setState(() {});
  }

  Future<void> loadCategoryNotes() async {
    if (mounted) {
      setState(() {
        isLoadingNotes = true;
        notesLoadError = null;
      });
    }
    try {
      final notes = await noteRepository.getByCategory(noteCategory);
      if (!mounted) return;
      setState(() {
        categoryNotes
          ..clear()
          ..addAll(notes);
        expansionControllers
          ..clear()
          ..addAll(
            List.generate(notes.length, (_) => ExpansionTileController()),
          );
        isLoadingNotes = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingNotes = false;
        notesLoadError = error;
      });
    }
  }

  Future<Note?> insertCategoryNote(Note note) async {
    final saved = await noteRepository.insert(noteCategory, note);
    if (!mounted) return null;
    setState(() {
      categoryNotes.add(saved);
      expansionControllers.add(ExpansionTileController());
    });
    return saved;
  }

  Future<void> updateCategoryNote(Note note) async {
    await noteRepository.update(note);
    await loadCategoryNotes();
  }

  Future<void> deleteCategoryNote(Note note, {bool showUndo = true}) async {
    if (note.id == null) return;
    final deletedCopy = Note.fromJson(note.toJson());
    await noteRepository.delete(note.id!);
    await loadCategoryNotes();
    if (!mounted || !showUndo) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa “${note.title}”'),
        action: SnackBarAction(
          label: 'HOÀN TÁC',
          onPressed: () async {
            deletedCopy.id = null;
            await noteRepository.insert(noteCategory, deletedCopy);
            await loadCategoryNotes();
          },
        ),
      ),
    );
  }

  Future<void> resetCategoryNotes(List<Note> defaults) async {
    await noteRepository.resetCategory(noteCategory, defaults);
    await loadCategoryNotes();
  }

  void collapseOtherTiles(int index, bool expanded) {
    if (!expanded) return;
    for (var i = 0; i < expansionControllers.length; i++) {
      if (i != index) expansionControllers[i].collapse();
    }
  }
}
