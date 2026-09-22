// Phase 3 Final Visual QA Page for Billiardlearning
//
// DEV / Verification Harness for testing Phase 3 SceneRenderer features,
// 8 view modes, vertical/horizontal orientations, legacy playback animation,
// and on-screen checklist.

import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/value_objects/value_objects.dart';
import '../rendering/scene/scene_render_model.dart';
import '../rendering/scene/scene_renderer.dart';
import '../rendering/scene/scene_viewport.dart';
import 'fullscreen_billiard_viewer.dart';

/// Helper calculating canonical canvas [Size] for a given [SceneViewMode] and orientation
/// based on exact diamond proportions and rail boundaries.
Size phase3QaCanvasSize(
  SceneViewMode mode, {
  required bool isVertical,
  double targetWidth = 280.0,
}) {
  final bool hasRightRail =
      mode != SceneViewMode.halfWidth &&
      mode != SceneViewMode.halfWidthHalfLength &&
      mode != SceneViewMode.halfWidthThirdLength &&
      mode != SceneViewMode.halfWidthQuarterLength;

  final bool hasBottomRail =
      mode == SceneViewMode.full || mode == SceneViewMode.halfWidth;

  final double railScaleDenom = hasRightRail ? 124.0 : 62.0;
  final double w = targetWidth;
  final double totalR = w * (12.0 / railScaleDenom);
  final double pWidth = w - totalR - (hasRightRail ? totalR : 0.0);
  final int hSegments = hasRightRail ? 4 : 2;
  final double diamondSpacing = pWidth / hSegments;

  int vSegments;
  switch (mode) {
    case SceneViewMode.full:
    case SceneViewMode.halfWidth:
      vSegments = 8;
      break;
    case SceneViewMode.half:
    case SceneViewMode.halfWidthHalfLength:
      vSegments = 4;
      break;
    case SceneViewMode.third:
    case SceneViewMode.halfWidthThirdLength:
      vSegments = 3;
      break;
    case SceneViewMode.quarter:
    case SceneViewMode.halfWidthQuarterLength:
      vSegments = 2;
      break;
  }

  final double pHeight = vSegments * diamondSpacing;
  final double h = totalR + pHeight + (hasBottomRail ? totalR : 0.0);

  if (isVertical) {
    return Size(w, h);
  } else {
    return Size(h, w);
  }
}

/// Comprehensive DEV/QA page for visual inspection of Phase 3 scene rendering.
class Phase3VisualQaPage extends StatefulWidget {
  const Phase3VisualQaPage({super.key});

  @override
  State<Phase3VisualQaPage> createState() => _Phase3VisualQaPageState();
}

