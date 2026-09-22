# SCENE & COORDINATE SYSTEM

## 1. Table Coordinate
Scene có thể lưu normalized coordinate:
- u in [0,1]
- v in [0,1]

Đây là coordinate mô tả vị trí tương đối trên vùng chơi.

## 2. Physics World
Physics không tính trực tiếp khoảng cách/góc trên normalized square nếu table có aspect ratio khác 1.
Chuyển:
`TablePoint(u,v) -> WorldPoint(xMeters,yMeters)`
dựa trên `TableGeometry`.

## 3. Screen Coordinate
Renderer chuyển:
`TablePoint/WorldPoint -> screen pixels`
và xử lý zoom/pan/orientation.

## 4. TableGeometry
- playfieldWidth
- playfieldHeight
- ballRadius
- cushion boundaries
- cushion normals
- diamond metadata
- table profile reference

## 5. Bất biến
- Không persist pixel.
- Không dùng Flutter `Offset` trong domain.
- Camera reconstruction trả TablePoint/domain model.
- Renderer là nơi duy nhất biết pixel/layout.
