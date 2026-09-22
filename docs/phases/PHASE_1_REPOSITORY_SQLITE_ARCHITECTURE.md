# PHASE 1 - REPOSITORY + SQLITE ARCHITECTURE

## Mục tiêu
Tạo schema/repository/mappers mới song song legacy, chuẩn bị migration an toàn.

## Spec bắt buộc đọc
- `docs/specs/11_DATA_AND_STORAGE.md`
- `docs/specs/17_LEGACY_MIGRATION.md`

## Deliverables
1. Schema vNext
2. Mappers domain<->data
3. Repository implementations
4. Migration test harness
5. Legacy read compatibility

## Không làm trong phase này
- Không xóa notes table/write path nếu chưa migrate
- Không đổi sqflite sang framework khác tùy ý

## Acceptance Criteria
- [ ] CRUD repository test pass
- [ ] Schema migration test pass
- [ ] Không dùng DB entity trực tiếp trong UI/domain

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
