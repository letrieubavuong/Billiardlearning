# AGENTS.md - Billiard Learning Studio

Tài liệu này áp dụng cho **toàn bộ repository** và có độ ưu tiên cao hơn hành vi cũ trong code.

## 1. Stack chính thức

- Dart + Flutter.
- Android là nền tảng phát hành ưu tiên.
- Pure Dart cho domain, geometry, teaching core và physics core.
- SQLite local-first. Có thể tiếp tục dùng `sqflite` trong giai đoạn migration; không đổi DB framework chỉ để refactor hình thức.
- Camera/Computer Vision có thể dùng plugin hoặc native Android bridge khi cần, nhưng output cuối cùng phải về domain model chung.

## 2. Source of Truth

Đọc theo thứ tự:
1. `docs/MASTER_SPEC.md`
2. `docs/00_ROADMAP.md`
3. `docs/specs/*.md` liên quan
4. `docs/phases/*.md` của phase hiện tại

Nếu code cũ trái spec mới:
- không tiếp tục nhân rộng hành vi cũ;
- ghi nhận legacy discrepancy;
- migrate trong đúng scope phase;
- không xóa dữ liệu cũ khi chưa có compatibility/migration path.

## 3. Architecture Guards bắt buộc

1. Domain và Physics không import `package:flutter/*`.
2. Domain không dùng `Color`, `Offset`, `Widget`, `BuildContext`, `Canvas`, `Paint`.
3. Renderer không truy cập SQLite/repository trực tiếp.
4. UI không gọi SQL trực tiếp.
5. `BilliardScene` là nguồn dữ liệu chung cho Lesson, Camera, Teaching, Physics, Technique, Practice.
6. Lesson không nhúng Scene JSON trực tiếp trong block.
7. Lesson tham chiếu Scene bằng stable ID.
8. Không hard-code Number System theo tên hoặc enum đóng.
9. Không dùng pixel làm world/domain coordinate.
10. Teaching Animation != Physics Simulation.
11. Physics không nằm trong `CustomPainter`.
12. Stable ID dùng UUID/String.
13. Lesson/Scene xóa thường bằng soft delete.
14. Media lớn không lưu blob trực tiếp trong SQLite.
15. Schema thay đổi phải có migration + test.
16. Math/physics mới phải có unit test.
17. Không tự ý làm phase tiếp theo.
18. Không xóa test để build xanh.
19. Không catch lỗi rồi bỏ qua im lặng trong logic nghiệp vụ.
20. Không báo DONE nếu Acceptance Criteria còn FAIL.

## 4. Legacy Rules

Các thành phần cũ sau đây là nguồn để migrate, không phải kiến trúc đích:
- `Note`
- `NoteBlock.content` chứa JSON
- `DiagramSystem` enum
- `SystemDefaultNotes`
- `SharedPreferences` lưu nghiệp vụ chính
- hard delete theo integer ID
- physics/animation giả lập nằm trong painter

Không xóa chúng trước khi importer/migration tương ứng hoạt động và test pass.

## 5. Completion Report bắt buộc

Mỗi phase phải báo:
- Summary
- Files changed
- Architecture impact
- Legacy compatibility impact
- Schema/migration impact
- Tests đã chạy
- Acceptance checklist PASS/FAIL từng mục
- Manual test steps
- Known limitations
- Nội dung cố ý chưa làm vì thuộc phase sau
