# PHYSICS ENGINE

## Mục tiêu

Physics engine 2D chuyên dụng cho billiard carom trước, có khả năng mở rộng.

## State mỗi bi

- position Vec2
- linearVelocity Vec2
- angularVelocity Vec3
- mass
- radius
- motionState: STATIONARY | SLIDING | ROLLING | SPINNING

## Simulation loop

Khuyến nghị fixed time step.
Ví dụ 1/240 s hoặc giá trị được benchmark.
Không dùng frame time UI làm bước vật lý trực tiếp.

## Pipeline mỗi step

1. Apply cloth forces/friction.
2. Integrate position/rotation.
3. Detect ball-ball contacts.
4. Resolve ball-ball collisions.
5. Detect cushion contacts.
6. Resolve cushion collisions.
7. Correct penetration.
8. Update motion states.
9. Record significant events.
10. Stop balls dưới threshold.

## Determinism

Cùng input + cùng SimulationProfile phải cho kết quả gần như giống nhau trên cùng engine version.

## SimulationProfile

Các hệ số không hard-code toàn cục:
- ballRadius
- ballMass
- ballRestitution
- clothSlidingFriction
- clothRollingResistance
- spinDecay
- cushionRestitution
- cushionFriction
- stopLinearThreshold
- stopAngularThreshold

## Không được

- Physics phụ thuộc Canvas.
- Physics gọi ViewModel.
- Physics dùng pixel.
- UI tự tính collision.
