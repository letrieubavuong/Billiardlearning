# PHASE 3 VERIFICATION REPORT

## Summary

Phase 3 — Scene Renderer Refactor đã hoàn tất tách rendering khỏi god-file legacy `lib/widgets/billiard_diagram.dart` (~2269 dòng) thành gói rendering mô-đun hóa độc lập tại `lib/rendering/scene/`. Các responsibilities chính (mặt bàn, bi, đường chạy, chú thích/góc quay, viewport transform, và adapter tương thích) đã được phân tách rõ ràng.

Tất cả các góp ý của External Reviewer đã được sửa triệt để và kiểm chứng tự động.

## External review corrections

1. **Legacy Coordinate Conversion**:
   Đã thêm helper `LegacyRenderAdapter.legacyRelativeToTablePoint(Offset p)` chuyển đổi chính xác từ tọa độ tương đối legacy `Offset(xDiamond/4, yDiamond/4)` sang canonical `TablePoint(u = dx, v = dy / 2.0)` cho `Ball`, `BallPath`, `BilliardLabel`, và `BilliardAngle`.
2. **Crop Viewport Non-Stretching Semantics**:
   Đã sửa `SceneViewport` để tính `fullTablePixelWidth` ($4 \times \text{diamondSpacing}$) và `fullTablePixelHeight` ($8 \times \text{diamondSpacing}$). Các chế độ view cắt bàn (`half`, `third`, `quarter`, `halfWidth`,...) sử dụng cùng tỉ lệ diamond và không bị co kéo/bóp méo hình ảnh bàn.
3. **View Boundaries & Inverse Viewport**:
   Đã cập nhật phạm vi hiển thị cho cả 8 chế độ view và đảm bảo phép chuyển đổi ngược `offsetToTablePoint(tablePointToOffset(pt))` chính xác trên 100% các chế độ view mode.
4. **Legacy Playback Metric & Centralized Match Threshold**:
   * Đã tạo `LegacyPlaybackCompatibility.distance()` tính khoảng cách theo công thức chuẩn 1:2 aspect ratio:
     $$\text{dist} = \sqrt{\Delta u^2 + (2 \times \Delta v)^2}$$
     Đã kiểm tra khoảng cách 2 nút ngang (`TablePoint(0,0)` $\rightarrow$ `TablePoint(0.5,0)`) và 2 nút dọc (`TablePoint(0,0)` $\rightarrow$ `TablePoint(0,0.25)`) có độ dài đại số legacy bằng nhau (= 0.5).
   * Đã khôi phục và tập trung hóa ngưỡng ghép nối đường chạy / bi `pathMatchTolerance = 0.05` trong `LegacyPlaybackCompatibility`. Dùng helper `isWithinPathMatchTolerance()` đồng nhất ở cả `computeTimings()` và `ScenePainter`.
   * Đã bổ sung regression test kiểm tra ranh giới 0.04 (thỏa mãn) và 0.075 (không thỏa mãn).
5. **Ghost & Legacy Type Semantics Fix**:
   * Sửa cờ `isGhost`: CHỈ dựa vào `ballType == 'ghost'` (không tự động gán `legacyType == 1` làm ghost). `legacyType` là chỉ số kiểu hiển thị bi (0 = full, 1 = half, 2 = numbered).
   * Thêm test bổ sung với `ballType = 'extra'` và `legacyType = 1` $\rightarrow$ `isGhost = false`, `ballTypeIndex = 1` (bi sọc không-ghost).
6. **hasBottomRail Hardening**:
   Tự động suy ra `hasBottomRail = true` từ `viewMode` đã giải thích (`full` hoặc `halfWidth`), ngăn ngừa lệch dữ liệu khi `legacyViewTypeIndex` vượt khoảng bị clamp.
7. **Physics Wording Cleanup**:
   Đã làm sạch các đoạn ghi chú trong `LegacyPlaybackCompatibility` thành "Apply the legacy quadratic ease-out used for visual deceleration. This is compatibility playback, not physics."
8. **Analyzer Scope Restoration**:
   Đã gỡ bỏ hoàn toàn khối `analyzer.exclude` trong `analysis_options.yaml`, đưa cấu hình analyzer về baseline chuẩn pre-Phase-3.
9. **Visual Verification Status Realism**:
   Đã tách biệt kết quả tự động `AUTOMATED VERIFICATION = PASS` và kết quả kiểm tra mắt người `HUMAN VISUAL VERIFICATION = PENDING`.

## Renderer architecture after

