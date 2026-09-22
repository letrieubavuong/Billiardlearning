# CODEX WORKING RULES

## Trước khi code

Codex phải:
1. Đọc `docs/MASTER_SPEC.md`.
2. Đọc `docs/00_ROADMAP.md`.
3. Đọc các spec liên quan.
4. Đọc file phase hiện tại.
5. Khảo sát code hiện có trước khi đề xuất thay đổi.

## Trong khi code

- Không rewrite phần ổn định nếu không cần.
- Không đổi public contract ngoài phạm vi phase nếu chưa thật sự cần.
- Không thêm dependency lớn khi chưa giải thích lý do.
- Không hard-code dữ liệu nghiệp vụ mẫu vào production logic.
- Không đưa physics vào ViewModel/Composable.
- Không đưa Room entity vào domain/UI.
- Không tạo duplicate model cùng nghĩa ở nhiều package.
- Ưu tiên testable pure Kotlin cho geometry/physics.

## Khi gặp mâu thuẫn

Ưu tiên:
1. MASTER_SPEC
2. Spec nghiệp vụ cụ thể
3. Phase document
4. Code hiện hữu

Nếu code hiện hữu trái spec, ghi rõ discrepancy rồi sửa theo phase nếu thuộc phạm vi.

## Khi kết thúc phase

Codex phải trả báo cáo:
- Files changed
- Architecture impact
- Database migrations
- Tests added/updated
- Acceptance checklist
- Known limitations
- Manual test steps
- Không tự chuyển sang phase kế tiếp.
