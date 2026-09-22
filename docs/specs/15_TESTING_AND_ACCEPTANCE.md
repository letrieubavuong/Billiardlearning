# TESTING & ACCEPTANCE

## Test pyramid
- Pure Dart unit tests: domain/math/physics/number system.
- Repository/data tests: migrations, mapping, CRUD, soft delete.
- Widget tests: lesson/editor flows.
- Golden/render tests khi ổn định.
- Integration tests: import/export, camera pipeline contract, backup/restore.

## Architecture tests
Tự động kiểm tra khi practical:
- domain không import Flutter;
- physics không import Flutter/data/UI;
- renderer không import DB helper;
- feature UI không truy cập raw SQL.

## Legacy regression
Các editor gestures cũ đã có test nên được giữ hoặc port trước khi refactor sâu.

## Acceptance report
Mỗi phase báo PASS/FAIL từng tiêu chí, không dùng câu “done” chung chung.
