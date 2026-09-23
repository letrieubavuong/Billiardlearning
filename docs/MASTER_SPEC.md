# MASTER SPEC - Billiard Learning Studio v2

## 1. Mục tiêu sản phẩm

Xây dựng ứng dụng Flutter ưu tiên Android cho phép:
- tạo và tổ chức bài học billiard;
- dựng và lưu thế bi;
- dựng và lưu thế bi (Manual Scene Editor là workflow chính thức);
- vẽ đường ngắm, đường bi, điểm chạm, băng, diamond và annotation;
- chạy Teaching Animation theo đường giáo viên dựng;
- chạy Physics Simulation độc lập;
- xây dựng thư viện kỹ thuật;
- xây dựng các bộ số theo hướng data-driven;
- tạo bài luyện tập tương tác;
- import/export/backup nội dung;
- hoạt động local-first/offline.

## 2. Công nghệ

- Dart + Flutter.
- Android là nền tảng phát hành ưu tiên.
- Pure Dart cho Domain, Geometry, Teaching Core, Physics Core.
- SQLite local-first; giai đoạn migration có thể tiếp tục dùng `sqflite`.
- Media lưu file; DB giữ metadata/reference.
- Camera/vision: OUT OF ACTIVE SCOPE (không thuộc active roadmap; các DTO/interface cũ giữ nguyên độ tương thích).

## 3. Entity trung tâm

`BilliardScene` là entity trung tâm kết nối:
- Lesson
- Scene Editor (PRIMARY)
- Camera Capture (OUT OF ACTIVE SCOPE - giữ DTO compatibility)
- Teaching Simulation
- Physics Simulation
- Technique
- Number System examples
- Practice

Mọi nguồn tạo Scene đều quy về một format domain duy nhất.

## 4. Hai chế độ mô phỏng

### Teaching Mode
- đường chạy do người soạn dựng;
- engine nội suy theo trajectory/timeline;
- mục tiêu: minh họa sư phạm;
- không tự nhận là physics thực.

### Physics Mode
- input: cue direction, power, tip offset, cue elevation, table profile;
- engine tính motion, collision, cushion, friction, rolling/sliding, spin;
- output là simulation/replay data độc lập với renderer.

## 5. Cấu trúc bài học

`Course -> Chapter -> Lesson -> Section -> LessonBlock`

Block tham chiếu entity bằng ID khi cần:
- Text
- ImageReference
- VideoReference
- Formula
- Note
- SceneReference
- AnimationReference
- TechniqueReference
- NumberSystemReference
- ExerciseReference

## 6. Number System

Number System là domain riêng, không phải một Note.
Phải data-driven, có:
- stable ID;
- variables;
- expression/formula;
- mappings;
- conditions/corrections;
- examples;
- scene references.

## 7. Camera / Computer Vision Decision

Camera capture, table detection, perspective correction, ball detection và automatic scene reconstruction nằm ngoài active product scope hiện tại.

Manual Scene Editor là đường soạn thảo Scene chuẩn chính thức (PRIMARY).
Import JSON/package được hỗ trợ sau.
Camera reconstruction = OUT OF ACTIVE SCOPE.

## 8. Storage

- Stable IDs: UUID/String.
- Lesson/Scene: soft delete.
- Version history cho nội dung quan trọng.
- Media: asset entity + file path/checksum.
- Backup phải bao gồm DB + media + manifest.

## 9. Legacy compatibility

Repo cũ có giá trị ở:
- table renderer;
- drag/drop ball;
- trajectory editor;
- labels/angles/ghost ball;
- undo/redo;
- block editor UX;
- versioned codec idea;
- repository abstraction idea.

Nhưng phải migrate khỏi:
- `Note` làm Lesson/System/Technique;
- JSON scene nhúng trong `NoteBlock.content`;
- `DiagramSystem` enum hard-coded;
- hard delete integer IDs;
- animation giả physics trong painter;
- business state trong SharedPreferences.

## 10. Definition of Done chung

Một phase chỉ DONE khi:
- code build/analyze pass theo scope;
- tests liên quan pass;
- không phá phase trước;
- không tạo dependency ngược boundary;
- migration/compatibility được xử lý nếu schema đổi;
- acceptance criteria được báo PASS/FAIL rõ;
- không có TODO chặn nghiệp vụ chính của phase.
