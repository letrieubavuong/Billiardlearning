import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/note_model.dart';
import '../widgets/note_block_renderer.dart';
import 'note_editor_page.dart';

class ArticleDetailPage extends StatefulWidget {
  final Note note;
  final String category;
  final VoidCallback onUpdated;
  final NoteRepository repository;

  const ArticleDetailPage({
    super.key,
    required this.note,
    required this.category,
    required this.onUpdated,
    this.repository = const SqliteNoteRepository(),
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  void _editNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: _note)),
    );
    if (result != null && result is Note) {
      await widget.repository.update(result);
      if (!mounted) return;
      setState(() {
        _note = result;
      });
      widget.onUpdated();
    }
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc chắn muốn xóa bài này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (_note.id == null) return;

              final deletedCopy = Note.fromJson(_note.toJson());
              await widget.repository.delete(_note.id!);
              widget.onUpdated();
              if (!mounted) return;

              final controller = ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa “${_note.title}”'),
                  action: SnackBarAction(
                    label: 'HOÀN TÁC',
                    onPressed: () async {
                      deletedCopy.id = null;
                      final restored = await widget.repository.insert(
                        widget.category,
                        deletedCopy,
                      );
                      if (!mounted) return;
                      setState(() => _note = restored);
                      widget.onUpdated();
                    },
                  ),
                ),
              );
              final reason = await controller.closed;
              if (mounted && reason != SnackBarClosedReason.action) {
                Navigator.pop(context);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: _editNote,
            tooltip: 'Chỉnh sửa bài viết',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteNote,
            tooltip: 'Xóa bài viết',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_note.subtitle.isNotEmpty) ...[
                Text(
                  _note.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
                const Divider(height: 24, color: Colors.white24),
              ],
              for (final block in _note.blocks)
                NoteBlockRenderer(block: block, noteColor: _note.color),
            ],
          ),
        ),
      ),
    );
  }
}
