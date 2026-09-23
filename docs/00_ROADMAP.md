# ROADMAP TỔNG THỂ - FLUTTER v2

## Camera / Computer Vision Decision

Camera capture, table detection, perspective correction,
ball detection and automatic scene reconstruction are
outside the current active product scope.

Manual Scene Editor is the canonical scene-authoring path.

Camera support may be reconsidered in a future roadmap,
but no active phase depends on it.

## Scene Creation & Editing Authoring Workflow

```text
Scene creation/editing:
Manual Scene Editor = PRIMARY

Import:
JSON/package = supported later

Camera reconstruction = OUT OF ACTIVE SCOPE
```

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

## Mốc C - Physics Core

### Phase 8 - Physics Geometry + Fixed Time Step
Pure Dart vector/math/time-step nền móng.

### Phase 9 - Ball Motion + Friction
Motion cơ bản, stop threshold, friction model v1.

### Phase 10 - Ball-Ball Collision
Detection + response + test cases.

### Phase 11 - Cushion Collision
Cushion geometry, restitution/friction v1.

### Phase 12 - Sliding + Rolling
State transitions và energy/spin coupling cơ bản.

### Phase 13 - Spin Engine
Top/bottom/side spin và decay.

### Phase 14 - Cue Strike Model
Cue input -> linear/angular velocity.

### Phase 15 - Physics Calibration
Table profile + experimental dataset + error metrics.

## Mốc D - Nội dung nâng cao

### Phase 16 - Number System Engine
Variables/formulas/mappings/corrections/examples data-driven.

### Phase 17 - Technique Library
Technique entity, tags, difficulty, scene references.

### Phase 18 - Practice Engine
Interactive task, reference solution, comparison/evaluation.

## Mốc E - Dữ liệu và release

### Phase 19 - Media + Package Import/Export
MediaAsset + package manifest + content dependencies.

### Phase 20 - Backup + Restore
Backup DB + media + manifest; validation/rollback.

### Phase 21 - Performance + Android Release
Profiling, large-screen UX, crash handling, release migration tests, signed Android build.

---

## Quy tắc chuyển phase

Không làm phase kế tiếp khi acceptance criteria quan trọng của phase hiện tại chưa đạt, trừ khi file phase ghi rõ có thể phát triển song song.