Cấu trúc mô-đun mới trong `lib/rendering/scene/`:
* `scene_viewport.dart`: Quản lý kích thước canvas, vùng chơi, và chuyển đổi tọa độ hai chiều giữa [TablePoint] và Canvas pixel [Offset].
* `scene_render_model.dart`: Định nghĩa DTO bất biến và theme `SceneRenderTheme`.
* `table_renderer.dart`: Render nỉ bàn, băng cao su, đường lưới, vạch phụ, nút số diamond, và overlay hệ thống.
* `ball_renderer.dart`: Render bi thường, bi ghost, bi outline, bi đánh số, chấm điểm carom, và đổ bóng 3D.
* `trajectory_renderer.dart`: Render đường đứt/liền nét, tính toán hoạt họa tiệm tiến.
* `annotation_renderer.dart`: Render nhãn chữ, cung góc, và sơ đồ mini áp-phê.
* `scene_painter.dart`: Facade `CustomPainter` phối hợp các sub-renderers.
* `scene_renderer.dart`: Facade `StatelessWidget` bọc `CustomPaint` và `ScenePainter`.
* `legacy/legacy_render_adapter.dart`: Chuyển đổi từ `BilliardScene` hoặc legacy diagram objects.
* `legacy/legacy_playback_compatibility.dart`: Chứa metric khoảng cách 1:2 aspect ratio, ngưỡng matching 0.05, và tính toán thời gian cho playback legacy.

## Files changed

* `analysis_options.yaml` [REVERT EXCLUSIONS]
* `lib/rendering/scene/scene_viewport.dart` [MODIFY]
* `lib/rendering/scene/scene_render_model.dart` [MODIFY]
* `lib/rendering/scene/table_renderer.dart` [NEW]
* `lib/rendering/scene/ball_renderer.dart` [NEW]
* `lib/rendering/scene/trajectory_renderer.dart` [MODIFY]
* `lib/rendering/scene/annotation_renderer.dart` [NEW]
* `lib/rendering/scene/scene_painter.dart` [MODIFY]
* `lib/rendering/scene/scene_renderer.dart` [NEW]
* `lib/rendering/scene/legacy/legacy_render_adapter.dart` [MODIFY]
* `lib/rendering/scene/legacy/legacy_playback_compatibility.dart` [MODIFY]
* `lib/widgets/billiard_diagram.dart` [MODIFY]
* `test/scene_viewport_test.dart` [MODIFY]
* `test/scene_render_model_test.dart` [MODIFY]
* `test/scene_renderer_smoke_test.dart` [MODIFY]
* `test/architecture_test.dart` [MODIFY]
* `docs/PHASE_STATUS.md` [MODIFY]
* `docs/reports/PHASE_3_MANUAL_VISUAL_CHECKLIST.md` [MODIFY]
* `docs/reports/PHASE_3_VERIFICATION_REPORT.md` [MODIFY]

## Database access audit

Đã kiểm tra độc lập và bổ sung test kiểm chứng trong `test/architecture_test.dart`:
`lib/rendering/**` TUYỆT ĐỐI KHÔNG chứa import `sqflite`, `sqflite_common_ffi`, database connection, hay repositories.

## Domain boundary audit

`lib/domain/**` giữ nguyên 100% Pure Dart (không import `package:flutter/*`, `dart:ui`, `Color`, `Offset`, `Canvas`, `Widget`).

## Tests

Tất cả unit test & smoke test pass 100%:
* `test/scene_viewport_test.dart` (Full table non-stretching & 8 view modes round-trip)
* `test/scene_render_model_test.dart` (Legacy coordinate conversion, 1:2 playback metric & 0.05 tolerance boundary test)
* `test/scene_renderer_smoke_test.dart` (Domain ghost & extra half-ball conversion + widget smoke tests)
* `test/architecture_test.dart` (Domain pure Dart guard & rendering DB isolation guard)
* Full suite regression: PASS.

## Analyzer

`flutter analyze` (Exit code: 1, 0 errors, 13 warnings, 298 infos/deprecations in pre-existing legacy files). No exclusions block in `analysis_options.yaml`.

## Visual manual checklist

Tạo `docs/reports/PHASE_3_MANUAL_VISUAL_CHECKLIST.md` ghi nhận `HUMAN_REQUIRED` cho kiểm tra mắt người.

## Final Visual QA

Visual QA screen:
`lib/screens/phase3_visual_qa_page.dart`

Automated verification:
PASS

Human visual verification:
PENDING

Full test suite:
TOTAL = 104
PASSED = 104
FAILED = 0

## Visual QA Harness External Review Fix

