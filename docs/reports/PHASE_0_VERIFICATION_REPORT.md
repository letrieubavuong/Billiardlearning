# PHASE 0 VERIFICATION REPORT

## Summary
Báo cáo nghiệm thu hoàn tất các hạng mục của **Phase 0 — Pure Dart Domain Foundation** cho dự án **Billiardlearning**. Phase này tập trung xây dựng và củng cố toàn bộ Pure Dart Domain entities, value objects và repository contracts hoàn toàn độc lập với Flutter UI, renderer và SQLite persistence layer. Đã nâng cấp chiến lược `StableId` từ generator tạm sang chuẩn **UUID v4**, bổ sung bộ unit test thuần domain (không phụ thuộc Flutter/SQLite), nâng cấp kiến trúc test ranh giới pure Dart và bảo toàn 100% khả năng tương thích ngược với Phase 1 đã hoàn thành.

---

## Files changed
- **`pubspec.yaml`**: Bổ sung dependency `uuid: ^4.6.0` (Pure Dart package).
- **`lib/domain/value_objects/value_objects.dart`**: Cập nhật `StableId.generate()` sử dụng `Uuid().v4()`, giữ nguyên kiểu trả về `String` để đảm bảo tương thích SQLite schema.
- **`test/value_objects_test.dart`**: Bổ sung unit test toàn diện cho `Vec2`, `TablePoint` boundaries, `Angle` normalizations, `WorldPoint` và `StableId` UUID v4 regex validation + 1000 UUID uniqueness sample test.
- **`test/domain_foundation_test.dart`** *(NEW)*: Thêm bộ test thuần domain kiểm tra khả năng khởi tạo và làm việc độc lập của `BilliardScene`, `Lesson`, `Technique`, `NumberSystem` mà không cần Flutter UI hay SQLite.
- **`test/architecture_test.dart`**: Nâng cấp test ranh giới pure Dart cho `lib/domain/` kiểm tra cấm tuyệt đối imports (`package:flutter/`, `package:sqflite/`, `package:sqflite_common_ffi/`, `dart:ui`) và các Flutter UI symbols (`Color`, `Offset`, `Canvas`, `Paint`, `Widget`, `BuildContext`).
- **`docs/PHASE_STATUS.md`**: Cập nhật trạng thái Phase 0 thành `REVIEW`.
- **`docs/reports/PHASE_0_VERIFICATION_REPORT.md`** *(NEW)*: Báo cáo nghiệm thu chi tiết Phase 0.

---

## Stable ID strategy
- **Previous implementation:** Generator dựa trên timestamp và random nhỏ (`'id_${now}_$rand'`).
- **Production strategy vNext:** Chuẩn **UUID v4** độc lập bằng package Pure Dart `uuid`.
- **Format:** `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` (Chuẩn IETF RFC 4122).
- **Schema Compatibility:** `StableId.generate()` tiếp tục trả về kiểu `String` giữ nguyên tính tương thích với toàn bộ SQLite primary keys (`TEXT PRIMARY KEY`) trong vNext database tables (`vnext_lessons`, `vnext_scenes`, `vnext_techniques`, `vnext_number_systems`, `vnext_exercises`, `vnext_media_assets`, `vnext_learning_progress`, `vnext_simulation_profiles`). Không gây breaking changes cho Phase 1 repositories hay DB migrations.

---

## Pure Dart boundary
- Toàn bộ source code trong `lib/domain/` (`entities/`, `value_objects/`, `repositories/`) đáp ứng nghiêm ngặt 5 quy tắc kiến trúc Domain:
  1. Không import `package:flutter/*`.
  2. Không import `package:sqflite/*` hay `package:sqflite_common_ffi/*`.
  3. Không import `dart:ui`.
  4. Không sử dụng các kiểu Flutter UI: `Color`, `Offset`, `Canvas`, `Paint`, `Widget`, `BuildContext`.
  5. Repository contracts (`lib/domain/repositories/repositories.dart`) chỉ trao đổi các domain entities/value objects, hoàn toàn không phụ thuộc data layer hay SQLite row models.

---

## Value objects
- **`Vec2`**: Hỗ trợ phép cộng, trừ, nhân/chia scalar, dot product, length, length squared, normalization. Xử lý an toàn trường hợp normalize vector không `Vec2.zero`.
- **`TablePoint`**: Tọa độ chuẩn hóa $(u,v) \in [0,1] \times [0,1]$ đại diện cho vị trí trên mặt bàn. Hàm `isWithinTable` xác minh chính xác biên $[0,1]^2$.
- **`WorldPoint`**: Tọa độ vật lý $(x,y)$ tính bằng mét. Định nghĩa ngữ nghĩa equality, hashCode và string format.
- **`Angle`**: Chuyển đổi hai chiều giữa radians và degrees, hỗ trợ chuẩn hóa góc vượt quá $360^\circ$ ($2\pi$) và góc âm về khoảng $[0, 2\pi)$.
- **`StableId`**: Value object đại diện cho định danh bền vững, cung cấp phương thức tĩnh `generate()` tạo chuỗi UUID v4.

