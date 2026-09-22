# PHASE 2 VERIFICATION REPORT

## Summary
Báo cáo nghiệm thu hoàn tất triển khai **Phase 2 — Scene Model + Coordinate System** cho dự án **Billiardlearning**. Phase 2 đã xây dựng engine tọa độ và hình học mặt bàn Pure Dart `TableGeometry`, thiết lập quy trình biến đổi tọa độ 4 tầng chuẩn ($x_{diamond}/4, y_{diamond}/8 \rightarrow TablePoint(u,v) \rightarrow WorldPoint(x_m,y_m)$), triển khai công cụ chuyển đổi sơ đồ cũ Pure Dart `LegacySceneImporter` với hệ thống chẩn đoán cảnh báo `LegacyImportWarning`, đảm bảo khả năng lưu trữ không cần thay đổi SQLite schema V4 và bảo toàn 100% kết quả test từ các phase trước.

---

## Files changed
- **`lib/domain/geometry/table_geometry.dart`** *(NEW)*: Model hình học bàn bida Pure Dart (`playfieldWidthMeters`, `playfieldLengthMeters`, `ballRadiusMeters`) cùng các phương thức biến đổi hai chiều `TablePoint` $\leftrightarrow$ `WorldPoint` và tính khoảng cách vật lý theo tỉ lệ 1:2.
- **`lib/domain/importers/legacy_scene_importer.dart`** *(NEW)*: Bộ nạp sơ đồ legacy Pure Dart chuyển đổi payload JSON từ `DiagramBuilderPage` thành đối tượng `BilliardScene` vNext với tọa độ $u=x/4, v=y/8$ và ghi nhận các warning chẩn đoán.
- **`test/scene_coordinate_test.dart`** *(NEW)*: Unit test cho `TableGeometry`, kiểm tra biến đổi tọa độ hai chiều, tỷ lệ khống chế aspect ratio 1:2 và kiềm tra biên $[0,1]^2$.
- **`test/legacy_scene_importer_test.dart`** *(NEW)*: Unit test kiểm tra `LegacySceneImporter` với dữ liệu legacy payload thực tế, mapping bi, polyline paths, nhãn chú thích, tip offset và cảnh báo deferred gaps.
- **`docs/PHASE_STATUS.md`**: Đóng Phase 0 thành `DONE`, chuyển Phase 2 sang trạng thái `REVIEW`.
- **`docs/INDEX.md`**: Bổ sung liên kết báo cáo Phase 2.
- **`docs/reports/PHASE_0_VERIFICATION_REPORT.md`**: Cập nhật trạng thái Phase 0 thành `DONE` (External review PASS).
- **`docs/reports/PHASE_2_VERIFICATION_REPORT.md`** *(NEW)*: Báo cáo nghiệm thu chi tiết Phase 2.

---

## Scene model changes
- Đối tượng `BilliardScene` giữ nguyên cấu trúc hạt nhân ổn định từ Phase 0: `TableConfig`, `balls`, `trajectories`, `annotations`, `cueInstruction`, `teachingTimeline`, `source`, `status`, `version`, `createdAt`, `updatedAt`, `deletedAt`.
- Thêm thuộc tính lưu thông tin hệ thống hiển thị cũ (`legacySystemIndex`, `legacyViewTypeIndex`) vào `teachingTimeline` nhằm bảo toàn cấu hình trình diễn legacy mà không phá hỏng schema SQLite.

---

## TableGeometry
- **Lớp Pure Dart:** `TableGeometry` định nghĩa kích thước chuẩn của bàn bida Carom Match ($1.42m \times 2.84m$) và bán kính bi standard ($0.03075m$ / đường kính 61.5mm).
- **Ràng buộc khởi tạo:** Kiểm tra kích thước bàn và bán kính bi phải là số dương (`> 0`). Thất bại sẽ kích hoạt assertion error.
- **Biến đổi tọa độ:**
  - `toWorldPoint(TablePoint point)` $\rightarrow$ `WorldPoint(point.u * widthMeters, point.v * lengthMeters)`.
  - `toTablePoint(WorldPoint point)` $\rightarrow$ `TablePoint(point.x / widthMeters, point.y / lengthMeters)`.
