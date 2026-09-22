# ROADMAP TỔNG THỂ

## Mốc A - Nền móng

### Phase 0 - Domain Architecture
Mục tiêu: chốt domain, module boundary, naming, dữ liệu.
Kết quả: project skeleton + domain models + repository contracts.

### Phase 1 - Android Foundation
Mục tiêu: app shell, navigation, theme, Room, DI/state.
Kết quả: app chạy ổn định, CRUD mẫu hoạt động.

## Mốc B - Scene Editor

### Phase 2 - Table Coordinate System
Mục tiêu: hệ tọa độ chuẩn hóa, mapping world-screen.
Kết quả: renderer bàn không phụ thuộc kích thước màn hình.

### Phase 3 - Table & Ball Editor
Mục tiêu: đặt/kéo/xóa/duplicate bi, diamond, zoom/pan, undo/redo.
Kết quả: tạo và lưu một thế bi hoàn chỉnh.

### Phase 4 - Trajectory Mathematics
Mục tiêu: line, segment, point, angle, intersection, path geometry.
Kết quả: có thư viện hình học dùng chung.

### Phase 5 - Trajectory Editor
Mục tiêu: vẽ đường ngắm, đường chạy, điểm chạm, điểm băng.
Kết quả: dựng được bài minh họa không cần physics.

## Mốc C - Physics Core

### Phase 6 - Ball Motion Engine
Mục tiêu: tích phân chuyển động, time step cố định, stop threshold.

### Phase 7 - Ball-Ball Collision
Mục tiêu: phát hiện và xử lý va chạm 2 bi.

### Phase 8 - Cushion Collision
Mục tiêu: va chạm băng, hệ số đàn hồi và ma sát băng.

### Phase 9 - Friction / Sliding / Rolling
Mục tiêu: chuyển trạng thái trượt -> lăn -> dừng.

### Phase 10 - Spin Engine
Mục tiêu: top/bottom/side spin, spin decay và ảnh hưởng quỹ đạo.

### Phase 11 - Cue Strike Model
Mục tiêu: ánh xạ hướng cơ, lực và điểm chạm thành v, omega.

### Phase 12 - Physics Calibration
Mục tiêu: bộ tham số theo từng bàn, test data và sai số.
Kết quả: Physics Core v1.

## Mốc D - Nội dung dạy học

### Phase 13 - Lesson Builder
Mục tiêu: course/chapter/lesson/section/block, preview và reorder.

### Phase 14 - Technique Library
Mục tiêu: thư viện kỹ thuật, tag, mức độ, scene minh họa.

### Phase 15 - Number System Engine
Mục tiêu: bộ số data-driven, công thức, biến, diamond mapping.

### Phase 16 - Interactive Practice
Mục tiêu: bài tập tương tác và so sánh phương án người học.

### Phase 17 - Animation / Replay
Mục tiêu: play/pause/scrub/slow-motion/step collision.

## Mốc E - Hoàn thiện

### Phase 18 - Import / Export / Backup
Mục tiêu: JSON package, backup, restore, media references.

### Phase 19 - UX Polish / Performance
Mục tiêu: tối ưu FPS, tablet layouts, accessibility cơ bản.

### Phase 20 - Release Readiness
Mục tiêu: crash handling, telemetry tùy chọn, migration tests, signed build.

---

## Quy tắc chuyển phase

Không làm phase N+1 nếu acceptance criteria quan trọng của phase N chưa đạt, trừ khi tài liệu phase N+1 ghi rõ có thể phát triển song song.
