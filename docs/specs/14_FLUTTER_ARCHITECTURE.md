# FLUTTER ARCHITECTURE

## Package boundaries đề xuất

```text
lib/
  app/
  core/
  domain/
    lesson/
    scene/
    technique/
    number_system/
    practice/
    media/
    learning/
  simulation/
    teaching/
    physics/
  camera/
  rendering/
  data/
    database/
    repositories/
    mappers/
    import_export/
    legacy/
  features/
    home/
    lesson/
    scene_editor/
    camera_capture/
    technique/
    number_system/
    practice/
    settings/
```

## State management
Không bắt buộc đổi toàn bộ state management trong phase migration. Nhưng feature mới phải có controller/view-model boundary rõ và immutable state khi practical.

## Rendering
- CustomPainter/Canvas được phép ở rendering layer.
- Painter nhận render model/state; không chứa repository/SQL/physics rules.

## Native Android bridge
Chỉ dùng khi Flutter plugin không đủ cho Camera/OpenCV/TFLite/performance. Bridge phải trả DTO về adapter, sau đó map sang domain.
