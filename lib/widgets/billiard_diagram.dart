import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/theme_manager.dart';
import '../screens/fullscreen_billiard_viewer.dart';
import '../rendering/scene/scene_painter.dart';
import '../rendering/scene/legacy/legacy_render_adapter.dart';

enum BallType { full, half, numbered }

class Ball {
  final Offset position; // Tỷ lệ từ 0.0 đến 1.0 (4 nút = 1.0)
  final Color color;
  final double opacity;
  final bool isGhost;
  final bool isOutline;
  final BallType type;
  final double rotation;
  final String? text;

  /// Hằng số đường kính bi theo đơn vị Nút Số (Diamonds)
  static const double diameter = 0.172;

  Ball(
    this.position,
    this.color, {
    this.opacity = 1.0, // Mặc định là hiện rõ hoàn toàn
    this.isGhost = false,
    this.isOutline = false,
    this.type = BallType.full,
    this.rotation = 0,
    this.text,
  });

  /// Tạo bi nhanh dựa trên đơn vị Nút Số (Diamonds)
  static Ball at(
    double xDiamond,
    double yDiamond,
    Color color, {
    double opacity = 1.0,
    bool isGhost = false,
    bool isOutline = false,
    BallType type = BallType.full,
    double rotation = 0,
    String? text,
  }) {
    return Ball(
      Offset(xDiamond / 4, yDiamond / 4),
      color,
      opacity: opacity,
      isGhost: isGhost,
      isOutline: isOutline,
      type: type,
      rotation: rotation,
      text: text,
    );
  }

  /// Tạo nhanh một hàng bi đặt sát nhau theo chiều ngang
  static List<Ball> row({
    required double startX,
    required double startY,
    required int count,
    required Color color,
    double? spacing, // Khoảng cách giữa các tâm bi (mặc định là đường kính)
    bool isGhost = true,
    bool isOutline = false,
    BallType type = BallType.full,
    double rotation = 0,
  }) {
    double step = spacing ?? diameter;
    return List.generate(count.abs(), (i) {
      return Ball.at(
        startX + (i * step),
        startY,
        color,
        isGhost: isGhost,
        isOutline: isOutline,
        type: type,
        rotation: rotation,
      );
    });
  }

  /// Tạo nhanh một cột bi đặt sát nhau theo chiều dọc
  static List<Ball> column({
    required double startX,
    required double startY,
    required int count,
    required Color color,
    double? spacing, // Khoảng cách giữa các tâm bi (mặc định là đường kính)
    bool isGhost = true,
    bool isOutline = false,
    BallType type = BallType.full,
    double rotation = 0,
  }) {
    double step = spacing ?? diameter;
    return List.generate(count.abs(), (i) {
      return Ball.at(
        startX,
        startY + (i * step),
        color,
        isGhost: isGhost,
        isOutline: isOutline,
        type: type,
        rotation: rotation,
      );
    });
  }
}

class BallPath {
  final List<Offset> points;
  final Color color;
  final double opacity; // Thêm thuộc tính độ mờ
  final bool isDashed;
  final String? role; // Indicator role

  BallPath({
    required this.points,
    this.color = Colors.white70,
    this.opacity = 1.0,
    this.isDashed = true,
    this.role,
  });

  static BallPath diamonds({
    required List<Offset> points,
    Color color = Colors.white70,
    double opacity = 1.0,
    bool isDashed = true,
    String? role,
  }) {
    return BallPath(
      points: points.map((p) => Offset(p.dx / 4, p.dy / 4)).toList(),
      color: color,
      opacity: opacity,
      isDashed: isDashed,
      role: role,
    );
  }

  /// Tính góc (độ) tại đỉnh B tạo bởi 3 điểm A, B, C
  static double calculateAngle(Offset a, Offset b, Offset c) {
    double angle1 = math.atan2(a.dy - b.dy, a.dx - b.dx);
    double angle2 = math.atan2(c.dy - b.dy, c.dx - b.dx);
    double result = (angle1 - angle2).abs() * 180 / math.pi;
    return result > 180 ? 360 - result : result;
  }
}

