# PHASE 2 VERIFICATION REPORT

## Summary
Báo cáo nghiệm thu hoàn tất các chỉnh sửa nâng cao độ tin cậy và khôi phục dữ liệu chính xác cho **Phase 2 — Scene Model + Coordinate System** của dự án **Billiardlearning**. Phối hợp với kết quả kiểm tra external review, `LegacySceneImporter` đã được tái thiết kế hoàn toàn để giải mã đúng 100% cấu trúc payload legacy thực tế từ `DiagramBuilderPage._captureCurrentLayout()`. Toàn bộ các trường dữ liệu như bi bóng (`ghosts`), bi phụ (`extraBalls`), điểm bắt đầu quỹ đạo bi (`trajectory start points`), màu đường chạy (`pathColors`, `freePathColors`), nhãn chú thích (`labels`, `cushionNumbers`), thông số trình diễn (`ScenePresentationConfig`), và trạng thái lực cơ chưa giải mã (`powerIsResolved = false`) đã được bảo toàn đầy đủ trong mô hình miền Pure Dart mà không làm nảy sinh mất mát dữ liệu ẩn hoặc thay đổi SQLite Schema V4.

---

## Files changed
- **`lib/domain/entities/entities.dart`**: Mở rộng các trường typed backward-compatible cho `BallPosition` (`label`, `colorHex`, `rotation`, `legacyType`), `SceneAnnotation` (`colorHex`, `rotation`, `role`, `cushionSide`), `CueInstruction` (`powerIsResolved`), bổ sung lớp pure Dart `ScenePresentationConfig`, và cập nhật `BilliardScene.copyWith`.
- **`lib/domain/importers/legacy_scene_importer.dart`**: Tái thiết kế bộ nạp sơ đồ legacy Pure Dart, loại bỏ toàn bộ việc đoán hoặc bỏ qua Map items, thêm điểm bắt đầu vị trí bi cho trajectories main ball, chuyển đổi màu ARGB int thành `#AARRGGBB` hex string, thẩm định dải giá trị index enum (`system`, `viewType`), và phát cảnh báo chẩn đoán rõ ràng cho dữ liệu hình dạng không hợp lệ.
- **`lib/data/mappers/mappers.dart`**: Cập nhật `SceneMapper` để tuần tự hóa và giải tuần tự hóa backward-compatible toàn bộ các thuộc tính mở rộng mới qua JSON hiện có (`tableConfigJson`, `ballsJson`, `annotationsJson`, `cueInstructionJson`), duy trì tính tương thích 100% với SQLite Schema V4.
- **`test/legacy_scene_importer_test.dart`**: Cập nhật fixture theo đúng format legacy sản xuất thực tế (`extraBalls` Map, `ghosts` Map, `pathColors`, `freePathColors`, `labels` role/color/rotation, `cushionNumbers` cushionSide, `labelFontSize`), bổ sung unit test cho trajectory start point, colors, presentation config, enum range validation, unresolved power và malformed payload diagnostics.
- **`docs/LEGACY_MIGRATION_MAP.md`**: Cập nhật tài liệu phản ánh chính xác payload legacy JSON thực tế và làm rõ sự khác biệt giữa legacy `schemaVersion` (phiên bản codec JSON) và `BilliardScene.version` (phiên bản entity revision).
- **`docs/reports/PHASE_2_VERIFICATION_REPORT.md`**: Cập nhật báo cáo chi tiết theo các tiêu chí nghiệm thu mới.

---

## Real legacy payload verification
Đã đối soát và xác minh trực tiếp với mã nguồn legacy `lib/screens/diagram_builder_page.dart` (`_captureCurrentLayout()`):
1. **`extraBalls` Map**:
   - Structure: `[{"x": 1.5, "y": 3.0, "color": 4280391411, "number": "7"}]`
   - Mapping: `u = x / 4`, `v = y / 8`, `label = number`, `colorHex = #FF2196F3`, `ballType = 'extra'`.
2. **`ghosts` Map**:
   - Structure: `[{"x": 2.0, "y": 4.0, "color": 4294967295, "type": 0, "rotation": 20.0, "number": "1"}]`
   - Mapping: `u = x / 4`, `v = y / 8`, `label = number`, `colorHex = #FFFFFFFF`, `rotation = 20.0`, `legacyType = 0`, `ballType = 'ghost'`.
3. **`labels` Map**:
   - Structure: `[{"x": 2.0, "y": 6.0, "text": "...", "color": 4294967295, "rotation": 15.0, "role": "cueBall"}]`
   - Mapping: `SceneAnnotation` với `colorHex`, `rotation`, `role`.
4. **`cushionNumbers` Map**:
   - Structure: `[{"x": 0.0, "y": 4.0, "text": "50", "color": 4294967295, "rotation": 0.0, "cushionSide": "left"}]`
   - Mapping: `SceneAnnotation` với `role = 'cushionNumber'`, `cushionSide`, `colorHex`, `rotation`.