---

## Domain entities
- Khởi tạo đầy đủ và kiểm thử độc lập cho các đối tượng domain cốt lõi:
  - `BilliardScene`: Chứa `TableConfig`, `List<BallPosition>`, `List<TrajectoryLine>`, `List<SceneAnnotation>`, `CueInstruction?`, `teachingTimeline`, `source`, `status`, `version`, `createdAt`, `updatedAt`, `deletedAt`.
  - `Lesson`: Chứa `LessonSection` phân tầng và `List<LessonBlock>` type-safe (`TextBlock`, `SceneReferenceBlock`, `MediaReferenceBlock`, `TechniqueReferenceBlock`, `NumberSystemReferenceBlock`, `ExerciseReferenceBlock`, `CustomLessonBlock`).
  - `Technique`: Đối tượng kỹ thuật gôm/bida.
  - `NumberSystem`: Đối tượng hệ thống bộ số.
  - `Exercise`, `MediaAsset`, `LearningProgressRecord`, `SimulationProfile`.

## CueInstruction power contract
- **Normalized Instructional Power:** `CueInstruction.power` đại diện cho giá trị lực hướng dẫn đã chuẩn hóa trong khoảng $[0.0, 1.0]$ (`0.00` = zero, `0.25` = lực nhẹ/low, `0.50` = lực vừa/medium, `0.75` = lực mạnh/high, `1.00` = lực tối đa/max).
- **Physical Boundary:** `power` KHÔNG đại diện cho vận tốc vật lý ($m/s$), tốc độ ($km/h$) hay phần trăm phô trương $[0, 100]$.
- **Test Alignment:** Đã đồng bộ mẫu test trong `test/vnext_repository_test.dart` từ `power: 75.0` thành `power: 0.75` để tuân thủ 100% domain contract.
- **Physical Calibration:** Việc quy đổi từ `power` chuẩn hóa sang vận tốc/xung lực vật lý thuộc phạm vi của Phase 15 (Cue Strike Model) và Phase 16 (Physics Calibration).

---

## Repository contracts
- `lib/domain/repositories/repositories.dart` định nghĩa 8 repository interfaces thuần Pure Dart:
  - `VNextLessonRepository` & `VNextSceneRepository`: Hỗ trợ đầy đủ vòng đời Soft Delete (`getById(id, {includeDeleted})`, `list({includeDeleted})`, `save`, `softDelete`, `restore`, `purge`).
  - `VNextTechniqueRepository`, `VNextNumberSystemRepository`, `VNextExerciseRepository`, `VNextMediaRepository`: Hợp đồng CRUD & delete trực tiếp.
  - `VNextLearningProgressRepository`: Hợp đồng theo dõi tiến độ (`getByEntityId`, `listAll`, `saveProgress`).
  - `VNextSimulationProfileRepository`: Hợp đồng cấu hình giả lập (`getById`, `getDefault`, `list`, `save`).
- Tất cả các repository contracts đều là interface thuần Dart, chỉ trao đổi Domain Entities, không phụ thuộc SQLite/sqflite hay data layer row models.

---

