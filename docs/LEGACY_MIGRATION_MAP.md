# LEGACY MIGRATION MAP

This document specifies the exact mapping strategy from legacy data structures and storage representations to the vNext Pure Dart Domain entities and SQLite schemas.

---

## 1. `Note` → Target Domain Mapping

Legacy `Note` records stored in the SQLite `notes` table map to distinct vNext Domain entities depending on their category and content inspection:

```
                  ┌── Category: 'coban', 'general' ──> Lesson Entity (vnext_lessons)
                  │
Legacy Note ──────┼── Category: 'boso' ──────────────> NumberSystem Entity (vnext_number_systems)
(notes table)     │
                  ├── Category: 'gombi' ─────────────> Technique Entity (vnext_techniques)
                  │
                  └── Custom User Note ─────────────> Personal Note (Lesson in personal chapter)
```

| Legacy Category | Content Characteristics | vNext Target Entity | Primary Table |
| :--- | :--- | :--- | :--- |
| `coban` | Text + diagrams illustrating fundamentals | `Lesson` | `vnext_lessons` |
| `boso` | Diamond system formulas & numerical diamond positions | `NumberSystem` + `Lesson` | `vnext_number_systems` |
| `gombi` | Ball control, gathering techniques & cue spin instructions | `Technique` | `vnext_techniques` |
| `general` | General practice notes & user articles | `Lesson` (Personal Chapter) | `vnext_lessons` |

---

## 2. `NoteBlock` → Typed `LessonBlock` Mapping

Legacy `NoteBlock` instances embedded within `Note.blocks` JSON array map to type-safe `LessonBlock` sealed class variants in Pure Dart:

| Legacy `NoteBlock.type` | Legacy `content` Payload | vNext `LessonBlock` Variant | Target Payload Representation |
| :--- | :--- | :--- | :--- |
| `0` (`text`) | Plain markdown or styled text string | `TextBlock` | `text: String` |
| `1` (`image`) | Local filesystem image path string | `MediaReferenceBlock` | `mediaAssetId: StableId` (references `vnext_media_assets`) |
| `2` (`diagram`) | Embedded diagram JSON object string | `SceneReferenceBlock` | `sceneId: StableId` (references `vnext_scenes`) |
| `3` (`video`) | YouTube URL or video link string | `MediaReferenceBlock` | `mediaAssetId: StableId` (type: video URL) |
| `4` (`shotDetail`) | ShotDetail JSON string (spin, force, elevation) | `CueInstructionBlock` | `cueInstruction: CueInstruction` DTO |
| `5` (`formula`) | Mathematical system formula text | `FormulaBlock` | `expression: String` |

> **Constraint:** `LessonBlock` MUST NOT store raw inline diagram JSON. All diagram structures are extracted, saved into `vnext_scenes`, and referenced via a stable `sceneId` UUID.

---

## 3. Legacy Diagram JSON → `BilliardScene` Mapping

Legacy diagram JSON representations (produced by `diagram_builder_page.dart`) are mapped to the unified `BilliardScene` entity:

```json
// Legacy Diagram JSON Structure
{
  "version": 1,
  "system": "boSo50",
  "cueBall": {"x": 120.0, "y": 300.0},
  "objectBall1": {"x": 200.0, "y": 150.0},
  "objectBall2": {"x": 250.0, "y": 100.0},
  "lines": [...],
  "labels": [...]
}
```

Mapped to **`BilliardScene` Domain Entity**:

| Legacy Diagram JSON Property | Mapped `BilliardScene` Property | Domain Type | Mapping Transformation |
| :--- | :--- | :--- | :--- |
| `version` | `version` | `int` | Retained for schema migration tracking |
| `cueBall`, `objectBall1`, `objectBall2` | `balls` | `List<BallPlacement>` | Screen pixels converted to normalized `TablePoint(u,v)` |
| `lines` / `trajectories` | `trajectories` | `List<Trajectory>` | Polyline points converted to `TablePoint(u,v)` sequences |
| `labels` / text annotations | `annotations` | `List<Annotation>` | Position mapped to `TablePoint(u,v)` + `text` string |
| `angles` | `annotations` | `List<Annotation>` | Encoded as `AnnotationType.angle` |
| `ghostBall` | `balls` | `List<BallPlacement>` | Mapped with `isGhost: true` flag |
| `system` / rail overlay | `tableConfig` | `TableConfig` | Active system overlay ID stored in configuration |
| `shotDetail` | `cueInstruction` | `CueInstruction?` | Tip offset $(dx, dy)$, force %, elevation angle |