---

## Main ball trajectory start point semantics
- Trong renderer legacy `ParsedBilliardLayout.parse()`, đường chạy `paths.white`, `paths.yellow`, `paths.red` đại diện cho các waypoint *sau* vị trí xuất phát của bi.
- `LegacySceneImporter` đã được sửa để tự động **thêm vị trí hiện tại của bi (trắng, vàng, đỏ)** vào đầu mảng điểm của `TrajectoryLine` tương ứng khi bi và path tồn tại.
- **Không thực hiện prepend** đối với đường chạy tự do `paths.free`.

---

## Path colors mapping
- Giải mã mảng `pathColors` (`white`, `yellow`, `red`, `free`) và `freePathColors` (`[int, ...]`).
- Chuyển đổi số nguyên legacy ARGB thành chuỗi hex `#AARRGGBB` mà không import Flutter `Color`.
- `freePathColors[i]` được ưu tiên ánh xạ tương ứng với `paths.free[i]`, fallback về `pathColors.free` hoặc màu xanh lam mặc định (`#2196F3`).

---

## Presentation metadata vs TeachingTimeline boundary
- Loại bỏ hoàn toàn việc đưa `legacySystemIndex` và `legacyViewTypeIndex` vào `teachingTimeline`. `teachingTimeline` giữ giá trị `null` cho các sơ đồ tĩnh legacy.
- Tạo lớp Pure Dart `ScenePresentationConfig`:
  - `legacySystemIndex` (`system` field)
  - `legacyViewTypeIndex` (`viewType` field)
  - `labelFontSize` (`labelFontSize` field)
- Đính kèm vào `BilliardScene.presentationConfig` và lưu trữ backward-compatible bên trong `tableConfigJson` khi ghi vào SQLite.

---

## Legacy enum indices validation
- Thẩm định phạm vi giá trị index của `DiagramSystem` (0..5) và `TableViewType` (0..7).
- Nếu `system` vượt ngoài [0..5], importer tạo cảnh báo: `UNKNOWN_LEGACY_SYSTEM_INDEX`.
- Nếu `viewType` vượt ngoài [0..7], importer tạo cảnh báo: `UNKNOWN_LEGACY_VIEW_TYPE_INDEX`.
- Giữ nguyên giá trị thô trong `presentationConfig` để hỗ trợ forensic migration mà không gây crash ứng dụng.

---

## Cue power unresolved contract
- Tuyệt đối KHÔNG tự gán giá trị giả định `power = 0.5`.
- Khi đọc payload `effet` có chứa `forceImage`, importer thiết lập:
  - `power = 0.0`
  - `powerIsResolved = false`
  - Phát cảnh báo `DEFERRED_FIELD_FORCE_IMAGE`.
- Bảo toàn `tipOffset` từ `effet.effet[0]` và `effet.effet[1]`.
- Giữ nguyên các cảnh báo `DEFERRED_FIELD_CUE_ANGLE` và `DEFERRED_FIELD_THICKNESS`.

---

## Payload diagnostics & No silent data loss
- Khi phát hiện hình dạng dữ liệu sai (ví dụ `white` không phải List, `extraBalls` chứa phần tử sai kiểu, map thiếu `x`/`y`, path sai định dạng), importer không crash bằng `cast<num>()` mà trả cảnh báo chẩn đoán typed/consistent:
  - `INVALID_FIELD_TYPE`
  - `INVALID_POINT_SHAPE`
  - `MISSING_REQUIRED_COORDINATE`
  - `INVALID_LEGACY_BALL`
  - `INVALID_LEGACY_PATH`
- Đảm bảo 100% các key dữ liệu legacy quan trọng đều được MAPPED, DEFERRED (có warning) hoặc UNSUPPORTED (có warning), tuyệt đối không bỏ qua im lặng.

---

## Persistence & Database compatibility
- `SceneMapper` hỗ trợ đọc và ghi đầy đủ các trường mới của `BallPosition`, `SceneAnnotation`, `CueInstruction`, `ScenePresentationConfig`.
- Dữ liệu hàng cũ (old JSON) thiếu các field mới vẫn được deserialized chính xác mà không gặp lỗi.
- Giữ nguyên Database Schema V4. Không yêu cầu bump database version hay thêm cột SQLite.

---

## Regression tests & Verification
- Chạy kiểm tra bộ test suite:
  - `dart format .`: Clean (55 files checked/formatted)
  - `flutter analyze`: **0 Errors** (312 legacy deprecation infos)
  - `flutter test`: **57/57 Tests PASS** (100% PASS)
- Các suite test đã verify:
  - `test/value_objects_test.dart`: PASS
  - `test/domain_foundation_test.dart`: PASS
  - `test/vnext_repository_test.dart`: PASS
  - `test/vnext_migration_test.dart`: PASS
  - `test/scene_coordinate_test.dart`: PASS
  - `test/legacy_scene_importer_test.dart`: PASS

