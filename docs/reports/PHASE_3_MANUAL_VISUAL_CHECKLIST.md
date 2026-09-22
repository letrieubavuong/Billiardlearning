# PHASE 3 MANUAL VISUAL CHECKLIST

Tài liệu theo dõi trạng thái kiểm tra trực quan thủ công và kiểm tra tự động cho Phase 3 — Scene Renderer Refactor.

## 1. AUTOMATED TEST SUITE STATUS

| Hạng mục kiểm tra tự động | Trạng thái | Ghi chú |
|---|---|---|
| Viewport TablePoint(0,0) $\rightarrow$ top-left | PASS | `test/scene_viewport_test.dart` |
| Viewport TablePoint(1,1) $\rightarrow$ bottom-right | PASS | `test/scene_viewport_test.dart` |
| Viewport Inverse offsetToTablePoint round-trip | PASS | Tất cả 8 view modes pass |
| Viewport non-stretching per view mode boundaries | PASS | full, half, third, quarter, halfWidth... |
| Legacy coordinate conversion `Ball.at(2,6)` $\rightarrow$ `TablePoint(0.5, 0.75)` | PASS | `test/scene_render_model_test.dart` |
| Legacy coordinate conversion `(4,8)` $\rightarrow$ `TablePoint(1.0, 1.0)` | PASS | `test/scene_render_model_test.dart` |
| Legacy playback metric equality (2-diamond horizontal == vertical) | PASS | `test/scene_render_model_test.dart` |
| Domain degrees $\rightarrow$ renderer radians conversion | PASS | `test/scene_render_model_test.dart` |
| Hex color `#AARRGGBB` $\rightarrow$ Flutter `Color` parsing | PASS | `test/scene_render_model_test.dart` |
| Domain ghost ball (`ballType='ghost'`) $\rightarrow$ `isGhost=true`, `opacity=0.5` | PASS | `test/scene_renderer_smoke_test.dart` |
| Domain extra numbered ball (`ballType='extra'`, `label='7'`) $\rightarrow$ `type=2`, `text='7'` | PASS | `test/scene_renderer_smoke_test.dart` |
| Rendering layer DB isolation (0 sqflite/repo imports) | PASS | `test/architecture_test.dart` |
| Domain Pure Dart guard (0 Flutter UI imports) | PASS | `test/architecture_test.dart` |

---

## 2. HUMAN VISUAL CHECKLIST (HUMAN_REQUIRED / PENDING)

| STT | Item kiểm tra trực quan mắt người | Trạng thái | Ghi chú |
|---:|---|---|---|
| 1 | Full table view rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 2 | Half table view mode | HUMAN_REQUIRED | PENDING human teacher/user review |
| 3 | Third table view mode | HUMAN_REQUIRED | PENDING human teacher/user review |
| 4 | Quarter table view mode | HUMAN_REQUIRED | PENDING human teacher/user review |
| 5 | Half-width table view modes | HUMAN_REQUIRED | PENDING human teacher/user review |
| 6 | Vertical orientation rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 7 | Horizontal orientation rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 8 | White/Yellow/Red ball rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 9 | Ghost ball rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 10 | Extra/numbered ball rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 11 | Normal trajectory line rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 12 | Dashed trajectory line rendering | HUMAN_REQUIRED | PENDING human teacher/user review |
| 13 | Text labels & annotations | HUMAN_REQUIRED | PENDING human teacher/user review |
| 14 | Cushion numbers / DiagramSystem overlays | HUMAN_REQUIRED | PENDING human teacher/user review |
| 15 | Rotation of balls & labels | HUMAN_REQUIRED | PENDING human teacher/user review |
| 16 | DiagramSystem overlays (xohaibang, babangcha) | HUMAN_REQUIRED | PENDING human teacher/user review |
| 17 | Color parsing & indicator theme colors | HUMAN_REQUIRED | PENDING human teacher/user review |
| 18 | Fullscreen viewer integration | HUMAN_REQUIRED | PENDING human teacher/user review |
| 19 | Legacy animation visual behavior non-regression | HUMAN_REQUIRED | PENDING human teacher/user review |
