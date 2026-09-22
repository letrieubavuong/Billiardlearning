# TEACHING SIMULATION

## Mục tiêu
Trực quan hóa đúng ý người soạn, không phải giải phương trình vật lý.

## Input
- Scene
- authored trajectories
- timeline/events
- optional step text

## Output
- deterministic playback state
- replay samples/events

## Controls
- play/pause/restart
- scrub
- speed 0.25x/0.5x/1x/2x
- step-by-step

## Legacy migration
Logic nội suy/ease-out hiện có trong `billiard_diagram.dart` có thể được tái sử dụng sau khi tách khỏi painter và đặt tên đúng nghĩa.

## Bất biến
Teaching Simulation không được dùng làm bằng chứng physics accuracy.