---

## Final hardening
- **Unsafe Top-Level Casts Removed**: Loại bỏ hoàn toàn các ép kiểu trực tiếp dạng `as int?` và `as num?` trên JSON legacy không tin cậy. Sử dụng các hàm trợ giúp an toàn Pure Dart `parseOptionalInt` và `parseOptionalDouble` để trích xuất số liệu mà không gây `TypeError` hay `CastError`.
- **Malformed Metadata Diagnostics**: Khi gặp dữ liệu metadata bị sai kiểu (ví dụ `"schemaVersion": "bad"`, `"ghosts": [{"rotation": "bad"}]`, `"effet": "bad"`), importer phát cảnh báo chẩn đoán typed `INVALID_FIELD_TYPE` kèm tên field cụ thể, bỏ qua thuộc tính metadata lỗi và tiếp tục nạp các vị trí và đối tượng hợp lệ.
- **No Silent Wrong-Type Metadata Loss**: Xử lý tường minh các trường hợp key `effet`, `effet.effet`, `pathColors`, `freePathColors` sai type hoặc sai độ dài bằng warning `INVALID_FIELD_TYPE` thay vì silently drop hay silent default.
- **Rotation Unit Contract**: Khẳng định rõ trong domain documentation rằng `BallPosition.rotation` và `SceneAnnotation.rotation` lưu trữ góc quay trình diễn theo đơn vị **độ (degrees)**. Renderer Phase 3 sẽ thực hiện chuyển đổi degrees $\rightarrow$ radians khi vẽ Canvas.
- **Fractional Numeric Rejection**: Fractional numeric values (e.g. `1.5`, `2.7`) are no longer silently truncated when integer legacy fields (`schemaVersion`, `system`, `viewType`) are expected. Rejection emits an explicit `INVALID_INTEGER_VALUE` warning and uses safe fallbacks.
- **Independent `pathColors` & `freePathColors` Validation**: `pathColors` and `freePathColors` maps/lists are validated at top-level independently of `paths` presence, ensuring malformed color structures (e.g., `{"pathColors": "bad"}`) trigger specific `INVALID_FIELD_TYPE` warnings regardless of `paths`.
- **Full SceneMapper Round-Trip Coverage**: Bổ sung unit test kiểm tra khứ hồi 100% tất cả các thuộc tính mở rộng Phase 2 của `BilliardScene` qua `SceneMapper` (`domainToRow` $\rightarrow$ `rowToDomain`), xác minh đầy đủ: `BallPosition` (`label`, `colorHex`, `rotation`, `legacyType`), `SceneAnnotation` (`colorHex`, `rotation`, `role`, `cushionSide`), `CueInstruction` (`power = 0.0`, `powerIsResolved = false`, `tipOffset`), và `ScenePresentationConfig` (`legacySystemIndex`, `legacyViewTypeIndex`, `labelFontSize`).
- **Legacy Row Backward Compatibility**: Xác minh hàng dữ liệu cũ (old JSON row từ Phase 1) thiếu các trường mới vẫn giải tuần tự hóa an toàn với `presentationConfig = null`, `powerIsResolved = true`, và các metadata phụ = `null`.

---

## Acceptance checklist
- [x] Sử dụng fixture đúng cấu trúc sản xuất thực tế của `_captureCurrentLayout()`
- [x] Parse đầy đủ metadata bi bóng (`ghosts` Map) và bi phụ (`extraBalls` Map)
- [x] Tự động thêm điểm xuất phát vị trí bi cho `paths.white`, `yellow`, `red`
- [x] Chuyển đổi màu ARGB int thành hex string `#AARRGGBB`
- [x] Đưa metadata trình diễn vào `ScenePresentationConfig` (không nhầm vào `teachingTimeline`)
- [x] Thẩm định dải index enum `system` và `viewType` với warning rõ ràng
- [x] Thiết lập `powerIsResolved = false` cho lực cơ chưa quy đổi
- [x] Trả warning chẩn đoán typed cho dữ liệu hình dạng không hợp lệ, không crash
- [x] Không còn mất mát dữ liệu im lặng trên các field legacy
- [x] `schemaVersion` được phân định rõ với `BilliardScene.version` trong tài liệu
- [x] `SceneMapper` tương thích khứ hồi 100% với SQLite Schema V4
- [x] Pure Dart boundary được bảo đảm 100% trong `lib/domain/`
- [x] Complete test suite pass (57/57 pass) 100%
- [x] Trạng thái Phase 2 được duy trì tại `REVIEW`

---

## Recommended status
- **Phase -1:** `DONE`
- **Phase 0:** `DONE`
- **Phase 1:** `DONE`
- **Phase 2:** `REVIEW` (Ready for external review)
- **Phase 3:** `NOT_STARTED`

---

## Git synchronization status
- **Current branch:** `main`
- **Working tree:** `CLEAN`
- **Sync state:** `SYNCED`
