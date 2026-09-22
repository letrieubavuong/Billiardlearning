import 'package:flutter/material.dart';

enum BlockType {
  text,
  item,
  image,
  diagram,
  shotDetail,
  section,
  subSection,
  headingText,
  dataTable,
  iconText,
  youtube,
  effetDiagram,
  formula,
  animatedText,
}

class NoteIconHelper {
  static IconData getIcon(int codePoint) {
    if (codePoint == Icons.lightbulb.codePoint) return Icons.lightbulb;
    if (codePoint == Icons.info.codePoint) return Icons.info;
    if (codePoint == Icons.warning.codePoint) return Icons.warning;
    if (codePoint == Icons.star.codePoint) return Icons.star;
    return Icons.lightbulb;
  }
}

class NoteBlock {
  String
  content; // Chứa văn bản hoặc đường dẫn/URL hình ảnh hoặc JSON cho các block phức tạp
  BlockType type;
  NoteBlock({required this.content, required this.type});

  Map<String, dynamic> toJson() => {'content': content, 'type': type.index};

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
    content: json['content'],
    type: BlockType.values[json['type'] ?? 0],
  );
}

class Note {
  int? id;
  String title;
  String subtitle;
  List<NoteBlock> blocks;
  DateTime date;
  Color color;

  Note({
    this.id,
    required this.title,
    this.subtitle = '',
    required this.blocks,
    required this.date,
    this.color = Colors.deepPurple,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'date': date.toIso8601String(),
    'color': color.value,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'] ?? 'Không tiêu đề',
    subtitle: json['subtitle'] ?? '',
    blocks:
        (json['blocks'] as List?)?.map((b) => NoteBlock.fromJson(b)).toList() ??
        [],
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    color: Color(json['color'] ?? Colors.deepPurple.value),
  );
}