---

## 4. Coordinate Transformation Path

$$\text{LegacyDiamondCoordinate } (x_{diamond}, y_{diamond}) \quad (0..4 \text{ horizontal}, 0..8 \text{ vertical})$$
$$\downarrow \text{ (Normalize by 4 diamond units per short rail: } u = x/4, v = y/4)$$
$$\text{TablePoint } (u, v) \in [0,1] \times [0,1] \quad \text{--- PERSISTED IN DATABASE}$$
$$\downarrow \text{ (Multiply by physical table metrics: } 1.422m \times 2.844m)$$
$$\text{PhysicsWorld } (x_m, y_m) \text{ in meters} \quad \text{--- USED BY PHYSICS ENGINE}$$
$$\downarrow \text{ (Viewport scaling, y-axis orientation \& canvas transform)}$$
$$\text{ScreenCoordinate } (x_{screen}, y_{screen}) \text{ in pixels} \quad \text{--- USED BY RENDERER ONLY}$$

> **Critical Rule:** Canvas pixels (`ScreenCoordinate`) are NEVER persisted to SQLite. Only normalized `TablePoint(u,v)` values are stored in `vnext_scenes`.

---

## 5. `ShotDetail` → `CueInstruction` Mapping

Legacy `ShotDetail` JSON payload (cue ball contact point, force bar, tip spin):

| Legacy `ShotDetail` Field | `CueInstruction` Domain Field | Domain Unit / Range |
| :--- | :--- | :--- |
| `effetX` (range -1.0 to 1.0) | `tipOffset.x` | Normalized offset $[-1.0, 1.0]$ |
| `effetY` (range -1.0 to 1.0) | `tipOffset.y` | Normalized offset $[-1.0, 1.0]$ |
| `force` (range 0 to 100) | `cueSpeed` | Expressed as percentage or $m/s$ |
| `cueAngle` (degrees) | `cueElevation` | Radians / `Angle` Value Object |

---

## 6. Number System Mapping

- **Legacy Architecture:** Conflates visual presets (`DiagramSystem` enum), article notes (`SystemDefaultNotes.getBoSoNotes()`), and hardcoded math logic into a single monolithic implementation.
- **Target vNext Architecture:** Explicitly separates Number Systems into three distinct tiers:
  1. **Visual System Overlay / Preset (`TableConfig`):** Visual diamond labels and rail overlays drawn on `BilliardScene`.
  2. **Teaching Lesson Content (`Lesson` Entity):** Pedagogical article text, images, and diagrams explaining how to play the system.
  3. **NumberSystem Domain Entity (`vnext_number_systems`):** Data-driven mathematical evaluation entity:
     - `id`: Stable UUID
     - `name`: String (e.g., "Hệ thống Bộ Số 50 (Diamond System)")
     - `variables`: Input/output variable definitions (e.g., `Target = Origin - Cushion3`)
     - `expression`: Mathematical evaluation formula string
     - `mappings`: Numerical mappings along rail diamond positions
     - `conditions`: Correction rules and adjustments (e.g., speed, spin, cue elevation)
     - `exampleSceneIds`: List of reference `BilliardScene` UUIDs illustrating the system

---

## 7. Learning Progress Mapping

- **Legacy Representation:** Composite strings stored in `SharedPreferences` or app metadata under format `"category:intId"` (e.g., `"coban:3"`).
- **Target vNext Representation:** `vnext_learning_progress` SQLite table:
  - `id`: Stable UUID primary key
  - `entity_id`: Stable UUID of the target `Lesson`, `Technique`, or `NumberSystem` (`UNIQUE`)
  - `category`: Category identifier string
  - `is_completed`: Integer (`1` for completed, `0` for incomplete)
  - `completed_at`: ISO-8601 UTC timestamp string
- **Migration Strategy:** An automatic one-time migration maps legacy `"category:intId"` pairs to the newly generated stable UUID of the corresponding migrated entity.

---

## 8. Media Asset Mapping

- **Legacy Representation:** Raw local filesystem path strings (e.g., `/data/user/0/.../app_flutter/image_123.jpg`) embedded in `NoteBlock.content`.
- **Target vNext Representation:** Dedicated `MediaAsset` entity in SQLite `vnext_media_assets`:
  - `id`: Stable UUID (`mediaAssetId`)
  - `type`: String (`image`, `video`)
  - `local_path`: Relative or absolute filesystem path
  - `mime_type`: String (e.g., `image/jpeg`)
  - `size_bytes`: Integer
  - `checksum`: SHA-256 hash string for data verification & backup integrity
