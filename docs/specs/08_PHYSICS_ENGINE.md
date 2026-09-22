# PHYSICS ENGINE

## Boundary
Pure Dart. Không import Flutter UI.

## State tối thiểu
Mỗi ball simulation state có:
- position world units
- linear velocity
- angular velocity
- motion state
- mass/radius/material profile reference

## Subsystems
- geometry/math
- fixed time step
- motion integration
- ball-ball collision
- cushion collision
- cloth friction
- sliding/rolling transition
- spin decay/coupling
- cue strike model
- calibration/profile

## Accuracy goal
Mục tiêu là đủ tốt cho giảng dạy và phân tích, không tuyên bố 100% thực tế.

## Determinism
Cùng input + profile + timestep phải cho cùng output trong tolerance.

## Testing
Math/physics mới luôn có unit test; ưu tiên golden numeric cases và conservation/tolerance assertions.