## Sample BilliardScene test
- Unit test tại [test/domain_foundation_test.dart](file:///c:/Lap%20trinh%20Android/Libre2026/Billiardlearning/test/domain_foundation_test.dart) khởi tạo thành công một đối tượng `BilliardScene` đầy đủ phức tạp:
  - UUID v4 generated ID.
  - Cấu hình bàn `carom_3c` ($1.42m \times 2.84m$).
  - Vị trí 3 bi (bi chủ trắng, bi vàng, bi đỏ) sử dụng `TablePoint(u,v)`.
  - Quỹ đạo đường chạy bi chủ dạng polyline `TrajectoryLine`.
  - Chú thích điểm chạm `SceneAnnotation`.
  - Hướng dẫn lực & áp-phê `CueInstruction` (`power: 0.75`, `direction: 45°`, `tipOffset: Vec2(0.0, 0.5)`).
  - Nguồn dữ liệu `SceneSource.manual` và trạng thái `SceneStatus.active`.
- Test khẳng định `BilliardScene` có thể tồn tại và vận hành hoàn toàn độc lập, không cần Flutter context hay SQLite database.

---

## Tests
- **`dart format .`**:
  - Exit code: `0`
  - Details: 52 files checked, formatted cleanly.
- **`flutter analyze`**:
  - Exit code: `1`
  - Errors: `0`
  - Warnings/Infos: `312` pre-existing legacy deprecations (Baseline Phase -1 không tạo error mới).
- **`flutter test`**:
  - Exit code: `0`
  - Details: **41/41 PASS** (bao gồm 35 tests cũ + 6 test suites mới cho value objects, domain foundation & architecture boundary).

---

## Architecture impact
- Đảm bảo ranh giới Domain Core đạt tiêu chuẩn Pure Dart 100%.
- Tách biệt tuyệt đối giữa Domain Entities và Renderer/UI/SQLite Data Layer.
- Thiết lập nền tảng sẵn sàng cho Phase 2 (Scene Model & Coordinate System Engine).

---

## Legacy compatibility impact
- Không làm thay đổi bất kỳ code UI legacy hay legacy models (`Note`, `NoteBlock`, `DiagramSystem`).
- Giữ nguyên `String` representation của `StableId`, đảm bảo mappers và repositories của Phase 1 hoạt động bình thường không gặp regression.

---

## Database/schema impact
- `NONE`: Không thay đổi SQLite Schema (Database v4 giữ nguyên).
- Không yêu cầu database migration mới.

---

## Deferred gaps
- `cueAngle` (cue elevation): DEFERRED $\rightarrow$ Owner: **Phase 15 — Cue Strike Model**.
- `thickness` (contact fraction): DEFERRED $\rightarrow$ Owner: **Phase 6 — Lesson Domain / CueInstruction teaching block integration**.
- `forceImage`: Legacy `forceImage` preset $\rightarrow$ `normalized instructional power [0.0, 1.0]` mapping: DEFERRED $\rightarrow$ Physical conversion & calibration: **Phase 15 / Phase 16**.

---

## Final external review corrections
- **Corrected `forceImage` Terminology:** Chuẩn hóa quy trình dữ liệu: $\text{Legacy } forceImage \xrightarrow{\text{PLANNED mapping}} \text{normalized instructional power } [0.0, 1.0] \xrightarrow{\text{Phase 15/16}} \text{physical parameters}$. Không mô tả `forceImage` như direct numeric speed mapping.
- **Corrected Deferred Phase Ownership:** Phân định rõ phase owner cho từng gap: `cueAngle` thuộc Phase 15, `thickness` thuộc Phase 6, physical calibration thuộc Phase 15/16.
- **Corrected Repository Lifecycle Description:** Làm rõ hợp đồng Soft Delete (`includeDeleted`, `softDelete`, `restore`, `purge`) áp dụng cụ thể cho 2 aggregates `Lesson` và `Scene`, các repositories còn lại áp dụng hợp đồng CRUD tương ứng.
- **Production Behavior Impact:** `NONE` (Không có bất kỳ thay đổi nào trong code sản xuất).

---

## Acceptance checklist
- [x] `StableId` không còn timestamp + small Random generator
- [x] `StableId` dùng UUID v4 chuẩn (Pure Dart `uuid` package)
- [x] ID vẫn tương thích String schema hiện tại
- [x] Domain không import Flutter
- [x] Domain không import sqflite
- [x] Domain không import `dart:ui`
- [x] Domain không dùng `Color`, `Offset`, `Canvas`, `Paint`, `Widget`, `BuildContext`
- [x] `Vec2` tests pass (bao gồm zero vector normalization)
- [x] `TablePoint` boundary tests pass ($[0,1]^2$)
- [x] `WorldPoint` tests pass
- [x] `Angle` tests pass (positive overflow & negative angle normalization)
- [x] `StableId` UUID tests pass (regex format & 1000 UUID uniqueness sample test)
- [x] Dedicated pure-domain Scene test được tạo tại `test/domain_foundation_test.dart`
- [x] Sample `BilliardScene` tạo thành công độc lập không cần SQLite
- [x] Repository contracts thuần Pure Dart
- [x] Existing Phase 1 tests không regression (41/41 tests pass)
- [x] Production SQLite schema không đổi (V4)
- [x] Phase 2 vẫn `NOT_STARTED`
- [x] `PHASE_0_VERIFICATION_REPORT.md` đã được tạo
- [x] Trạng thái Phase 0 cập nhật thành `REVIEW`

---

## Recommended phase status
- **Phase -1:** `DONE`
- **Phase 0:** `REVIEW` (Ready for external review)
- **Phase 1:** `DONE`
- **Phase 2:** `NOT_STARTED`

---

## Git synchronization status
- **Current branch:** `main`
- **Working tree:** `CLEAN`
- **Sync state:** `SYNCED`
