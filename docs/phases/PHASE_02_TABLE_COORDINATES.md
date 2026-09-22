# PHASE 02 - TABLE COORDINATE SYSTEM

## Mục tiêu

Tạo hệ tọa độ chuẩn làm nền cho editor và physics.

## Công việc

- TableGeometry.
- WorldToScreenTransform.
- Normalize/denormalize.
- Zoom/pan transform.
- Diamond position generator.
- Unit tests roundtrip coordinate mapping.

## Acceptance Criteria

- Cùng scene render đúng trên nhiều kích thước màn hình.
- screenToWorld(worldToScreen(p)) sai số nhỏ.
- Physics/domain không chứa px/dp.
- Diamond giữ đúng vị trí tương đối khi zoom.
