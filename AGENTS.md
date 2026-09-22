# AGENTS.md - Billiard Lesson Studio

Tài liệu này áp dụng cho toàn bộ repository.

## Source of Truth

Đọc theo thứ tự:
1. `docs/MASTER_SPEC.md`
2. `docs/00_ROADMAP.md`
3. `docs/specs/*.md` liên quan
4. `docs/phases/PHASE_XX_*.md` của phase hiện tại

Nếu code trái với spec, không tự ý giữ hành vi cũ. Ghi nhận discrepancy và xử lý trong đúng scope phase.

## Architecture Guards

- Android native: Kotlin + Jetpack Compose.
- Physics/geometry: pure Kotlin, không phụ thuộc Android UI.
- Domain: không phụ thuộc Room/Compose.
- Room entity: không dùng trực tiếp trong UI/domain.
- World coordinate: normalized/world units; pixel chỉ ở rendering adapter.
- Number systems: data-driven.
- Lessons/Techniques/Exercises tham chiếu Scene bằng stable ID.

## Change Discipline

- Chỉ làm phase được giao.
- Không refactor diện rộng ngoài scope nếu không cần để đạt acceptance criteria.
- Mọi thay đổi schema phải có migration và test.
- Mọi logic toán/physics mới phải có unit test.
- Không xóa test để làm build xanh.
- Không bỏ qua lỗi bằng catch rỗng hoặc fallback im lặng.

## Completion Report

Mỗi lần hoàn thành phải báo:
- Summary
- Files changed
- Architecture impact
- Schema/migration impact
- Tests
- Acceptance checklist PASS/FAIL
- Manual test steps
- Known limitations
