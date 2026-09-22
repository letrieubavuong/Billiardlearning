# DOMAIN MODEL

## Aggregate chính

### BilliardScene
- id: SceneId
- name
- tableConfig
- balls
- trajectories
- annotations
- cueInstruction optional
- teachingTimeline optional
- source: MANUAL/CAMERA/IMPORT/GENERATED
- status
- version
- createdAt/updatedAt/deletedAt

### Lesson
- id: LessonId
- chapterId
- title/subtitle
- sections
- status: DRAFT/READY/PUBLISHED/ARCHIVED/DELETED
- version
- timestamps

### LessonSection
- id
- title
- order
- blocks

### LessonBlock
Các loại block phải type-safe. Reference block chỉ giữ stable ID + presentation metadata nhỏ.

### Technique
- id/name/group/difficulty/tags
- content
- sceneIds
- recommended cue instructions

### NumberSystem
- id/name/description
- variables
- expression/model
- mappings
- conditions/corrections
- exampleSceneIds

### Exercise
- id
- prompt
- sceneId
- expected/reference solution
- evaluation rules

### MediaAsset
- id
- type
- localPath
- mimeType
- size/checksum
- timestamps

## Value objects
- Vec2
- Vec3 nếu physics cần
- TablePoint(u,v)
- WorldPoint(x,y)
- Angle
- SceneId/LessonId/... wrapper nếu practical
- SpinInput
- CueInput

## Quy tắc dependency
Domain không biết Flutter, SQLite, file system, CameraX, OpenCV hay Widget.
