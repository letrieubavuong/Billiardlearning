# DATA & STORAGE

## Local-first
App phải hoạt động offline cho authoring và viewing cơ bản.

## Layers
Domain Model != SQLite row/entity != DTO/import model.
Phải có mapper rõ.

## Repositories
Tối thiểu:
- LessonRepository
- SceneRepository
- TechniqueRepository
- NumberSystemRepository
- ExerciseRepository
- MediaRepository
- LearningProgressRepository
- SimulationProfileRepository

## IDs
Stable UUID/String.

## Soft delete
Lesson/Scene có `deletedAt` hoặc status DELETED; query mặc định loại bỏ deleted records.

## Versioning
Version snapshot có thể lưu full snapshot hoặc delta tùy phase, nhưng API domain phải hỗ trợ restore.

## Migration
Mọi schema change có migration test. Không destructive migration trong release.
