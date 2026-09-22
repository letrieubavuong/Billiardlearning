# IMPORT / EXPORT / BACKUP

## Content package
ZIP/package gợi ý:
- `manifest.json`
- `lessons/`
- `scenes/`
- `techniques/`
- `number_systems/`
- `exercises/`
- `media/`

Manifest:
- schemaVersion
- packageId
- createdAt
- appVersion optional
- content IDs
- dependencies
- checksums

## Backup
Backup toàn app phải gồm:
- SQLite DB consistent snapshot
- media files
- manifest/metadata

## Restore
- validate package/integrity
- compatibility check
- safety backup current state
- transactional restore where possible
- rollback on failure

Không lặp lại lỗi legacy: chỉ copy `.db` nhưng bỏ mất `note_images`.