class BilliardLabel {
  final Offset position; // Tỷ lệ từ 0.0 đến 1.0 (4 nút = 1.0)
  final String text;
  final Color color;
  final double fontSize;
  final double rotation; // Độ xoay (radian)
  final String? role; // Indicator role

  BilliardLabel(
    this.position,
    this.text, {
    this.color = Colors.white,
    this.fontSize = 12,
    this.rotation = 0,
    this.role,
  });

  static BilliardLabel at(
    double xDiamond,
    double yDiamond,
    String text, {
    Color color = Colors.white,
    double fontSize = 12,
    double rotation = 0,
    String? role,
  }) {
    return BilliardLabel(
      Offset(xDiamond / 4, yDiamond / 4),
      text,
      color: color,
      fontSize: fontSize,
      rotation: rotation,
      role: role,
    );
  }
}

class BilliardAngle {
  final Offset a, b, c; // Tọa độ relative (0-1)
  final double radius; // Bán kính cung (pixel)
  final Color color;
  final String? label;
  final String? role; // Indicator role

  BilliardAngle({
    required this.a,
    required this.b,
    required this.c,
    this.radius = 20,
    this.color = Colors.yellowAccent,
    this.label,
    this.role,
  });

  /// Tạo cung góc nhanh dựa trên đơn vị Nút Số (Diamonds)
  /// [a], [b], [c] là tọa độ các điểm theo nút số. Góc được vẽ tại đỉnh [b].
  static BilliardAngle at({
    required Offset a,
    required Offset b,
    required Offset c,
    double radius = 20,
    Color color = Colors.yellowAccent,
    String? label,
    String? role,
  }) {
    return BilliardAngle(
      a: Offset(a.dx / 4, a.dy / 4),
      b: Offset(b.dx / 4, b.dy / 4),
      c: Offset(c.dx / 4, c.dy / 4),
      radius: radius,
      color: color,
      label: label,
      role: role,
    );
  }
}

enum DiagramSystem {
  standard,
  diamond,
  short3Cushion,
  shortLongShort,
  xohaibang,
  babangcha,
}

enum TableViewType {
  full,
  half,
  third,
  quarter,
  halfWidth,
  halfWidthHalfLength,
  halfWidthThirdLength,
  halfWidthQuarterLength,
}

class ParsedBilliardLayout {
  final List<Ball> balls;
  final List<BallPath> paths;
  final List<BilliardLabel> labels;
  final List<BilliardAngle> angles;
  final TableViewType viewType;
  final DiagramSystem system;
  final Map<String, dynamic>? effetData;

  ParsedBilliardLayout({
    required this.balls,
    required this.paths,
    required this.labels,
    required this.angles,
    required this.viewType,
    required this.system,
    this.effetData,
  });

