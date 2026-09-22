import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/note_model.dart';

class LessonPreviewCard extends StatelessWidget {
  const LessonPreviewCard({
    super.key,
    required this.note,
    required this.accentColor,
    required this.completed,
    required this.onOpen,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
    this.thumbnail,
    this.categoryLabel = 'Bài học',
  });

  final Note note;
  final Color accentColor;
  final bool completed;
  final VoidCallback onOpen;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? thumbnail;
  final String categoryLabel;

  String get _previewText {
    if (note.subtitle.trim().isNotEmpty) return note.subtitle.trim();
    for (final block in note.blocks) {
      if (block.type == BlockType.text || block.type == BlockType.item) {
        final text = block.content.replaceAll('\n', ' ').trim();
        if (text.isNotEmpty) return text;
      }
      try {
        final decoded = jsonDecode(block.content);
        if (decoded is Map) {
          final text =
              decoded['text'] ?? decoded['title'] ?? decoded['heading'];
          if (text != null && text.toString().trim().isNotEmpty) {
            return text.toString().replaceAll('\n', ' ').trim();
          }
        }
      } catch (_) {}
    }
    return 'Chạm để xem nội dung và sơ đồ hướng dẫn chi tiết.';
  }

  int get _visualBlockCount => note.blocks.where((block) {
    return block.type == BlockType.diagram ||
        block.type == BlockType.image ||
        block.type == BlockType.youtube ||
        block.type == BlockType.effetDiagram;
  }).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${note.title}. ${completed ? 'Đã học xong' : 'Chưa hoàn thành'}',
      child: Card(
        margin: const EdgeInsets.fromLTRB(12, 7, 12, 7),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: completed
                ? Colors.greenAccent.withValues(alpha: 0.45)
                : accentColor.withValues(alpha: 0.22),
          ),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (thumbnail != null)
                AspectRatio(
                  aspectRatio: 16 / 8.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumbnail!,
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB0000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: _CategoryBadge(
                          label: categoryLabel,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (thumbnail == null)
                      Container(
                        width: 54,
                        height: 54,
                        margin: const EdgeInsets.only(right: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.28),
                              accentColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          completed
                              ? Icons.check_rounded
                              : Icons.school_outlined,
                          color: completed ? Colors.greenAccent : accentColor,
                          size: 29,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (thumbnail == null)
                            _CategoryBadge(
                              label: categoryLabel,
                              color: accentColor,
                            ),
                          if (thumbnail == null) const SizedBox(height: 7),
                          Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _previewText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 5,
                            children: [
                              _InfoLabel(
                                icon: Icons.view_agenda_outlined,
                                text: '${note.blocks.length} mục',
                              ),
                              if (_visualBlockCount > 0)
                                _InfoLabel(
                                  icon: Icons.image_outlined,
                                  text: '$_visualBlockCount minh họa',
                                ),
                              _InfoLabel(
                                icon: completed
                                    ? Icons.check_circle
                                    : Icons.play_circle_outline,
                                text: completed ? 'Đã học' : 'Xem bài',
                                color: completed ? Colors.greenAccent : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn bài học',
                      onSelected: (value) {
                        switch (value) {
                          case 'complete':
                            onToggleCompleted();
                            break;
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'complete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              completed
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle_outline,
                            ),
                            title: Text(
                              completed ? 'Đánh dấu chưa học' : 'Đã học xong',
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Chỉnh sửa'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            title: Text('Xóa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: effectiveColor)),
      ],
    );
  }
}
