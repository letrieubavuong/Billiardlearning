# LEGACY AUDIT & ARCHITECTURE SUMMARY

## 1. Legacy Architecture Summary

The legacy Billiardlearning codebase is a Flutter application built primarily around a single content abstraction called `Note`. It uses SQLite (`sqflite`) for local storage, combined with `SharedPreferences` for local configuration and draft state.

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

The legacy domain revolves around a single monolithic model:
- **`Note` (`lib/models/note_model.dart`):**
  - `id`: `int?` (Autoincrement primary key in SQLite)
  - `category`: `String` (`coban`, `boso`, `gombi`, `general`)
  - `title`: `String`
  - `subtitle`: `String?`
  - `blocks`: `List<NoteBlock>` (Serialized into raw JSON string inside SQLite column)
  - `date`: `String` (ISO-8601 timestamp)
  - `color`: `int` (ARGB color integer)

- **`NoteBlock`:**
  - `type`: `NoteBlockType` (enum: `text`, `image`, `diagram`, `video`, `shotDetail`, `formula`)
  - `content`: `String` (Contains raw text, image file path, YouTube URL, or serialized diagram JSON string)

---

## 4. Legacy Data Flow

```
[UI Screen / Editor] ──(Direct call)──> [DatabaseHelper / NoteRepository] ──(Raw SQL)──> [SQLite DB (notes table)]
         │
         ├──(JSON string parsing)──> [BilliardDiagram / NoteBlockRenderer]
         │
         └──(SharedPreferences)──> [Drafts / Custom Systems / Theme]
```

- **Coupling:** UI components directly query SQLite or parse embedded JSON strings inside `NoteBlock.content`.
- **Identity:** Relies on integer `id` assigned by SQLite autoincrement.

---

## 5. Legacy Persistence

1. **SQLite (`lib/models/database_helper.dart`):**
   - Table `notes`: `id` (INTEGER PK AUTOINCREMENT), `category` (TEXT), `title` (TEXT), `subtitle` (TEXT), `blocks` (TEXT JSON), `date` (TEXT), `color` (INTEGER).
   - Table `app_metadata`: `key` (TEXT PK), `value` (TEXT).
2. **SharedPreferences:**
   - Draft notes stored under keys `note_draft_<category>_<id>`.
   - Theme settings under `app_theme`.
   - Custom billiard diamond system definitions under `custom_billiard_systems`.

---

## 6. Legacy Editor

- **`diagram_builder_page.dart` (~238 KB, ~5600 lines):**
  - God-file managing canvas state, tool selections, ball drag-and-drop, line/trajectory generation, snap-to-diamond logic, ghost ball placements, label insertion, undo/redo stack, and diagram JSON encoding/decoding.
- **`note_editor_page.dart` (~152 KB, ~3200 lines):**
  - Manages article block list editing, block reordering, draft autosaving, image picking, embedded diagram invocation, and saving to SQLite.

---

## 7. Legacy Rendering

- **`billiard_diagram.dart` (~74 KB, ~2200 lines):**
  - Monolithic `BilliardDiagram` widget and `BilliardDiagramPainter` (`CustomPainter`).
  - Directly draws playfield, cushions, diamond markers, numbered rails, main balls (cue, target, object), trajectory paths, velocity vectors, ghost balls, shot detail overlays, and labels.
  - Blends rendering logic with canvas coordinate calculations and interactive hit-testing.

---

## 8. Legacy Animation

- Animation is executed inside `BilliardDiagramPainter` via a Flutter `AnimationController`.
- Interpolates ball positions step-by-step along user-drawn line segments.
- **Classification:** This animation is a **Teaching Simulation** (pedagogical trajectory interpolation), NOT a Physics Engine.

---

## 9. Legacy Number Systems

- **`system_notes.dart` & `bo_so_page.dart`:**
  - Hardcoded `DiagramSystem` enum (`tuDo`, `boSo50`, `gongBi`, etc.).
  - System formulas and diamond values are hardcoded in static Dart arrays (`SystemDefaultNotes.getBoSoNotes()`).
  - Formulas evaluated using hardcoded `if/switch` branching on system names.

---

## 10. Legacy Media

- Media (primarily images picked from gallery) are copied to local app storage via `path_provider`.
- Raw file paths (e.g., `/data/user/0/.../image.jpg`) are embedded directly inside `NoteBlock.content` JSON.
- **Risk:** No central media registry or checksum checking. SQLite backup does not include local media files, leading to missing images if files are moved or deleted.

---

## 11. Legacy Learning Progress

- **`learning_progress.dart`:**
  - Progress tracked using composite string keys: `category:intId` (e.g., `"coban:1"`, `"boso:12"`).
  - Saved in SharedPreferences or app metadata.

---

## 12. Known Architecture Problems

1. **God-Files:** Overly large files (`diagram_builder_page.dart`, `note_editor_page.dart`, `billiard_diagram.dart`) combining state, UI, render, math, and data storage.
2. **Hardcoded Systems:** Closed enums and switch-case logic for Number Systems preventing user-defined or data-driven expansion.
3. **Embedded JSON:** Scene data embedded inside `NoteBlock.content` raw JSON strings instead of stable entity references.
4. **Hard Delete & Integer Identity:** Hard deletion by SQLite integer ID breaks progress links and cross-references.
5. **Mixed Simulation Concepts:** Pseudo-physics animations inside CustomPainter masquerading as physical simulation.
6. **Coordinate Transformations:** Legacy models store positions using Legacy Diamond Coordinates (`Offset(x/4, y/4)` normalized relative to 4 short-rail diamond units), which `billiard_diagram.dart` scales to canvas screen pixels during rendering. The vNext architecture formalizes this into normalized `TablePoint(u,v)` in $[0,1]^2$ for DB persistence and `PhysicsWorld` metric units for physics calculations.

---

## 13. Valuable Reusable Components

1. **Diamond Snapping Math:** Precise snapping logic to rail diamond nodes.
2. **Interactive Canvas Tools:** Ball dragging, velocity handles, control point creation, label overlays.
3. **Block Editor UX:** Article structure with drag-to-reorder, block deletion, collapse/expand, draft autosave.
4. **Codec Versioning Concept:** Preserving schema version tags inside JSON payloads for migration.

---

## 14. Technical Debt

- Widespread use of deprecated Flutter APIs (`withOpacity`, `Color.value`, `Color.red/green/blue`).
- Missing unit tests for geometry calculations and coordinate transforms.
- High coupling between UI widgets and persistence layers.

---

## 15. Data-Loss Risks

- **Unlinked File Dependencies:** Local media file paths stored as plain text strings can break if local directories change.
- **SQLite Single File Backup:** Exporting SQLite DB alone omits media assets.
- **Hard Delete:** Permanently deletes notes and associated diagrams without recovery paths.

---

## 16. Migration Constraints

- **Zero Data Loss:** Existing `notes` table data and SharedPreferences progress must remain completely intact.
- **Coexistence:** Legacy `notes` storage must operate in parallel with vNext `vnext_lessons`, `vnext_scenes`, etc., during the migration phase.
- **Pure Dart Core:** All new domain models, geometry algorithms, and physics models must be Pure Dart (no Flutter UI imports).
