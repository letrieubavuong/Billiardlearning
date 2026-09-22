# ARCHITECTURE DECISIONS

## ADR-001: Giữ Flutter/Dart
Giữ Flutter app hiện tại, không rewrite Kotlin Native. Android vẫn là nền tảng phát hành ưu tiên.

## ADR-002: Pure Dart Core
Domain, geometry và physics không phụ thuộc Flutter UI.

## ADR-003: BilliardScene là entity trung tâm
Lesson, Camera, Teaching, Physics, Technique và Practice dùng chung Scene.

## ADR-004: Teaching != Physics
Animation theo path giáo viên dựng được giữ và đổi nghĩa thành Teaching Simulation. Physics Engine là subsystem khác.

## ADR-005: Stable UUID/String IDs
Không dùng integer autoincrement làm identity nghiệp vụ xuyên hệ thống.

## ADR-006: Soft Delete
Lesson/Scene không hard delete trong thao tác xóa thông thường.

## ADR-007: Number System data-driven
Không thêm enum/if theo từng tên bộ số.

## ADR-008: Table Coordinate tách Physics World
Scene có thể lưu normalized table coordinate `(u,v)` trong `[0,1]x[0,1]`. Physics chuyển sang world units/meter dựa trên `TableGeometry` trước khi tính khoảng cách/góc.

## ADR-009: Giữ sqflite trong migration
Không đổi sang Drift đồng thời với domain migration trừ khi có lý do kỹ thuật bắt buộc được ghi thành ADR mới.

## ADR-010: Media là entity
Ảnh/video có stable asset ID; backup bao gồm cả file media.
