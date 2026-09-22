# Billiard Learning Studio - Flutter Architecture v2

Bộ tài liệu này là **Source of Truth mới** cho repository `Billiardlearning`.

Mục tiêu của lần tái cấu trúc này là **giữ Dart + Flutter và tận dụng phần UI/editor cũ có giá trị**, đồng thời thay xương sống nghiệp vụ cũ kiểu `Note + JSON block` bằng kiến trúc đúng cho một ứng dụng dạy, dựng thế bi và mô phỏng billiard.

## Nguyên tắc cốt lõi

- Flutter/Dart là nền tảng chính.
- Domain, geometry và physics là **pure Dart**.
- `BilliardScene` là entity trung tâm được dùng chung bởi Lesson, Camera, Teaching, Physics, Technique và Practice.
- Lesson chỉ tham chiếu Scene/Technique/NumberSystem/Exercise qua stable ID.
- Teaching Animation và Physics Simulation là hai hệ thống độc lập.
- Không hard-code bộ số trong enum/if/switch theo tên.
- Không dùng pixel làm dữ liệu nghiệp vụ.
- Lesson/Scene dùng stable UUID/String ID và soft delete.
- Media lớn lưu file; SQLite chỉ lưu metadata/reference.
- Không phá compatibility dữ liệu cũ trước khi migration hoàn tất.

## Thứ tự Codex phải đọc

1. `AGENTS.md`
2. `docs/MASTER_SPEC.md`
3. `docs/00_ROADMAP.md`
4. `docs/specs/01_PRODUCT_SCOPE.md`
5. `docs/specs/02_DOMAIN_MODEL.md`
6. Spec liên quan phase hiện tại
7. `docs/specs/16_CODEX_WORKING_RULES.md`
8. `docs/phases/<phase-hien-tai>.md`

Không bắt đầu feature mới trước khi hoàn thành `PHASE_-1_LEGACY_AUDIT_AND_SPEC_RESET.md`.
