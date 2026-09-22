# TRAJECTORY ENGINE

## Mục tiêu

Cung cấp representation thống nhất cho:
- đường minh họa thủ công;
- kết quả physics;
- replay;
- so sánh lý thuyết với mô phỏng.

## Segment model

Mỗi segment cần tối thiểu:
- start
- end
- type
- duration optional
- eventAtEnd optional

Event ví dụ:
- BALL_COLLISION
- CUSHION_COLLISION
- STOP
- CUE_STRIKE

## Manual trajectory

Author có thể tạo đường nhiều điểm:
Ball -> point -> cushion -> cushion -> ball.

Manual trajectory không được bị physics engine tự ý chỉnh.

## Physics trajectory

Được sinh từ simulation sample/event log.
Có thể simplify để render nhưng phải giữ event points chính xác.

## Overlay

Cho phép render đồng thời:
- theoretical/manual path
- simulated path
- predicted ghost path

Mỗi loại phải phân biệt bằng style, không trộn dữ liệu.
