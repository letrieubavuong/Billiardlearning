# LEGACY AUDIT & ARCHITECTURE SUMMARY

## 1. Legacy Architecture Summary

The legacy Billiardlearning codebase is a Flutter application built around the legacy `Note` model and `NoteBlock` list structures. It uses SQLite (`sqflite`) for local note storage, combined with `SharedPreferences` for local configuration, user drafts, and progress state.

While the app features rich interactive billiard table rendering and diagram building capabilities, its legacy architecture exhibits high coupling between UI, data storage, interactive canvas painting, and pseudo-physics animations.

---

## 2. Legacy Stack

- **Framework:** Flutter 3.x / Dart 3.x
- **Target Platform:** Android (primary deployment target)
- **Database:** SQLite via `sqflite` (Database version 1 to 3 legacy, upgraded to v4 in Phase 1)
- **State & Storage:** `shared_preferences`, `path_provider`, `image_picker`, `youtube_player_flutter`
- **UI Architecture:** StatefulWidgets, InheritedWidgets, raw `CustomPainter` canvas rendering.

---

## 3. Legacy Domain Model

The legacy domain model in `lib/models/note_model.dart` revolves around:
- **`Note` (`lib/models/note_model.dart`):**
  - `id`: `int?` (Autoincrement primary key in SQLite)
  - `title`: `String`
  - `subtitle`: `String`
  - `blocks`: `List<NoteBlock>`
  - `date`: `DateTime` (Serialized to ISO-8601 String in SQLite)
  - `color`: `Color` (Serialized to ARGB int in SQLite)

> **Boundary Distinction:** `Note` model in Dart DOES NOT contain a `category` field. The `category` string (`'coban'`, `'boso'`, `'gombi'`, `'general'`) belongs exclusively to the SQLite persistence boundary (`notes.category` column) and repository parameters.

- **`NoteBlock`:**
  - `content`: `String` (Contains raw text, image file path, YouTube URL, or serialized diagram JSON string)
  - `type`: `BlockType` (enum index 0 to 13)

- **`BlockType` Enum & Index Mapping (`lib/models/note_model.dart`):**
  - `0` = `text`
  - `1` = `item`
  - `2` = `image`
  - `3` = `diagram`
  - `4` = `shotDetail`
  - `5` = `section`
  - `6` = `subSection`
  - `7` = `headingText`
  - `8` = `dataTable`
  - `9` = `iconText`
  - `10` = `youtube`
  - `11` = `effetDiagram`
  - `12` = `formula`
  - `13` = `animatedText`

---

## 4. Legacy Data Flow

```
[UI Screen / Editor] ──(Direct call)──> [DatabaseHelper / NoteRepository] ──(Raw SQL)──> [SQLite DB (notes table)]
         │
         ├──(JSON string parsing)──> [BilliardDiagram / NoteBlockRenderer]
         │
         └──(SharedPreferences)──> [Drafts / Custom Systems / Theme / Progress]
```

- **Coupling:** UI components directly query SQLite or parse embedded JSON strings inside `NoteBlock.content`.
- **Identity:** Relies on integer `id` assigned by SQLite autoincrement.

---

## 5. Legacy Persistence & SharedPreferences Keys

1. **SQLite (`lib/models/database_helper.dart`):**
   - Table `notes`: `id` (INTEGER PK AUTOINCREMENT), `category` (TEXT), `title` (TEXT), `subtitle` (TEXT), `blocks` (TEXT JSON), `date` (TEXT ISO-8601), `color` (INTEGER ARGB).
   - Table `app_metadata`: `key` (TEXT PK), `value` (TEXT).
2. **SharedPreferences Keys (Verified from Source Code):**
   - Draft notes: `note_draft_<id>` (for existing notes) and `note_draft_new` (for new drafts). (No category in key).
   - Theme settings: `selected_billiard_theme_id`.
   - Custom billiard systems: `custom_billiard_systems`.
   - Learning progress: `completed_learning_notes` storing a list of string values in format `"$category:$id"` (e.g., `"coban:1"`).

---

## 6. Legacy Editor & Renderers

- **`diagram_builder_page.dart` (~238 KB, ~5400 lines):**
  - Manages canvas state, tool selections, ball drag-and-drop, line/trajectory generation, snap-to-diamond logic, ghost ball placements, label insertion, undo/redo stack, and diagram JSON encoding/decoding.
- **`note_editor_page.dart` (~152 KB, ~3200 lines):**
  - Manages article block list editing, block reordering, draft autosaving via SharedPreferences, image picking, embedded diagram invocation, and saving to SQLite.

---

## 7. Legacy Rendering & Coordinate System

- **`billiard_diagram.dart` (~74 KB, ~2200 lines):**
  - Widget and `BilliardDiagramPainter` (`CustomPainter`).
  - Directly draws playfield, cushions, diamond markers, numbered rails, main balls, trajectory paths, velocity vectors, ghost balls, shot detail overlays, and labels.
