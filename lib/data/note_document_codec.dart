import 'dart:convert';

import '../models/note_model.dart';

class NoteDocumentCodec {
  const NoteDocumentCodec._();

  static String encode(Note note) =>
      jsonEncode({'schemaVersion': 1, ...note.toJson()});

  static Note decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Tài liệu ghi chú phải là một JSON object.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final version = map['schemaVersion'] as int? ?? 1;
    if (version != 1) {
      throw FormatException('Phiên bản tài liệu không được hỗ trợ: $version.');
    }
    return Note.fromJson(map);
  }
}
