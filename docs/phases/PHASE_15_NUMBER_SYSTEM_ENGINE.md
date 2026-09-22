# PHASE 15 - NUMBER SYSTEM ENGINE

## Mục tiêu
Cho phép tạo và chạy nhiều bộ số mà không viết code riêng từng bộ.

## Scope
- Definition editor/model.
- Variables.
- Safe expression parser/evaluator.
- Constraints.
- Diamond mapping.
- Example scenes.

## Không làm
- Không dùng arbitrary code eval.

## Acceptance Criteria
- Thêm system mới chỉ bằng data/model.
- Missing/invalid variable trả domain error, không crash.
- Formula tests pass.
- World position <-> system number mapping testable.
