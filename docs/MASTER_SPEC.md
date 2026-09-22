# MASTER SPEC - Billiard Lesson Studio

## 1. Mục tiêu sản phẩm

Xây dựng ứng dụng Android để:
- Soạn bài học billiard.
- Tạo và lưu thế bi.
- Minh họa đường ngắm, đường bi, điểm chạm, băng, diamond.
- Mô phỏng chuyển động bi theo vật lý.
- Xây dựng thư viện kỹ thuật và các bộ số.
- Tạo bài luyện tập tương tác.
- Cho phép so sánh đường lý thuyết với đường mô phỏng vật lý.

## 2. Nền tảng

- Android native.
- Kotlin.
- Jetpack Compose.
- Room cho dữ liệu local.
- Coroutines + Flow.
- Kiến trúc nhiều module hoặc package boundary rõ ràng.

## 3. Các engine lõi

### BilliardSceneEngine
Quản lý trạng thái bàn, bi, annotation, trajectory và các đối tượng trực quan.

### BilliardPhysicsEngine
Tính chuyển động, va chạm bi-bi, bi-băng, ma sát, rolling/sliding, spin.

### LessonEngine
Quản lý cấu trúc course/chapter/lesson/section/block.

### NumberSystemEngine
Quản lý công thức, biến, mapping diamond, ví dụ và tính toán của các bộ số.

### PracticeEngine
Quản lý đề bài, đáp án mẫu, lời giải và so sánh phương án người học.

## 4. Hai chế độ mô phỏng

### Teaching Mode
Đường chạy do người soạn quyết định. Animation chạy theo trajectory đã dựng.

### Physics Mode
Người dùng chọn hướng cơ, lực, điểm chạm, spin. Physics engine tự tính đường chạy.

Hai mode phải tồn tại độc lập nhưng dùng chung scene model.

## 5. Bất biến kiến trúc

- Physics engine không import Compose/View/Android UI.
- Rendering không chứa luật nghiệp vụ bài học.
- Domain model không phụ thuộc Room entity.
- Room entity không được dùng trực tiếp trong UI.
- Lesson không sở hữu logic vật lý; lesson chỉ tham chiếu scene/animation/system/technique.
- Number System phải data-driven, không `if(systemName == ...)`.
- Tọa độ lưu ở normalized coordinate `[0,1]`.
- Pixel chỉ tồn tại trong renderer/layout adapter.

## 6. Mức chính xác mục tiêu

Mục tiêu là đủ chính xác để giảng dạy và phân tích:
- Bi-bi: >= 95% xu hướng/kết quả hình học trong phạm vi mô hình.
- Bi-băng không spin: >= 95% sau calibration.
- Ma sát/rolling: >= 95% quãng đường trong bộ dữ liệu calibration.
- Follow/draw: khoảng 90-95%.
- Side spin + cushion: khoảng 88-93%.

Không tuyên bố 100% giống bàn thật.

## 7. Definition of Done chung

Một phase chỉ hoàn tất khi:
- Build thành công.
- Test liên quan pass.
- Không phá phase trước.
- Có sample/demo tối thiểu.
- Có migration nếu schema đổi.
- Tài liệu domain liên quan được cập nhật.
- Không còn TODO chặn nghiệp vụ chính của phase.