class _Phase3VisualQaPageState extends State<Phase3VisualQaPage>
    with SingleTickerProviderStateMixin {
  bool _isVertical = true;
  int _diagramSystemIndex = 1; // 1: Diamond system
  double _animationProgress = 1.0;
  bool _isPlayingAnimation = false;
  Timer? _animTimer;
  late TabController _tabController;

  final Map<String, bool> _checklistState = {
    'Full table đúng tỷ lệ': false,
    'Crop modes không bị stretch': false,
    'Vertical đúng': false,
    'Horizontal đúng': false,
    'White/yellow/red đúng': false,
    'Ghost đúng': false,
    'Numbered ball đúng': false,
    'Solid path đúng': false,
    'Dashed path đúng': false,
    'Label đúng': false,
    'Rotation đúng': false,
    'Cushion numbers đúng': false,
    'DiagramSystem overlay đúng': false,
    'Animation không regression': false,
    'Fullscreen không lỗi': false,
  };

  int get _verifiedCount => _checklistState.values.where((v) => v).length;
  int get _totalCount => _checklistState.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlayingAnimation = !_isPlayingAnimation;
    });

    if (_isPlayingAnimation) {
      if (_animationProgress >= 1.0) {
        _animationProgress = 0.0;
      }
      _animTimer?.cancel();
      _animTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {
          _animationProgress += 0.015;
          if (_animationProgress >= 1.0) {
            _animationProgress = 1.0;
            _isPlayingAnimation = false;
            timer.cancel();
          }
        });
      });
    } else {
      _animTimer?.cancel();
    }
  }

  /// Constructs the canonical QA test scene with all representative elements.
  SceneRenderModel _buildSampleRenderModel({
    SceneViewMode viewMode = SceneViewMode.full,
    double animationProgress = 1.0,
    bool isVertical = true,
  }) {
    final balls = [
      // White Cue Ball at (0.25, 0.75)
      const BallRenderItem(
        position: TablePoint(0.25, 0.75),
        color: Colors.white,
        isGhost: false,
        ballTypeIndex: 0,
      ),
      // Yellow Ball at (0.5, 0.5)
      const BallRenderItem(
        position: TablePoint(0.5, 0.5),
        color: Colors.yellow,
        isGhost: false,
        ballTypeIndex: 0,
      ),
      // Red Ball at (0.75, 0.25)
      const BallRenderItem(
        position: TablePoint(0.75, 0.25),
        color: Colors.red,
        isGhost: false,
        ballTypeIndex: 0,
      ),
      // Ghost Ball at (0.5, 0.35)
      const BallRenderItem(
        position: TablePoint(0.5, 0.35),
        color: Colors.white,
        opacity: 0.5,
        isGhost: true,
        ballTypeIndex: 0,
      ),
      // Extra Numbered Ball '7' at (0.25, 0.25)
      const BallRenderItem(
        position: TablePoint(0.25, 0.25),
        color: Colors.amber,
        ballTypeIndex: 2,
        text: '7',
      ),
      // Rotated Ball at (0.75, 0.75)
      BallRenderItem(
        position: const TablePoint(0.75, 0.75),
        color: Colors.cyan,
        rotationInRadians: degreesToRadians(45.0),
        ballTypeIndex: 0,
      ),
    ];

    final trajectories = [
      // Main solid trajectory from white cue ball to yellow ball to red ball
      const TrajectoryRenderItem(
        points: [
          TablePoint(0.25, 0.75),
          TablePoint(0.5, 0.5),
          TablePoint(0.75, 0.25),
        ],
        color: Colors.white,
        isDashed: false,
        role: 'main_path',
      ),
      // Secondary dashed trajectory from yellow ball to ghost ball
      const TrajectoryRenderItem(
        points: [TablePoint(0.5, 0.5), TablePoint(0.5, 0.35)],
        color: Colors.yellowAccent,
        isDashed: true,
        role: 'sub_path',
      ),
    ];

    final annotations = [
      const AnnotationRenderItem(
        position: TablePoint(0.3, 0.8),
        text: 'Cue Ball',
        color: Colors.cyanAccent,
        fontSize: 12.0,
      ),
      AnnotationRenderItem(
        position: const TablePoint(0.6, 0.4),
        text: 'Rotated Label',
        color: Colors.lightGreenAccent,
        fontSize: 11.0,
        rotationInRadians: degreesToRadians(30.0),
      ),
    ];

    final angles = [
      const AngleRenderItem(
        a: TablePoint(0.25, 0.75),
        b: TablePoint(0.5, 0.5),
        c: TablePoint(0.75, 0.25),
        label: '45°',
        color: Colors.yellowAccent,
      ),
    ];

    const effet = EffetRenderData(
      spots: [
        {'x': 0.3, 'y': 0.4},
      ],
      showHitBall: true,
      hitThickness: 6,
      hitSide: 'right',
      spotSize: 25.0,
    );

    return SceneRenderModel(
      balls: balls,
      trajectories: trajectories,
      annotations: annotations,
      angles: angles,
      viewMode: viewMode,
      diagramSystemIndex: _diagramSystemIndex,
      isVertical: isVertical,
      hasBottomRail:
          (viewMode == SceneViewMode.full ||
          viewMode == SceneViewMode.halfWidth),
      animationProgress: animationProgress,
      theme: const SceneRenderTheme(
        indicatorColors: {
          'main_path': Colors.white,
          'sub_path': Colors.yellowAccent,
        },
      ),
      effetData: effet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PHASE 3 VISUAL QA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'HUMAN VERIFICATION: PENDING',
              style: TextStyle(fontSize: 10, color: Colors.amberAccent),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF004D40),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: '8 View Modes'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Playback Anim'),
            Tab(icon: Icon(Icons.tune), text: 'Effet Overlay'),
            Tab(icon: Icon(Icons.checklist), text: 'QA Checklist'),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text('Vertical', style: TextStyle(fontSize: 12)),
              Switch(
                value: _isVertical,
                onChanged: (val) {
                  setState(() {
                    _isVertical = val;
                  });
                },
                activeColor: Colors.amberAccent,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Fullscreen View',
                onPressed: () {
                  final model = _buildSampleRenderModel(
                    viewMode: SceneViewMode.full,
                    isVertical: _isVertical,
                    animationProgress: _animationProgress,
                  );
                  final size = phase3QaCanvasSize(
                    SceneViewMode.full,
                    isVertical: _isVertical,
                    targetWidth: 320.0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullscreenBilliardViewer(
                        child: AspectRatio(
                          aspectRatio: size.width / size.height,
                          child: SceneRenderer(model: model),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Global status bar
          Container(
            color: const Color(0xFF00332C),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      _isVertical
                          ? 'Orientation: Vertical'
                          : 'Orientation: Horizontal',
                    ),
                    backgroundColor: Colors.teal.shade800,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verified: $_verifiedCount / $_totalCount',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text(
                      'Standard Grid',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _diagramSystemIndex == 0,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _diagramSystemIndex = 0);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text(
                      'Diamond System',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _diagramSystemIndex == 1,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _diagramSystemIndex = 1);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 8 View Modes
                _build8ViewModesGrid(),
                // Tab 2: Legacy Playback Animation Demo
                _buildPlaybackAnimationTab(),
                // Tab 3: Mini Effet Overlay Demo
                _buildEffetDemoTab(),
                // Tab 4: On-Screen QA Checklist
                _buildChecklistTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Renders grid of all 8 View Modes using canonical diamond sizing.
  Widget _build8ViewModesGrid() {
    final modes = SceneViewMode.values;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final mode = modes[index];
        final model = _buildSampleRenderModel(
          viewMode: mode,
          isVertical: _isVertical,
        );
        final size = phase3QaCanvasSize(
          mode,
          isVertical: _isVertical,
          targetWidth: _isVertical ? 260.0 : 340.0,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E282A),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View Mode ${index + 1}: ${mode.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullscreenBilliardViewer(
                              child: AspectRatio(
                                aspectRatio: size.width / size.height,
                                child: SceneRenderer(model: model),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: SceneRenderer(model: model),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tab 2: Interactive Animation Playback Demo using canonical diamond sizing.
  Widget _buildPlaybackAnimationTab() {
    final animatedModel = _buildSampleRenderModel(
      viewMode: SceneViewMode.full,
      isVertical: _isVertical,
      animationProgress: _animationProgress,
    );
    final size = phase3QaCanvasSize(
      SceneViewMode.full,
      isVertical: _isVertical,
      targetWidth: _isVertical ? 260.0 : 360.0,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.amber.shade900,
          padding: const EdgeInsets.all(10),
          child: const Text(
            'LEGACY VISUAL PLAYBACK — NOT PHYSICS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amberAccent, width: 2),
              ),
              child: SceneRenderer(model: animatedModel),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(16),
          color: const Color(0xFF1E282A),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlayingAnimation ? Icons.pause : Icons.play_arrow,
                        color: Colors.amberAccent,
                      ),
                      iconSize: 32,
                      onPressed: _togglePlayback,
                    ),
                    Expanded(
                      child: Slider(
                        value: _animationProgress,
                        onChanged: (val) {
                          setState(() {
                            _animationProgress = val;
                            _isPlayingAnimation = false;
                            _animTimer?.cancel();
                          });
                        },
                      ),
                    ),
                    Text(
                      '${(_animationProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const Text(
                  'Demonstrates visual progressive path rendering, cue ball movement along trajectory, and initial position ghost shadow.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 3: Mini Effet Overlay Demo using canonical diamond sizing.
  Widget _buildEffetDemoTab() {
    final model = _buildSampleRenderModel(
      viewMode: SceneViewMode.full,
      isVertical: _isVertical,
    );
    final size = phase3QaCanvasSize(
      SceneViewMode.full,
      isVertical: _isVertical,
      targetWidth: _isVertical ? 260.0 : 360.0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Cue Ball Effet Mini-Diagram Overlay',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Displays cue ball spin hit spots and collision indicator overlay on top right corner.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
            ),
            child: SceneRenderer(model: model),
          ),
        ],
      ),
    );
  }

  /// Tab 4: On-Screen QA Checklist (all unchecked by default).
  Widget _buildChecklistTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Phase 3 Visual Verification Checklist',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                fontSize: 17,
              ),
            ),
            Chip(
              label: Text('Verified: $_verifiedCount / $_totalCount'),
              backgroundColor: _verifiedCount == _totalCount
                  ? Colors.teal.shade700
                  : Colors.amber.shade900,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Interactive manual inspection items. Unchecked items represent PENDING verification state.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Divider(color: Colors.white24, height: 24),
        ..._checklistState.keys.map((item) {
          final isChecked = _checklistState[item] ?? false;
          return CheckboxListTile(
            title: Text(
              item,
              style: TextStyle(
                color: isChecked ? Colors.tealAccent : Colors.white,
                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              isChecked ? 'VERIFIED' : 'PENDING',
              style: TextStyle(
                color: isChecked ? Colors.tealAccent : Colors.amber,
                fontSize: 11,
              ),
            ),
            value: isChecked,
            activeColor: Colors.tealAccent,
            checkColor: Colors.black,
            onChanged: (val) {
              setState(() {
                _checklistState[item] = val ?? false;
              });
            },
          );
        }).toList(),
      ],
    );
  }
}
