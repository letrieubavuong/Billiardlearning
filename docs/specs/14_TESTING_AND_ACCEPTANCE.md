# TESTING & ACCEPTANCE

## Unit tests bắt buộc

### Geometry
- vector operations
- intersection
- projection
- angle normalization
- coordinate transforms

### Physics
- no-force motion
- friction deceleration
- stop threshold
- head-on collision
- grazing collision
- cushion reflection baseline
- energy sanity checks
- deterministic simulation

### Number System
- expression parse
- missing variable
- invalid range
- diamond mapping

### Persistence
- Room mapper
- migration
- export/import roundtrip

## Golden/UI tests nên có

- table rendering
- ball placement
- trajectory overlay
- spin selector

## Phase gate

Codex không được báo "hoàn thành phase" chỉ vì build pass.
Phải liệt kê acceptance criteria và trạng thái PASS/FAIL từng mục.
