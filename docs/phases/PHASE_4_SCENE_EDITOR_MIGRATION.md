# PHASE 4 - SCENE EDITOR MIGRATION

## Mục tiêu
Chuyển diagram editor cũ sang SceneEditor state/controller/tools và save BilliardScene.

## Spec bắt buộc đọc
- `docs/specs/04_SCENE_EDITOR.md`

## Deliverables
1. SceneEditorState/Controller
2. Tool abstraction
3. Undo/redo command/history
4. Save/load scene repository
5. Port gesture tests

## Không làm trong phase này
- Không thêm Camera/Physics

## Acceptance Criteria
- [ ] Các thao tác editor cũ quan trọng vẫn pass
- [ ] Editor save Scene ID chứ không raw JSON block
- [ ] God-file giảm đáng kể hoặc có migration boundary rõ

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
