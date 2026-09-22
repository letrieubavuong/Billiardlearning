import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../models/image_block_data.dart';
import 'article_blocks.dart';
import 'billiard_diagram.dart';
import 'youtube_player_widget.dart';
import 'note_image_block.dart';

/// The single read-only renderer for every persisted [NoteBlock].
///
/// Editors are responsible for producing block content. This widget owns the
/// decoding and presentation rules so all note-reading surfaces stay aligned.
class NoteBlockRenderer extends StatelessWidget {
  const NoteBlockRenderer({
    super.key,
    required this.block,
    required this.noteColor,
  });

  final NoteBlock block;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case BlockType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            block.content,
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.justify,
          ),
        );
      case BlockType.item:
        return _buildItems();
      case BlockType.image:
        return NoteImageBlock(data: ImageBlockData.decode(block.content));
      case BlockType.diagram:
        return _buildDiagram();
      case BlockType.shotDetail:
        return _buildShotDetail();
      case BlockType.effetDiagram:
        return ArticleBlocks.effetDiagram(_decodeJson() ?? const []);
      case BlockType.animatedText:
        return _buildAnimatedText();
      case BlockType.section:
        return _buildSection();
      case BlockType.subSection:
        return _buildSubSection();
      case BlockType.headingText:
        final data = _decodeMap();
        return ArticleBlocks.text(
          data['heading']?.toString() ?? '',
          data['text']?.toString() ?? '',
        );
      case BlockType.dataTable:
        return _buildDataTable();
      case BlockType.iconText:
        return _buildIconText();
      case BlockType.youtube:
        return _buildYoutube();
      case BlockType.formula:
        return ArticleBlocks.formula(block.content, noteColor);
    }
  }

  Widget _buildItems() {
    final lines = block.content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        var cleanLine = line;
        if (cleanLine.startsWith('• ')) {
          cleanLine = cleanLine.substring(2);
        } else if (cleanLine.startsWith('•')) {
          cleanLine = cleanLine.substring(1);
        }
        if (cleanLine.trim().isEmpty) return const SizedBox.shrink();
        return ArticleBlocks.iconText(
          Icons.fiber_manual_record,
          noteColor,
          cleanLine,
          bottomPadding: 6,
        );
      }).toList(),
    );
  }

  Widget _buildDiagram() {
    final data = _decodeMap();
    final balls = <Ball>[];
    _addMainBall(data, 'white', Colors.white, balls);
    _addMainBall(data, 'yellow', Colors.yellow, balls);
    _addMainBall(data, 'red', Colors.red, balls);

    final ghosts = data['ghosts'];
    if (ghosts is List) {
      for (final value in ghosts) {
        if (value is! Map) continue;
        final ghost = Map<String, dynamic>.from(value);
        final x = _number(ghost['x']);
        final y = _number(ghost['y']);
        if (x == null || y == null) continue;
        balls.add(
          Ball.at(
            x,
            y,
            Color(_int(ghost['color'], Colors.white.toARGB32())),
            isGhost: true,
            opacity: 0.5,
            type: _enumValue(BallType.values, ghost['type'], BallType.full),
            rotation: (_number(ghost['rotation']) ?? 0) * math.pi / 180,
            text: ghost['number']?.toString(),
          ),
        );
      }
    }

    final paths = <BallPath>[];
    final pathData = data['paths'];
    if (pathData is Map) {
      _addMainPath(data, pathData, 'white', Colors.white70, paths);
      _addMainPath(data, pathData, 'yellow', Colors.yellow, paths);
      _addMainPath(data, pathData, 'red', Colors.redAccent, paths);
      final freePaths = pathData['free'];
      if (freePaths is List) {
        for (final value in freePaths) {
          final points = _offsetList(value);
          if (points.isNotEmpty) {
            paths.add(
              BallPath.diamonds(points: points, color: Colors.cyanAccent),
            );
          }
        }
      }
    }

    final labelFontSize = _number(data['labelFontSize']) ?? 9.5;
    final labels = <BilliardLabel>[];
    final labelData = data['labels'];
    if (labelData is List) {
      for (final value in labelData) {
        if (value is! Map) continue;
        final label = Map<String, dynamic>.from(value);
        final x = _number(label['x']);
        final y = _number(label['y']);
        if (x == null || y == null) continue;
        labels.add(
          BilliardLabel.at(
            x,
            y,
            label['text']?.toString() ?? '',
            color: Color(_int(label['color'], Colors.yellowAccent.toARGB32())),
            fontSize: labelFontSize,
            rotation: (_number(label['rotation']) ?? 0) * math.pi / 180,
          ),
        );
      }
    }

    final stepTexts = data['stepTexts'] is List
        ? (data['stepTexts'] as List).map((value) => value.toString()).toList()
        : null;
    final stepScripts = data['stepScripts'] is List
        ? (data['stepScripts'] as List)
              .whereType<Map>()
              .map((value) => Map<String, dynamic>.from(value))
              .toList()
        : null;

    return ArticleBlocks.diagram(
      viewType: _enumValue(
        TableViewType.values,
        data['viewType'],
        TableViewType.full,
      ),
      system: _enumValue(
        DiagramSystem.values,
        data['system'],
        DiagramSystem.standard,
      ),
      isVertical: true,
      balls: balls,
      paths: paths,
      labels: labels,
      effetData: data['effet'] is Map
          ? Map<String, dynamic>.from(data['effet'] as Map)
          : null,
      stepTexts: stepTexts,
      stepScripts: stepScripts,
    );
  }

  void _addMainBall(
    Map<String, dynamic> data,
    String key,
    Color color,
    List<Ball> balls,
  ) {
    final position = _offset(data[key]);
    if (position != null) balls.add(Ball.at(position.dx, position.dy, color));
  }

  void _addMainPath(
    Map<String, dynamic> data,
    Map<dynamic, dynamic> pathData,
    String key,
    Color color,
    List<BallPath> paths,
  ) {
    final start = _offset(data[key]);
    final points = _offsetList(pathData[key]);
    if (start != null && points.isNotEmpty) {
      paths.add(BallPath.diamonds(points: [start, ...points], color: color));
    }
  }

  Widget _buildShotDetail() {
    final data = _decodeMap();
    final effet = _offset(data['effet']) ?? Offset.zero;
    return ArticleBlocks.details(
      thickness: _number(data['thickness']) ?? 0.5,
      effet: effet,
      forceImage: data['forceImage']?.toString(),
      cueAngle: _number(data['cueAngle']) ?? 0,
    );
  }

  Widget _buildAnimatedText() {
    final data = _decodeMap();
    return ArticleBlocks.animatedText(
      text: data['text']?.toString() ?? block.content,
      type: data['type']?.toString() ?? 'marquee',
      color: Color(_int(data['colorVal'], Colors.cyanAccent.toARGB32())),
      fontSize: _number(data['fontSize']) ?? 16,
      speed: _number(data['speed']) ?? 1,
    );
  }

  Widget _buildSection() {
    final data = _decodeMap();
    final text = data['text']?.toString();
    return ArticleBlocks.section(
      _int(data['number'], 1),
      data['title']?.toString() ?? '',
      Color(_int(data['colorVal'], noteColor.toARGB32())),
      text: text == null || text.isEmpty ? null : text,
    );
  }

  Widget _buildSubSection() {
    final data = _decodeMap();
    final text = data['text']?.toString();
    return ArticleBlocks.subSection(
      data['title']?.toString() ?? '',
      Color(_int(data['colorVal'], noteColor.toARGB32())),
      text: text == null || text.isEmpty ? null : text,
    );
  }

  Widget _buildDataTable() {
    final rows = <List<String>>[];
    final data = _decodeMap()['data'];
    if (data is List) {
      for (final row in data) {
        if (row is List) rows.add(row.map((cell) => cell.toString()).toList());
      }
    }
    if (rows.isEmpty) rows.add(['Không có dữ liệu']);
    return ArticleBlocks.dataTable(
      rows,
      headerColor: noteColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildIconText() {
    final data = _decodeMap();
    return ArticleBlocks.iconText(
      NoteIconHelper.getIcon(_int(data['iconCode'], Icons.lightbulb.codePoint)),
      Color(_int(data['colorVal'], Colors.amber.toARGB32())),
      data['text']?.toString() ?? '',
    );
  }

  Widget _buildYoutube() {
    var videoId = block.content;
    int? startSeconds;
    int? endSeconds;
    final data = _decodeJson();
    if (data is Map) {
      videoId = data['videoId']?.toString() ?? '';
      startSeconds = _nullableInt(data['startSeconds']);
      endSeconds = _nullableInt(data['endSeconds']);
    }
    return YoutubePlayerWidget(
      videoId: videoId,
      startSeconds: startSeconds,
      endSeconds: endSeconds,
    );
  }

  dynamic _decodeJson() {
    try {
      return jsonDecode(block.content);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _decodeMap() {
    final value = _decodeJson();
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static double? _number(dynamic value) =>
      value is num ? value.toDouble() : null;

  static int _int(dynamic value, int fallback) =>
      value is num ? value.toInt() : fallback;

  static int? _nullableInt(dynamic value) =>
      value is num ? value.toInt() : null;

  static Offset? _offset(dynamic value) {
    if (value is! List || value.length < 2) return null;
    final x = _number(value[0]);
    final y = _number(value[1]);
    return x == null || y == null ? null : Offset(x, y);
  }

  static List<Offset> _offsetList(dynamic value) {
    if (value is! List) return [];
    return value.map(_offset).whereType<Offset>().toList();
  }

  static T _enumValue<T>(List<T> values, dynamic index, T fallback) {
    if (index is! num || index < 0 || index >= values.length) return fallback;
    return values[index.toInt()];
  }
}
