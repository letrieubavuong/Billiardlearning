# PHASE 04 - TRAJECTORY MATHEMATICS

## Mục tiêu
Tạo nền toán hình học pure Kotlin dùng chung cho editor và physics.

## Scope
- Vec2 operations.
- Segment/ray/line.
- Projection.
- Distance point-segment.
- Intersections.
- Angle normalize/convert.
- Circle-line và circle-circle helpers khi cần.
- Cushion line/normal representation.

## Không làm
- Không vẽ trajectory UI.
- Không collision dynamics.

## Deliverables
- Geometry package.
- Unit tests cho edge cases.
- API naming/documentation ngắn.

## Acceptance Criteria
- Không phụ thuộc Android.
- Không NaN ở input hợp lệ.
- Có tolerance/epsilon strategy thống nhất.
- Test intersection/projection/angle pass.
