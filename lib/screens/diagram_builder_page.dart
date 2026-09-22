import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/billiard_diagram.dart';
import '../models/theme_manager.dart';
import 'effet_diagram_builder_page.dart';
import '../data/diagram_document_codec.dart';

enum ActiveBall { white, yellow, red, ghost, free }

class CustomLabelData {
  Offset pos;
  String text;
  Color color;
  double rotation;
  String? role; // Indicator role
  CustomLabelData(
    this.pos,
    this.text,
    this.color, {
    this.rotation = 0.0,
    this.role,
  });
}

class CushionNumberData {
  Offset pos;
  String text;
  Color color;
  double rotation;
  String? cushionSide;
  CushionNumberData(
    this.pos,
    this.text,
    this.color, {
    this.rotation = 0.0,
    this.cushionSide,
  });
}

class DiagramBuilderPage extends StatefulWidget {
  final String? initialData;
  const DiagramBuilderPage({super.key, this.initialData});

  @override
  State<DiagramBuilderPage> createState() => _DiagramBuilderPageState();
}

class _DiagramBuilderPageState extends State<DiagramBuilderPage> {
  Offset whitePos = const Offset(2.0, 2.0);
  Offset yellowPos = const Offset(1.0, 4.0);
  Offset redPos = const Offset(3.0, 6.0);
  double _labelFontSize = 9.5;
  Map<String, dynamic>? _effetData;
  List<Map<String, dynamic>> stepScripts = [];
  int? _activeStepIndex;
  double _timelinePlayhead = 0.0;

  ActiveBall _selectedBall = ActiveBall.white;
  bool _isDrawingPath = false;
  bool _isDrawingSegment = false;
  Offset? _pendingSegmentStart;
  Offset? _segmentDragStart;
  Offset? _segmentDragEnd;
  bool _isAddingLabel = false;
  bool _isAddingCushionNumber = false;
  bool _handledByPan = false;

  TableViewType _viewType = TableViewType.full;
  DiagramSystem _system = DiagramSystem.standard;
  String _selectedSystemKey = 'system:standard';
  List<Map<String, dynamic>> _customSystems = [];

  List<Offset> whitePath = [];
  List<Offset> yellowPath = [];
  List<Offset> redPath = [];
  List<List<Offset>> freePaths = [];
  List<Color> freePathColors = [];
  Color whitePathColor = Colors.white70;
  Color yellowPathColor = Colors.yellow;
  Color redPathColor = Colors.redAccent;
  Color freePathColor = Colors.cyanAccent;
  Color segmentColor = Colors.cyanAccent;

  int? _editingPointIndex;
  int? _editingFreePathIndex;

  List<CustomLabelData> customLabels = [];
  int? _editingLabelIndex;

  List<CushionNumberData> customCushionNumbers = [];
  int? _editingCushionNumberIndex;

  ActiveBall? _draggingMainBall;

  List<Map<String, dynamic>> customGhosts = [];
  int? _editingGhostIndex;
  List<Map<String, dynamic>> customBalls = [];
  int? _editingCustomBallIndex;
  Offset? _dragPosition;

  bool get _isDraggingSomething =>
      _editingPointIndex != null ||
      _editingLabelIndex != null ||
      _editingCushionNumberIndex != null ||
      _draggingMainBall != null ||
      _editingGhostIndex != null ||
      _editingCustomBallIndex != null;

