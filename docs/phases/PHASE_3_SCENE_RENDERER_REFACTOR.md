# PHASE 3 - SCENE RENDERER REFACTOR

## Mục tiêu
Tách renderer khỏi billiard_diagram god-file theo incremental refactor.

## Spec bắt buộc đọc
- `docs/specs/04_SCENE_EDITOR.md`
- `docs/specs/14_FLUTTER_ARCHITECTURE.md`

## Deliverables
1. Table renderer
2. Ball renderer
3. Trajectory renderer
4. Annotation renderer
5. Scene renderer facade

## Không làm trong phase này
- Không đổi UX editor lớn
- Không thêm physics

## Acceptance Criteria
- [ ] Visual behavior chính không regression
- [ ] Renderer không truy cập DB
- [ ] Painter không chứa repository/business rules mới

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