* Checklist default values are all `false` (unchecked = PENDING verification).
* Implemented `phase3QaCanvasSize` helper for exact canonical diamond-based canvas sizing across all 8 view modes.
* All 8 view modes verified for bottom-right mapping `TablePoint` -> `playfieldRect.bottomRight`.
* Horizontal & Vertical aspect ratio sizing fixed; fullscreen viewer updated to use calculated `size.width / size.height`.
* Added debug-only drawer entry (`if (kDebugMode)`) in `MyHomePage` to launch `Phase3VisualQaPage`.
* Human visual verification status remains `PENDING`.

## Final Visual QA Responsive Layout Fix

* **Analyzer Regression Reverted**: Completely removed `analyzer.exclude` from `analysis_options.yaml`. Added automated architecture test in `test/architecture_test.dart` to enforce zero platform exclusions (`android/**`, `ios/**`, `windows/**`, `build/**`).
* **Responsive Preview Aspect Ratio**: Implemented `Phase3QaPreview` helper using `LayoutBuilder` to compute uniform scaling (`scale = min(1.0, min(maxWidth / logicalSize.width, maxHeight / logicalSize.height))`), ensuring `actualWidth / actualHeight == logicalWidth / logicalHeight` without non-uniform distortion.
* **Phone Viewport Verification**: Verified preview rendering on phone constraints (`390 x 844`), ensuring wide horizontal modes fit container width without clipping or squeezing.
* **Cushion Number Sample & Metadata**: Added representative `cushionNumber` annotation (`role: 'cushionNumber'`, `text: '20'`) to the sample QA scene. Documented that `cushionSide` serves as editor/migration metadata while rendering uses canonical `TablePoint` positioning.
* **Updated Widget Tests**: Added explicit widget aspect ratio assertion tests verifying all 8 view modes match logical aspect ratio within `1e-3` tolerance, and checklist toggle updates count from 0 to 1 while preserving `PENDING` state.
* **Full Test Suite & Analyzer Status**:
  * Total tests: 105 / 105 PASS (0 failed)
  * Analyzer: Exit code 1 (0 errors, 13 warnings, 300 infos/deprecations in pre-existing files). Zero exclusions.

## Known limitations

* Chưa có golden test infrastructure tĩnh tự động so sánh pixel-by-pixel.

## Deferred to Phase 4

* `SceneEditorController`, undo/redo architecture, tool handlers, tương tác kéo thả bi trong editor.

## Deferred to Phase 5

* `TeachingTimeline` engine, physics simulation, collision dynamics.

## Acceptance checklist

- [x] Phase 2 đã DONE
- [x] rendering package/module tồn tại tại `lib/rendering/scene/`
- [x] Table renderer được tách
- [x] Ball renderer được tách
- [x] Trajectory renderer được tách
- [x] Annotation renderer được tách
- [x] Scene renderer facade tồn tại
- [x] Legacy coordinate conversion `Ball.at(2,6) -> TablePoint(0.5, 0.75)` PASS
- [x] `TablePoint` $\leftrightarrow$ `Canvas` transform non-stretching tests PASS
- [x] Inverse viewport `offsetToTablePoint` round-trip PASS (8 view modes)
- [x] Legacy 1:2 playback metric equality test PASS
- [x] Legacy match tolerance 0.05 restored and centralized PASS
- [x] Domain ghost ball conversion PASS
- [x] Domain extra non-ghost half ball conversion PASS
- [x] Domain degrees $\rightarrow$ renderer radians test PASS
- [x] Domain color string $\rightarrow$ Flutter Color test PASS
- [x] Renderer không access DB
- [x] Painter không có repository/business rules mới
- [x] Domain vẫn Pure Dart
- [x] Existing `BilliardDiagram` API không bị phá diện rộng
- [x] Phase 4 editor architecture chưa được implement
- [x] Phase 5 TeachingSimulation chưa được implement
- [x] Full regression tests pass
- [x] [`PHASE_3_MANUAL_VISUAL_CHECKLIST.md`](./PHASE_3_MANUAL_VISUAL_CHECKLIST.md) hoàn thành
- [x] [`PHASE_3_VERIFICATION_REPORT.md`](./PHASE_3_VERIFICATION_REPORT.md) hoàn thành

## Recommended phase status

`Phase 3 = REVIEW`

RENDERER CORE = PASS  
ARCHITECTURE = PASS  
AUTOMATED VERIFICATION = PASS  
VISUAL QA HARNESS = READY  
HUMAN VISUAL VERIFICATION = PENDING  

## Git synchronization status

Synchronized with origin/main after commit and push.