  static ParsedBilliardLayout parse(Map<String, dynamic> data) {
    List<Ball> balls = [];
    if (data.containsKey('white')) {
      balls.add(
        Ball.at(
          (data['white'][0] as num).toDouble(),
          (data['white'][1] as num).toDouble(),
          Colors.white,
        ),
      );
    }
    if (data.containsKey('yellow')) {
      balls.add(
        Ball.at(
          (data['yellow'][0] as num).toDouble(),
          (data['yellow'][1] as num).toDouble(),
          Colors.yellow,
        ),
      );
    }
    if (data.containsKey('red')) {
      balls.add(
        Ball.at(
          (data['red'][0] as num).toDouble(),
          (data['red'][1] as num).toDouble(),
          Colors.red,
        ),
      );
    }
    if (data.containsKey('ghosts')) {
      var gh = data['ghosts'];
      if (gh is List) {
        for (var g in gh) {
          balls.add(
            Ball.at(
              (g['x'] as num).toDouble(),
              (g['y'] as num).toDouble(),
              Color(g['color'] ?? Colors.white.value),
              isGhost: true,
              opacity: 0.5,
              type: BallType.values[g['type'] ?? 0],
              rotation: ((g['rotation'] ?? 0.0) as double) * math.pi / 180.0,
              text: g['number']?.toString(),
            ),
          );
        }
      }
    }

    TableViewType vType = TableViewType.values[data['viewType'] ?? 0];
    DiagramSystem sys = DiagramSystem.values[data['system'] ?? 0];

    List<BallPath> paths = [];
    if (data.containsKey('paths')) {
      var p = data['paths'];
      if (p['white'] != null &&
          (p['white'] as List).isNotEmpty &&
          data.containsKey('white')) {
        paths.add(
          BallPath.diamonds(
            points: [
              Offset(
                (data['white'][0] as num).toDouble(),
                (data['white'][1] as num).toDouble(),
              ),
              ...(p['white'] as List).map(
                (e) =>
                    Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()),
              ),
            ],
            color: Colors.white70,
          ),
        );
      }
      if (p['yellow'] != null &&
          (p['yellow'] as List).isNotEmpty &&
          data.containsKey('yellow')) {
        paths.add(
          BallPath.diamonds(
            points: [
              Offset(
                (data['yellow'][0] as num).toDouble(),
                (data['yellow'][1] as num).toDouble(),
              ),
              ...(p['yellow'] as List).map(
                (e) =>
                    Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()),
              ),
            ],
            color: Colors.yellow,
          ),
        );
      }
      if (p['red'] != null &&
          (p['red'] as List).isNotEmpty &&
          data.containsKey('red')) {
        paths.add(
          BallPath.diamonds(
            points: [
              Offset(
                (data['red'][0] as num).toDouble(),
                (data['red'][1] as num).toDouble(),
              ),
              ...(p['red'] as List).map(
                (e) =>
                    Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()),
              ),
            ],
            color: Colors.redAccent,
          ),
        );
      }
      if (p['free'] != null && (p['free'] as List).isNotEmpty) {
        for (var fp in p['free']) {
          if (fp is List && fp.isNotEmpty) {
            paths.add(
              BallPath.diamonds(
                points: fp
                    .map(
                      (e) => Offset(
                        (e[0] as num).toDouble(),
                        (e[1] as num).toDouble(),
                      ),
                    )
                    .toList(),
                color: Colors.cyanAccent,
              ),
            );
          }
        }
      }
    }

    double labelFontSize = (data['labelFontSize'] as num?)?.toDouble() ?? 9.5;
    List<BilliardLabel> labels = [];
    if (data.containsKey('labels')) {
      var lbls = data['labels'];
      if (lbls is List) {
        for (var l in lbls) {
          labels.add(
            BilliardLabel.at(
              (l['x'] as num).toDouble(),
              (l['y'] as num).toDouble(),
              l['text'].toString(),
              color: Color(l['color'] ?? Colors.yellowAccent.value),
              fontSize: labelFontSize,
              rotation: ((l['rotation'] ?? 0.0) as double) * math.pi / 180.0,
            ),
          );
        }
      }
    }

    List<BilliardAngle> angles = [];
    if (data.containsKey('angles')) {
      var angs = data['angles'];
      if (angs is List) {
        for (var a in angs) {
          angles.add(
            BilliardAngle.at(
              a: Offset(
                (a['a'][0] as num).toDouble(),
                (a['a'][1] as num).toDouble(),
              ),
              b: Offset(
                (a['b'][0] as num).toDouble(),
                (a['b'][1] as num).toDouble(),
              ),
              c: Offset(
                (a['c'][0] as num).toDouble(),
                (a['c'][1] as num).toDouble(),
              ),
              radius: (a['radius'] as num?)?.toDouble() ?? 20.0,
              color: Color(a['color'] ?? Colors.yellowAccent.value),
              label: a['label']?.toString(),
              role: a['role']?.toString(),
            ),
          );
        }
      }
    }

    Map<String, dynamic>? effetData;
    if (data.containsKey('effet')) {
      effetData = Map<String, dynamic>.from(data['effet']);
    }

    return ParsedBilliardLayout(
      balls: balls,
      paths: paths,
      labels: labels,
      angles: angles,
      viewType: vType,
      system: sys,
      effetData: effetData,
    );
  }
}

