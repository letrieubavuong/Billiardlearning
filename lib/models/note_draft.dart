import 'package:flutter/material.dart';

import 'note_model.dart';

class NoteDraft {
  const NoteDraft({
    this.id,
    required this.title,
    required this.subtitle,
    required this.blocks,
    required this.date,
    required this.color,
  });

  final int? id;
  final String title;
  final String subtitle;
  final List<NoteBlock> blocks;
  final DateTime date;
  final Color color;

  bool get isEmpty => title.trim().isEmpty && blocks.isEmpty;

  Note toNote() => Note(
    id: id,
    title: title.trim().isEmpty ? 'Không tiêu đề' : title.trim(),
    subtitle: subtitle.trim(),
    blocks: List.unmodifiable(blocks),
    date: date,
    color: color,
  );
}
