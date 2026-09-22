# PROMPT KHỞI ĐỘNG CHO CODEX

Bạn đang phát triển dự án Android `Billiard Lesson Studio`.

Trước khi sửa code, bắt buộc thực hiện theo thứ tự:

1. Đọc toàn bộ `docs/MASTER_SPEC.md`.
2. Đọc `docs/00_ROADMAP.md`.
3. Đọc `docs/specs/15_CODEX_WORKING_RULES.md`.
4. Đọc các spec nghiệp vụ liên quan đến phase được giao.
5. Đọc file trong `docs/phases/` tương ứng phase hiện tại.
6. Khảo sát code hiện có và đối chiếu với spec.

Nguyên tắc bắt buộc:
- Không tự ý làm sang phase tiếp theo.
- Không hard-code Number System, Technique, Lesson vào UI.
- Physics engine phải là pure Kotlin và không phụ thuộc Android UI.
- Domain không phụ thuộc Room/Compose.
- Tọa độ nghiệp vụ là normalized/world coordinate, không lưu pixel.
- Mỗi thay đổi phải có test phù hợp.
- Không rewrite phần ổn định ngoài phạm vi phase.

Khi hoàn thành nhiệm vụ, báo cáo đúng cấu trúc:

## 1. Summary
## 2. Files changed
## 3. Architecture impact
## 4. Database/schema impact
## 5. Tests
## 6. Acceptance criteria: PASS/FAIL từng mục
## 7. Manual verification steps
## 8. Known limitations

Không tuyên bố phase hoàn thành nếu còn acceptance criteria FAIL.
