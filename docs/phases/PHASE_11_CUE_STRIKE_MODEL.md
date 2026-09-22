# PHASE 11 - CUE STRIKE MODEL

## Mục tiêu
Chuyển input người dùng thành trạng thái đầu của cue ball.

## Scope
- Aim angle.
- Power.
- Contact X/Y.
- Mapping sang linear/angular velocity.
- Cue strike event.
- UI contract cho cue-ball contact selector.

## Acceptance Criteria
- Center hit cho side/top spin xấp xỉ 0.
- Off-center hit tạo angular velocity đúng dấu quy ước.
- Power tăng cho tốc độ đầu tăng đơn điệu.
- Mapping logic không nằm trong Composable.
