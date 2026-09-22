# SCENE EDITOR

## Chức năng bắt buộc

- Add ball.
- Delete ball.
- Drag ball.
- Multi-select.
- Duplicate.
- Lock position.
- Snap tùy chọn.
- Toggle diamond.
- Toggle labels.
- Add annotation.
- Undo/redo.
- Save/load scene.

## Gesture

- Tap: select.
- Drag ball: move selected ball.
- Drag background: pan khi ở navigation mode.
- Pinch: zoom.
- Long press: context action.

## Editor State

Không dùng trực tiếp Room state.
Nên có:
`SceneEditorState(scene, selection, viewport, tool, history)`

## Undo/Redo

Dùng command/history snapshot hợp lý.
Mọi thay đổi nội dung scene phải đi qua editor action để có thể undo.

## Validation

- Bi không được lưu ngoài playable area trừ khi author cố ý bật debug.
- Hai bi overlap phải cảnh báo.
- Scene vẫn lưu được nếu trajectory chưa hoàn chỉnh nhưng phải có trạng thái draft.
