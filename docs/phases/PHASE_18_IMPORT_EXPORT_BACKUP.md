# PHASE 18 - IMPORT / EXPORT / BACKUP

## Mục tiêu
Sao lưu và chia sẻ nội dung an toàn.

## Scope
- Package manifest.
- JSON structured data.
- Media references/assets.
- Schema version.
- Import validation.
- Backup/restore.

## Acceptance Criteria
- Export -> import roundtrip giữ stable IDs/relations theo policy.
- File lỗi không crash app.
- Unsupported schema version báo lỗi rõ.
- Không ghi đè dữ liệu hiện có im lặng.
