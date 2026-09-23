# PHASE 4A VERIFICATION REPORT — Scene Editor Core

## Summary

Phase 4A đã hoàn tất việc xây dựng **Editor Core** tại `lib/application/scene_editor/`. Đây là lớp nghiệp vụ pure Dart chịu trách nhiệm quản lý trạng thái soạn thảo thế bi (`BilliardScene`), thao tác với các thực thể bi, đường chạy, chú thích/bộ số, cấu hình hiển thị, quản lý lịch sử undo/redo, và theo dõi trạng thái `isDirty` hoàn toàn độc lập với Flutter UI và SQLite database persistence.

Toàn bộ các yêu cầu kiến trúc, sửa lỗi phản hồi từ External Review, và kiểm thử tự động của Phase 4A đã hoàn thành 100% và không làm ảnh hưởng tới lớp rendering Phase 3 hay legacy editor.

---

## Scope & Implementation

* **Scope**: Phase 4A tập trung xây dựng Editor Core thuần Dart. Chưa chuyển đổi giao diện UI hay liên kết kéo thả canvas (đã hoãn tới Phase 4B/4C/4D).
* **Architecture**: Nằm tại `lib/application/scene_editor/` tuân thủ nguyên tắc Pure Dart Boundary:
  * Không import `package:flutter/*`, `dart:ui`, `package:sqflite/`.
  * Không sử dụng các kiểu Flutter UI (`Color`, `Offset`, `Canvas`, `Widget`, `BuildContext`).
  * Sử dụng các kiểu dữ liệu canonical domain (`BilliardScene`, `TablePoint`, `BallPosition`, `TrajectoryLine`, `SceneAnnotation`, `ScenePresentationConfig`, `StableId`).

---

## Files Added / Modified

* `lib/application/scene_editor/scene_editor_exception.dart` [NEW - Pure Dart Exception Hierarchy]
* `lib/application/scene_editor/scene_editor_tool.dart` [NEW]
* `lib/application/scene_editor/scene_editor_selection.dart` [NEW]
* `lib/application/scene_editor/scene_editor_state.dart` [NEW]
* `lib/application/scene_editor/scene_editor_history.dart` [MODIFY - Validate maxHistory <= 0]
* `lib/application/scene_editor/scene_editor_controller.dart` [MODIFY - Factory single baseline, immutable snapshots, semantic equality, sanitizeSelection, target exceptions, deep teachingTimeline freeze, point selection drift fix]
* `test/scene_editor_state_test.dart` [NEW]
* `test/scene_editor_history_test.dart` [MODIFY]
* `test/scene_editor_controller_test.dart` [MODIFY - Added regression tests for timeline freeze and point selection drift]
* `test/architecture_test.dart` [MODIFY - Guard test cho application/scene_editor]
* `docs/reports/PHASE_4A_VERIFICATION_REPORT.md` [MODIFY]

---

## Final External Review Hardening

Nhận phản hồi từ đợt review code ngoại viện thứ hai, lớp Editor Core đã được xử lý dứt điểm 2 blockers còn lại:

1. **Deep Freeze `teachingTimeline`**:
   - Xây dựng hàm helper đệ quy thuần Dart `_freezeJson()` đóng gói tất cả các đối tượng kiểu Map và List bên trong `teachingTimeline` thành `Map.unmodifiable` và `List.unmodifiable`.
   - Ngăn chặn mọi hành vi biến đổi dữ liệu timeline từ bên ngoài sau khi nạp vào editor (bảo vệ cả Input Alias lẫn Output Immutability).
2. **Deep Semantic Comparison for `teachingTimeline`**:
   - Thêm hàm so sánh đệ quy ngữ nghĩa `_areJsonValuesIdentical()` trong `_areScenesIdentical()`. Hai instance Map/List timeline chứa cùng cấu trúc giá trị sẽ so sánh bằng nhau, tránh việc dirty state bị kích hoạt nhầm.
3. **TrajectoryPoint Selection Drift Adjustment**:
   - Khi xóa một point trên đường chạy (`removeTrajectoryPoint`), nếu point đang chọn (`trajectoryPoint`) nằm ở chỉ số sau điểm bị xóa (`selectedIndex > removedIndex`), chỉ số selection tự động lùi về (`selectedIndex - 1`), đảm bảo selection giữ đúng điểm ngữ nghĩa. Nếu xóa đúng điểm đang chọn, selection chuyển thành `none()`.
4. **Undo / Redo Point-Selection Policy**:
   - Khi thực hiện `undo` hoặc `redo`, nếu vùng chọn hiện tại thuộc kiểu `trajectoryPoint`, selection tự động reset về `SceneEditorSelection.none()` để tránh trường hợp chỉ số point cũ trỏ nhầm điểm ngữ nghĩa sau khi khôi phục snapshot lịch sử. Vùng chọn Bi, Trajectory, và Annotation vẫn được giữ nguyên nếu ID còn tồn tại.

---

## Core Policies & Semantics

### 1. Editor State Model (`SceneEditorState`)
* Định nghĩa đối tượng bất biến (`immutable`):
  * `scene`: `BilliardScene` (canonical domain entity).
  * `activeTool`: `SceneEditorTool` (`select`, `move`, `ball`, `trajectory`, `label`, `cushionNumber`, `ghostBall`, `extraBall`, `delete`).
  * `selection`: `SceneEditorSelection` (xác định qua Stable ID).
  * `isDirty`: `bool` (theo dõi sai lệch so với mốc lưu gần nhất).
  * `canUndo`: `bool` / `canRedo`: `bool`.
  * `errorMessage`: `String?`.

