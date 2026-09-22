# NUMBER SYSTEM ENGINE

## Mục tiêu

Cho phép định nghĩa các bộ số billiard bằng dữ liệu thay vì code riêng từng system.

## NumberSystemDefinition

- id
- name
- description
- category
- variables[]
- formula
- constraints[]
- diamondMapping
- recommendedSpin
- recommendedPowerRange
- exampleSceneIds[]

## Variable

- key
- label
- unit/type
- allowed range
- source: USER | DERIVED | TABLE

## Formula

Dùng expression model/parser có kiểm soát.
Không dùng eval tùy ý.

Ví dụ khái niệm:
`arrival = start - attack`

Nhưng công thức thực tế của từng bộ số do nội dung author định nghĩa.

## Diamond Mapping

Tách mapping hiển thị diamond khỏi physics coordinate.
System có thể ánh xạ world position <-> system number.

## Validation

- thiếu biến -> không tính;
- ngoài range -> warning/error theo rule;
- công thức lỗi -> không crash app;
- unit conversion phải rõ ràng.
