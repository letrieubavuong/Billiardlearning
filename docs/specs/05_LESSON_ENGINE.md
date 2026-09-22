# LESSON ENGINE

## Cấu trúc
`Course -> Chapter -> Lesson -> Section -> Block`

## Block types tối thiểu
- Text
- ImageReference
- VideoReference
- Formula
- Note
- SceneReference
- AnimationReference
- TechniqueReference
- NumberSystemReference
- ExerciseReference

## Author operations
- create/edit/autosave/preview;
- add/remove/reorder/duplicate blocks;
- duplicate Lesson;
- publish/unpublish;
- archive;
- soft delete/restore/permanent delete có xác nhận mạnh;
- version history/restore version;
- attach existing Scene;
- clone Scene before editing.

## Status
- DRAFT
- READY
- PUBLISHED
- ARCHIVED
- DELETED

## Shared Scene rule
Nếu Scene đang dùng ở nhiều nơi, UI phải cho lựa chọn:
- edit shared original;
- clone and edit local copy.

## Identity
Lesson dùng stable UUID/String ID. Restore không đổi ID.
