# DATA & STORAGE

## Local first

MVP hoạt động offline hoàn toàn.
Room lưu metadata và nội dung có cấu trúc.
Media lớn lưu file, DB chỉ giữ reference/path metadata.

## Layers

Domain Model != Room Entity != DTO.
Phải có mapper rõ ràng.

## Repository contracts

- LessonRepository
- SceneRepository
- TechniqueRepository
- NumberSystemRepository
- ExerciseRepository
- SimulationProfileRepository

## IDs

Dùng UUID/String stable ID để thuận tiện import/export/sync sau này.

## Versioning

Mỗi export package cần:
- schemaVersion
- appVersion optional
- createdAt
- content manifests

Room migration bắt buộc khi schema thay đổi.
Không dùng destructive migration trong release build.