  void _editEffet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EffetDiagramBuilderPage(
          initialData: _effetData != null ? jsonEncode(_effetData) : null,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _effetData = jsonDecode(result);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomSystems();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        final data = DiagramDocumentCodec.decode(widget.initialData!);
        if (data.containsKey('white')) {
          whitePos = Offset(
            (data['white'][0] as num).toDouble(),
            (data['white'][1] as num).toDouble(),
          );
        }
        if (data.containsKey('yellow')) {
          yellowPos = Offset(
            (data['yellow'][0] as num).toDouble(),
            (data['yellow'][1] as num).toDouble(),
          );
        }
        if (data.containsKey('red')) {
          redPos = Offset(
            (data['red'][0] as num).toDouble(),
            (data['red'][1] as num).toDouble(),
          );
        }
        _viewType = TableViewType.values[data['viewType'] ?? 0];
        _system = DiagramSystem.values[data['system'] ?? 0];
        _selectedSystemKey = 'system:${_system.name}';
        _labelFontSize = (data['labelFontSize'] as num?)?.toDouble() ?? 9.5;

        if (data.containsKey('paths')) {
          var p = data['paths'];
          if (p['white'] != null) {
            whitePath = (p['white'] as List)
                .map(
                  (e) => Offset(
                    (e[0] as num).toDouble(),
                    (e[1] as num).toDouble(),
                  ),
                )
                .toList();
          }
          if (p['yellow'] != null) {
            yellowPath = (p['yellow'] as List)
                .map(
                  (e) => Offset(
                    (e[0] as num).toDouble(),
                    (e[1] as num).toDouble(),
                  ),
                )
                .toList();
          }
          if (p['red'] != null) {
            redPath = (p['red'] as List)
                .map(
                  (e) => Offset(
                    (e[0] as num).toDouble(),
                    (e[1] as num).toDouble(),
                  ),
                )
                .toList();
          }
          if (p['free'] != null) {
            var fList = p['free'] as List;
            freePaths = fList
                .map(
                  (path) => (path as List)
                      .map(
                        (e) => Offset(
                          (e[0] as num).toDouble(),
                          (e[1] as num).toDouble(),
                        ),
                      )
                      .toList(),
                )
                .toList();
          }
        }

        if (data.containsKey('labels')) {
          var lbls = data['labels'];
          if (lbls is List) {
            customLabels = lbls
                .map(
                  (l) => CustomLabelData(
                    Offset(
                      (l['x'] as num).toDouble(),
                      (l['y'] as num).toDouble(),
                    ),
                    l['text'].toString(),
                    Color(l['color'] ?? Colors.yellowAccent.value),
                    rotation: (l['rotation'] as num?)?.toDouble() ?? 0.0,
                    role: l['role']?.toString(),
                  ),
                )
                .toList();
          }
        }
        if (data.containsKey('ghosts')) {
          var gh = data['ghosts'];
          if (gh is List) {
            customGhosts = gh
                .map(
                  (g) => {
                    'pos': Offset(
                      (g['x'] as num).toDouble(),
                      (g['y'] as num).toDouble(),
                    ),
                    'color': Color(g['color'] ?? Colors.white.value),
                    'type': BallType.values[g['type'] ?? 0],
                    'rotation': (g['rotation'] ?? 0.0).toDouble(),
                    'number': g['number']?.toString() ?? '',
                  },
                )
                .toList();
          }
        }
        if (data['extraBalls'] is List) {
          customBalls = (data['extraBalls'] as List)
              .map(
                (b) => {
                  'pos': Offset(
                    (b['x'] as num).toDouble(),
                    (b['y'] as num).toDouble(),
                  ),
                  'color': Color(b['color'] ?? Colors.blue.value),
                  'number': b['number']?.toString() ?? '',
                },
              )
              .toList();
        }
        if (data['pathColors'] is Map) {
          final colors = data['pathColors'] as Map;
          whitePathColor = Color(colors['white'] ?? Colors.white70.value);
          yellowPathColor = Color(colors['yellow'] ?? Colors.yellow.value);
          redPathColor = Color(colors['red'] ?? Colors.redAccent.value);
          freePathColor = Color(colors['free'] ?? Colors.cyanAccent.value);
        }
        if (data.containsKey('effet')) {
          _effetData = Map<String, dynamic>.from(data['effet']);
        }
        if (data.containsKey('stepScripts') && data['stepScripts'] is List) {
          stepScripts = (data['stepScripts'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else if (data.containsKey('stepTexts') && data['stepTexts'] is List) {
          final oldTexts = (data['stepTexts'] as List)
              .map((e) => e.toString())
              .toList();
          final double dur = 7.0 / oldTexts.length;
          stepScripts = List.generate(oldTexts.length, (i) {
            return {'text': oldTexts[i], 'start': i * dur, 'duration': dur};
          });
        }
        if (stepScripts.isNotEmpty) {
          _activeStepIndex = 0;
        }
      } catch (e) {
        // Bỏ qua nếu có lỗi parse
      }
    }
  }

  Future<void> _loadCustomSystems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('custom_billiard_systems');
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        setState(() {
          _customSystems = decoded
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveCustomSystem() async {
    if (customLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng vẽ ít nhất một nhãn số trước khi lưu bộ số mẫu!',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lưu bộ số mẫu'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên bộ số',
            hintText: 'Ví dụ: Bộ số 1 Băng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(dialogContext);

              // Chuẩn bị nhãn
              final labelsData = customLabels
                  .map(
                    (l) => {
                      'x': l.pos.dx,
                      'y': l.pos.dy,
                      'text': l.text,
                      'color': l.color.value,
                      'role': l.role,
                      'rotation': l.rotation,
                    },
                  )
                  .toList();

              // Kiểm tra xem tên đã tồn tại chưa
              int index = _customSystems.indexWhere((s) => s['name'] == name);
              if (index != -1) {
                _customSystems[index]['labels'] = labelsData;
              } else {
                _customSystems.add({'name': name, 'labels': labelsData});
              }

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'custom_billiard_systems',
                jsonEncode(_customSystems),
              );

              setState(() {
                _selectedSystemKey = 'custom:$name';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã lưu bộ số mẫu "$name" thành công!')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  final Map<TableViewType, String> viewTypeNames = {
    TableViewType.full: 'Full bàn',
    TableViewType.half: '1/2 bàn (dọc)',
    TableViewType.third: '1/3 bàn (dọc)',
    TableViewType.quarter: '1/4 bàn (dọc)',
    TableViewType.halfWidth: '1/2 bàn (ngang)',
    TableViewType.halfWidthHalfLength: '1/2 ngang & 1/2 dọc',
    TableViewType.halfWidthThirdLength: '1/2 ngang & 1/3 dọc',
    TableViewType.halfWidthQuarterLength: '1/2 ngang & 1/4 dọc',
  };

  final Map<DiagramSystem, String> systemNames = {
    DiagramSystem.standard: 'Không số',
    DiagramSystem.diamond: 'Hệ Diamond',
    DiagramSystem.short3Cushion: '3 Băng ngắn',
    DiagramSystem.shortLongShort: 'Ngắn-Dài-Ngắn',
    DiagramSystem.xohaibang: 'Xổ 2 băng',
    DiagramSystem.babangcha: '3 Băng cha',
  };

  Map<String, dynamic> _captureCurrentLayout() {
    return {
      "white": [whitePos.dx, whitePos.dy],
      "yellow": [yellowPos.dx, yellowPos.dy],
      "red": [redPos.dx, redPos.dy],
      "viewType": _viewType.index,
      "system": _system.index,
      "paths": {
        "white": whitePath.map((e) => [e.dx, e.dy]).toList(),
        "yellow": yellowPath.map((e) => [e.dx, e.dy]).toList(),
        "red": redPath.map((e) => [e.dx, e.dy]).toList(),
        "free": freePaths
            .map((path) => path.map((e) => [e.dx, e.dy]).toList())
            .toList(),
      },
      "freePathColors": freePathColors.map((c) => c.value).toList(),
      "labels": customLabels
          .map(
            (l) => {
              "x": l.pos.dx,
              "y": l.pos.dy,
              "text": l.text,
              "color": l.color.value,
              "rotation": l.rotation,
              "role": l.role,
            },
          )
          .toList(),
      "cushionNumbers": customCushionNumbers
          .map(
            (c) => {
              "x": c.pos.dx,
              "y": c.pos.dy,
              "text": c.text,
              "color": c.color.value,
              "rotation": c.rotation,
              "cushionSide": c.cushionSide,
            },
          )
          .toList(),
      "ghosts": customGhosts
          .map(
            (g) => {
              "x": (g['pos'] as Offset).dx,
              "y": (g['pos'] as Offset).dy,
              "color": (g['color'] as Color).value,
              "type": (g['type'] as BallType).index,
              "rotation": (g['rotation'] as num).toDouble(),
              "number": g['number'] ?? '',
            },
          )
          .toList(),
      "extraBalls": customBalls
          .map(
            (b) => {
              "x": (b['pos'] as Offset).dx,
              "y": (b['pos'] as Offset).dy,
              "color": (b['color'] as Color).value,
              "number": b['number'] ?? '',
            },
          )
          .toList(),
      "pathColors": {
        "white": whitePathColor.value,
        "yellow": yellowPathColor.value,
        "red": redPathColor.value,
        "free": freePathColor.value,
      },
      "labelFontSize": _labelFontSize,
      "effet": _effetData,
    };
  }

  void _applyLayout(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('white')) {
        whitePos = Offset(
          (data['white'][0] as num).toDouble(),
          (data['white'][1] as num).toDouble(),
        );
      }
      if (data.containsKey('yellow')) {
        yellowPos = Offset(
          (data['yellow'][0] as num).toDouble(),
          (data['yellow'][1] as num).toDouble(),
        );
      }
      if (data.containsKey('red')) {
        redPos = Offset(
          (data['red'][0] as num).toDouble(),
          (data['red'][1] as num).toDouble(),
        );
      }
      _viewType = TableViewType.values[data['viewType'] ?? 0];
      _system = DiagramSystem.values[data['system'] ?? 0];
      _selectedSystemKey = 'system:${_system.name}';
      _labelFontSize = (data['labelFontSize'] as num?)?.toDouble() ?? 9.5;

      if (data.containsKey('paths')) {
        var p = data['paths'];
        whitePath = p['white'] != null
            ? (p['white'] as List)
                  .map(
                    (e) => Offset(
                      (e[0] as num).toDouble(),
                      (e[1] as num).toDouble(),
                    ),
                  )
                  .toList()
            : [];
        yellowPath = p['yellow'] != null
            ? (p['yellow'] as List)
                  .map(
                    (e) => Offset(
                      (e[0] as num).toDouble(),
                      (e[1] as num).toDouble(),
                    ),
                  )
                  .toList()
            : [];
        redPath = p['red'] != null
            ? (p['red'] as List)
                  .map(
                    (e) => Offset(
                      (e[0] as num).toDouble(),
                      (e[1] as num).toDouble(),
                    ),
                  )
                  .toList()
            : [];
        if (p['free'] != null) {
          var fList = p['free'] as List;
          freePaths = fList
              .map(
                (path) => (path as List)
                    .map(
                      (e) => Offset(
                        (e[0] as num).toDouble(),
                        (e[1] as num).toDouble(),
                      ),
                    )
                    .toList(),
              )
              .toList();
        } else {
          freePaths = [];
        }
      } else {
        whitePath = [];
        yellowPath = [];
        redPath = [];
        freePaths = [];
      }

      if (data.containsKey('freePathColors') &&
          data['freePathColors'] is List) {
        freePathColors = (data['freePathColors'] as List)
            .map((c) => Color((c as num).toInt()))
            .toList();
      } else {
        freePathColors = [];
      }

      if (data.containsKey('labels')) {
        var lbls = data['labels'];
        if (lbls is List) {
          customLabels = lbls
              .map(
                (l) => CustomLabelData(
                  Offset(
                    (l['x'] as num).toDouble(),
                    (l['y'] as num).toDouble(),
                  ),
                  l['text'].toString(),
                  Color(l['color'] ?? Colors.yellowAccent.value),
                  rotation: (l['rotation'] as num?)?.toDouble() ?? 0.0,
                  role: l['role']?.toString(),
                ),
              )
              .toList();
        } else {
          customLabels = [];
        }
      } else {
        customLabels = [];
      }

      if (data.containsKey('cushionNumbers')) {
        var cNums = data['cushionNumbers'];
        if (cNums is List) {
          customCushionNumbers = cNums
              .map(
                (c) => CushionNumberData(
                  Offset(
                    (c['x'] as num).toDouble(),
                    (c['y'] as num).toDouble(),
                  ),
                  c['text'].toString(),
                  Color(c['color'] ?? Colors.yellowAccent.value),
                  rotation: (c['rotation'] as num?)?.toDouble() ?? 0.0,
                  cushionSide: c['cushionSide']?.toString(),
                ),
              )
              .toList();
        } else {
          customCushionNumbers = [];
        }
      } else {
        customCushionNumbers = [];
      }
      if (data.containsKey('ghosts')) {
        var gh = data['ghosts'];
        if (gh is List) {
          customGhosts = gh
              .map(
                (g) => {
                  'pos': Offset(
                    (g['x'] as num).toDouble(),
                    (g['y'] as num).toDouble(),
                  ),
                  'color': Color(g['color'] ?? Colors.white.value),
                  'type': BallType.values[g['type'] ?? 0],
                  'rotation': (g['rotation'] ?? 0.0).toDouble(),
                  'number': g['number']?.toString() ?? '',
                },
              )
              .toList();
        } else {
          customGhosts = [];
        }
      } else {
        customGhosts = [];
      }
      if (data['extraBalls'] is List) {
        customBalls = (data['extraBalls'] as List)
            .map(
              (b) => {
                'pos': Offset(
                  (b['x'] as num).toDouble(),
                  (b['y'] as num).toDouble(),
                ),
                'color': Color(b['color'] ?? Colors.blue.value),
                'number': b['number']?.toString() ?? '',
              },
            )
            .toList();
      } else {
        customBalls = [];
      }
      if (data['pathColors'] is Map) {
        final colors = data['pathColors'] as Map;
        whitePathColor = Color(colors['white'] ?? Colors.white70.value);
        yellowPathColor = Color(colors['yellow'] ?? Colors.yellow.value);
        redPathColor = Color(colors['red'] ?? Colors.redAccent.value);
        freePathColor = Color(colors['free'] ?? Colors.cyanAccent.value);
      }
      if (data.containsKey('effet')) {
        _effetData = data['effet'] != null
            ? Map<String, dynamic>.from(data['effet'])
            : null;
      } else {
        _effetData = null;
      }
    });
  }

  void _editStepTexts() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.amberAccent),
                const SizedBox(width: 8),
                const Expanded(child: Text('Kịch bản thuyết minh (Timeline)')),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  onPressed: () {
                    setDialogState(() {
                      stepScripts.add({
                        'text': 'Bước mới',
                        'start': stepScripts.isEmpty
                            ? 0.0
                            : ((stepScripts.last['start'] as double) +
                                      (stepScripts.last['duration'] as double))
                                  .clamp(0.0, 7.0),
                        'duration': 2.0,
                        'fontSize': 14.0,
                      });
                    });
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: stepScripts.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có kịch bản chạy chữ thuyết minh.\nBấm nút + ở trên để thêm dòng thuyết minh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stepScripts.length,
                      itemBuilder: (context, index) {
                        final script = stepScripts[index];
                        final double start = (script['start'] as num)
                            .toDouble();
                        final double duration = (script['duration'] as num)
                            .toDouble();
                        final double fontSize =
                            (script['fontSize'] as num?)?.toDouble() ?? 14.0;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.teal,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Capture Layout button
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 12,
                                      color: Colors.greenAccent,
                                    ),
                                    label: const Text(
                                      'Lưu thế bi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: Text(
                                            'Lưu thế bi - Bước ${index + 1}',
                                          ),
                                          content: const Text(
                                            'Hành động này sẽ ghi đè thế bi đang vẽ trên bàn vào Bước này. Bạn có chắc chắn muốn tiếp tục không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogCtx),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogCtx);
                                                script['layout'] =
                                                    _captureCurrentLayout();
                                                setDialogState(
                                                  () {},
                                                ); // update button state if it was null
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Đã lưu thế bi hiện tại vào Bước ${index + 1}!',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Lưu',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  // Restore Layout button (only if has layout)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: Icon(
                                      Icons.settings_backup_restore,
                                      size: 12,
                                      color: script['layout'] != null
                                          ? Colors.cyanAccent
                                          : Colors.grey,
                                    ),
                                    label: Text(
                                      'Tải lên bàn vẽ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: script['layout'] != null
                                            ? Colors.cyanAccent
                                            : Colors.grey,
                                      ),
                                    ),
                                    onPressed: script['layout'] != null
                                        ? () {
                                            _applyLayout(
                                              Map<String, dynamic>.from(
                                                script['layout'] as Map,
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Đã tải thế bi Bước ${index + 1} lên bàn vẽ!',
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        stepScripts.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller:
                                    TextEditingController(text: script['text'])
                                      ..selection = TextSelection.fromPosition(
                                        TextPosition(
                                          offset:
                                              (script['text'] as String).length,
                                        ),
                                      ),
                                onChanged: (val) {
                                  script['text'] = val;
                                },
                                maxLines: null,
                                minLines: 2,
                                decoration: InputDecoration(
                                  hintText:
                                      'Nhập phụ đề thuyết minh thuyết trình...',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Bắt đầu:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      min: 0.0,
                                      max: 7.0,
                                      divisions: 70,
                                      label: '${start.toStringAsFixed(1)}s',
                                      value: start.clamp(0.0, 7.0),
                                      onChanged: (v) {
                                        setDialogState(() {
                                          script['start'] = double.parse(
                                            v.toStringAsFixed(1),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${start.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Hiển thị:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      min: 0.5,
                                      max: 7.0,
                                      divisions: 65,
                                      label: '${duration.toStringAsFixed(1)}s',
                                      value: duration.clamp(0.5, 7.0),
                                      onChanged: (v) {
                                        setDialogState(() {
                                          script['duration'] = double.parse(
                                            v.toStringAsFixed(1),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${duration.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 60,
                                    child: Text(
                                      'Cỡ chữ:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      min: 10.0,
                                      max: 24.0,
                                      divisions: 14,
                                      label: '${fontSize.toStringAsFixed(0)}',
                                      value: fontSize.clamp(10.0, 24.0),
                                      onChanged: (v) {
                                        setDialogState(() {
                                          script['fontSize'] = double.parse(
                                            v.toStringAsFixed(0),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${fontSize.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  stepScripts.sort(
                    (a, b) => (a['start'] as num).compareTo(b['start'] as num),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Xác nhận & Sắp xếp'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTableAndSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chế độ bàn & Hệ số'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TableViewType>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Chế độ bàn',
                        isDense: true,
                      ),
                      value: _viewType,
                      items: TableViewType.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                viewTypeNames[e]!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _viewType = v;
                        });
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Đánh số (Hệ)',
                        isDense: true,
                      ),
                      value: _selectedSystemKey,
                      items: [
                        ...DiagramSystem.values.map(
                          (e) => DropdownMenuItem<String>(
                            value: 'system:${e.name}',
                            child: Text(
                              systemNames[e]!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        ..._customSystems.map((s) {
                          final name = s['name'] as String;
                          return DropdownMenuItem<String>(
                            value: 'custom:$name',
                            child: Text(
                              'Hệ: $name',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedSystemKey = v;
                          if (v.startsWith('system:')) {
                            final systemName = v.substring(7);
                            _system = DiagramSystem.values.firstWhere(
                              (e) => e.name == systemName,
                              orElse: () => DiagramSystem.standard,
                            );
                          } else if (v.startsWith('custom:')) {
                            _system = DiagramSystem.standard;
                            final name = v.substring(7);
                            final sys = _customSystems.firstWhere(
                              (s) => s['name'] == name,
                              orElse: () => {},
                            );
                            if (sys.containsKey('labels')) {
                              customLabels.clear();
                              final List<dynamic> lbls = sys['labels'];
                              for (var l in lbls) {
                                customLabels.add(
                                  CustomLabelData(
                                    Offset(
                                      (l['x'] as num).toDouble(),
                                      (l['y'] as num).toDouble(),
                                    ),
                                    l['text'].toString(),
                                    Color(
                                      l['color'] ?? Colors.yellowAccent.value,
                                    ),
                                    rotation:
                                        (l['rotation'] as num?)?.toDouble() ??
                                        0.0,
                                    role: l['role']?.toString(),
                                  ),
                                );
                              }
                            }
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _showLabelManagementDialog();
                        },
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Chỉnh số trên các băng'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.format_size,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cỡ chữ nút số:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: 6.0,
                            max: 16.0,
                            divisions: 20,
                            label: _labelFontSize.toStringAsFixed(1),
                            value: _labelFontSize.clamp(6.0, 16.0),
                            onChanged: (v) {
                              setState(() {
                                _labelFontSize = v;
                              });
                              setDialogState(() {});
                            },
                          ),
                        ),
                        Text(
                          _labelFontSize.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBallSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Bi điều khiển & Vị trí'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn quả bi để di chuyển bằng kéo thả:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBallSelectCircle(
                          ActiveBall.white,
                          Colors.white,
                          'Trắng',
                          setDialogState,
                        ),
                        _buildBallSelectCircle(
                          ActiveBall.yellow,
                          Colors.yellow,
                          'Vàng',
                          setDialogState,
                        ),
                        _buildBallSelectCircle(
                          ActiveBall.red,
                          Colors.red,
                          'Đỏ',
                          setDialogState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _showCoordinateInputDialog();
                      },
                      icon: const Icon(Icons.edit_location_alt, size: 16),
                      label: const Text(
                        'Nhập toạ độ bằng số',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBallSelectCircle(
    ActiveBall ball,
    Color color,
    String name,
    StateSetter setDialogState,
  ) {
    final bool isSelected = _selectedBall == ball;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBall = ball;
          _isDrawingPath = false;
          _isAddingLabel = false;
        });
        setDialogState(() {});
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                width: isSelected ? 3.0 : 1.0,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color == Colors.white ? Colors.black : Colors.white,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showPathManagementDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Vẽ đường bi chạy'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Chế độ Vẽ đường chạy',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Chạm vào bàn để vẽ các điểm nối tiếp',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isDrawingPath,
                      onChanged: (val) {
                        setState(() {
                          _isDrawingPath = val;
                          if (val) {
                            _isAddingLabel = false;
                            if (_selectedBall == ActiveBall.ghost)
                              _selectedBall = ActiveBall.white;
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Chọn loại bi vẽ đường chạy:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBallSelectCircle(
                          ActiveBall.white,
                          Colors.white,
                          'Bi Trắng',
                          setDialogState,
                        ),
                        _buildBallSelectCircle(
                          ActiveBall.yellow,
                          Colors.yellow,
                          'Bi Vàng',
                          setDialogState,
                        ),
                        _buildBallSelectCircle(
                          ActiveBall.red,
                          Colors.red,
                          'Bi Đỏ',
                          setDialogState,
                        ),
                        _buildBallSelectCircle(
                          ActiveBall.free,
                          Colors.cyan,
                          'Tự do',
                          setDialogState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.undo,
                            color: Colors.amberAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_selectedBall == ActiveBall.white &&
                                  whitePath.isNotEmpty)
                                whitePath.removeLast();
                              if (_selectedBall == ActiveBall.yellow &&
                                  yellowPath.isNotEmpty)
                                yellowPath.removeLast();
                              if (_selectedBall == ActiveBall.red &&
                                  redPath.isNotEmpty)
                                redPath.removeLast();
                              if (_selectedBall == ActiveBall.free &&
                                  freePaths.isNotEmpty) {
                                if (freePaths.last.isNotEmpty) {
                                  freePaths.last.removeLast();
                                } else {
                                  freePaths.removeLast();
                                }
                              }
                            });
                          },
                          tooltip: 'Hoàn tác điểm vừa vẽ',
                        ),
                        if (_selectedBall == ActiveBall.free) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.add_road,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                freePaths.add([]);
                              });
                            },
                            tooltip: 'Bắt đầu vẽ đường tự do mới',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                if (freePaths.isNotEmpty) {
                                  freePaths.removeLast();
                                }
                              });
                            },
                            tooltip: 'Xoá đường tự do cuối cùng',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLabelManagementDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Đánh số nhãn bàn'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Chế độ Đánh số',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Chạm vào bàn để đặt nhãn số',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isAddingLabel,
                      onChanged: (val) {
                        setState(() {
                          _isAddingLabel = val;
                          if (val) {
                            _isDrawingPath = false;
                            if (_selectedBall == ActiveBall.ghost)
                              _selectedBall = ActiveBall.white;
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    const Divider(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _showLabelInputDialog(const Offset(2.0, 4.0));
                      },
                      icon: const Icon(Icons.add_comment, size: 16),
                      label: const Text(
                        'Thêm nhãn mới bằng toạ độ',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Danh sách nhãn hiện tại:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (customLabels.isEmpty)
                      const Text(
                        'Chưa có nhãn nào',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: customLabels.length,
                          itemBuilder: (context, idx) {
                            final lbl = customLabels[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                'Nhãn: "${lbl.text}" tại (${lbl.pos.dx.toStringAsFixed(1)}, ${lbl.pos.dy.toStringAsFixed(1)})',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.orangeAccent,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      _showLabelInputDialog(lbl.pos, idx);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        customLabels.removeAt(idx);
                                      });
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGhostBallManagementDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Quản lý Bi ảo (Ghost Ball)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Chế độ Bi ảo',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Chạm vào bàn để đặt thêm bi ảo mới',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _selectedBall == ActiveBall.ghost,
                      onChanged: (val) {
                        setState(() {
                          if (val) {
                            _selectedBall = ActiveBall.ghost;
                            _isDrawingPath = false;
                            _isAddingLabel = false;
                          } else {
                            _selectedBall = ActiveBall.white;
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    const Divider(),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          customGhosts.add({
                            'pos': const Offset(2.0, 4.0),
                            'color': Colors.white,
                            'type': BallType.full,
                            'rotation': 0.0,
                            'number': '',
                          });
                        });
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Thêm nhanh bi ảo tại tâm',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      'Danh sách bi ảo hiện tại:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (customGhosts.isEmpty)
                      const Text(
                        'Chưa có bi ảo nào',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: customGhosts.length,
                          itemBuilder: (context, idx) {
                            final g = customGhosts[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                'Bi ảo ${idx + 1} tại (${(g['pos'] as Offset).dx.toStringAsFixed(1)}, ${(g['pos'] as Offset).dy.toStringAsFixed(1)})',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.palette,
                                      size: 16,
                                      color: Colors.cyanAccent,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      _showGhostActionsDialog(idx);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        customGhosts.removeAt(idx);
                                      });
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool get _canUndoCurrentAction {
    if (_isDrawingSegment) {
      return _pendingSegmentStart != null || freePaths.isNotEmpty;
    }
    if (_isDrawingPath) {
      if (_selectedBall == ActiveBall.white) return whitePath.isNotEmpty;
      if (_selectedBall == ActiveBall.yellow) return yellowPath.isNotEmpty;
      if (_selectedBall == ActiveBall.red) return redPath.isNotEmpty;
      return freePaths.isNotEmpty && freePaths.last.isNotEmpty;
    }
    if (_isAddingLabel) return customLabels.isNotEmpty;
    if (_isAddingCushionNumber) return customCushionNumbers.isNotEmpty;
    if (_selectedBall == ActiveBall.ghost) return customGhosts.isNotEmpty;
    return false;
  }

  // The diagram editor is intentionally static. Animation/timeline controls
  // are kept out of the editing flow to make ball placement easier.
  bool get _showAnimationEditor => false;

  void _selectEditorMode(String mode) {
    setState(() {
      _isDrawingPath = mode == 'path';
      _isDrawingSegment = mode == 'segment';
      if (!_isDrawingSegment) _pendingSegmentStart = null;
      _isAddingLabel = mode == 'label';
      _isAddingCushionNumber = mode == 'cushion_number';
      if (mode == 'ghost') {
        _selectedBall = ActiveBall.ghost;
      } else if (_selectedBall == ActiveBall.ghost ||
          _selectedBall == ActiveBall.free) {
        _selectedBall = ActiveBall.white;
      }
    });
  }

  void _selectMainBall(ActiveBall ball) {
    setState(() {
      _selectedBall = ball;
      _isAddingLabel = false;
      _isAddingCushionNumber = false;
    });
  }

  void _undoCurrentAction() {
    setState(() {
      if (_isDrawingSegment) {
        if (_pendingSegmentStart != null) {
          _pendingSegmentStart = null;
        } else if (freePaths.isNotEmpty) {
          freePaths.removeLast();
          if (freePathColors.isNotEmpty) freePathColors.removeLast();
        }
      } else if (_isDrawingPath) {
        if (_selectedBall == ActiveBall.white && whitePath.isNotEmpty) {
          whitePath.removeLast();
        } else if (_selectedBall == ActiveBall.yellow &&
            yellowPath.isNotEmpty) {
          yellowPath.removeLast();
        } else if (_selectedBall == ActiveBall.red && redPath.isNotEmpty) {
          redPath.removeLast();
        } else if (_selectedBall == ActiveBall.free && freePaths.isNotEmpty) {
          if (freePaths.last.isNotEmpty) freePaths.last.removeLast();
          if (freePaths.last.isEmpty) {
            freePaths.removeLast();
            if (freePathColors.isNotEmpty) freePathColors.removeLast();
          }
        }
      } else if (_isAddingLabel && customLabels.isNotEmpty) {
        customLabels.removeLast();
      } else if (_isAddingCushionNumber && customCushionNumbers.isNotEmpty) {
        customCushionNumbers.removeLast();
      } else if (_selectedBall == ActiveBall.ghost && customGhosts.isNotEmpty) {
        customGhosts.removeLast();
      }
    });
  }

  Color get _activePathColor {
    if (_selectedBall == ActiveBall.yellow) return yellowPathColor;
    if (_selectedBall == ActiveBall.red) return redPathColor;
    if (_selectedBall == ActiveBall.free) return freePathColor;
    return whitePathColor;
  }

  void _setActivePathColor(Color color) {
    setState(() {
      if (_selectedBall == ActiveBall.yellow) {
        yellowPathColor = color;
      } else if (_selectedBall == ActiveBall.red) {
        redPathColor = color;
      } else if (_selectedBall == ActiveBall.free) {
        freePathColor = color;
      } else {
        whitePathColor = color;
      }
    });
  }

  Widget _buildToolsToolbar() {
    Widget tool(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap, {
      bool selected = false,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? Colors.cyanAccent.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFF0D1528),
      child: SizedBox(
        height: 51,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            tool(
              Icons.table_restaurant,
              'Bộ số hệ thống',
              Colors.tealAccent,
              _showTableAndSystemSettingsDialog,
            ),
            tool(
              Icons.add_circle,
              'Thêm bi',
              Colors.lightGreenAccent,
              () => _showCustomBallDialog(),
            ),
            tool(
              Icons.linear_scale,
              'Đoạn thẳng',
              Colors.lightBlueAccent,
              () => _selectEditorMode('segment'),
              selected: _isDrawingSegment,
            ),
            tool(
              Icons.route,
              'Quỹ đạo',
              Colors.orangeAccent,
              () => _selectEditorMode('path'),
              selected: _isDrawingPath,
            ),
            tool(
              Icons.numbers,
              'Nhãn',
              Colors.amberAccent,
              () => _selectEditorMode('label'),
              selected: _isAddingLabel,
            ),
            tool(
              Icons.format_list_numbered,
              'Số băng',
              Colors.lightGreenAccent,
              () => _selectEditorMode('cushion_number'),
              selected: _isAddingCushionNumber,
            ),
            tool(
              Icons.blur_circular,
              'Bi ảo',
              Colors.cyanAccent,
              _showGhostBallManagementDialog,
            ),
            tool(
              Icons.blur_on_rounded,
              'Ép-phê',
              Colors.pinkAccent,
              _editEffet,
            ),
            tool(
              Icons.save_alt,
              'Lưu mẫu',
              Colors.deepOrangeAccent,
              _saveCustomSystem,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEditorToolbar() {
    final String activeMode = _isDrawingSegment
        ? 'segment'
        : _isDrawingPath
        ? 'path'
        : _isAddingLabel
        ? 'label'
        : _isAddingCushionNumber
        ? 'cushion_number'
        : _selectedBall == ActiveBall.ghost
        ? 'ghost'
        : 'none';

    if (activeMode == 'segment') {
      final List<Color> presetColors = [
        Colors.cyanAccent,
        Colors.white,
        Colors.yellow,
        Colors.redAccent,
        Colors.greenAccent,
        Colors.pinkAccent,
        Colors.amberAccent,
        Colors.orangeAccent,
      ];
      return Material(
        color: const Color(0xFF121A2D),
        child: SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Text('Màu nét kẻ:', style: TextStyle(fontSize: 12)),
                ),
              ),
              ...presetColors.map(
                (color) => Tooltip(
                  message: 'Chọn màu nét',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => segmentColor = color),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: segmentColor.value == color.value
                              ? Colors.white
                              : Colors.white24,
                          width: segmentColor.value == color.value ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _canUndoCurrentAction ? _undoCurrentAction : null,
                icon: const Icon(Icons.undo),
                tooltip: 'Hoàn tác',
              ),
            ],
          ),
        ),
      );
    }

    if (activeMode == 'cushion_number') {
      return Material(
        color: const Color(0xFF121A2D),
        child: SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Text('Số băng:', style: TextStyle(fontSize: 12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showCushionNumberInputDialog(const Offset(2.0, 0.0)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Thêm số băng',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _canUndoCurrentAction ? _undoCurrentAction : null,
                icon: const Icon(Icons.undo),
                tooltip: 'Hoàn tác',
              ),
            ],
          ),
        ),
      );
    }

    // Các chế độ đã có ở thanh công cụ phía trên.
    // Thanh phụ chỉ xuất hiện cho tùy chọn riêng của Quỹ đạo.
    if (activeMode != 'path') return const SizedBox.shrink();

    Widget ballButton(ActiveBall ball, Color color, String tooltip) {
      final selected = _selectedBall == ball;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _selectMainBall(ball),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected ? Colors.cyanAccent : Colors.white54,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFF121A2D),
      child: SizedBox(
        height: 54,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Center(child: Text('Chọn bi:')),
            ),
            ballButton(ActiveBall.white, Colors.white, 'Quỹ đạo bi trắng'),
            ballButton(ActiveBall.yellow, Colors.yellow, 'Quỹ đạo bi vàng'),
            ballButton(ActiveBall.red, Colors.red, 'Quỹ đạo bi đỏ'),
            IconButton(
              onPressed: _canUndoCurrentAction ? _undoCurrentAction : null,
              icon: const Icon(Icons.undo),
              tooltip: 'Hoàn tác',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ bi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _canUndoCurrentAction ? _undoCurrentAction : null,
            tooltip: 'Hoàn tác thao tác gần nhất',
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: () {
              // Tự động sắp xếp timeline theo thời điểm bắt đầu
              stepScripts.sort(
                (a, b) => (a['start'] as num).compareTo(b['start'] as num),
              );
              final data = _captureCurrentLayout();
              data['stepScripts'] = stepScripts;
              Navigator.pop(context, DiagramDocumentCodec.encode(data));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.black38,
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  _isAddingLabel
                      ? Icons.numbers
                      : (_isDrawingSegment
                            ? Icons.linear_scale
                            : _isDrawingPath
                            ? Icons.timeline
                            : (_selectedBall == ActiveBall.ghost
                                  ? Icons.add_circle_outline
                                  : Icons.touch_app)),
                  size: 14,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isAddingLabel
                        ? 'Chế độ: Đánh số nhãn. Chạm lên bàn để đặt nhãn.'
                        : (_isDrawingSegment
                              ? (_pendingSegmentStart == null
                                    ? 'Chạm nút băng đầu tiên của đoạn thẳng.'
                                    : 'Chạm nút băng thứ hai để hoàn tất đoạn thẳng.')
                              : _isDrawingPath
                              ? 'Quỹ đạo: chọn bi, chạm để thêm điểm; kéo điểm để chỉnh sửa.'
                              : (_selectedBall == ActiveBall.ghost
                                    ? 'Chế độ: Thêm bi ảo. Chạm để đặt bi ảo.'
                                    : 'Chế độ xem sơ đồ. Chọn Nhãn hoặc Bi ảo để thao tác.')),
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          _buildToolsToolbar(),
          _buildQuickEditorToolbar(),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _getAspect(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          onPanStart: (details) {
                            setState(() {
                              _dragPosition = details.localPosition;
                            });
                            Offset diamondPos = _pixelToDiamond(
                              details.localPosition,
                              constraints,
                              clamp: false,
                            );

                            if ((_isDrawingPath &&
                                    !_isInsidePlayArea(diamondPos)) ||
                                (_isDrawingSegment &&
                                    !_isInsideSegmentArea(diamondPos))) {
                              _handledByPan = true;
                              setState(() => _dragPosition = null);
                              return;
                            }

                            // The selected ball's starting position remains
                            // draggable. Other balls are checked after path
                            // points so an endpoint overlapping a target ball
                            // can still be adjusted.
                            if (_isDrawingPath) {
                              final selectedBallPosition =
                                  _selectedBall == ActiveBall.white
                                  ? whitePos
                                  : _selectedBall == ActiveBall.yellow
                                  ? yellowPos
                                  : _selectedBall == ActiveBall.red
                                  ? redPos
                                  : null;
                              if (selectedBallPosition != null &&
                                  (selectedBallPosition - diamondPos).distance <
                                      0.4) {
                                _handledByPan = true;
                                _draggingMainBall = _selectedBall;
                                setState(() {});
                                return;
                              }
                            }

                            // 1. Kiểm tra bấm trúng số băng hoặc nhãn
                            if (!_isDrawingPath && !_isDrawingSegment) {
                              if (_isAddingCushionNumber) {
                                double minDistance = 0.4;
                                int? closestIndex;
                                for (
                                  int i = 0;
                                  i < customCushionNumbers.length;
                                  i++
                                ) {
                                  double dist =
                                      (customCushionNumbers[i].pos - diamondPos)
                                          .distance;
                                  if (dist < minDistance) {
                                    minDistance = dist;
                                    closestIndex = i;
                                  }
                                }
                                _editingCushionNumberIndex = closestIndex;
                                if (_editingCushionNumberIndex != null) return;
                              } else {
                                double minDistance = 0.4;
                                int? closestIndex;
                                for (int i = 0; i < customLabels.length; i++) {
                                  double dist =
                                      (customLabels[i].pos - diamondPos)
                                          .distance;
                                  if (dist < minDistance) {
                                    minDistance = dist;
                                    closestIndex = i;
                                  }
                                }
                                _editingLabelIndex = closestIndex;
                                if (_editingLabelIndex != null) return;
                              }
                            }

                            // 2. Kiểm tra bấm trúng điểm trên đường chạy (nếu đang ở chế độ Vẽ đường)
                            if (_isDrawingPath || _isDrawingSegment) {
                              _handledByPan = true;
                              // Vùng bắt lớn hơn bán kính hiển thị để
                              // thao tác kéo bằng ngón tay không bị trượt
                              // khỏi điểm cuối quỹ đạo.
                              double minDistance = 0.8;
                              int? closestIndex;
                              ActiveBall? foundBallType;
                              int? foundFreePathIndex;

                              if (_isDrawingPath) {
                                // 1. Ưu tiên kiểm tra điểm quỹ đạo của bi đang chọn trước
                                List<Offset>? activeList;
                                if (_selectedBall == ActiveBall.white)
                                  activeList = whitePath;
                                else if (_selectedBall == ActiveBall.yellow)
                                  activeList = yellowPath;
                                else if (_selectedBall == ActiveBall.red)
                                  activeList = redPath;

                                if (activeList != null &&
                                    activeList.isNotEmpty) {
                                  for (int i = 0; i < activeList.length; i++) {
                                    final dist =
                                        (activeList[i] - diamondPos).distance;
                                    if (dist < minDistance) {
                                      minDistance = dist;
                                      closestIndex = i;
                                      foundBallType = _selectedBall;
                                    }
                                  }
                                }

                                // 2. Nếu chưa chạm điểm của bi hiện tại, kiểm tra các bi khác
                                if (closestIndex == null) {
                                  for (int i = 0; i < whitePath.length; i++) {
                                    final dist =
                                        (whitePath[i] - diamondPos).distance;
                                    if (dist < minDistance) {
                                      minDistance = dist;
                                      closestIndex = i;
                                      foundBallType = ActiveBall.white;
                                    }
                                  }
                                  for (int i = 0; i < yellowPath.length; i++) {
                                    final dist =
                                        (yellowPath[i] - diamondPos).distance;
                                    if (dist < minDistance) {
                                      minDistance = dist;
                                      closestIndex = i;
                                      foundBallType = ActiveBall.yellow;
                                    }
                                  }
                                  for (int i = 0; i < redPath.length; i++) {
                                    final dist =
                                        (redPath[i] - diamondPos).distance;
                                    if (dist < minDistance) {
                                      minDistance = dist;
                                      closestIndex = i;
                                      foundBallType = ActiveBall.red;
                                    }
                                  }
                                }
                              }
                              // 3. Kiểm tra các đường tự do
                              if (closestIndex == null) {
                                for (
                                  int pIdx = 0;
                                  pIdx < freePaths.length;
                                  pIdx++
                                ) {
                                  for (
                                    int i = 0;
                                    i < freePaths[pIdx].length;
                                    i++
                                  ) {
                                    double dist =
                                        (freePaths[pIdx][i] - diamondPos)
                                            .distance;
                                    if (dist < minDistance) {
                                      minDistance = dist;
                                      closestIndex = i;
                                      foundBallType = ActiveBall.free;
                                      foundFreePathIndex = pIdx;
                                    }
                                  }
                                }
                              }

                              if (closestIndex != null &&
                                  foundBallType != null) {
                                _selectedBall = foundBallType;
                                _editingPointIndex = closestIndex;
                                _editingFreePathIndex = foundFreePathIndex;
                                setState(() {});
                                return;
                              }

                              // 4. Nếu ở chế độ vẽ và chạm/kéo ở vị trí chưa có điểm:
                              // Tự động thêm điểm mới tại điểm chạm và cho phép kéo thả tự do vị trí cuối ngay lập tức!
                              if (_isDrawingPath) {
                                if (_selectedBall == ActiveBall.white) {
                                  whitePath.add(diamondPos);
                                  _editingPointIndex = whitePath.length - 1;
                                } else if (_selectedBall == ActiveBall.yellow) {
                                  yellowPath.add(diamondPos);
                                  _editingPointIndex = yellowPath.length - 1;
                                } else if (_selectedBall == ActiveBall.red) {
                                  redPath.add(diamondPos);
                                  _editingPointIndex = redPath.length - 1;
                                } else if (_selectedBall == ActiveBall.free) {
                                  if (freePaths.isEmpty) {
                                    freePaths.add([]);
                                    freePathColors.add(freePathColor);
                                  }
                                  freePaths.last.add(diamondPos);
                                  _editingFreePathIndex = freePaths.length - 1;
                                  _editingPointIndex =
                                      freePaths.last.length - 1;
                                }
                                setState(() {});
                                return;
                              }

                              if (_isDrawingSegment) {
                                final start = _snapSegmentPosition(diamondPos);
                                _segmentDragStart = start;
                                _segmentDragEnd = start;
                                setState(() {});
                                return;
                              }

                              // Chế độ vẽ chỉ được tương tác với các
                              // điểm đường chạy. Không cho thao tác kéo rơi
                              // xuống các bi hoặc thành phần khác.
                              _draggingMainBall = null;
                              _editingCustomBallIndex = null;
                              _editingGhostIndex = null;
                              return;
                            }

                            if (false) {
                              int? hitCustomBallIndex;
                              double minCustomBallDistance = 0.4;
                              for (int i = 0; i < customBalls.length; i++) {
                                final distance =
                                    ((customBalls[i]['pos'] as Offset) -
                                            diamondPos)
                                        .distance;
                                if (distance < minCustomBallDistance) {
                                  minCustomBallDistance = distance;
                                  hitCustomBallIndex = i;
                                }
                              }
                              if (hitCustomBallIndex != null) {
                                _editingCustomBallIndex = hitCustomBallIndex;
                                setState(() {});
                                return;
                              }
                            }

                            // 2.5 Kiểm tra bấm trúng bi ảo
                            int? hitGhostIndex;
                            double minGhostDist = 0.4;
                            for (int i = 0; i < customGhosts.length; i++) {
                              double dist =
                                  ((customGhosts[i]['pos'] as Offset) -
                                          diamondPos)
                                      .distance;
                              if (dist < minGhostDist) {
                                minGhostDist = dist;
                                hitGhostIndex = i;
                              }
                            }
                            if (hitGhostIndex != null) {
                              _editingGhostIndex = hitGhostIndex;
                              setState(() {});
                              return;
                            }

                            bool hitBall = false;
                            // Chỉ cho phép chọn/kéo ba bi chính trong chế độ
                            // Di chuyển. Khi vẽ đường, rung tay nhẹ lúc thêm
                            // điểm không được làm thay đổi tọa độ bi.
                            if (!_isDrawingPath &&
                                !_isAddingLabel &&
                                !_isAddingCushionNumber) {
                              final distToWhite =
                                  (whitePos - diamondPos).distance;
                              final distToYellow =
                                  (yellowPos - diamondPos).distance;
                              final distToRed = (redPos - diamondPos).distance;
                              const threshold = 0.4;

                              if (distToWhite < threshold &&
                                  distToWhite <= distToYellow &&
                                  distToWhite <= distToRed) {
                                _selectedBall = ActiveBall.white;
                                hitBall = true;
                              } else if (distToYellow < threshold &&
                                  distToYellow <= distToWhite &&
                                  distToYellow <= distToRed) {
                                _selectedBall = ActiveBall.yellow;
                                hitBall = true;
                              } else if (distToRed < threshold &&
                                  distToRed <= distToWhite &&
                                  distToRed <= distToYellow) {
                                _selectedBall = ActiveBall.red;
                                hitBall = true;
                              }
                            }

                            // Để tránh xung đột: khi vẽ đường hoặc đánh số, nếu KHÔNG bấm trúng bi thì không cho di chuyển bi
                            _draggingMainBall = hitBall ? _selectedBall : null;
                            setState(() {});
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _dragPosition = details.localPosition;
                            });
                            Offset diamondPos = _pixelToDiamond(
                              details.localPosition,
                              constraints,
                              clamp: false,
                            );
                            if (_draggingMainBall != null) {
                              setState(() {
                                final position = _clampBallPosition(diamondPos);
                                if (_draggingMainBall == ActiveBall.white) {
                                  whitePos = position;
                                }
                                if (_draggingMainBall == ActiveBall.yellow) {
                                  yellowPos = position;
                                }
                                if (_draggingMainBall == ActiveBall.red) {
                                  redPos = position;
                                }
                              });
                            } else if (_isDrawingSegment &&
                                _segmentDragStart != null) {
                              setState(() {
                                _segmentDragEnd = _snapSegmentPosition(
                                  diamondPos,
                                );
                              });
                            } else if ((_isDrawingPath || _isDrawingSegment) &&
                                _editingPointIndex != null) {
                              final pathPosition = _clampToPlayArea(diamondPos);
                              setState(() {
                                if (_selectedBall == ActiveBall.white)
                                  whitePath[_editingPointIndex!] = pathPosition;
                                if (_selectedBall == ActiveBall.yellow)
                                  yellowPath[_editingPointIndex!] =
                                      pathPosition;
                                if (_selectedBall == ActiveBall.red)
                                  redPath[_editingPointIndex!] = pathPosition;
                                if (_selectedBall == ActiveBall.free &&
                                    _editingFreePathIndex != null) {
                                  freePaths[_editingFreePathIndex!][_editingPointIndex!] =
                                      pathPosition;
                                }
                              });
                            } else if (_editingCushionNumberIndex != null) {
                              Offset labelPos = _pixelToDiamond(
                                details.localPosition,
                                constraints,
                                clamp: false,
                              );
                              setState(() {
                                customCushionNumbers[_editingCushionNumberIndex!]
                                        .pos =
                                    labelPos;
                              });
                            } else if (_editingLabelIndex != null) {
                              Offset labelPos = _pixelToDiamond(
                                details.localPosition,
                                constraints,
                                clamp: false,
                              );
                              setState(() {
                                customLabels[_editingLabelIndex!].pos =
                                    labelPos;
                              });
                            } else if (_editingCustomBallIndex != null) {
                              setState(() {
                                customBalls[_editingCustomBallIndex!]['pos'] =
                                    _clampBallPosition(diamondPos);
                              });
                            } else if (_editingGhostIndex != null) {
                              setState(() {
                                customGhosts[_editingGhostIndex!]['pos'] =
                                    _clampBallPosition(diamondPos);
                              });
                            } else if (!_isDrawingPath &&
                                !_isAddingLabel &&
                                !_isAddingCushionNumber &&
                                _draggingMainBall != null) {
                              // Tọa độ bi chỉ thay đổi khi thao tác kéo
                              // bắt đầu trúng bi trong chế độ Di chuyển.
                              setState(() {
                                if (_draggingMainBall == ActiveBall.white)
                                  whitePos = diamondPos;
                                if (_draggingMainBall == ActiveBall.yellow)
                                  yellowPos = diamondPos;
                                if (_draggingMainBall == ActiveBall.red)
                                  redPos = diamondPos;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            setState(() {
                              if (_isDrawingSegment &&
                                  _segmentDragStart != null &&
                                  _segmentDragEnd != null &&
                                  _segmentDragStart != _segmentDragEnd) {
                                freePaths.add([
                                  _segmentDragStart!,
                                  _segmentDragEnd!,
                                ]);
                                freePathColors.add(segmentColor);
                                _pendingSegmentStart = null;
                              }
                              _segmentDragStart = null;
                              _segmentDragEnd = null;
                              _handledByPan = false;
                              _dragPosition = null;
                              _editingPointIndex = null;
                              _editingLabelIndex = null;
                              _editingCushionNumberIndex = null;
                              _draggingMainBall = null;
                              _editingGhostIndex = null;
                              _editingCustomBallIndex = null;
                              _editingFreePathIndex = null;
                            });
                          },
                          onPanCancel: () {
                            setState(() {
                              _segmentDragStart = null;
                              _segmentDragEnd = null;
                              _handledByPan = false;
                              _dragPosition = null;
                              _editingPointIndex = null;
                              _editingLabelIndex = null;
                              _editingCushionNumberIndex = null;
                              _draggingMainBall = null;
                              _editingGhostIndex = null;
                              _editingCustomBallIndex = null;
                              _editingFreePathIndex = null;
                            });
                          },
                          onTapUp: (details) {
                            if (_handledByPan) {
                              _handledByPan = false;
                              return;
                            }
                            Offset diamondPos = _pixelToDiamond(
                              details.localPosition,
                              constraints,
                              clamp: false,
                            );
                            if ((_isDrawingPath &&
                                    !_isInsidePlayArea(diamondPos)) ||
                                (_isDrawingSegment &&
                                    !_isInsideSegmentArea(diamondPos))) {
                              return;
                            }
                            if (_isDrawingSegment) {
                              final snapped = _snapSegmentPosition(diamondPos);
                              setState(() {
                                if (_pendingSegmentStart == null) {
                                  _pendingSegmentStart = snapped;
                                } else {
                                  freePaths.add([
                                    _pendingSegmentStart!,
                                    snapped,
                                  ]);
                                  freePathColors.add(segmentColor);
                                  _pendingSegmentStart = null;
                                }
                              });
                            } else if (_isDrawingPath) {
                              // Chạm vào vùng trống để thêm điểm mới cho bi đang chọn
                              setState(() {
                                if (_selectedBall == ActiveBall.white)
                                  whitePath.add(diamondPos);
                                if (_selectedBall == ActiveBall.yellow)
                                  yellowPath.add(diamondPos);
                                if (_selectedBall == ActiveBall.red)
                                  redPath.add(diamondPos);
                                if (_selectedBall == ActiveBall.free) {
                                  if (freePaths.isEmpty) {
                                    freePaths.add([]);
                                    freePathColors.add(freePathColor);
                                  }
                                  freePaths.last.add(diamondPos);
                                }
                              });
                            } else if (_isAddingCushionNumber) {
                              int? clickedCushionIndex;
                              double minDistance = 0.4;
                              for (
                                int i = 0;
                                i < customCushionNumbers.length;
                                i++
                              ) {
                                final distance =
                                    (customCushionNumbers[i].pos - diamondPos)
                                        .distance;
                                if (distance < minDistance) {
                                  minDistance = distance;
                                  clickedCushionIndex = i;
                                }
                              }
                              if (clickedCushionIndex != null) {
                                _showCushionNumberInputDialog(
                                  customCushionNumbers[clickedCushionIndex].pos,
                                  clickedCushionIndex,
                                );
                                return;
                              }
                              _showCushionNumberInputDialog(diamondPos);
                              return;
                            } else {
                              int? clickedLabelIndex;
                              double minLabelDistance = 0.4;
                              for (int i = 0; i < customLabels.length; i++) {
                                final distance =
                                    (customLabels[i].pos - diamondPos).distance;
                                if (distance < minLabelDistance) {
                                  minLabelDistance = distance;
                                  clickedLabelIndex = i;
                                }
                              }

                              // Existing labels can always be selected and
                              // edited. Label mode only controls creation.
                              if (clickedLabelIndex != null) {
                                _showLabelInputDialog(
                                  customLabels[clickedLabelIndex].pos,
                                  clickedLabelIndex,
                                );
                                return;
                              }

                              if (_isAddingLabel) {
                                _showLabelInputDialog(diamondPos);
                                return;
                              }

                              int? clickedCustomBallIndex;
                              double minCustomBallDistance = 0.4;
                              for (int i = 0; i < customBalls.length; i++) {
                                final distance =
                                    ((customBalls[i]['pos'] as Offset) -
                                            diamondPos)
                                        .distance;
                                if (distance < minCustomBallDistance) {
                                  minCustomBallDistance = distance;
                                  clickedCustomBallIndex = i;
                                }
                              }
                              if (clickedCustomBallIndex != null) {
                                _showCustomBallDialog(
                                  index: clickedCustomBallIndex,
                                );
                                return;
                              }

                              int? clickedGhostIndex;
                              double minGhostDistance = 0.4;
                              for (int i = 0; i < customGhosts.length; i++) {
                                final distance =
                                    ((customGhosts[i]['pos'] as Offset) -
                                            diamondPos)
                                        .distance;
                                if (distance < minGhostDistance) {
                                  minGhostDistance = distance;
                                  clickedGhostIndex = i;
                                }
                              }

                              // Existing ghost balls can always be edited by
                              // tapping them, even while using Move mode.
                              if (clickedGhostIndex != null) {
                                _showGhostActionsDialog(clickedGhostIndex);
                              } else if (_selectedBall == ActiveBall.ghost) {
                                setState(() {
                                  customGhosts.add({
                                    'pos': _clampBallPosition(diamondPos),
                                    'color': Colors.white,
                                    'type': BallType.full,
                                    'rotation': 0.0,
                                    'number': '',
                                  });
                                });
                              }
                            }
                          },
                          child: BilliardDiagram(
                            balls: _buildBalls(),
                            paths: _buildPaths(),
                            labels: _buildLabels(),
                            system: _system,
                            viewType: _viewType,
                            isVertical: true,
                            showPlayButton: false,
                            effetData: _effetData,
                          ),
                        ),
                        // Real-time subtitle/narration preview in editor
                        if (_showAnimationEditor &&
                            _activeStepIndex != null &&
                            _activeStepIndex! < stepScripts.length)
                          () {
                            final script = stepScripts[_activeStepIndex!];
                            final String text = script['text'] ?? '';
                            if (text.isEmpty) return const SizedBox();

                            final double fs =
                                (script['fontSize'] as num?)?.toDouble() ??
                                14.0;
                            final double? customX = script['x'] != null
                                ? (script['x'] as num).toDouble()
                                : null;
                            final double? customY = script['y'] != null
                                ? (script['y'] as num).toDouble()
                                : null;
                            final double customRot = script['rotation'] != null
                                ? (script['rotation'] as num).toDouble()
                                : 0.0;
                            final Color customColor = script['color'] != null
                                ? Color(script['color'] as int)
                                : Colors.white;

                            Widget textWidget = Text(
                              text,
                              style: TextStyle(
                                fontSize: fs,
                                fontWeight: FontWeight.bold,
                                color: customColor,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1.5, 1.5),
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.9),
                                  ),
                                  Shadow(
                                    offset: const Offset(-1.5, -1.5),
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.9),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            );

                            if (customRot != 0.0) {
                              textWidget = Transform.rotate(
                                angle: customRot * math.pi / 180.0,
                                child: textWidget,
                              );
                            }

                            if (customX != null && customY != null) {
                              final bool rightRail =
                                  _viewType != TableViewType.halfWidth &&
                                  _viewType !=
                                      TableViewType.halfWidthHalfLength &&
                                  _viewType !=
                                      TableViewType.halfWidthThirdLength &&
                                  _viewType !=
                                      TableViewType.halfWidthQuarterLength;
                              final double baseW = rightRail ? 124.0 : 62.0;
                              final double woodR =
                                  constraints.maxWidth * (8.0 / baseW);
                              final double cushionW =
                                  constraints.maxWidth * (4.0 / baseW);
                              final double totalR = woodR + cushionW;
                              final double playW =
                                  constraints.maxWidth -
                                  totalR -
                                  (rightRail ? totalR : 0);
                              final double diamondSp =
                                  playW / (rightRail ? 4.0 : 2.0);

                              final double relX = customX / 4.0;
                              final double relY = customY / 4.0;
                              final double pxX =
                                  totalR + (relX * diamondSp * 4);
                              final double pxY =
                                  totalR + (relY * diamondSp * 4);

                              double leftPos = pxX;
                              double topPos = pxY;

                              return Positioned(
                                left: leftPos - 120,
                                width: 240,
                                top: topPos - 20,
                                child: IgnorePointer(child: textWidget),
                              );
                            } else {
                              return Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: IgnorePointer(
                                  child: Center(child: textWidget),
                                ),
                              );
                            }
                          }(),
                        if (_dragPosition != null && _isDraggingSomething)
                          () {
                            final double left = (_dragPosition!.dx - 50).clamp(
                              0.0,
                              constraints.maxWidth - 100.0,
                            );
                            final double top = (_dragPosition!.dy - 110).clamp(
                              0.0,
                              constraints.maxHeight - 100.0,
                            );
                            final double centerX = left + 50.0;
                            final double centerY = top + 50.0;
                            final Offset dynamicFocalPointOffset = Offset(
                              _dragPosition!.dx - centerX,
                              _dragPosition!.dy - centerY,
                            );

                            return Positioned(
                              left: left,
                              top: top,
                              child: RawMagnifier(
                                decoration: const MagnifierDecoration(
                                  shape: CircleBorder(
                                    side: BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                size: const Size(100, 100),
                                magnificationScale: 2.0,
                                focalPointOffset: dynamicFocalPointOffset,
                              ),
                            );
                          }(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (_showAnimationEditor) const SizedBox(height: 5),
          // Timeline Steps Selector Bar (Capcut-style Timeline Track Editor)
          if (_showAnimationEditor)
            LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth =
                    constraints.maxWidth - 24; // margin padding offset
                final double timelineMaxSeconds = 7.0;
                final double timeScale = totalWidth / timelineMaxSeconds;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row
                      Row(
                        children: [
                          const Icon(
                            Icons.video_label,
                            size: 16,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Timeline thuyết minh:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          // Add step button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final double startVal = stepScripts.isEmpty
                                    ? 0.0
                                    : ((stepScripts.last['start'] as double) +
                                              (stepScripts.last['duration']
                                                  as double))
                                          .clamp(0.0, 7.0);
                                stepScripts.add({
                                  'text': 'Bước mới',
                                  'start': startVal,
                                  'duration': 2.0,
                                  'fontSize': 14.0,
                                });
                                _activeStepIndex = stepScripts.length - 1;
                                _timelinePlayhead = startVal;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm phân cảnh mới!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 12,
                                    color: Colors.greenAccent,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Thêm phân cảnh',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Visual Timeline Widget (Capcut-style)
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Stack(
                          children: [
                            // 1. Time Ruler ticks & labels
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 20,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  setState(() {
                                    _timelinePlayhead =
                                        (details.localPosition.dx / timeScale)
                                            .clamp(0.0, 7.0);
                                    _timelinePlayhead = double.parse(
                                      _timelinePlayhead.toStringAsFixed(1),
                                    );
                                    // Locate active step under playhead
                                    int? foundIndex;
                                    for (
                                      int i = 0;
                                      i < stepScripts.length;
                                      i++
                                    ) {
                                      double start =
                                          (stepScripts[i]['start'] as num)
                                              .toDouble();
                                      double end =
                                          start +
                                          (stepScripts[i]['duration'] as num)
                                              .toDouble();
                                      if (_timelinePlayhead >= start &&
                                          _timelinePlayhead <= end) {
                                        foundIndex = i;
                                        break;
                                      }
                                    }
                                    if (foundIndex != null) {
                                      _activeStepIndex = foundIndex;
                                      if (stepScripts[foundIndex]['layout'] !=
                                          null) {
                                        _applyLayout(
                                          Map<String, dynamic>.from(
                                            stepScripts[foundIndex]['layout']
                                                as Map,
                                          ),
                                        );
                                      }
                                    }
                                  });
                                },
                                onTapDown: (details) {
                                  setState(() {
                                    _timelinePlayhead =
                                        (details.localPosition.dx / timeScale)
                                            .clamp(0.0, 7.0);
                                    _timelinePlayhead = double.parse(
                                      _timelinePlayhead.toStringAsFixed(1),
                                    );
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.white10),
                                    ),
                                    color: Colors.black12,
                                  ),
                                  child: Stack(
                                    children: List.generate(15, (i) {
                                      final double seconds = i * 0.5;
                                      final double leftPos =
                                          seconds * timeScale;
                                      final bool isWhole = i % 2 == 0;
                                      return Positioned(
                                        left: leftPos,
                                        bottom: 0,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (isWhole)
                                              Text(
                                                '${seconds.toInt()}s',
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            Container(
                                              width: 1,
                                              height: isWhole ? 6 : 3,
                                              color: Colors.grey.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Step Clips Track (displays sequential clips horizontally)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 22,
                              bottom: 0,
                              child: stepScripts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Chưa có phân cảnh. Bấm "Thêm phân cảnh" ở trên.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      children: List.generate(stepScripts.length, (
                                        index,
                                      ) {
                                        final script = stepScripts[index];
                                        final double start =
                                            (script['start'] as num).toDouble();
                                        final double duration =
                                            (script['duration'] as num)
                                                .toDouble();
                                        final bool isActive =
                                            _activeStepIndex == index;
                                        final bool hasLayout =
                                            script['layout'] != null;

                                        return Stack(
                                          children: [
                                            // Main clip box (draggable/selectable middle)
                                            Positioned(
                                              left: start * timeScale,
                                              width: duration * timeScale,
                                              top: 4,
                                              bottom: 4,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? Colors.amber
                                                            .withOpacity(0.15)
                                                      : Colors.blueGrey
                                                            .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isActive
                                                        ? Colors.amberAccent
                                                        : Colors.white24,
                                                    width: isActive ? 1.5 : 1.0,
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    // Center draggable section
                                                    Positioned(
                                                      left: 10,
                                                      right: 10,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          setState(() {
                                                            _activeStepIndex =
                                                                index;
                                                            _timelinePlayhead =
                                                                start;
                                                            if (hasLayout) {
                                                              _applyLayout(
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(
                                                                  script['layout']
                                                                      as Map,
                                                                ),
                                                              );
                                                            }
                                                          });
                                                        },
                                                        onHorizontalDragUpdate: (details) {
                                                          setState(() {
                                                            double
                                                            deltaSeconds =
                                                                details
                                                                    .delta
                                                                    .dx /
                                                                timeScale;
                                                            double oldStart =
                                                                script['start']
                                                                    as double;
                                                            double newStart =
                                                                (oldStart +
                                                                        deltaSeconds)
                                                                    .clamp(
                                                                      0.0,
                                                                      timelineMaxSeconds -
                                                                          (script['duration']
                                                                              as double),
                                                                    );
                                                            script['start'] =
                                                                double.parse(
                                                                  newStart
                                                                      .toStringAsFixed(
                                                                        1,
                                                                      ),
                                                                );
                                                          });
                                                        },
                                                        child: Center(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              if (hasLayout) ...[
                                                                const Icon(
                                                                  Icons
                                                                      .videocam,
                                                                  size: 10,
                                                                  color: Colors
                                                                      .greenAccent,
                                                                ),
                                                                const SizedBox(
                                                                  width: 2,
                                                                ),
                                                              ],
                                                              Expanded(
                                                                child: Text(
                                                                  'B${index + 1}: ${script['text']}',
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight:
                                                                        isActive
                                                                        ? FontWeight
                                                                              .bold
                                                                        : FontWeight
                                                                              .normal,
                                                                    color:
                                                                        isActive
                                                                        ? Colors
                                                                              .amberAccent
                                                                        : Colors
                                                                              .white70,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Left edge resize handle
                                                    Positioned(
                                                      left: 0,
                                                      width: 10,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .translucent,
                                                        onHorizontalDragUpdate: (details) {
                                                          setState(() {
                                                            double
                                                            deltaSeconds =
                                                                details
                                                                    .delta
                                                                    .dx /
                                                                timeScale;
                                                            double oldStart =
                                                                script['start']
                                                                    as double;
                                                            double oldDur =
                                                                script['duration']
                                                                    as double;
                                                            double newStart =
                                                                (oldStart +
                                                                        deltaSeconds)
                                                                    .clamp(
                                                                      0.0,
                                                                      oldStart +
                                                                          oldDur -
                                                                          0.5,
                                                                    );
                                                            newStart = double.parse(
                                                              newStart
                                                                  .toStringAsFixed(
                                                                    1,
                                                                  ),
                                                            );
                                                            double actualDelta =
                                                                newStart -
                                                                oldStart;
                                                            script['start'] =
                                                                newStart;
                                                            script['duration'] =
                                                                double.parse(
                                                                  (oldDur -
                                                                          actualDelta)
                                                                      .clamp(
                                                                        0.5,
                                                                        timelineMaxSeconds,
                                                                      )
                                                                      .toStringAsFixed(
                                                                        1,
                                                                      ),
                                                                );
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: isActive
                                                                ? Colors
                                                                      .amberAccent
                                                                : Colors.grey
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        5,
                                                                      ),
                                                                  bottomLeft:
                                                                      Radius.circular(
                                                                        5,
                                                                      ),
                                                                ),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .drag_indicator,
                                                              size: 8,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Right edge resize handle
                                                    Positioned(
                                                      right: 0,
                                                      width: 10,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .translucent,
                                                        onHorizontalDragUpdate: (details) {
                                                          setState(() {
                                                            double
                                                            deltaSeconds =
                                                                details
                                                                    .delta
                                                                    .dx /
                                                                timeScale;
                                                            double oldDur =
                                                                script['duration']
                                                                    as double;
                                                            double
                                                            newDur = (oldDur + deltaSeconds).clamp(
                                                              0.5,
                                                              timelineMaxSeconds -
                                                                  (script['start']
                                                                      as double),
                                                            );
                                                            script['duration'] =
                                                                double.parse(
                                                                  newDur
                                                                      .toStringAsFixed(
                                                                        1,
                                                                      ),
                                                                );
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: isActive
                                                                ? Colors
                                                                      .amberAccent
                                                                : Colors.grey
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topRight:
                                                                      Radius.circular(
                                                                        5,
                                                                      ),
                                                                  bottomRight:
                                                                      Radius.circular(
                                                                        5,
                                                                      ),
                                                                ),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .drag_indicator,
                                                              size: 8,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                            ),

                            // 3. Red Playhead Line
                            Positioned(
                              left: _timelinePlayhead * timeScale,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Container(
                                      width: 1.5,
                                      color: Colors.redAccent,
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Narration Text Editor & Actions panel for the active step
                      if (_activeStepIndex != null &&
                          _activeStepIndex! < stepScripts.length) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.03),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Cài đặt Phân cảnh ${_activeStepIndex! + 1}:',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Thời điểm: ${(stepScripts[_activeStepIndex!]['start'] as num).toDouble().toStringAsFixed(1)}s - '
                                    '${((stepScripts[_activeStepIndex!]['start'] as num).toDouble() + (stepScripts[_activeStepIndex!]['duration'] as num).toDouble()).toStringAsFixed(1)}s '
                                    '(Dài ${(stepScripts[_activeStepIndex!]['duration'] as num).toDouble().toStringAsFixed(1)}s)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Quick text edit field
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          TextEditingController(
                                              text:
                                                  stepScripts[_activeStepIndex!]['text'],
                                            )
                                            ..selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        (stepScripts[_activeStepIndex!]['text']
                                                                as String)
                                                            .length,
                                                  ),
                                                ),
                                      onChanged: (val) {
                                        stepScripts[_activeStepIndex!]['text'] =
                                            val;
                                      },
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Nhập thuyết minh phụ đề...',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Narration Text Customization Controls
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Toggle custom coordinates checkbox
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value:
                                          stepScripts[_activeStepIndex!]['x'] !=
                                          null,
                                      onChanged: (bool? checked) {
                                        setState(() {
                                          if (checked == true) {
                                            stepScripts[_activeStepIndex!]['x'] =
                                                2.0;
                                            stepScripts[_activeStepIndex!]['y'] =
                                                7.0;
                                          } else {
                                            stepScripts[_activeStepIndex!]
                                                .remove('x');
                                            stepScripts[_activeStepIndex!]
                                                .remove('y');
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const Text(
                                    'Định vị tọa độ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Color Picker
                                  const Text(
                                    'Màu sắc:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ...[
                                    Colors.white,
                                    Colors.yellow,
                                    Colors.red,
                                    Colors.cyan,
                                  ].map((c) {
                                    final bool isSelected =
                                        (stepScripts[_activeStepIndex!]['color']
                                                as int?) ==
                                            c.value ||
                                        (stepScripts[_activeStepIndex!]['color'] ==
                                                null &&
                                            c == Colors.white);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          stepScripts[_activeStepIndex!]['color'] =
                                              c.value;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.amberAccent
                                                : Colors.grey.withOpacity(0.5),
                                            width: isSelected ? 2.0 : 1.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              if (stepScripts[_activeStepIndex!]['x'] !=
                                  null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      'Tọa độ X:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 24,
                                        child: Slider(
                                          value:
                                              (stepScripts[_activeStepIndex!]['x']
                                                      as num)
                                                  .toDouble()
                                                  .clamp(-0.5, 4.5),
                                          min: -0.5,
                                          max: 4.5,
                                          divisions: 50,
                                          onChanged: (v) {
                                            setState(() {
                                              stepScripts[_activeStepIndex!]['x'] =
                                                  double.parse(
                                                    v.toStringAsFixed(1),
                                                  );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      (stepScripts[_activeStepIndex!]['x']
                                              as num)
                                          .toDouble()
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Tọa độ Y:',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 24,
                                        child: Slider(
                                          value:
                                              (stepScripts[_activeStepIndex!]['y']
                                                      as num)
                                                  .toDouble()
                                                  .clamp(-0.5, 8.5),
                                          min: -0.5,
                                          max: 8.5,
                                          divisions: 90,
                                          onChanged: (v) {
                                            setState(() {
                                              stepScripts[_activeStepIndex!]['y'] =
                                                  double.parse(
                                                    v.toStringAsFixed(1),
                                                  );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      (stepScripts[_activeStepIndex!]['y']
                                              as num)
                                          .toDouble()
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Xoay góc:',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 24,
                                      child: Slider(
                                        value:
                                            (stepScripts[_activeStepIndex!]['rotation']
                                                    as num?)
                                                ?.toDouble()
                                                .clamp(0.0, 360.0) ??
                                            0.0,
                                        min: 0.0,
                                        max: 360.0,
                                        divisions: 72,
                                        onChanged: (v) {
                                          setState(() {
                                            stepScripts[_activeStepIndex!]['rotation'] =
                                                double.parse(
                                                  v.toStringAsFixed(0),
                                                );
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${((stepScripts[_activeStepIndex!]['rotation'] as num?)?.toDouble() ?? 0.0).round()}°',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Cỡ chữ:',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 24,
                                      child: Slider(
                                        value:
                                            (stepScripts[_activeStepIndex!]['fontSize']
                                                    as num?)
                                                ?.toDouble()
                                                .clamp(10.0, 30.0) ??
                                            14.0,
                                        min: 10.0,
                                        max: 30.0,
                                        divisions: 20,
                                        onChanged: (v) {
                                          setState(() {
                                            stepScripts[_activeStepIndex!]['fontSize'] =
                                                double.parse(
                                                  v.toStringAsFixed(0),
                                                );
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${((stepScripts[_activeStepIndex!]['fontSize'] as num?)?.toDouble() ?? 14.0).round()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Buttons row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Save Board to Clip
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.withOpacity(
                                        0.2,
                                      ),
                                      foregroundColor: Colors.greenAccent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 12,
                                    ),
                                    label: const Text(
                                      'Lưu thế bi',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: Text(
                                            'Lưu thế bi - Bước ${_activeStepIndex! + 1}',
                                          ),
                                          content: Text(
                                            'Bạn có chắc muốn lưu thế bi hiện tại trên bàn vẽ vào Bước ${_activeStepIndex! + 1}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogCtx),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogCtx);
                                                setState(() {
                                                  stepScripts[_activeStepIndex!]['layout'] =
                                                      _captureCurrentLayout();
                                                });
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Đã lưu thế bi vào Bước ${_activeStepIndex! + 1}!',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Lưu',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Load Clip to Board (Nạp thế bi)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyan.withOpacity(
                                        0.2,
                                      ),
                                      foregroundColor: Colors.cyanAccent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.settings_backup_restore,
                                      size: 12,
                                    ),
                                    label: const Text(
                                      'Nạp thế bi',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    onPressed:
                                        stepScripts[_activeStepIndex!]['layout'] !=
                                            null
                                        ? () {
                                            _applyLayout(
                                              Map<String, dynamic>.from(
                                                stepScripts[_activeStepIndex!]['layout']
                                                    as Map,
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Đã nạp thế bi của Bước ${_activeStepIndex! + 1} lên bàn vẽ!',
                                                ),
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  // Delete step
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: Text(
                                            'Xoá Phân cảnh ${_activeStepIndex! + 1}',
                                          ),
                                          content: const Text(
                                            'Bạn có chắc muốn xoá phân cảnh này khỏi dòng thời gian không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogCtx),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogCtx);
                                                setState(() {
                                                  stepScripts.removeAt(
                                                    _activeStepIndex!,
                                                  );
                                                  if (stepScripts.isEmpty) {
                                                    _activeStepIndex = null;
                                                  } else {
                                                    _activeStepIndex = math.min(
                                                      _activeStepIndex!,
                                                      stepScripts.length - 1,
                                                    );
                                                  }
                                                });
                                              },
                                              child: const Text(
                                                'Xoá',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showCoordinateInputDialog() {
    double initX = 0, initY = 0;
    if (!_isDrawingPath) {
      if (_selectedBall == ActiveBall.white) {
        initX = whitePos.dx;
        initY = whitePos.dy;
      }
      if (_selectedBall == ActiveBall.yellow) {
        initX = yellowPos.dx;
        initY = yellowPos.dy;
      }
      if (_selectedBall == ActiveBall.red) {
        initX = redPos.dx;
        initY = redPos.dy;
      }
    } else {
      List<Offset> path = _selectedBall == ActiveBall.white
          ? whitePath
          : (_selectedBall == ActiveBall.yellow
                ? yellowPath
                : (_selectedBall == ActiveBall.red
                      ? redPath
                      : (freePaths.isNotEmpty ? freePaths.last : [])));
      if (path.isNotEmpty) {
        initX = path.last.dx;
        initY = path.last.dy;
      } else {
        if (_selectedBall == ActiveBall.white) {
          initX = whitePos.dx;
          initY = whitePos.dy;
        }
        if (_selectedBall == ActiveBall.yellow) {
          initX = yellowPos.dx;
          initY = yellowPos.dy;
        }
        if (_selectedBall == ActiveBall.red) {
          initX = redPos.dx;
          initY = redPos.dy;
        }
      }
    }

    double xVal = initX.clamp(-0.5, 4.5);
    double yVal = initY.clamp(-0.5, 8.5);
    final double originalX = xVal;
    final double originalY = yVal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            _isDrawingPath ? 'Nhập toạ độ điểm ngắm' : 'Nhập toạ độ vị trí bi',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trục ngang X: ${xVal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Giới hạn: -0.5 đến 4.5',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: xVal,
                min: -0.5,
                max: 4.5,
                divisions: 500,
                onChanged: (val) {
                  setStateDialog(() {
                    xVal = val;
                  });
                  if (!_isDrawingPath) {
                    setState(() {
                      if (_selectedBall == ActiveBall.white)
                        whitePos = Offset(xVal, yVal);
                      if (_selectedBall == ActiveBall.yellow)
                        yellowPos = Offset(xVal, yVal);
                      if (_selectedBall == ActiveBall.red)
                        redPos = Offset(xVal, yVal);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trục dọc Y: ${yVal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Giới hạn: -0.5 đến 8.5',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: yVal,
                min: -0.5,
                max: 8.5,
                divisions: 900,
                onChanged: (val) {
                  setStateDialog(() {
                    yVal = val;
                  });
                  if (!_isDrawingPath) {
                    setState(() {
                      if (_selectedBall == ActiveBall.white)
                        whitePos = Offset(xVal, yVal);
                      if (_selectedBall == ActiveBall.yellow)
                        yellowPos = Offset(xVal, yVal);
                      if (_selectedBall == ActiveBall.red)
                        redPos = Offset(xVal, yVal);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!_isDrawingPath) {
                  setState(() {
                    if (_selectedBall == ActiveBall.white)
                      whitePos = Offset(originalX, originalY);
                    if (_selectedBall == ActiveBall.yellow)
                      yellowPos = Offset(originalX, originalY);
                    if (_selectedBall == ActiveBall.red)
                      redPos = Offset(originalX, originalY);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_isDrawingPath) {
                    if (_selectedBall == ActiveBall.white)
                      whitePath.add(Offset(xVal, yVal));
                    if (_selectedBall == ActiveBall.yellow)
                      yellowPath.add(Offset(xVal, yVal));
                    if (_selectedBall == ActiveBall.red)
                      redPath.add(Offset(xVal, yVal));
                    if (_selectedBall == ActiveBall.free) {
                      if (freePaths.isEmpty) {
                        freePaths.add([]);
                      }
                      freePaths.last.add(Offset(xVal, yVal));
                    }
                  } else {
                    if (_selectedBall == ActiveBall.white)
                      whitePos = Offset(xVal, yVal);
                    if (_selectedBall == ActiveBall.yellow)
                      yellowPos = Offset(xVal, yVal);
                    if (_selectedBall == ActiveBall.red)
                      redPos = Offset(xVal, yVal);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(_isDrawingPath ? 'Thêm điểm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCushionNumberInputDialog(Offset pos, [int? editIndex]) {
    final textController = TextEditingController(
      text: editIndex != null ? customCushionNumbers[editIndex].text : '',
    );
    final xController = TextEditingController(text: pos.dx.toStringAsFixed(2));
    final yController = TextEditingController(text: pos.dy.toStringAsFixed(2));
    Color selectedColor = editIndex != null
        ? customCushionNumbers[editIndex].color
        : Colors.yellowAccent;
    double selectedRotation = editIndex != null
        ? customCushionNumbers[editIndex].rotation
        : 0.0;

    final List<Color> labelColors = [
      Colors.yellowAccent,
      Colors.cyanAccent,
      Colors.white,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(editIndex == null ? 'Thêm số băng' : 'Chỉnh số băng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị số (VD: 10, 20, 50, -1)',
                    hintText: 'Nhập số băng...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ X',
                          hintText: '0.0 - 4.0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ Y',
                          hintText: '0.0 - 8.0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Màu chữ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: labelColors.map((color) {
                    return InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setStateDialog(() => selectedColor = color),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: selectedColor.value == color.value
                                ? Colors.white
                                : Colors.white24,
                            width: selectedColor.value == color.value ? 2.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (editIndex != null)
              TextButton(
                onPressed: () {
                  setState(() => customCushionNumbers.removeAt(editIndex));
                  Navigator.pop(context);
                },
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  final xVal = double.tryParse(xController.text) ?? pos.dx;
                  final yVal = double.tryParse(yController.text) ?? pos.dy;
                  final finalPos = Offset(
                    xVal.clamp(-0.5, 4.5),
                    yVal.clamp(-0.5, 8.5),
                  );
                  setState(() {
                    if (editIndex != null) {
                      customCushionNumbers[editIndex].text = text;
                      customCushionNumbers[editIndex].color = selectedColor;
                      customCushionNumbers[editIndex].pos = finalPos;
                      customCushionNumbers[editIndex].rotation =
                          selectedRotation;
                    } else {
                      customCushionNumbers.add(
                        CushionNumberData(
                          finalPos,
                          text,
                          selectedColor,
                          rotation: selectedRotation,
                        ),
                      );
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelInputDialog(Offset pos, [int? editIndex]) {
    final textController = TextEditingController(
      text: editIndex != null ? customLabels[editIndex].text : '',
    );
    final xController = TextEditingController(text: pos.dx.toStringAsFixed(2));
    final yController = TextEditingController(text: pos.dy.toStringAsFixed(2));
    Color selectedColor = editIndex != null
        ? customLabels[editIndex].color
        : Colors.yellowAccent;
    double selectedRotation = editIndex != null
        ? customLabels[editIndex].rotation
        : 0.0;
    String? selectedRole = editIndex != null
        ? customLabels[editIndex].role
        : null;

    final Map<String?, String> rolesList = {
      null: 'Tự chọn màu (Mặc định)',
      'cueBallAngle': 'Góc bi chủ',
      'cardeBallClearance': 'Độ hở bi Carde',
      'contactPoint': 'Điểm chạm / Vị trí bi Carde',
      'targetPoint': 'Điểm trúng',
      'slantCueCarde': 'Độ xiên bi chủ & Carde',
      'slantCardeTarget': 'Độ xiên bi Carde & mục tiêu',
    };

    final List<Color> labelColors = [
      Colors.white,
      Colors.yellowAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.amberAccent,
      Colors.limeAccent,
      Colors.tealAccent,
      Colors.blueAccent,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nhập chữ hoặc số'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 50, 10, Điểm chạm...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ X',
                          hintText: '0.0 - 4.0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ Y',
                          hintText: '0.0 - 8.0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loại thông tin (Vai trò):',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<String?>(
                  isExpanded: true,
                  value: selectedRole,
                  items: rolesList.entries.map((e) {
                    Color? dotColor;
                    if (e.key != null) {
                      dotColor = ThemeManager
                          .currentTheme
                          .value
                          .indicatorColors[e.key];
                    }
                    return DropdownMenuItem<String?>(
                      value: e.key,
                      child: Row(
                        children: [
                          if (dotColor != null) ...[
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedRole = val;
                      if (val != null) {
                        selectedColor = ThemeManager
                            .currentTheme
                            .value
                            .indicatorColors[val]!;
                      }
                    });
                  },
                ),
                if (selectedRole == null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Màu sắc tùy chỉnh:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: labelColors
                        .map(
                          (c) => GestureDetector(
                            onTap: () =>
                                setStateDialog(() => selectedColor = c),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == c
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Xoay chữ:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${selectedRotation.round()}°',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 0,
                  max: 360,
                  divisions: 360,
                  value: selectedRotation,
                  onChanged: (val) {
                    setStateDialog(() => selectedRotation = val);
                  },
                ),
                Wrap(
                  spacing: 8,
                  children: [0.0, 90.0, 180.0, 270.0]
                      .map(
                        (angle) => ChoiceChip(
                          label: Text('${angle.round()}°'),
                          selected: selectedRotation == angle,
                          onSelected: (val) {
                            if (val) {
                              setStateDialog(() => selectedRotation = angle);
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (editIndex != null)
              TextButton(
                onPressed: () {
                  setState(() => customLabels.removeAt(editIndex));
                  Navigator.pop(context);
                },
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  final newX = double.tryParse(xController.text) ?? pos.dx;
                  final newY = double.tryParse(yController.text) ?? pos.dy;
                  final finalPos = Offset(newX, newY);
                  setState(() {
                    if (editIndex != null) {
                      customLabels[editIndex].text = textController.text;
                      customLabels[editIndex].color = selectedColor;
                      customLabels[editIndex].pos = finalPos;
                      customLabels[editIndex].rotation = selectedRotation;
                      customLabels[editIndex].role = selectedRole;
                    } else {
                      customLabels.add(
                        CustomLabelData(
                          finalPos,
                          textController.text,
                          selectedColor,
                          rotation: selectedRotation,
                          role: selectedRole,
                        ),
                      );
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomBallDialog({int? index}) {
    final existing = index != null ? customBalls[index] : null;
    final position = existing?['pos'] as Offset? ?? const Offset(2.0, 4.0);
    Color selectedColor = existing?['color'] as Color? ?? Colors.blue;
    bool addAsGhost = false;
    final xController = TextEditingController(
      text: position.dx.toStringAsFixed(2),
    );
    final yController = TextEditingController(
      text: position.dy.toStringAsFixed(2),
    );
    final numberController = TextEditingController(
      text: existing?['number']?.toString() ?? '',
    );
    const colors = [
      Colors.white,
      Colors.yellow,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.black,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Thêm bi thật' : 'Chỉnh sửa bi thật'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ X',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ Y',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Màu bi:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in colors)
                      InkWell(
                        onTap: () =>
                            setDialogState(() => selectedColor = color),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              width: selectedColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (index == null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bi ảo'),
                    subtitle: const Text('Hiển thị mờ để minh họa vị trí'),
                    value: addAsGhost,
                    onChanged: (value) =>
                        setDialogState(() => addAsGhost = value),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Số/chữ trên bi (tùy chọn)',
                    hintText: 'Ví dụ: 1, 2, A...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (index != null)
              TextButton(
                onPressed: () {
                  setState(() => customBalls.removeAt(index));
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Xóa bi',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final x = double.tryParse(xController.text) ?? position.dx;
                final y = double.tryParse(yController.text) ?? position.dy;
                final ball = <String, dynamic>{
                  'pos': _clampBallPosition(Offset(x, y)),
                  'color': selectedColor,
                  'number': numberController.text.trim(),
                };
                setState(() {
                  if (index == null && addAsGhost) {
                    customGhosts.add({
                      'pos': ball['pos'],
                      'color': selectedColor,
                      'type': BallType.full,
                      'rotation': 0.0,
                      'number': numberController.text.trim(),
                    });
                  } else if (index == null) {
                    customBalls.add(ball);
                  } else {
                    customBalls[index] = ball;
                  }
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGhostActionsDialog(int index) {
    BallType selectedType = customGhosts[index]['type'] ?? BallType.full;
    double selectedRotation = customGhosts[index]['rotation'] ?? 0.0;
    final currentPosition = customGhosts[index]['pos'] as Offset;
    final xController = TextEditingController(
      text: currentPosition.dx.toStringAsFixed(2),
    );
    final yController = TextEditingController(
      text: currentPosition.dy.toStringAsFixed(2),
    );
    final textController = TextEditingController(
      text: customGhosts[index]['number']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Tùy chỉnh Bi ảo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ X',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tọa độ Y',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Chọn màu cho bi ảo:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        side: customGhosts[index]['color'] == Colors.white
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : null,
                      ),
                      onPressed: () {
                        setState(
                          () => customGhosts[index]['color'] = Colors.white,
                        );
                        setStateDialog(() {});
                      },
                      child: const Text('Trắng'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        side: customGhosts[index]['color'] == Colors.yellow
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : null,
                      ),
                      onPressed: () {
                        setState(
                          () => customGhosts[index]['color'] = Colors.yellow,
                        );
                        setStateDialog(() {});
                      },
                      child: const Text('Vàng'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        side: customGhosts[index]['color'] == Colors.red
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : null,
                      ),
                      onPressed: () {
                        setState(
                          () => customGhosts[index]['color'] = Colors.red,
                        );
                        setStateDialog(() {});
                      },
                      child: const Text('Đỏ'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Dạng bi ảo:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Nguyên trái'),
                      selected: selectedType == BallType.full,
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => customGhosts[index]['type'] = BallType.full,
                          );
                          setStateDialog(() => selectedType = BallType.full);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Nửa trái (1/2)'),
                      selected: selectedType == BallType.half,
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => customGhosts[index]['type'] = BallType.half,
                          );
                          setStateDialog(() => selectedType = BallType.half);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Đánh số'),
                      selected: selectedType == BallType.numbered,
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () =>
                                customGhosts[index]['type'] = BallType.numbered,
                          );
                          setStateDialog(
                            () => selectedType = BallType.numbered,
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (selectedType == BallType.half) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Góc xoay:'),
                      Text('${selectedRotation.round()}°'),
                    ],
                  ),
                  Slider(
                    min: 0,
                    max: 360,
                    divisions: 36,
                    value: selectedRotation,
                    onChanged: (val) {
                      setState(() => customGhosts[index]['rotation'] = val);
                      setStateDialog(() => selectedRotation = val);
                    },
                  ),
                ],
                if (selectedType == BallType.numbered) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Số/Chữ hiển thị trên bi',
                      hintText: 'Ví dụ: 1, 2, 3...',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => customGhosts[index]['number'] = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => customGhosts.removeAt(index));
                Navigator.pop(context);
              },
              child: const Text(
                'Xoá bi ảo',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                final x = double.tryParse(xController.text);
                final y = double.tryParse(yController.text);
                if (x != null && y != null) {
                  setState(() {
                    customGhosts[index]['pos'] = _clampBallPosition(
                      Offset(x, y),
                    );
                    customGhosts[index]['number'] = textController.text;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  double _getAspect() {
    double playWidth = 100.0;
    double playHeight = 200.0;
    bool bottomRail = false;
    bool rightRail = true;

    switch (_viewType) {
      case TableViewType.half:
        playHeight = 100.0;
        break;
      case TableViewType.third:
        playHeight = 75.0;
        break;
      case TableViewType.quarter:
        playHeight = 50.0;
        break;
      case TableViewType.halfWidth:
        playWidth = 50.0;
        playHeight = 200.0;
        bottomRail = true;
        rightRail = false;
        break;
      default:
        playHeight = 200.0;
        bottomRail = true;
    }

    double totalW = playWidth + 12.0 + (rightRail ? 12.0 : 0);
    double totalH = playHeight + 12.0 + (bottomRail ? 12.0 : 0);
    return totalW / totalH;
  }

  Offset _pixelToDiamond(
    Offset localPosition,
    BoxConstraints constraints, {
    bool clamp = true,
  }) {
    // Trừ đi margin của BilliardDiagram để khớp tọa độ vẽ thực tế
    double w = constraints.maxWidth - 8; // Tổng margin ngang là 8 (4 mỗi bên)
    double localX = localPosition.dx - 4; // Lùi lại 4px do margin trái
    double localY = localPosition.dy - 8; // Lùi lại 8px do margin trên

    final bool rightRail =
        _viewType != TableViewType.halfWidth &&
        _viewType != TableViewType.halfWidthHalfLength &&
        _viewType != TableViewType.halfWidthThirdLength &&
        _viewType != TableViewType.halfWidthQuarterLength;
    final double baseWidth = rightRail ? 124.0 : 62.0;
    double totalRail = w * (12.0 / baseWidth);
    double playAreaWidth = w - totalRail - (rightRail ? totalRail : 0);
    double diamondSpacing = playAreaWidth / (rightRail ? 4.0 : 2.0);

    double x = (localX - totalRail) / diamondSpacing;
    double y = (localY - totalRail) / diamondSpacing;

    if (clamp) {
      return Offset(x.clamp(0.0, _maxDiamondX), y.clamp(0.0, _maxDiamondY));
    }
    return Offset(x, y);
  }

  double get _maxDiamondX {
    switch (_viewType) {
      case TableViewType.halfWidth:
      case TableViewType.halfWidthHalfLength:
      case TableViewType.halfWidthThirdLength:
      case TableViewType.halfWidthQuarterLength:
        return 2.0;
      default:
        return 4.0;
    }
  }

  double get _maxDiamondY {
    switch (_viewType) {
      case TableViewType.half:
      case TableViewType.halfWidthHalfLength:
        return 4.0;
      case TableViewType.third:
      case TableViewType.halfWidthThirdLength:
        return 3.0;
      case TableViewType.quarter:
      case TableViewType.halfWidthQuarterLength:
        return 2.0;
      default:
        return 8.0;
    }
  }

  Offset _clampBallPosition(Offset position) {
    const radius = Ball.diameter / 2;
    return Offset(
      position.dx.clamp(radius, _maxDiamondX - radius),
      position.dy.clamp(radius, _maxDiamondY - radius),
    );
  }

  bool _isInsidePlayArea(Offset position) {
    return position.dx >= 0 &&
        position.dx <= _maxDiamondX &&
        position.dy >= 0 &&
        position.dy <= _maxDiamondY;
  }

  Offset _clampToPlayArea(Offset position) {
    return Offset(
      position.dx.clamp(0.0, _maxDiamondX),
      position.dy.clamp(0.0, _maxDiamondY),
    );
  }

  static const double _railDiamondExtent = 0.48;

  bool get _hasRightRail =>
      _viewType != TableViewType.halfWidth &&
      _viewType != TableViewType.halfWidthHalfLength &&
      _viewType != TableViewType.halfWidthThirdLength &&
      _viewType != TableViewType.halfWidthQuarterLength;

  bool get _hasBottomRail =>
      _viewType == TableViewType.full || _viewType == TableViewType.halfWidth;

  bool _isInsideSegmentArea(Offset position) {
    return position.dx >= -_railDiamondExtent &&
        position.dx <=
            _maxDiamondX + (_hasRightRail ? _railDiamondExtent : 0) &&
        position.dy >= -_railDiamondExtent &&
        position.dy <= _maxDiamondY + (_hasBottomRail ? _railDiamondExtent : 0);
  }

  Offset _snapSegmentPosition(Offset position) {
    final maxX = _maxDiamondX + (_hasRightRail ? _railDiamondExtent : 0);
    final maxY = _maxDiamondY + (_hasBottomRail ? _railDiamondExtent : 0);
    final clampedX = position.dx.clamp(-_railDiamondExtent, maxX);
    final clampedY = position.dy.clamp(-_railDiamondExtent, maxY);
    return Offset(
      clampedX >= 0 && clampedX <= _maxDiamondX
          ? clampedX.roundToDouble()
          : clampedX,
      clampedY >= 0 && clampedY <= _maxDiamondY
          ? clampedY.roundToDouble()
          : clampedY,
    );
  }

  List<Ball> _buildBalls() {
    List<Ball> balls = [
      Ball.at(whitePos.dx, whitePos.dy, Colors.white),
      Ball.at(yellowPos.dx, yellowPos.dy, Colors.yellow),
      Ball.at(redPos.dx, redPos.dy, Colors.red),
    ];

    for (var b in customBalls) {
      final number = b['number']?.toString() ?? '';
      balls.add(
        Ball.at(
          (b['pos'] as Offset).dx,
          (b['pos'] as Offset).dy,
          b['color'] as Color,
          type: number.isEmpty ? BallType.full : BallType.numbered,
          text: number,
        ),
      );
    }

    for (var g in customGhosts) {
      balls.add(
        Ball.at(
          (g['pos'] as Offset).dx,
          (g['pos'] as Offset).dy,
          g['color'] as Color,
          isGhost: true,
          opacity: 0.5,
          type: g['type'] ?? BallType.full,
          rotation: ((g['rotation'] ?? 0.0) as double) * math.pi / 180.0,
          text: g['number']?.toString(),
        ),
      );
    }

    if (_isDrawingPath || _isDrawingSegment) {
      if (_isDrawingSegment || _selectedBall == ActiveBall.free) {
        for (int i = 0; i < freePaths.length; i++) {
          var path = freePaths[i];
          Color pColor = (i < freePathColors.length)
              ? freePathColors[i]
              : Colors.cyanAccent;
          for (var pos in path) {
            balls.add(
              Ball.at(pos.dx, pos.dy, pColor, opacity: 0.6, isGhost: true),
            );
          }
        }
        if (_pendingSegmentStart != null) {
          balls.add(
            Ball.at(
              _pendingSegmentStart!.dx,
              _pendingSegmentStart!.dy,
              segmentColor,
              opacity: 0.75,
              isGhost: true,
            ),
          );
        }
      } else {
        List<Offset> currentPath = _selectedBall == ActiveBall.white
            ? whitePath
            : (_selectedBall == ActiveBall.yellow ? yellowPath : redPath);
        Color pointColor = _selectedBall == ActiveBall.white
            ? Colors.white
            : (_selectedBall == ActiveBall.yellow ? Colors.yellow : Colors.red);

        for (var pos in currentPath) {
          // Hiển thị các điểm chỉnh sửa (nút) dưới dạng một hình tròn có chữ thập
          balls.add(
            Ball.at(pos.dx, pos.dy, pointColor, opacity: 0.5, isGhost: true),
          );
        }
      }
    }

    if (_isAddingLabel) {
      for (var l in customLabels) {
        balls.add(
          Ball.at(
            l.pos.dx,
            l.pos.dy,
            Colors.orangeAccent,
            opacity: 0.4,
            isGhost: true,
          ),
        );
      }
    }
    if (_isAddingCushionNumber) {
      for (var c in customCushionNumbers) {
        balls.add(
          Ball.at(
            c.pos.dx,
            c.pos.dy,
            Colors.lightGreenAccent,
            opacity: 0.4,
            isGhost: true,
          ),
        );
      }
    }
    return balls;
  }

  List<BallPath> _buildPaths() {
    List<BallPath> paths = [];
    if (whitePath.isNotEmpty)
      paths.add(
        BallPath.diamonds(
          points: [whitePos, ...whitePath],
          color: whitePathColor,
        ),
      );
    if (yellowPath.isNotEmpty)
      paths.add(
        BallPath.diamonds(
          points: [yellowPos, ...yellowPath],
          color: yellowPathColor,
        ),
      );
    if (redPath.isNotEmpty)
      paths.add(
        BallPath.diamonds(points: [redPos, ...redPath], color: redPathColor),
      );
    for (int i = 0; i < freePaths.length; i++) {
      var path = freePaths[i];
      if (path.isNotEmpty) {
        Color pColor = (i < freePathColors.length)
            ? freePathColors[i]
            : freePathColor;
        paths.add(BallPath.diamonds(points: path, color: pColor));
      }
    }
    if (_segmentDragStart != null && _segmentDragEnd != null) {
      paths.add(
        BallPath.diamonds(
          points: [_segmentDragStart!, _segmentDragEnd!],
          color: segmentColor,
        ),
      );
    }
    return paths;
  }

  List<BilliardLabel> _buildLabels() {
    List<BilliardLabel> result = [];
    result.addAll(
      customLabels.map(
        (l) => BilliardLabel.at(
          l.pos.dx,
          l.pos.dy,
          l.text,
          color: l.color,
          fontSize: _labelFontSize,
          rotation: l.rotation * math.pi / 180.0,
          role: l.role,
        ),
      ),
    );
    result.addAll(
      customCushionNumbers.map(
        (c) => BilliardLabel.at(
          c.pos.dx,
          c.pos.dy,
          c.text,
          color: c.color,
          fontSize: _labelFontSize,
          rotation: c.rotation * math.pi / 180.0,
          role: 'cushion',
        ),
      ),
    );
    return result;
  }
}
