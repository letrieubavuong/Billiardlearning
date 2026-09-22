# PHASE 0 - PURE DART DOMAIN FOUNDATION

## Mục tiêu
Tạo nền móng domain pure Dart và stable IDs, chưa migrate UI.

## Spec bắt buộc đọc
- `docs/specs/02_DOMAIN_MODEL.md`
- `docs/specs/03_SCENE_AND_COORDINATES.md`

## Deliverables
1. Value objects Vec2/TablePoint/WorldPoint/Angle
2. Stable ID strategy
3. Skeleton entities Scene/Lesson/Technique/NumberSystem/Exercise/MediaAsset
4. Repository interfaces
5. Unit tests domain

## Không làm trong phase này
- Không làm SQLite implementation lớn
- Không làm UI mới
- Không làm physics collision

## Acceptance Criteria
- [ ] Domain không import Flutter
- [ ] Có tests value objects
- [ ] Có sample Scene tạo được trong test
- [ ] Repository contracts không phụ thuộc sqflite

## Completion report
Báo Summary, Files changed, Migration impact, Tests, Acceptance PASS/FAIL, Manual test steps, Known limitations.
