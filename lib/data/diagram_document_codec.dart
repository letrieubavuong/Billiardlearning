import 'dart:convert';

class DiagramDocumentCodec {
  const DiagramDocumentCodec._();

  static String encode(Map<String, dynamic> document) =>
      jsonEncode({'schemaVersion': 1, ...document});

  static Map<String, dynamic> decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Sơ đồ phải là một JSON object.');
    }
    final document = Map<String, dynamic>.from(decoded);
    final version = document['schemaVersion'] as int? ?? 1;
    if (version != 1) {
      throw FormatException('Phiên bản sơ đồ không được hỗ trợ: $version.');
    }
    return document;
  }
}
