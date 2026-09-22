import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';

/// Legacy visual view type enum for table clipping / zoom modes.
enum SceneViewMode {
  full,
  half,
  third,
  quarter,
  halfWidth,
  halfWidthHalfLength,
  halfWidthThirdLength,
  halfWidthQuarterLength,
}

/// Rendering viewport transform managing Canvas bounds, playfield dimensions,
/// and bidirectional mapping between normalized [TablePoint] (u, v in [0,1]^2)
/// and Canvas screen [Offset] pixels.
class SceneViewport {
  final Size canvasSize;
  final SceneViewMode viewMode;
  final bool isVertical;
  final bool hasBottomRail;

  final double woodRailWidth;
  final double cushionWidth;
  final double totalRail;
  final double playAreaWidth;
  final double playAreaHeight;
  final double diamondSpacing;
  final Rect playfieldRect;
  final int hSegments;

  /// Full table pixel width (4 diamonds span).
  final double fullTablePixelWidth;

  /// Full table pixel height (8 diamonds span).
  final double fullTablePixelHeight;

  factory SceneViewport({
    required Size canvasSize,
    SceneViewMode viewMode = SceneViewMode.full,
    bool isVertical = true,
    bool hasBottomRail = true,
  }) {
    final double w = isVertical ? canvasSize.width : canvasSize.height;
    final double h = isVertical ? canvasSize.height : canvasSize.width;

    final bool hasRightRail =
        viewMode != SceneViewMode.halfWidth &&
        viewMode != SceneViewMode.halfWidthHalfLength &&
        viewMode != SceneViewMode.halfWidthThirdLength &&
        viewMode != SceneViewMode.halfWidthQuarterLength;

    final double railScaleDenom = hasRightRail ? 124.0 : 62.0;
    final double woodRail = w * (8.0 / railScaleDenom);
    final double cushion = w * (4.0 / railScaleDenom);
    final double totalR = woodRail + cushion;

    final double pWidth = w - totalR - (hasRightRail ? totalR : 0.0);
    final double pHeight = h - totalR - (hasBottomRail ? totalR : 0.0);

    final int segments =
        (viewMode == SceneViewMode.halfWidth ||
            viewMode == SceneViewMode.halfWidthHalfLength ||
            viewMode == SceneViewMode.halfWidthThirdLength ||
            viewMode == SceneViewMode.halfWidthQuarterLength)
        ? 2
        : 4;

    final double spacing = pWidth / segments;
    final Rect pfRect = Rect.fromLTWH(totalR, totalR, pWidth, pHeight);

    final double fullW = 4.0 * spacing;
    final double fullH = 8.0 * spacing;

    return SceneViewport._internal(
      canvasSize: canvasSize,
      viewMode: viewMode,
      isVertical: isVertical,
      hasBottomRail: hasBottomRail,
      woodRailWidth: woodRail,
      cushionWidth: cushion,
      totalRail: totalR,
      playAreaWidth: pWidth,
      playAreaHeight: pHeight,
      diamondSpacing: spacing,
      playfieldRect: pfRect,
      hSegments: segments,
      fullTablePixelWidth: fullW,
      fullTablePixelHeight: fullH,
    );
  }

  const SceneViewport._internal({
    required this.canvasSize,
    required this.viewMode,
    required this.isVertical,
    required this.hasBottomRail,
    required this.woodRailWidth,
    required this.cushionWidth,
    required this.totalRail,
    required this.playAreaWidth,
    required this.playAreaHeight,
    required this.diamondSpacing,
    required this.playfieldRect,
    required this.hSegments,
    required this.fullTablePixelWidth,
    required this.fullTablePixelHeight,
  });

  /// Maps a normalized [TablePoint] (u, v in [0,1]^2) to Canvas pixel [Offset].
  ///
  /// `x_px = playfieldRect.left + u * fullTablePixelWidth`
  /// `y_px = playfieldRect.top  + v * fullTablePixelHeight`
  Offset tablePointToOffset(TablePoint point) {
    final double dx = playfieldRect.left + point.u * fullTablePixelWidth;
    final double dy = playfieldRect.top + point.v * fullTablePixelHeight;
    return Offset(dx, dy);
  }

  /// Maps Canvas pixel [Offset] back to normalized [TablePoint] (u, v in [0,1]^2).
  ///
  /// `u = (offset.dx - playfieldRect.left) / fullTablePixelWidth`
  /// `v = (offset.dy - playfieldRect.top)  / fullTablePixelHeight`
  TablePoint offsetToTablePoint(Offset offset) {
    if (fullTablePixelWidth == 0 || fullTablePixelHeight == 0) {
      return const TablePoint(0.0, 0.0);
    }
    final double u = (offset.dx - playfieldRect.left) / fullTablePixelWidth;
    final double v = (offset.dy - playfieldRect.top) / fullTablePixelHeight;
    return TablePoint(u, v);
  }
}
