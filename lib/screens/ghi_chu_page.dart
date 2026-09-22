import 'package:flutter/material.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';
import 'note_editor_page.dart';
import '../widgets/data_state_view.dart';
import '../widgets/note_search_field.dart';
import '../widgets/lesson_preview_card.dart';
import 'category_notes_state.dart';
import 'article_detail_page.dart';

class GhiChuPage extends StatefulWidget {
  const GhiChuPage({super.key, this.repository = const SqliteNoteRepository()});

  final NoteRepository repository;

  @override
  State<GhiChuPage> createState() => GhiChuPageState();
}

class GhiChuPageState extends State<GhiChuPage>
    with CategoryNotesState<GhiChuPage> {
  @override
  NoteRepository get noteRepository => widget.repository;

  @override
  String get noteCategory => 'general';

  List<Note> get _notes => filteredCategoryNotes;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() => loadCategoryNotes();

  void addNewNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorPage()),
    );
    if (!mounted) return;

    if (result != null && result is Note) {
      await insertCategoryNote(result);
    }
  }

  Future<void> _openNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(
          note: note,
          category: noteCategory,
          onUpdated: loadNotes,
          repository: noteRepository,
        ),
      ),
    );
    if (mounted) await loadNotes();
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)),
    );
    if (result is Note) await updateCategoryNote(result);
  }

  Future<void> _confirmDeleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: Text('Bạn có chắc muốn xóa “${note.title}” không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await deleteCategoryNote(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DataStateView(
        isLoading: isLoadingNotes,
        error: notesLoadError,
        onRetry: loadNotes,
        child: ListView(
          children: [
            NoteSearchField(
              onChanged: updateNotesQuery,
              hintText: 'Tìm trong ghi chú…',
            ),
            if (_notes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Chưa có ghi chú nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._notes.map(
                (note) => LessonPreviewCard(
                  note: note,
                  accentColor: note.color,
                  completed: isNoteCompleted(note),
                  categoryLabel: 'Ghi chú',
                  onOpen: () => _openNote(note),
                  onToggleCompleted: () => toggleNoteCompleted(note),
                  onEdit: () => _editNote(note),
                  onDelete: () => _confirmDeleteNote(note),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