class BilliardDiagram extends StatefulWidget {
  final List<Ball> balls;
  final List<BallPath>? paths;
  final List<BilliardLabel>? labels;
  final List<BilliardAngle>? angles; // Thêm danh sách cung góc
  final DiagramSystem system;
  final TableViewType viewType;
  final bool isVertical;
  final bool showPlayButton;
  final Map<String, dynamic>? effetData;
  final List<String>? stepTexts;
  final List<Map<String, dynamic>>? stepScripts;
  final bool showFullscreenButton;

  const BilliardDiagram({
    super.key,
    required this.balls,
    this.paths,
    this.labels,
    this.angles,
    this.system = DiagramSystem.standard,
    this.viewType = TableViewType.full,
    this.isVertical = false,
    this.showPlayButton = false,
    this.effetData,
    this.stepTexts,
    this.stepScripts,
    this.showFullscreenButton = true,
  });

  @override
  State<BilliardDiagram> createState() => _BilliardDiagramState();
}

class _BilliardDiagramState extends State<BilliardDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  bool _showControls = true;
  Timer? _hideTimer;

  double _getTotalDuration() {
    final scripts = _getProcessedScripts();
    if (scripts.isEmpty) return 7.0;
    double maxEnd = 7.0;
    for (var step in scripts) {
      double start = (step['start'] as num).toDouble();
      double dur = (step['duration'] as num).toDouble();
      if (start + dur > maxEnd) {
        maxEnd = start + dur;
      }
    }
    return maxEnd;
  }

  @override
  void initState() {
    super.initState();
    final double totalSec = _getTotalDuration();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: (totalSec * 1000).round()),
          )
          ..addListener(() {
            _syncStepFromController();
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              setState(() {});
            }
          });
    _startHideTimer();
  }

  void _startHideTimer() {
    _cancelHideTimer();
    final hasPaths = widget.paths != null && widget.paths!.isNotEmpty;
    if (hasPaths && widget.showPlayButton) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _resetHideTimer() {
    _startHideTimer();
  }

  void _onTapDiagram() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _cancelHideTimer();
    }
  }

  List<Map<String, dynamic>> _getProcessedScripts() {
    if (widget.stepScripts != null && widget.stepScripts!.isNotEmpty) {
      return widget.stepScripts!;
    }
    if (widget.stepTexts != null && widget.stepTexts!.isNotEmpty) {
      final n = widget.stepTexts!.length;
      final double durationPerStep = 7.0 / n;
      return List.generate(n, (i) {
        return {
          'text': widget.stepTexts![i],
          'start': i * durationPerStep,
          'duration': durationPerStep,
        };
      });
    }
    return [];
  }

  void _syncStepFromController() {
    final scripts = _getProcessedScripts();
    if (scripts.isEmpty) return;

    final double totalSec = _getTotalDuration();
    double elapsed = _controller.value * totalSec;
    int foundIndex = -1;
    for (int i = 0; i < scripts.length; i++) {
      double start = (scripts[i]['start'] as num).toDouble();
      double dur = (scripts[i]['duration'] as num).toDouble();
      if (elapsed >= start && elapsed <= (start + dur)) {
        foundIndex = i;
        break;
      }
    }
    if (foundIndex != -1) {
      _currentStep = foundIndex;
    }
  }

  void _moveToScript(int index) {
    _resetHideTimer();
    final scripts = _getProcessedScripts();
    if (index < 0 || index >= scripts.length) return;
    _currentStep = index;

    double start = (scripts[index]['start'] as num).toDouble();
    final double totalSec = _getTotalDuration();
    double targetProgress = start / totalSec;

    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.animateTo(
      targetProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _cancelHideTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double woodRailWidth = 8.0;
        const double cushionWidth = 4.0;
        const double totalRailWidth = woodRailWidth + cushionWidth;
        double viewPlayWidth = 100.0;
        double viewPlayHeight = 200.0;
        bool hasBottomRail = false;
        bool hasRightRail = true;

        switch (widget.viewType) {
          case TableViewType.half:
            viewPlayHeight = 100.0;
            break;
          case TableViewType.third:
            viewPlayHeight = 75.0;
            break;
          case TableViewType.quarter:
            viewPlayHeight = 50.0;
            break;
          case TableViewType.halfWidth:
            viewPlayWidth = 50.0;
            viewPlayHeight = 200.0;
            hasBottomRail = true;
            hasRightRail = false;
            break;
          case TableViewType.halfWidthHalfLength:
            viewPlayWidth = 50.0;
            viewPlayHeight = 100.0;
            hasBottomRail = false;
            hasRightRail = false;
            break;
          case TableViewType.halfWidthThirdLength:
            viewPlayWidth = 50.0;
            viewPlayHeight = 75.0;
            hasBottomRail = false;
            hasRightRail = false;
            break;
          case TableViewType.halfWidthQuarterLength:
            viewPlayWidth = 50.0;
            viewPlayHeight = 50.0;
            hasBottomRail = false;
            hasRightRail = false;
            break;
          default:
            viewPlayHeight = 200.0;
            hasBottomRail = true;
        }

        double totalWidth =
            viewPlayWidth +
            totalRailWidth +
            (hasRightRail ? totalRailWidth : 0);
        double totalHeight =
            viewPlayHeight +
            totalRailWidth +
            (hasBottomRail ? totalRailWidth : 0);

        double finalW = widget.isVertical ? totalWidth : totalHeight;
        double finalH = widget.isVertical ? totalHeight : totalWidth;

        return ValueListenableBuilder<BilliardTheme>(
          valueListenable: ThemeManager.currentTheme,
          builder: (context, currentTheme, _) {
            final scripts = _getProcessedScripts();
            final totalSec = _getTotalDuration();
            final hasPaths = widget.paths != null && widget.paths!.isNotEmpty;
            final showPlayBar = hasPaths && widget.showPlayButton;
            final hasSteps = scripts.isNotEmpty;

            // Determine the active step's custom layout if available
            List<Ball> activeBalls = widget.balls;
            List<BallPath> activePaths = widget.paths ?? [];
            List<BilliardLabel> activeLabels = widget.labels ?? [];
            List<BilliardAngle> activeAngles = widget.angles ?? [];
            TableViewType activeViewType = widget.viewType;
            DiagramSystem activeSystem = widget.system;
            Map<String, dynamic>? activeEffetData = widget.effetData;

            // Static diagrams (editor, cards and previews) must render the whole
            // trajectory immediately. Previously progress stayed at 0 when the
            // play button was hidden, so points appeared without connecting lines.
            double localProgress = widget.showPlayButton
                ? _controller.value
                : 1.0;

            // Chỉ dùng bố cục của từng bước khi đang phát hoạt
            // họa. Trình chỉnh sửa và các bản xem trước tĩnh
            // (showPlayButton == false) phải luôn hiển thị dữ liệu gốc
            // đang được chỉnh sửa; nếu không, hình bi nhìn thấy và
            // vùng bắt thao tác sẽ nằm ở hai tọa độ khác nhau.
            if (widget.showPlayButton &&
                scripts.isNotEmpty &&
                _currentStep < scripts.length) {
              final activeStep = scripts[_currentStep];
              double start = (activeStep['start'] as num).toDouble();
              double dur = (activeStep['duration'] as num).toDouble();
              double elapsed = _controller.value * totalSec;

              // Calculate local progress: 0.0 to 1.0 within the step duration
              localProgress = dur > 0
                  ? ((elapsed - start) / dur).clamp(0.0, 1.0)
                  : 0.0;

              if (activeStep.containsKey('layout') &&
                  activeStep['layout'] != null) {
                try {
                  final layoutMap = Map<String, dynamic>.from(
                    activeStep['layout'] as Map,
                  );
                  final parsed = ParsedBilliardLayout.parse(layoutMap);
                  activeBalls = parsed.balls;
                  activePaths = parsed.paths;
                  activeLabels = parsed.labels;
                  activeAngles = parsed.angles;
                  activeViewType = parsed.viewType;
                  activeSystem = parsed.system;
                  activeEffetData = parsed.effetData;
                } catch (_) {
                  // Fail-safe: fall back to root diagram data
                }
              }
            }

            final boardContainer = Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: BilliardPainter(
                        activeBalls,
                        activePaths,
                        activeLabels,
                        activeAngles,
                        woodRailWidth,
                        cushionWidth,
                        activeSystem,
                        activeViewType,
                        widget.isVertical,
                        hasBottomRail,
                        localProgress,
                        currentTheme,
                        activeEffetData,
                      ),
                    ),
                  ),
                  // Subtitles overlay
                  if (widget.showPlayButton &&
                      scripts.isNotEmpty &&
                      _currentStep < scripts.length)
                    () {
                      double elapsed = _controller.value * totalSec;
                      double start = (scripts[_currentStep]['start'] as num)
                          .toDouble();
                      double dur = (scripts[_currentStep]['duration'] as num)
                          .toDouble();
                      double fs =
                          (scripts[_currentStep]['fontSize'] as num?)
                              ?.toDouble() ??
                          14.0;

                      if (elapsed >= start && elapsed <= (start + dur)) {
                        final script = scripts[_currentStep];
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
                          script['text'] ?? '',
                          key: ValueKey<String>(
                            "sub_${_currentStep}_${_controller.value.toStringAsFixed(1)}",
                          ),
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
                          // Calculate pixel positions based on total W and H
                          final bool rightRail =
                              widget.viewType != TableViewType.halfWidth &&
                              widget.viewType !=
                                  TableViewType.halfWidthHalfLength &&
                              widget.viewType !=
                                  TableViewType.halfWidthThirdLength &&
                              widget.viewType !=
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
                          final double pxX = totalR + (relX * diamondSp * 4);
                          final double pxY = totalR + (relY * diamondSp * 4);

                          double leftPos = widget.isVertical ? pxX : pxY;
                          double topPos = widget.isVertical ? pxY : pxX;

                          return Positioned(
                            left:
                                leftPos -
                                120, // 240 width boundary offset center
                            width: 240,
                            top: topPos - 20,
                            child: IgnorePointer(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: textWidget,
                              ),
                            ),
                          );
                        } else {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: 16,
                            right: 16,
                            bottom: (showPlayBar && _showControls)
                                ? 64.0
                                : 16.0,
                            child: IgnorePointer(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: textWidget,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox();
                    }(),
                  // Floating play controls overlay (compact size & with fullscreen/exit buttons)
                  if (showPlayBar)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        child: IgnorePointer(
                          ignoring: !_showControls,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Backward Button
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.skip_previous),
                                    color: hasSteps && _currentStep > 0
                                        ? Colors.cyanAccent
                                        : Colors.grey,
                                    onPressed: hasSteps && _currentStep > 0
                                        ? () => _moveToScript(_currentStep - 1)
                                        : null,
                                    tooltip: 'Lùi bước',
                                  ),
                                  const SizedBox(width: 8),
                                  // Play / Pause Button
                                  InkWell(
                                    onTap: () {
                                      _resetHideTimer();
                                      if (_controller.isAnimating) {
                                        _controller.stop();
                                        setState(() {});
                                      } else {
                                        if (_controller.status ==
                                            AnimationStatus.completed) {
                                          _controller.reset();
                                        }
                                        _controller.forward();
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent.withOpacity(
                                          0.15,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.cyanAccent,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        _controller.isAnimating
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.cyanAccent,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Forward Button
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.skip_next),
                                    color:
                                        hasSteps &&
                                            _currentStep < scripts.length - 1
                                        ? Colors.cyanAccent
                                        : Colors.grey,
                                    onPressed:
                                        hasSteps &&
                                            _currentStep < scripts.length - 1
                                        ? () => _moveToScript(_currentStep + 1)
                                        : null,
                                    tooltip: 'Tiến bước',
                                  ),
                                  const SizedBox(width: 12),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 16,
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(width: 8),
                                  // Fullscreen / Exit Fullscreen Button
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      widget.showFullscreenButton
                                          ? Icons.fullscreen
                                          : Icons.fullscreen_exit,
                                    ),
                                    color: Colors.white,
                                    onPressed: () {
                                      _resetHideTimer();
                                      if (widget.showFullscreenButton) {
                                        // Enter Fullscreen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullscreenBilliardViewer(
                                                  child: BilliardDiagram(
                                                    balls: widget.balls,
                                                    paths: widget.paths,
                                                    labels: widget.labels,
                                                    angles: widget.angles,
                                                    system: widget.system,
                                                    viewType: widget.viewType,
                                                    isVertical:
                                                        widget.isVertical,
                                                    effetData: widget.effetData,
                                                    stepTexts: widget.stepTexts,
                                                    stepScripts:
                                                        widget.stepScripts,
                                                    showFullscreenButton:
                                                        false, // Exit button shows instead
                                                  ),
                                                ),
                                          ),
                                        );
                                      } else {
                                        // Exit Fullscreen
                                        Navigator.pop(context);
                                      }
                                    },
                                    tooltip: widget.showFullscreenButton
                                        ? 'Toàn màn hình'
                                        : 'Thu nhỏ',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

            return AspectRatio(
              aspectRatio: finalW / finalH,
              child: showPlayBar
                  ? GestureDetector(
                      onTap: _onTapDiagram,
                      behavior: HitTestBehavior.opaque,
                      child: boardContainer,
                    )
                  : boardContainer,
            );
          },
        );
      },
    );
  }
}