- **Đặc tính Tỷ lệ Bàn (Aspect Ratio):** Phân định rõ sự phi tuyến khoảng cách vật lý giữa trục $u$ và trục $v$: khoảng thay đổi $\Delta u = 0.1$ tương ứng $0.142m$, trong khi $\Delta v = 0.1$ tương ứng $0.284m$ (gấp đôi do tỷ lệ bàn 1:2).

---

## Coordinate conventions
- **Legacy Diamond Coordinates:** Hệ tọa độ nút số cũ $x_{diamond} \in [0, 4]$ (băng ngắn), $y_{diamond} \in [0, 8]$ (băng dài).
- **Quy tắc Chuẩn hóa Vị trí Bàn:** $u = x_{diamond} / 4.0$, $v = y_{diamond} / 8.0$ để tạo ra `TablePoint(u,v)` trong không gian $[0, 1] \times [0, 1]$.
- **Không nhầm lẫn Renderer Ratio:** Renderer helper cũ `Offset(x/4, y/4)` biểu diễn không gian vẽ ($relX \in [0,1], relY \in [0,2]$) KHÔNG được dùng làm `TablePoint`.
- **Ranh giới Màn hình (Pixel):** Toàn bộ tọa độ màn hình (`ScreenCoordinate` / Canvas Pixels) thuộc về sở hữu của Renderer ở Phase 3 và KHÔNG bao giờ được lưu trữ vào SQLite database.

---

