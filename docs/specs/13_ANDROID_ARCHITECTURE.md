# ANDROID ARCHITECTURE

## Stack

- Kotlin
- Jetpack Compose
- Navigation Compose
- Room
- Coroutines
- Flow/StateFlow
- ViewModel

DI có thể dùng Hilt/Koin/manual DI nhưng phải thống nhất từ Phase 1.

## Boundary đề xuất

```
app/
core/
domain/
data/
simulation/
rendering/
feature-home/
feature-scene-editor/
feature-lesson/
feature-technique/
feature-number-system/
feature-practice/
```

Nếu chưa multi-module, vẫn phải giữ package boundary tương tự.

## UI state

UI chỉ nhận immutable UI state và phát action/event.
ViewModel chuyển action thành use case/repository call.

## Rendering

SceneRenderer nhận domain-friendly render model.
Không truy cập DB.
Không chứa business logic lesson.

## Performance

- Tránh recomposition toàn bàn khi một thuộc tính nhỏ đổi.
- Physics chạy ngoài main thread.
- Render path tối ưu allocation.
- Replay dùng data samples/event log, không rerun physics nếu chỉ xem lại.
