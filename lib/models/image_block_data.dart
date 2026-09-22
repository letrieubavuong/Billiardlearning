import 'dart:convert';

class ImageBlockData {
  const ImageBlockData({
    required this.source,
    this.caption = '',
    this.altText = '',
    this.fit = 'contain',
  });

  final String source;
  final String caption;
  final String altText;
  final String fit;

  bool get isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  String encode() => jsonEncode({
    'schemaVersion': 1,
    'source': source,
    'caption': caption,
    'altText': altText,
    'fit': fit,
  });

  static ImageBlockData decode(String content) {
    if (content.startsWith('{')) {
      try {
        final value = jsonDecode(content);
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final source = map['source']?.toString() ?? '';
          return ImageBlockData(
            source: source,
            caption: map['caption']?.toString() ?? '',
            altText: map['altText']?.toString() ?? '',
            fit: map['fit'] == 'cover' ? 'cover' : 'contain',
          );
        }
      } on FormatException {
        // Fall through to the legacy raw-path representation.
      }
    }
    return ImageBlockData(source: content);
  }
}
