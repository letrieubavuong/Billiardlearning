# ROADMAP TỔNG THỂ - FLUTTER v2

## Mốc A - Cứu repo cũ và dựng nền móng

### Phase -1 - Legacy Audit & Specification Reset
Audit toàn repo, lập KEEP/MIGRATE/REWRITE/REMOVE-LATER, cập nhật spec và migration map. Không làm feature mới.

### Phase 0 - Pure Dart Domain Foundation
Tạo domain/value objects/repository contracts thuần Dart.

### Phase 1 - Repository + SQLite Architecture
Tạo data entities/mappers/repository implementations và migration nền móng.

### Phase 2 - Scene Model + Coordinate System
Chốt BilliardScene, TableCoordinate, PhysicsWorld mapping.

### Phase 3 - Scene Renderer Refactor
Tách renderer khỏi widget/god-file cũ, không đổi UX lớn.

### Phase 4 - Scene Editor Migration
Tách controller/state/tools/history, chuyển diagram cũ sang Scene.

### Phase 5 - Teaching Trajectory + Animation
Giữ animation cũ nhưng chuyển thành Teaching Simulation rõ ràng.

## Mốc B - Lesson đúng nghiệp vụ

### Phase 6 - Lesson Domain + Lesson Builder
Course/Chapter/Lesson/Section/Block, CRUD, autosave, preview.

### Phase 7 - Scene Sharing + Versioning
Shared scene, clone-on-edit, version history, soft delete/restore.

## Mốc C - Camera Capture

### Phase 8A - Camera Infrastructure
Permissions, capture pipeline, image lifecycle.

### Phase 8B - Table Detection
Detect playfield/corners và manual corner correction.

### Phase 8C - Perspective Transform
Homography/perspective correction và mapping về table coordinate.

### Phase 8D - Ball Detection
Nhận diện bi carom đỏ/trắng/vàng + confidence.

### Phase 8E - Scene Reconstruction
DetectionResult -> BilliardScene + manual correction + save.

## Mốc D - Physics Core

### Phase 9 - Physics Geometry + Fixed Time Step
Pure Dart vector/math/time-step nền móng.

### Phase 10 - Ball Motion + Friction
Motion cơ bản, stop threshold, friction model v1.

### Phase 11 - Ball-Ball Collision
Detection + response + test cases.

### Phase 12 - Cushion Collision
Cushion geometry, restitution/friction v1.

### Phase 13 - Sliding + Rolling
State transitions và energy/spin coupling cơ bản.

### Phase 14 - Spin Engine
Top/bottom/side spin và decay.

### Phase 15 - Cue Strike Model
Cue input -> linear/angular velocity.

### Phase 16 - Physics Calibration
Table profile + experimental dataset + error metrics.

## Mốc E - Nội dung nâng cao

### Phase 17 - Number System Engine
Variables/formulas/mappings/corrections/examples data-driven.

### Phase 18 - Technique Library
Technique entity, tags, difficulty, scene references.

### Phase 19 - Practice Engine
Interactive task, reference solution, comparison/evaluation.

## Mốc F - Dữ liệu và release

### Phase 20 - Media + Package Import/Export
MediaAsset + package manifest + content dependencies.

### Phase 21 - Backup + Restore
Backup DB + media + manifest; validation/rollback.

### Phase 22 - Performance + Android Release
Profiling, large-screen UX, crash handling, release migration tests, signed Android build.

---

## Quy tắc chuyển phase

Không làm phase kế tiếp khi acceptance criteria quan trọng của phase hiện tại chưa đạt, trừ khi file phase ghi rõ có thể phát triển song song.
