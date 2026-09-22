# LEGACY MIGRATION

## Legacy sources hiện có
- `Note`
- `NoteBlock`
- `notes` SQLite table
- `SystemDefaultNotes`
- diagram JSON
- shot detail JSON
- `DiagramSystem`
- learning progress `category:id`
- `note_images`
- SharedPreferences custom systems/drafts

## Mapping mục tiêu
- Note category `coban` -> Lesson/Technique candidate
- Note category `gombi` -> Lesson/Technique candidate
- Note category `boso` -> Lesson + NumberSystem candidate
- diagram JSON -> BilliardScene
- shotDetail -> CueInstruction
- image path -> MediaAsset
- progress -> stable LessonId mapping table

## Migration strategy
1. Audit + fixture samples.
2. Tạo legacy decoder không phụ thuộc UI.
3. Map sang domain mới.
4. Persist vào schema mới.
5. Verify counts/content references.
6. Chỉ sau khi pass mới deprecate legacy write path.
7. Xóa legacy code ở phase riêng sau release/migration confidence.

## Không được
Không dùng regex/heuristic thiếu kiểm soát để tự suy luận toàn bộ bộ số từ prose. Trường nào không chắc phải đánh dấu `needsReview`.
