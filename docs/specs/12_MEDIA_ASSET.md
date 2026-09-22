# MEDIA ASSET

## Mục tiêu
Quản lý ảnh/video/file độc lập khỏi Lesson.

## MediaAsset
- id
- type IMAGE/VIDEO/OTHER
- localPath/storageKey
- originalName
- mimeType
- sizeBytes
- checksum
- createdAt/updatedAt
- deletedAt optional

## Rules
- LessonBlock tham chiếu assetId.
- Không dùng absolute path như identity.
- Không nhét video/blob lớn vào SQLite.
- Import/export phải remap asset references an toàn.
- Xóa asset phải kiểm tra usage/reference.