class PathTiming {
  final double startTime;
  final double endTime;
  PathTiming(this.startTime, this.endTime);
}

class BilliardPainter extends CustomPainter {
  final List<Ball> balls;
  final List<BallPath> paths;
  final List<BilliardLabel> labels;
  final List<BilliardAngle> angles;
  final double woodRailWidth;
  final double cushionWidth;
  final DiagramSystem system;
  final TableViewType viewType;
  final bool isVertical;
  final bool hasBottomRail;
  final double animationProgress;
  final BilliardTheme theme;
  final Map<String, dynamic>? effetData;

  BilliardPainter(
    this.balls,
    this.paths,
    this.labels,
    this.angles,
    this.woodRailWidth,
    this.cushionWidth,
    this.system,
    this.viewType,
    this.isVertical,
    this.hasBottomRail,
    this.animationProgress,
    this.theme,
    this.effetData,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final renderModel = LegacyRenderAdapter.legacyParametersToRenderModel(
      balls: balls,
      paths: paths,
      labels: labels,
      angles: angles,
      system: system,
      viewType: viewType,
      isVertical: isVertical,
      hasBottomRail: hasBottomRail,
      animationProgress: animationProgress,
      themeIndicatorColors: theme.indicatorColors,
      effetData: effetData,
    );

    final scenePainter = ScenePainter(model: renderModel);
    scenePainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant BilliardPainter oldDelegate) {
    return !identical(balls, oldDelegate.balls) ||
        !identical(paths, oldDelegate.paths) ||
        !identical(labels, oldDelegate.labels) ||
        !identical(angles, oldDelegate.angles) ||
        woodRailWidth != oldDelegate.woodRailWidth ||
        cushionWidth != oldDelegate.cushionWidth ||
        system != oldDelegate.system ||
        viewType != oldDelegate.viewType ||
        isVertical != oldDelegate.isVertical ||
        hasBottomRail != oldDelegate.hasBottomRail ||
        animationProgress != oldDelegate.animationProgress ||
        theme != oldDelegate.theme ||
        !mapEquals(effetData, oldDelegate.effetData);
  }
}
