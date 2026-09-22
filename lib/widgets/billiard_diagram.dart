import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/theme_manager.dart';
import '../screens/fullscreen_billiard_viewer.dart';

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

  void drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize, {
    Color color = Colors.white,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  Offset _getPositionOnPath(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1 || t <= 0.0) return points.first;
    if (t >= 1.0) return points.last;

    // Apply quadratic ease-out to simulate rolling friction deceleration
    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      double len = (points[i + 1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return points.first;

    double targetDist = totalLength * easedT;
    double currentDist = 0.0;
    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDist + segmentLengths[i] >= targetDist) {
        double segmentT = (targetDist - currentDist) / segmentLengths[i];
        return Offset.lerp(points[i], points[i + 1], segmentT)!;
      }
      currentDist += segmentLengths[i];
    }
    return points.last;
  }

  List<Offset> _getProgressivePoints(List<Offset> points, double t) {
    if (points.isEmpty) return [];
    if (t >= 1.0) return points;

    // Apply quadratic ease-out to match the ball's deceleration trail
    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      double len = (points[i + 1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return [points.first];

    double targetDist = totalLength * easedT;
    double currentDist = 0.0;
    List<Offset> result = [points.first];

    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDist + segmentLengths[i] >= targetDist) {
        double segmentT = (targetDist - currentDist) / segmentLengths[i];
        result.add(Offset.lerp(points[i], points[i + 1], segmentT)!);
        break;
      } else {
        result.add(points[i + 1]);
        currentDist += segmentLengths[i];
      }
    }
    return result;
  }

  double _getPathLength(List<Offset> pts) {
    double len = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      len += (pts[i + 1] - pts[i]).distance;
    }
    return len;
  }

  List<PathTiming> _computeTimings() {
    int n = paths.length;
    List<double> lengths = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      lengths[i] = _getPathLength(paths[i].points);
    }

    List<int> parent = List.filled(n, -1);
    List<double> colFraction = List.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      Offset startPoint = paths[i].points.isNotEmpty
          ? paths[i].points.first
          : Offset.zero;
      double earliestCollisionFraction = double.infinity;
      int bestParent = -1;

      for (int j = 0; j < n; j++) {
        if (i == j) continue;

        double currentDist = 0.0;
        for (int k = 0; k < paths[j].points.length - 1; k++) {
          Offset A = paths[j].points[k];
          Offset B = paths[j].points[k + 1];
          double segLen = (B - A).distance;

          double dx = B.dx - A.dx;
          double dy = B.dy - A.dy;
          double abLenSq = dx * dx + dy * dy;
          if (abLenSq > 0) {
            double u =
                ((startPoint.dx - A.dx) * dx + (startPoint.dy - A.dy) * dy) /
                abLenSq;
            if (u < 0.0) u = 0.0;
            if (u > 1.0) u = 1.0;

            Offset closest = Offset(A.dx + u * dx, A.dy + u * dy);
            double dist = (startPoint - closest).distance;

            if (dist < 0.05) {
              double hitDist = currentDist + u * segLen;
              double frac = lengths[j] > 0 ? (hitDist / lengths[j]) : 0.0;
              if (frac < earliestCollisionFraction) {
                earliestCollisionFraction = frac;
                bestParent = j;
              }
            }
          }
          currentDist += segLen;
        }
      }

      if (bestParent != -1) {
        parent[i] = bestParent;
        colFraction[i] = earliestCollisionFraction;
      }
    }

    List<double> startTimes = List.filled(n, 0.0);
    List<bool> resolved = List.filled(n, false);

    for (int iter = 0; iter < n; iter++) {
      for (int i = 0; i < n; i++) {
        if (resolved[i]) continue;

        int p = parent[i];
        if (p == -1) {
          startTimes[i] = 0.0;
          resolved[i] = true;
        } else if (resolved[p]) {
          double parentLocalT = 1.0 - math.sqrt(1.0 - colFraction[i]);
          startTimes[i] = startTimes[p] + parentLocalT * (1.0 - startTimes[p]);
          resolved[i] = true;
        }
      }
    }

    for (int i = 0; i < n; i++) {
      if (!resolved[i]) {
        startTimes[i] = 0.0;
      }
    }

    List<PathTiming> timings = [];
    for (int i = 0; i < n; i++) {
      timings.add(PathTiming(startTimes[i], 1.0));
    }
    return timings;
  }

  void _drawGhostShadow(
    Canvas canvas,
    Ball ball,
    double ballRadius,
    double lineScale,
    double playAreaWidth,
    double diamondSpacing,
    double totalRail,
  ) {
    Offset actualPos = _getActualPos(
      ball.position,
      playAreaWidth,
      diamondSpacing,
      totalRail,
    );
    canvas.save();
    canvas.translate(actualPos.dx, actualPos.dy);
    canvas.rotate(ball.rotation);

    final ghostPaint = Paint()
      ..color = ball.color.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = ball.color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 * lineScale;

    if (ball.type == BallType.full) {
      canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
      canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
      canvas.drawLine(
        Offset(-ballRadius, 0),
        Offset(ballRadius, 0),
        strokePaint,
      );
      canvas.drawLine(
        Offset(0, -ballRadius),
        Offset(0, ballRadius),
        strokePaint,
      );
    } else if (ball.type == BallType.half) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ballRadius),
        -math.pi / 2,
        math.pi,
        true,
        ghostPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ballRadius),
        -math.pi / 2,
        math.pi,
        true,
        strokePaint,
      );
      canvas.drawLine(
        Offset(0, -ballRadius),
        Offset(0, ballRadius),
        strokePaint,
      );
    } else {
      canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
      canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
    }
    canvas.restore();
  }

  void _drawCaromDots(
    Canvas canvas,
    double ballRadius,
    Color ballColor,
    double opacity,
  ) {
    Color dotColor;
    if (ballColor.red > 180 && ballColor.green < 100 && ballColor.blue < 100) {
      // Red ball gets white/cream dots
      dotColor = Colors.white.withOpacity(opacity);
    } else {
      // White or Yellow ball gets dark red dots
      dotColor = const Color(0xFFD32F2F).withOpacity(opacity);
    }

    final Paint paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Center dot
    canvas.drawCircle(Offset.zero, ballRadius * 0.12, paint);

    // 5 outer dots symmetrically spaced
    final double radius = ballRadius * 0.55;
    for (int i = 0; i < 5; i++) {
      double angle = i * 2 * math.pi / 5;
      canvas.drawCircle(
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        ballRadius * 0.12,
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = isVertical ? size.width : size.height;
    final double h = isVertical ? size.height : size.width;

    final bool hasRightRail =
        viewType != TableViewType.halfWidth &&
        viewType != TableViewType.halfWidthHalfLength &&
        viewType != TableViewType.halfWidthThirdLength &&
        viewType != TableViewType.halfWidthQuarterLength;
    final double woodRail = w * (8.0 / (hasRightRail ? 124.0 : 62.0));
    final double cushion = w * (4.0 / (hasRightRail ? 124.0 : 62.0));
    final double totalRail = woodRail + cushion;
    final double scale = w / (hasRightRail ? 124.0 : 62.0);

    final double textScale = 1.0 + (scale - 1.0) * 0.15;
    final double lineScale = 1.0 + (scale - 1.0) * 0.15;

    final double playAreaWidth = w - totalRail - (hasRightRail ? totalRail : 0);
    final double playAreaHeight =
        h - totalRail - (hasBottomRail ? totalRail : 0);

    if (!isVertical) {
      canvas.save();
      canvas.rotate(-math.pi / 2);
      canvas.translate(-size.height, 0);
    }

    canvas.drawRect(
      Rect.fromLTWH(totalRail, totalRail, playAreaWidth, playAreaHeight),
      Paint()..color = Colors.teal,
    );

    final Paint cushionPaint = Paint()..color = Colors.teal.shade800;
    double verticalCushionHeight = playAreaHeight + cushion;
    canvas.drawRect(
      Rect.fromLTWH(
        woodRail,
        woodRail,
        w - woodRail - (hasRightRail ? woodRail : 0),
        cushion,
      ),
      cushionPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(woodRail, woodRail, cushion, verticalCushionHeight),
      cushionPaint,
    );
    if (hasRightRail) {
      canvas.drawRect(
        Rect.fromLTWH(w - totalRail, woodRail, cushion, verticalCushionHeight),
        cushionPaint,
      );
    }
    if (hasBottomRail) {
      canvas.drawRect(
        Rect.fromLTWH(
          woodRail,
          h - totalRail,
          w - woodRail - (hasRightRail ? woodRail : 0),
          cushion,
        ),
        cushionPaint,
      );
    }

    final int hSegments =
        (viewType == TableViewType.halfWidth ||
            viewType == TableViewType.halfWidthHalfLength ||
            viewType == TableViewType.halfWidthThirdLength ||
            viewType == TableViewType.halfWidthQuarterLength)
        ? 2
        : 4;
    final double diamondSpacing = playAreaWidth / hSegments;
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4 * lineScale;
    for (int i = 1; i < hSegments; i++) {
      double x = totalRail + i * diamondSpacing;
      canvas.drawLine(
        Offset(x, totalRail),
        Offset(x, totalRail + playAreaHeight),
        gridPaint,
      );
    }
    int vSegments = (playAreaHeight / diamondSpacing).floor();
    for (int i = 1; i <= vSegments; i++) {
      double y = totalRail + i * diamondSpacing;
      canvas.drawLine(
        Offset(totalRail, y),
        Offset(totalRail + playAreaWidth, y),
        gridPaint,
      );
    }

    // Chia khoảng giữa hai diamond thành 10 đơn vị trên
    // băng cao su. Mỗi khoảng có 9 vạch phụ; vạch giữa
    // dài hơn một chút để dễ ước lượng 5 đơn vị.
    final minorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 0.65 * lineScale
      ..strokeCap = StrokeCap.round;
    final horizontalTickSegments = hSegments;
    final verticalTickSegments = (playAreaHeight / diamondSpacing).round();

    for (int segment = 0; segment < horizontalTickSegments; segment++) {
      for (int unit = 1; unit < 10; unit++) {
        final x = totalRail + (segment + unit / 10.0) * diamondSpacing;
        final length = cushion * (unit == 5 ? 0.55 : 0.34);
        canvas.drawLine(
          Offset(x, totalRail),
          Offset(x, totalRail - length),
          minorTickPaint,
        );
        if (hasBottomRail) {
          final bottom = totalRail + playAreaHeight;
          canvas.drawLine(
            Offset(x, bottom),
            Offset(x, bottom + length),
            minorTickPaint,
          );
        }
      }
    }

    for (int segment = 0; segment < verticalTickSegments; segment++) {
      for (int unit = 1; unit < 10; unit++) {
        final y = totalRail + (segment + unit / 10.0) * diamondSpacing;
        if (y > totalRail + playAreaHeight) continue;
        final length = cushion * (unit == 5 ? 0.55 : 0.34);
        canvas.drawLine(
          Offset(totalRail, y),
          Offset(totalRail - length, y),
          minorTickPaint,
        );
        if (hasRightRail) {
          final right = totalRail + playAreaWidth;
          canvas.drawLine(
            Offset(right, y),
            Offset(right + length, y),
            minorTickPaint,
          );
        }
      }
    }

    final Paint diamondPaint = Paint()..color = Colors.white.withOpacity(0.8);
    for (int i = 0; i <= hSegments; i++) {
      double x = totalRail + i * diamondSpacing;
      canvas.drawCircle(
        Offset(x, woodRail / 2),
        1.45 * lineScale,
        diamondPaint,
      );
      if (hasBottomRail)
        canvas.drawCircle(
          Offset(x, h - woodRail / 2),
          1.45 * lineScale,
          diamondPaint,
        );
    }
    for (int i = 0; i <= (playAreaHeight / diamondSpacing).round(); i++) {
      double y = totalRail + i * diamondSpacing;
      if (y <= h) {
        canvas.drawCircle(
          Offset(woodRail / 2, y),
          1.45 * lineScale,
          diamondPaint,
        );
        if (hasRightRail) {
          canvas.drawCircle(
            Offset(w - woodRail / 2, y),
            1.45 * lineScale,
            diamondPaint,
          );
        }
      }
    }

    if (system == DiagramSystem.xohaibang) {
      for (int i = 0; i <= 4; i++) {
        double x = totalRail + i * diamondSpacing;
        drawText(
          canvas,
          "${i + 1}",
          Offset(x, woodRail / 2 - 8 * textScale),
          9 * textScale,
          color: Colors.yellow,
        );
      }
      if (hasBottomRail) {
        for (int i = 0; i <= 4; i++) {
          double x = totalRail + i * diamondSpacing;
          drawText(
            canvas,
            "$i",
            Offset(x, h - woodRail / 2 + 8 * textScale),
            9 * textScale,
            color: Colors.white,
          );
        }
      }
      int vCount = (playAreaHeight / diamondSpacing).round();
      for (int i = vCount; i >= 0; i--) {
        double y = totalRail + i * diamondSpacing;
        if (y <= h) {
          drawText(
            canvas,
            "${vCount - i}",
            Offset(woodRail / 2 - 10 * textScale, y),
            9 * textScale,
            color: Colors.cyanAccent,
          );
        }
      }
    }
    if (system == DiagramSystem.babangcha) {
      for (int i = 1; i <= 4; i++) {
        double x;
        if (i < 4 && i >= 3) {
          x = totalRail + 2.5 * diamondSpacing;
          drawText(
            canvas,
            "-1",
            Offset(x, woodRail / 2 - 8 * textScale),
            11 * textScale,
            color: Colors.red,
          );
        }
        if (i < 3 && i >= 2) {
          x = totalRail + 1.5 * diamondSpacing;
          drawText(
            canvas,
            "-2",
            Offset(x, woodRail / 2 - 8 * textScale),
            11 * textScale,
            color: Colors.red,
          );
        }
      }
      for (int v = 1; v <= 12; v++) {
        double nodeY;
        if (v <= 4) {
          nodeY = v * 0.5;
        } else {
          nodeY = 2.0 + (v - 4) * 0.25;
        }
        double y = totalRail + nodeY * diamondSpacing;
        if (y <= h - woodRail) {
          drawText(
            canvas,
            "$v",
            Offset(woodRail / 2 - 10 * textScale, y),
            11 * textScale,
            color: Colors.lightGreenAccent,
          );
        }
      }
      for (int v = 1; v <= 12; v++) {
        double nodeY;
        if (v <= 8) {
          nodeY = v * 0.5;
        } else {
          nodeY = 4.0 + (v - 8);
        }
        double y = totalRail + nodeY * diamondSpacing;
        if (y <= h - woodRail) {
          drawText(
            canvas,
            "$v",
            Offset(w - woodRail / 2 + 10 * textScale, y),
            11 * textScale,
            color: Colors.white,
          );
        }
      }
    }
    // Vẽ cung góc (BilliardAngle)
    for (var angle in angles) {
      Offset posA = _getActualPos(
        angle.a,
        playAreaWidth,
        diamondSpacing,
        totalRail,
      );
      Offset posB = _getActualPos(
        angle.b,
        playAreaWidth,
        diamondSpacing,
        totalRail,
      );
      Offset posC = _getActualPos(
        angle.c,
        playAreaWidth,
        diamondSpacing,
        totalRail,
      );

      double startAngle = math.atan2(posA.dy - posB.dy, posA.dx - posB.dx);
      double endAngle = math.atan2(posC.dy - posB.dy, posC.dx - posB.dx);
      double sweepAngle = endAngle - startAngle;

      if (sweepAngle > math.pi) sweepAngle -= 2 * math.pi;
      if (sweepAngle < -math.pi) sweepAngle += 2 * math.pi;

      final Color angleColor =
          (angle.role != null && theme.indicatorColors.containsKey(angle.role))
          ? theme.indicatorColors[angle.role]!
          : angle.color;

      final Paint anglePaint = Paint()
        ..color = angleColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * lineScale;

      canvas.drawArc(
        Rect.fromCircle(center: posB, radius: angle.radius * lineScale),
        startAngle,
        sweepAngle,
        false,
        anglePaint,
      );

      double midAngle = startAngle + sweepAngle / 2;
      double degreeValue = (sweepAngle.abs() * 180 / math.pi);
      String degreeText = angle.label ?? "${degreeValue.toStringAsFixed(1)}°";

      Offset labelPos = Offset(
        posB.dx +
            math.cos(midAngle) * (angle.radius * lineScale + 12 * textScale),
        posB.dy +
            math.sin(midAngle) * (angle.radius * lineScale + 12 * textScale),
      );

      drawText(canvas, degreeText, labelPos, 8 * textScale, color: angleColor);
    }

    final timings = _computeTimings();

    // Determine phase: 0.0 to 0.2 is the path-blinking phase, 0.2 to 1.0 is the rolling phase
    double motionProgress = 0.0;
    double blinkOpacity = 1.0;
    bool isBlinkingPhase = animationProgress > 0 && animationProgress <= 0.2;

    if (animationProgress > 0) {
      if (animationProgress <= 0.2) {
        motionProgress = 0.0;
        // Oscillate path opacity 3 times (frequency = 3 cycles)
        double sinVal = math.sin(animationProgress * 5.0 * math.pi * 3.0);
        blinkOpacity = 0.2 + 0.8 * (sinVal.abs());
      } else {
        motionProgress = (animationProgress - 0.2) / 0.8;
        blinkOpacity = 1.0;
      }
    }

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final timing = timings[i];

      double localT = 0.0;
      if (isBlinkingPhase) {
        localT = 1.0; // Show the full trajectory path during blinking phase
      } else if (motionProgress >= timing.endTime) {
        localT = 1.0;
      } else if (motionProgress <= timing.startTime) {
        localT = 0.0;
      } else {
        localT =
            (motionProgress - timing.startTime) /
            (timing.endTime - timing.startTime);
      }

      final List<Offset> activePoints = _getProgressivePoints(
        path.points,
        localT,
      );
      if (activePoints.isEmpty) continue;

      final Color pathColor =
          (path.role != null && theme.indicatorColors.containsKey(path.role))
          ? theme.indicatorColors[path.role]!
          : path.color;

      final Paint pathPaint = Paint()
        ..color = pathColor.withOpacity(
          path.opacity * (isBlinkingPhase ? blinkOpacity : 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * lineScale
        ..strokeCap = StrokeCap.round;

      for (int j = 0; j < activePoints.length - 1; j++) {
        Offset p1 = _getActualPos(
          activePoints[j],
          playAreaWidth,
          diamondSpacing,
          totalRail,
        );
        Offset p2 = _getActualPos(
          activePoints[j + 1],
          playAreaWidth,
          diamondSpacing,
          totalRail,
        );

        if (path.isDashed) {
          final double dashWidth = 4.0 * lineScale;
          final double dashSpace = 3.0 * lineScale;
          double distance = (p2 - p1).distance;
          int count = (distance / (dashWidth + dashSpace)).floor();
          for (int k = 0; k < count; k++) {
            double startT = (k * (dashWidth + dashSpace)) / distance;
            double endT = (k * (dashWidth + dashSpace) + dashWidth) / distance;
            canvas.drawLine(
              Offset.lerp(p1, p2, startT)!,
              Offset.lerp(p1, p2, endT)!,
              pathPaint,
            );
          }
        } else {
          canvas.drawLine(p1, p2, pathPaint);
        }
      }
    }

    // Keep the physical ball size consistent across cropped table views.
    // A ball radius is about one tenth of the distance between two diamonds.
    // Using a percentage of the visible width made balls 50% too small in
    // half-width modes because those views contain only two horizontal spans.
    final double ballRadius = diamondSpacing * 0.1;
    for (var ball in balls) {
      Offset relativePos = ball.position;
      double rollAngle = 0.0;

      if (animationProgress > 0 && !ball.isGhost && !ball.isOutline) {
        for (int i = 0; i < paths.length; i++) {
          final path = paths[i];
          if (path.points.isNotEmpty &&
              (ball.position - path.points.first).distance < 0.05) {
            // Draw a ghost shadow ball at the original position
            _drawGhostShadow(
              canvas,
              ball,
              ballRadius,
              lineScale,
              playAreaWidth,
              diamondSpacing,
              totalRail,
            );

            final timing = timings[i];
            double totalLength = _getPathLength(path.points);
            if (motionProgress < timing.startTime) {
              relativePos = path.points.first;
              rollAngle = 0.0;
            } else if (motionProgress > timing.endTime) {
              relativePos = path.points.last;
              rollAngle = totalLength * 50.0;
            } else {
              double localT =
                  (motionProgress - timing.startTime) /
                  (timing.endTime - timing.startTime);
              relativePos = _getPositionOnPath(path.points, localT);
              double easedT = localT * (2.0 - localT);
              rollAngle = totalLength * easedT * 50.0;
            }
            break;
          }
        }
      }

      Offset actualPos = _getActualPos(
        relativePos,
        playAreaWidth,
        diamondSpacing,
        totalRail,
      );

      canvas.save();
      canvas.translate(actualPos.dx, actualPos.dy);

      if (ball.isOutline) {
        canvas.save();
        canvas.rotate(ball.rotation);
        final strokePaint = Paint()
          ..color = ball.color.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * lineScale;

        const int dashCount = 12;
        const double dashAngle = (2 * math.pi) / dashCount;
        for (int i = 0; i < dashCount; i++) {
          if (i % 2 == 0) {
            canvas.drawArc(
              Rect.fromCircle(center: Offset.zero, radius: ballRadius),
              i * dashAngle,
              dashAngle,
              false,
              strokePaint,
            );
          }
        }
        canvas.restore();
      } else if (ball.isGhost) {
        canvas.save();
        canvas.rotate(ball.rotation);
        final ghostPaint = Paint()
          ..color = ball.color.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = ball.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 * lineScale;

        if (ball.type == BallType.full) {
          canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
          canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
          canvas.drawLine(
            Offset(-ballRadius, 0),
            Offset(ballRadius, 0),
            strokePaint,
          );
          canvas.drawLine(
            Offset(0, -ballRadius),
            Offset(0, ballRadius),
            strokePaint,
          );
        } else if (ball.type == BallType.half) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: ballRadius),
            -math.pi / 2,
            math.pi,
            true,
            ghostPaint,
          );
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: ballRadius),
            -math.pi / 2,
            math.pi,
            true,
            strokePaint,
          );
          canvas.drawLine(
            Offset(0, -ballRadius),
            Offset(0, ballRadius),
            strokePaint,
          );
        } else if (ball.type == BallType.numbered) {
          canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
          canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
          if (ball.text != null && ball.text!.isNotEmpty) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: ball.text,
                style: TextStyle(
                  color: ball.color.withOpacity(0.9),
                  fontSize: ballRadius * 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(-textPainter.width / 2, -textPainter.height / 2),
            );
          }
        }
        canvas.restore();
      } else {
        // Draw the 3D rotating ball body with measles pattern
        double totalRotation = ball.rotation + rollAngle;

        // 1. Draw body and dots rotated
        canvas.save();
        canvas.rotate(totalRotation);
        canvas.drawCircle(
          Offset.zero,
          ballRadius,
          Paint()..color = ball.color.withOpacity(ball.opacity),
        );
        _drawCaromDots(canvas, ballRadius, ball.color, ball.opacity);
        canvas.restore();

        // 2. Draw 3D specular highlight and ambient shadow overlay (stationary)
        final Rect rect = Rect.fromCircle(
          center: Offset.zero,
          radius: ballRadius,
        );
        final Paint highlightPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 0.85,
            colors: [
              Colors.white.withOpacity(0.65 * ball.opacity),
              Colors.white.withOpacity(0.2 * ball.opacity),
              Colors.transparent,
              Colors.black.withOpacity(0.45 * ball.opacity),
            ],
            stops: const [0.0, 0.35, 0.75, 1.0],
          ).createShader(rect);
        canvas.drawCircle(Offset.zero, ballRadius, highlightPaint);
      }
      canvas.restore();
    }

    for (var label in labels) {
      Offset actualPos = _getActualPos(
        label.position,
        playAreaWidth,
        diamondSpacing,
        totalRail,
      );

      canvas.save();
      canvas.translate(actualPos.dx, actualPos.dy);
      canvas.rotate(label.rotation);

      final Color labelColor =
          (label.role != null && theme.indicatorColors.containsKey(label.role))
          ? theme.indicatorColors[label.role]!
          : label.color;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: labelColor,
            fontSize: label.fontSize * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    if (effetData != null) {
      _drawMiniEffet(
        canvas,
        size,
        playAreaWidth,
        totalRail,
        scale,
        lineScale,
        textScale,
      );
    }

    if (!isVertical) canvas.restore();
  }

  void _drawMiniEffet(
    Canvas canvas,
    Size size,
    double playAreaWidth,
    double totalRail,
    double scale,
    double lineScale,
    double textScale,
  ) {
    if (effetData == null) return;

    final spots = effetData!['spots'] ?? [];
    final bool showHitBall = effetData!['showHitBall'] ?? false;
    final int hitThickness = effetData!['hitThickness'] ?? 6;
    final String hitSide = effetData!['hitSide'] ?? 'right';
    final double spotSize =
        (effetData!['spotSize'] as num?)?.toDouble() ?? 25.0;

    final double miniSize = (playAreaWidth * 0.24).clamp(55.0, 95.0);
    final double miniRadius = miniSize / 2;

    // Vị trí: dịch chuyển ra sát mép góc gỗ trên cùng bên phải
    final double w = isVertical ? size.width : size.height;
    final double centerX = w - miniRadius - 2.0;
    final double centerY = miniRadius + 2.0;

    final double ballRadius = showHitBall ? (miniSize / 2.8) : miniRadius;

    Offset cueCenter = Offset(centerX, centerY);
    Offset targetCenter = Offset(centerX, centerY);

    if (showHitBall) {
      final double centerDist = 2 * ballRadius * (1 - hitThickness / 12);
      final double halfDist = centerDist / 2;
      if (hitSide == 'right') {
        cueCenter = Offset(centerX + halfDist, centerY);
        targetCenter = Offset(centerX - halfDist, centerY);
      } else {
        cueCenter = Offset(centerX - halfDist, centerY);
        targetCenter = Offset(centerX + halfDist, centerY);
      }
    }

    // 1. Vẽ bi mục tiêu (Đỏ)
    if (showHitBall) {
      final Paint targetBgPaint = Paint()
        ..color = Colors.red.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetCenter, ballRadius, targetBgPaint);

      final Paint targetBorderPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * lineScale;
      canvas.drawCircle(targetCenter, ballRadius, targetBorderPaint);
    }

    // 2. Vẽ bi chủ (Trắng)
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF9F9F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(cueCenter, ballRadius, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * lineScale;
    canvas.drawCircle(cueCenter, ballRadius, borderPaint);

    // 3. Vẽ các đường đồng tâm (2 lớp cho hình mini)
    final Paint ringPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4 * lineScale;
    canvas.drawCircle(cueCenter, ballRadius * 0.5, ringPaint);

    // Vẽ hồng tâm
    final Paint linePaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 0.6 * lineScale;
    canvas.drawLine(
      Offset(cueCenter.dx - ballRadius, cueCenter.dy),
      Offset(cueCenter.dx + ballRadius, cueCenter.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(cueCenter.dx, cueCenter.dy - ballRadius),
      Offset(cueCenter.dx, cueCenter.dy + ballRadius),
      linePaint,
    );

    // Vẽ các chấm áp-phê
    final double computedSpotRadius = 3.5 * (spotSize / 25.0) * lineScale;
    for (var spot in spots) {
      final double dx = (spot['x'] as num).toDouble();
      final double dy = (spot['y'] as num).toDouble();
      final String text = spot['number']?.toString() ?? '';
      final Color color = Color(spot['color'] ?? Colors.teal.value);

      final Offset spotCenter = Offset(
        cueCenter.dx + dx * ballRadius,
        cueCenter.dy + dy * ballRadius,
      );

      final Paint spotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotPaint);

      final Paint spotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * lineScale;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotBorder);

      final Color textColor = color.computeLuminance() > 0.6
          ? Colors.black87
          : Colors.white;

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 4.5 * (spotSize / 25.0) * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(spotCenter.dx - tp.width / 2, spotCenter.dy - tp.height / 2),
      );
    }
  }

  Offset _getActualPos(
    Offset relative,
    double playWidth,
    double diamondSpacing,
    double totalRail,
  ) {
    return Offset(
      totalRail + (relative.dx * diamondSpacing * 4),
      totalRail + (relative.dy * diamondSpacing * 4),
    );
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
