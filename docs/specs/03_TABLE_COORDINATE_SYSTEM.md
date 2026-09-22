# TABLE COORDINATE SYSTEM

## Hệ tọa độ nghiệp vụ

Dùng normalized coordinate:
- x thuộc [0,1]
- y thuộc [0,1]

Gốc khuyến nghị: góc trái trên của vùng chơi nội bộ, hoặc gốc trái dưới nếu physics team thống nhất. Chỉ được chọn một quy ước và ghi cố định trong code/documentation.

Khuyến nghị cho physics: gốc trái dưới, +X sang phải, +Y hướng lên.
Renderer chịu trách nhiệm đảo trục Y khi vẽ lên Canvas Android.

## Không lưu pixel

Sai:
- ball.x = 463 px

Đúng:
- ball.x = 0.4123

## TableGeometry
Phải mô tả:
- playfield bounds
- cushion boundaries
- cushion normals
- diamond positions
- optional pocket metadata nếu mở rộng pool/snooker

## Mapping

WorldToScreenTransform:
- worldToScreen(Vec2)
- screenToWorld(Offset)
- zoom
- pan
- viewport padding

Physics engine chỉ biết world coordinate, không biết zoom/pan.
