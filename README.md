# Billiard Lesson Studio - Android

Bộ tài liệu nguồn chuẩn để Codex phát triển ứng dụng Android dạy và mô phỏng billiard.

## Nguyên tắc bắt buộc

1. Trước khi sửa code, Codex phải đọc `docs/MASTER_SPEC.md` và phase hiện tại.
2. Không tự ý thay đổi domain model nếu chưa cập nhật tài liệu liên quan.
3. Không hard-code hệ thống bộ số, kỹ thuật hoặc bài học vào UI.
4. Tách riêng `domain`, `simulation`, `rendering`, `data`, `feature`.
5. Physics engine không phụ thuộc UI Android.
6. Tất cả tọa độ nghiệp vụ dùng hệ tọa độ chuẩn hóa, không lưu pixel màn hình.
7. Mỗi phase phải đạt acceptance criteria trước khi chuyển phase tiếp theo.

## Thứ tự đọc

1. `docs/MASTER_SPEC.md`
2. `docs/00_ROADMAP.md`
3. `docs/specs/01_PRODUCT_SCOPE.md`
4. `docs/specs/02_DOMAIN_MODEL.md`
5. File nghiệp vụ tương ứng phase hiện tại
6. `docs/specs/15_CODEX_WORKING_RULES.md`
7. File `docs/phases/PHASE_XX_*.md` tương ứng

## File điều khiển Codex

- `AGENTS.md`: quy tắc bắt buộc toàn repo.
- `docs/PHASE_STATUS.md`: trạng thái từng phase.
- `CODEX_BOOTSTRAP_PROMPT.md`: prompt khởi động để giao Codex.
