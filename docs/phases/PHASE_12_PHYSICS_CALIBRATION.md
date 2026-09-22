# PHASE 12 - PHYSICS CALIBRATION

## Mục tiêu
Cho phép tinh chỉnh engine theo bàn/thực nghiệm thay vì sửa code.

## Scope
- SimulationProfile CRUD.
- Calibration shot schema.
- Real vs simulated comparison.
- Error metrics.
- Profile import/export.

## Dataset tối thiểu
- straight roll-down shots;
- cushion shots không spin;
- head-on/grazing ball collisions;
- follow/draw samples;
- side-spin cushion samples.

## Acceptance Criteria
- Thay profile không cần rebuild app.
- Có report sai số theo shot/dataset.
- Có profile mặc định versioned.
- Có test serialization roundtrip.
