# PRACTICE ENGINE

## Dạng bài tập v1

1. Chọn đường đánh.
2. Chọn điểm chạm băng.
3. Chọn effet.
4. Chọn lực.
5. Chọn hệ thống số.
6. Dự đoán điểm đến.

## Exercise model

- initialScene
- prompt
- interactionType
- acceptedSolution
- tolerance
- hints
- explanation

## So sánh đáp án

Không chỉ exact equality.
Có thể dùng:
- angular tolerance
- endpoint distance tolerance
- cushion sequence equality
- spin range tolerance
- score weighted nhiều tiêu chí

## Feedback

Phải phân biệt:
- đường người học;
- đường đáp án;
- đường physics nếu chạy mô phỏng.

Không tự động phán "sai hoàn toàn" nếu chỉ lệch trong ngưỡng nhỏ.
