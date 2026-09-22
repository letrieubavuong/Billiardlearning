# CODEX BOOTSTRAP PROMPT

Bạn đang làm việc trong repository Billiardlearning viết bằng **Dart + Flutter**.

## Bắt buộc trước khi sửa code

1. Đọc `AGENTS.md`.
2. Đọc `docs/MASTER_SPEC.md`.
3. Đọc `docs/00_ROADMAP.md`.
4. Đọc `docs/specs/01_PRODUCT_SCOPE.md`.
5. Đọc `docs/specs/02_DOMAIN_MODEL.md`.
6. Đọc `docs/specs/16_CODEX_WORKING_RULES.md`.
7. Đọc file phase được giao.
8. Chỉ đọc thêm spec có liên quan trực tiếp đến phase đó.

## Tình trạng repo

Repo chứa một Flutter app cũ đã có nhiều UI/editor đáng giữ, nhưng domain cũ phần lớn dựa trên `Note + NoteBlock + JSON content` và không còn là kiến trúc đích.

Không được:
- rewrite toàn bộ app từ đầu;
- đổi sang Kotlin Native;
- xóa editor cũ trước khi migration hoàn tất;
- coi animation hiện tại là physics engine;
- làm sang phase kế tiếp.

## Phase đầu tiên

Bắt đầu bằng:
`docs/phases/PHASE_-1_LEGACY_AUDIT_AND_SPEC_RESET.md`

Mục tiêu đầu tiên là lập bản đồ KEEP / MIGRATE / REWRITE / REMOVE-LATER và tạo đường migration an toàn, không phải xây feature mới.
