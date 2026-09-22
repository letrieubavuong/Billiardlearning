# SCENE EDITOR

## Chức năng
- create/open/save Scene;
- add/move/remove balls;
- chọn cue ball;
- trajectory/path tool;
- straight segment;
- contact/cushion marker;
- label/angle/annotation;
- ghost ball;
- snap diamond/grid optional;
- undo/redo;
- zoom/pan;
- duplicate Scene;
- preview Teaching Animation.

## Kiến trúc
Tách:
- `SceneEditorController`
- immutable `SceneEditorState`
- tool handlers
- command/history stack
- renderer
- persistence adapter

## Legacy reuse
Có thể tái sử dụng logic UX từ `diagram_builder_page.dart`, nhưng không giữ god-file 5000+ dòng làm kiến trúc đích.

## Save contract
Editor lưu `BilliardScene`, không trả raw JSON để nhét vào LessonBlock.
