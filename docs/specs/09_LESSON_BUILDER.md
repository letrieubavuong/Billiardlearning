# LESSON BUILDER

## Cấu trúc

Course -> Chapter -> Lesson -> Section -> Block

## Block types

- Text
- Image
- Formula
- Note
- Scene
- Animation
- Technique
- NumberSystem
- Exercise

## Nghiệp vụ author

- add block
- edit block
- delete block
- duplicate block
- reorder block
- preview lesson
- attach existing scene
- clone scene before editing nếu muốn tách phiên bản

## Quy tắc tham chiếu

Lesson tham chiếu asset/scene qua ID.
Không nhúng object graph khổng lồ nếu gây duplication dữ liệu.

## Draft / Published

Lesson tối thiểu có trạng thái:
- DRAFT
- PUBLISHED
- ARCHIVED

Published lesson không được silently thay đổi scene shared nếu scene đó đang dùng ở nhiều lesson; cần copy/version hoặc xác nhận workflow sau này.
