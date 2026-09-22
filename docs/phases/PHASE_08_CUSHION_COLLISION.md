# PHASE 08 - CUSHION COLLISION

## Mục tiêu
Xử lý va chạm bi-băng theo profile có thể calibration.

## Scope
- Cushion geometry.
- Contact normal.
- Restitution.
- Tangential friction baseline.
- Cushion event log.

## Không làm
- Chưa mô hình spin-băng đầy đủ; chỉ chuẩn bị interface.

## Acceptance Criteria
- Không spin: góc ra hợp lý theo baseline.
- Hệ số restitution thay đổi vận tốc ra có kiểm soát.
- Không dính/rung bi ở băng.
- Profile không hard-code trong resolver.
