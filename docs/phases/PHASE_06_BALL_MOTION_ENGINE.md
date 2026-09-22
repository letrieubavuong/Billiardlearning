# PHASE 06 - BALL MOTION ENGINE

## Mục tiêu
Tạo simulation loop và chuyển động tự do baseline.

## Scope
- Fixed timestep.
- Simulation state.
- Linear integration.
- Start/stop/pause engine API.
- Event/sample recording baseline.

## Không làm
- Không ball-ball collision.
- Không cushion collision.
- Không spin.

## Acceptance Criteria
- Cùng input cho kết quả deterministic trong tolerance.
- UI FPS không quyết định physics timestep.
- Physics chạy ngoài main thread khi tích hợp app.
- Có test chuyển động thẳng không lực.
