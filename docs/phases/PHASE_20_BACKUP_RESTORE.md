# PHASE 20 - BACKUP + RESTORE

## Mục tiêu
Backup/restore toàn bộ DB + media an toàn.

## Spec bắt buộc đọc
- `docs/specs/13_IMPORT_EXPORT_BACKUP.md`

## Deliverables
1. Consistent backup
2. Validation
3. Safety copy
4. Restore rollback

## Không làm trong phase này
- Không chỉ copy SQLite file

## Acceptance Criteria
- [ ] Restore trên clean install giữ media
- [ ] Corrupt package bị reject
- [ ] Rollback path test

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
