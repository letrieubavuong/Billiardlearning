# PHASE -1 - LEGACY AUDIT & SPECIFICATION RESET

## Mục tiêu
Audit toàn bộ Flutter repo, lập bản đồ KEEP/MIGRATE/REWRITE/REMOVE-LATER và chốt migration architecture trước khi xây feature mới.

## Spec bắt buộc đọc
- `docs/specs/17_LEGACY_MIGRATION.md`
- `docs/specs/14_FLUTTER_ARCHITECTURE.md`

## Deliverables
1. Legacy inventory theo file/domain
2. Bảng KEEP/MIGRATE/REWRITE/REMOVE-LATER
3. Migration map Note/Diagram/ShotDetail/Media/Progress
4. Xác nhận không rewrite Kotlin
5. Cập nhật discrepancy docs nếu phát hiện

## Không làm trong phase này
- Không xóa legacy code
- Không tạo physics mới
- Không redesign UI lớn

## Acceptance Criteria
- [ ] Có inventory các god-file và dependencies chính
- [ ] Có migration map dữ liệu cũ -> domain mới
- [ ] Không còn tài liệu nào yêu cầu Kotlin Native
- [ ] Build/test baseline được ghi nhận
- [ ] Không mất dữ liệu hoặc xóa code cũ

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