### 2. Undo / Redo Policy (`SceneEditorHistory`)
* Sử dụng stack lưu trữ các snapshot `BilliardScene`.
* Giới hạn lịch sử lưu tối đa (`maxHistory = 100`).
* Khi thực hiện chỉnh sửa nội dung mới sau khi undo, lịch sử redo cũ tự động bị xóa (`redoStack.clear()`).
* Các thao tác no-op (di chuyển đến cùng vị trí, thay đổi giá trị không đổi) hoặc thay đổi lựa chọn chọn/công cụ (`selection`, `activeTool`) **không** đẩy snapshot vào lịch sử undo.

### 3. Dirty State Policy
* Trạng thái `isDirty = false` khi khởi tạo hoặc nạp Scene mốc (`loadScene` / `markSaved`).
* Chuyển thành `isDirty = true` sau bất kỳ chỉnh sửa nội dung Scene nào.
* Khi `undo` trở lại đúng trạng thái baseline đã lưu, `isDirty` tự động khôi phục về `false`.

### 4. Stable-ID Policy & Boundary Rules
* Tất cả các đối tượng bi, đường chạy, chú thích được tạo mới đều được gán UUID v4 ngẫu nhiên qua `StableId.generate()`.
* Tọa độ bi và điểm đường chạy luôn được chuẩn hóa và kẹp boundary (`_clampTablePoint`) trong khoảng `TablePoint(u ∈ [0,1], v ∈ [0,1])`.
* Đơn vị góc quay chú thích lưu trong domain/editor là **độ (DEGREES)**.
* Màu sắc được lưu dạng chuỗi Hex (`#AARRGGBB` / `#RRGGBB`).
* Bi ghost được xác định duy nhất qua `ballType == 'ghost'`. Bi sọc đánh số có `legacyType == 1` nhưng `ballType == 'extra'` giữ nguyên ngữ nghĩa không-ghost.

---

## Final Analyzer & Test Suite Result

### Static Analysis
```text
Command: flutter analyze
Exit code: 1 (do warnings/infos legacy)
Errors: 0
Warnings: 16
Infos/deprecations: 304

analysis_options.yaml:
Zero platform exclusions. Standard flutter_lints configuration preserved.
```

### Test Suite Summary
```text
Command: flutter test
Total tests: 141
Passed: 141
Failed: 0
```
*(Bao gồm tất cả unit tests mới cho deep timeline freeze, output immutability, semantic timeline comparison, trajectory point removal index shift, và undo/redo selection clearing).*

---

## Explicit Defers

### Deferred to Phase 4B
* Chuyển đổi tọa độ gesture/canvas pixel sang `TablePoint`.
* Kéo thả bi, tạo đường chạy bằng cử chỉ trên UI.
* Thanh công cụ toolbar UI và overlay chọn vị trí bi.

### Deferred to Phase 4C
* Liên kết `VNextSceneRepository` cho việc load/save tự động.
* Debounce autosave và chuyển đổi `DiagramDocumentCodec` legacy.

### Deferred to Phase 4D
* Chuyển đổi toàn bộ `lib/screens/diagram_builder_page.dart` sang dùng controller mới.
* Dọn dẹp code legacy cũ và kiểm chứng Visual Regression QA cuối cùng cho Phase 4.

---

## Acceptance Checklist

- [x] Lớp `lib/application/scene_editor/` tồn tại và thuần Dart (Pure Dart).
- [x] `BilliardScene` là thực thể duy nhất đại diện cho thế bi (không tạo model song song `EditableScene`).
- [x] Không import `package:flutter/*`, `dart:ui`, `sqflite` hay các kiểu UI (`Color`, `Offset`, `Canvas`, `Widget`, `BuildContext`).
- [x] Khởi tạo `SceneEditorController` tạo default scene duy nhất 1 lần cho cả hai `savedBaseline` và `state.scene`.
- [x] Các collection snapshot (`balls`, `trajectories`, `points`, `annotations`, `teachingTimeline`) là immutable (`List.unmodifiable`, `Map.unmodifiable`).
- [x] Thao tác `updateBall` và `teachingTimeline` kiểm tra ngữ nghĩa no-op chính xác.
- [x] Vùng chọn `selection` được làm sạch (`sanitizeSelection`) và điều chỉnh chỉ số điểm đường chạy chính xác sau undo/redo/delete.
- [x] `SceneEditorException` hierarchy xử lý thống nhất các lỗi target không tồn tại.
- [x] Validation `maxHistory <= 0` hoạt động ở Release mode.
- [x] Undo/redo hoạt động chính xác với giới hạn 100 snapshot.
- [x] Trạng thái `isDirty` tính toán chính xác so với mốc lưu.
- [x] Quản lý đối tượng dựa trên Stable ID (UUID v4).
- [x] Boundary `TablePoint(u, v)` được đảm bảo và kẹp trong `[0,1]`.
- [x] Toàn bộ test suite regression và test Phase 3 pass 100%.
- [x] Phase 4 status đặt thành `IN_PROGRESS`.

---

## Recommended Status

```text
PHASE 4 = IN_PROGRESS
PHASE 4A = READY FOR EXTERNAL REVIEW

EDITOR CORE = PASS
IMMUTABLE SNAPSHOTS = PASS
TEACHING TIMELINE SNAPSHOT SAFETY = PASS
NO-OP SEMANTICS = PASS
UNDO/REDO = PASS
DIRTY STATE = PASS
POINT SELECTION CONSISTENCY = PASS
INVALID COMMAND POLICY = PASS
PHASE 3 REGRESSION = PASS

PHASE 4B = NOT_STARTED
PHASE 5 = NOT_STARTED
```
