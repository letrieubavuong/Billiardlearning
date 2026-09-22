# COLLISION & CUSHION

## Ball-Ball Collision

Cần:
- continuous hoặc swept check nếu tốc độ cao gây tunneling;
- normal/tangent decomposition;
- restitution;
- optional tangential friction/spin coupling;
- penetration correction ổn định.

Acceptance cơ bản:
- head-on equal-mass collision cho vận tốc truyền đúng xu hướng;
- grazing collision cho hướng tách hợp lý;
- không tạo năng lượng vô lý;
- không rung vô hạn khi 2 bi gần nhau.

## Cushion Collision

Không dùng luật phản xạ hình học đơn giản cho mọi trường hợp.
Cushion model phải nhận:
- incoming velocity;
- contact normal;
- spin;
- cushion restitution;
- cushion friction.

Cần hỗ trợ calibration theo từng table profile.

## Event log

Mỗi collision ghi:
- timestamp
- participants
- contact point
- incoming velocity
- outgoing velocity
- relevant spin
