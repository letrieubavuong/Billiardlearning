# PHASE 00 - DOMAIN ARCHITECTURE

## Mục tiêu

Tạo nền móng kiến trúc, chưa làm UI phức tạp và chưa làm physics thực tế.

## Công việc

1. Khởi tạo project/package/module boundaries.
2. Tạo các value object: Vec2, Vec3, Angle, NormalizedPoint.
3. Tạo domain models chính: BilliardScene, BallState, Trajectory, Lesson, Technique, NumberSystem, Exercise.
4. Tạo repository interfaces.
5. Tạo skeleton simulation/rendering interfaces.
6. Thiết lập conventions cho Result/Error.
7. Tạo test project/unit test baseline.

## Không làm

- Không làm collision engine.
- Không làm animation timeline.
- Không làm lesson editor UI.
- Không thêm cloud.

## Acceptance Criteria

- Project build thành công.
- Domain package không phụ thuộc Android UI.
- Không có Room annotation trong domain.
- Có unit test cho Vec2 cơ bản.
- Có sample tạo BilliardScene trong test.
- Có documentation package/module boundary.