- **Legacy Diamond Coordinates vs Normalized Coordinates:**
  - Authoring diamond units: `xDiamond ≈ 0..4` (short rail), `yDiamond ≈ 0..8` (long rail).
  - Renderer helper maps this as `Offset(xDiamond / 4, yDiamond / 4)`. This is a renderer-relative/aspect-preserving representation (`relativeX 0..1`, `relativeY 0..2` because table length is 2x width).
  - Target persistence model normalizes this into `TablePoint(u, v) ∈ [0,1] × [0,1]` where $u = x_{diamond} / 4$ and $v = y_{diamond} / 8$.

---

## 8. Legacy Animation

- Animation is executed inside `BilliardDiagramPainter` via a Flutter `AnimationController`.
- Interpolates ball positions step-by-step along user-drawn line segments.
- **Classification:** This animation is a **Teaching Simulation** (pedagogical trajectory interpolation), NOT a Physics Engine.

---

## 9. Legacy Number Systems & `DiagramSystem` Enum

- **Enum `DiagramSystem` (`lib/widgets/billiard_diagram.dart`):**
  - Exact enum values in code: `standard`, `diamond`, `short3Cushion`, `shortLongShort`, `xohaibang`, `babangcha`.
- **System Tier Distinction:**
  1. `DiagramSystem` enum: Visual rail diamond label overlay presets drawn on canvas.
  2. `SystemDefaultNotes` (`lib/models/system_notes.dart`): Hardcoded article/teaching content notes.
  3. `NumberSystem` vNext: Future data-driven mathematical business entity (`vnext_number_systems`).
- **Legacy Behavior:** Legacy codebase does NOT have a generic mathematical formula evaluator. Formulas are hardcoded text descriptions and fixed visual overlays.

---

## 10. Legacy ShotDetail

- **`ShotDetail` payload in `lib/widgets/shot_details.dart` / JSON:**
  - `thickness`: `double` (fraction of 8 parts, e.g. `4/8` = half ball)
  - `effet`: `Offset(x, y)` (tip contact point offset from `-1.0` to `1.0`)
  - `cueAngle`: `double` (cue elevation in degrees)
  - `forceImagePath`: `String?` (asset path string e.g. `"assets/images/Luc 1.png"` to `"assets/images/Luc 4.png"`)
- **Domain Gap:** Legacy `forceImagePath` represents discrete visual force preset images, NOT physical cue speed in $m/s$. This domain gap will be resolved in Phase 0 / Phase 15.

---

## 11. Legacy Media & Learning Progress

- **Media:** Images picked from gallery are copied to local app storage via `path_provider`. Raw file paths (e.g., `/data/user/0/.../image.jpg`) are stored inside `NoteBlock.content`.
  - **Risk:** No central media registry or SHA-256 checksum. SQLite DB backup alone omits local media files.
- **Learning Progress:** Tracked via `SharedPreferences` under key `completed_learning_notes` storing string items `"$category:$id"`.

---

## 12. Known Architecture Problems

1. **Large Legacy Files:** Overly large files (`diagram_builder_page.dart`, `note_editor_page.dart`, `billiard_diagram.dart`) combining state, UI, render, math, and data storage.
2. **Hardcoded Presets:** Closed enums for visual overlays and static arrays for number system articles.
3. **Embedded JSON:** Scene data embedded inside `NoteBlock.content` raw JSON strings instead of stable entity references.
4. **Hard Delete & Integer Identity:** Hard deletion by SQLite integer ID breaks progress links and cross-references.
5. **Mixed Simulation Concepts:** Pseudo-physics animations inside CustomPainter masquerading as physical simulation.

---

## 13. Reusable Legacy Capabilities (Must Not Be Discarded)

1. **Interactive Canvas Tools:** Ball dragging, velocity handles, control point creation, label overlays, angle markers, ghost balls.
2. **Diamond Snapping Math:** Precise snapping logic to rail diamond nodes.
3. **Block Editor UX:** Article block structure with drag-to-reorder, block deletion, collapse/expand, draft autosave.
4. **Undo/Redo & Timeline Controls:** CapCut-style step timeline editing and state undo/redo stack.

---

## 14. Technical Debt

- Widespread use of deprecated Flutter APIs (`withOpacity`, `Color.value`, `Color.red/green/blue`).
- Missing unit tests for geometry calculations and coordinate transforms.

---

## 15. Migration Constraints

- **Zero Data Loss:** Existing `notes` table data and SharedPreferences progress must remain completely intact.
- **Coexistence:** Legacy `notes` storage must operate in parallel with vNext `vnext_lessons`, `vnext_scenes`, etc., during the migration phase.
- **Pure Dart Core:** All new domain models, geometry algorithms, and physics models must be Pure Dart (no Flutter UI imports).