## Coordinate round-trip tests
- Unit test tại [test/scene_coordinate_test.dart](file:///c:/Lap%20trinh%20Android/Libre2026/Billiardlearning/test/scene_coordinate_test.dart) xác minh các điểm quan trọng:
  - $(0.0, 0.0) \leftrightarrow (0.0m, 0.0m)$
  - $(1.0, 1.0) \leftrightarrow (1.42m, 2.84m)$
  - $(0.5, 0.5) \leftrightarrow (0.71m, 1.42m)$
  - $(0.25, 0.75) \leftrightarrow (0.355m, 2.13m)$
- Đảm bảo tính nhất quán tuyệt đối trong phép biến đổi khứ hồi $TablePoint \rightarrow WorldPoint \rightarrow TablePoint$.

---

## LegacySceneImporter
- Triển khai lớp Pure Dart `LegacySceneImporter` giải mã Map dữ liệu legacy JSON.
- Phân tích và chuyển đổi payload chính xác:
  - Tọa độ 3 bi chính (trắng, vàng, đỏ), bi phụ (`extraBalls`) và bi bóng (`ghosts`).
  - Đường chạy polyline `paths` (`white`, `yellow`, `red`, `free`) thành `TrajectoryLine`.
  - Nhãn văn bản `labels` và nút số `cushionNumbers` thành `SceneAnnotation`.
  - Điểm xoáy `effet[0], effet[1]` thành `CueInstruction.tipOffset`.
- Tạo đối tượng `LegacySceneImportResult` trả về `BilliardScene` candidate kèm danh sách chẩn đoán `LegacyImportWarning`.

---

## Legacy fields mapped
- `white`, `yellow`, `red`, `extraBalls`, `ghosts` $\rightarrow$ `BallPosition` list với tọa độ $x/4, y/8$.
- `paths.white`, `paths.yellow`, `paths.red`, `paths.free` $\rightarrow$ `TrajectoryLine` list với tọa độ các điểm $x/4, y/8$.
- `labels`, `cushionNumbers` $\rightarrow$ `SceneAnnotation` list với tọa độ $x/4, y/8$.
- `effet[0]`, `effet[1]` $\rightarrow$ `CueInstruction.tipOffset`.
- `system`, `viewType` $\rightarrow$ `teachingTimeline` metadata (`legacySystemIndex`, `legacyViewTypeIndex`).

---

## Legacy fields deferred
- `forceImage`: Ghi nhận `DEFERRED_FIELD_FORCE_IMAGE` warning $\rightarrow$ Sở hữu bởi Phase 15/16 (Physical Cue Calibration).
- `cueAngle`: Ghi nhận `DEFERRED_FIELD_CUE_ANGLE` warning $\rightarrow$ Sở hữu bởi Phase 15 (Cue Strike Model).
- `thickness`: Ghi nhận `DEFERRED_FIELD_THICKNESS` warning $\rightarrow$ Sở hữu bởi Phase 6 (Lesson Domain).

---

## Migration warnings / diagnostics
- `OUT_OF_BOUNDS_COORDINATE`: Cảnh báo khi tọa độ nút số cũ vượt quá phạm vi bàn chuẩn $[0,1]^2$.
- `UNSUPPORTED_SCHEMA_VERSION`: Cảnh báo khi phiên bản schema khác 1.
- `DEFERRED_FIELD_*`: Cảnh báo các trường dữ liệu được hoãn xử lý cho các phase sau.

---

## Persistence compatibility
- Kiểm tra tính tương thích khứ hồi qua `SceneMapper` (`lib/data/mappers/mappers.dart`):
  - `SceneMapper.domainToRow(scene)`
  - `SceneMapper.rowToDomain(row)`
- Toàn bộ các đối tượng `BilliardScene` do `LegacySceneImporter` sinh ra đều tương thích 100% với SQLite schema V4 và pass toàn bộ repository CRUD tests.

---

## Database/schema impact
- `NONE`: Giữ nguyên Database Schema V4. Không yêu cầu migration hay bump database version.

---

## Architecture impact
- Đảm bảo ranh giới Pure Dart 100% cho `lib/domain/geometry/` và `lib/domain/importers/`.
- Không phụ thuộc vào bất kỳ Flutter UI widget hay Flutter Canvas types nào.

---

## Regression tests
- Bộ test suite **50/50 PASS** (bao gồm 41 tests cũ từ Phase -1, Phase 0, Phase 1 + 9 unit tests mới cho Phase 2).
- Các test ranh giới kiến trúc, migration SQLite, repository soft delete và UUID v4 đều tiếp tục duy trì trạng thái PASS.

---

## Analyzer result
- **`flutter analyze`**:
  - Exit code: `1`
  - Errors: `0`
  - Warnings/Infos: `312` pre-existing legacy deprecations (Baseline Phase -1 không tạo error mới).

---

## Acceptance checklist
- [x] Phase 0 đã chuyển trạng thái `DONE` trong `PHASE_STATUS.md` và report
- [x] `BilliardScene` model đáp ứng đầy đủ yêu cầu Phase 2
- [x] `TableGeometry` Pure Dart được triển khai chính xác
- [x] Phép biến đổi `TablePoint` $\rightarrow$ `WorldPoint` pass
- [x] Phép biến đổi `WorldPoint` $\rightarrow$ `TablePoint` pass
- [x] Khứ hồi biến đổi tọa độ pass
- [x] Đã test đặc tính tỷ lệ bàn 1:2 (aspect ratio)
- [x] Không persist pixel vào database
- [x] Domain không sử dụng Flutter `Offset` hay Flutter UI types
- [x] Nút số legacy $x=0..4, y=0..8$ được quy đổi chuẩn $x/4, y/8$
- [x] Sơ đồ legacy sample payload $\rightarrow$ `BilliardScene` candidate pass
- [x] Sử dụng đúng các keys từ legacy payload thực tế
- [x] Tọa độ không hợp lệ sinh cảnh báo chẩn đoán `LegacyImportWarning`
- [x] Các trường hoãn (deferred fields) sinh cảnh báo chẩn đoán rõ ràng
- [x] `SceneMapper` tương thích khứ hồi 100% với SQLite schema V4
- [x] Phase 1 repository & migration tests pass
- [x] Database v4 giữ nguyên
- [x] Không triển khai Phase 3 (Renderer)
- [x] Không triển khai Teaching Simulation hay Physics
- [x] Complete test suite pass (50/50 pass)
- [x] `PHASE_2_VERIFICATION_REPORT.md` đã được khởi tạo
- [x] Trạng thái Phase 2 cập nhật thành `REVIEW`

---

## Known limitations
- Việc chuyển đổi lực từ preset asset `forceImage` sang thông số vật lý $m/s$ chưa thực hiện ở Phase 2 (thuộc Phase 15/16).
- Độ nghiêng cơ `cueAngle` và độ dày va chạm `thickness` được ghi nhận dưới dạng warnings chẩn đoán để phục vụ Phase 6 và Phase 15.

---

## Intentionally deferred work
- Phase 3: `SceneRenderer` & Canvas rendering engine.
- Phase 4: `SceneEditorController` & interactive editing.
- Phase 5: Teaching simulation & trajectory animation playback.
- Phase 15/16: Physical cue strike model & physics calibration.

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
