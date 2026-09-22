# LEGACY MIGRATION MAP

This document specifies the exact mapping strategy from legacy data structures and storage representations to the vNext Pure Dart Domain entities and SQLite schemas.

---

## 1. `Note` → Target Domain Mapping

Legacy `Note` Dart instances (`lib/models/note_model.dart` with fields `id`, `title`, `subtitle`, `blocks`, `date`, `color`) are stored in the SQLite `notes` table along with a `category` column (`'coban'`, `'boso'`, `'gombi'`, `'general'`).

```
                  ┌── SQLite category: 'coban', 'general' ──> PLANNED Lesson Entity (vnext_lessons)
                  │
Legacy Note ──────┼── SQLite category: 'boso' ─────────────> PLANNED NumberSystem Entity (vnext_number_systems)
(notes table)     │
                  ├── SQLite category: 'gombi' ────────────> PLANNED Technique Entity (vnext_techniques)
                  │
                  └── Custom User Note ────────────────────> PLANNED Personal Note (Personal Chapter)
```

| SQLite `notes.category` | Legacy Content Characteristics | Target vNext Entity | Target SQLite Table | Current Implementation Status |
| :--- | :--- | :--- | :--- | :--- |
| `coban` | Text + diagrams illustrating fundamentals | `Lesson` | `vnext_lessons` | `vnext_lessons` schema ready (Phase 1) |
| `boso` | Diamond system formulas & numerical diamond positions | `NumberSystem` + `Lesson` | `vnext_number_systems` | `vnext_number_systems` schema ready (Phase 1) |
| `gombi` | Ball control, gathering techniques & cue spin instructions | `Technique` | `vnext_techniques` | `vnext_techniques` schema ready (Phase 1) |
| `general` | General practice notes & user articles | `Lesson` (Personal Chapter) | `vnext_lessons` | `vnext_lessons` schema ready (Phase 1) |

---

## 2. `NoteBlock` (`BlockType` 0..13) → Typed `LessonBlock` Mapping

Legacy `NoteBlock` instances (`type`: `BlockType`, `content`: `String`) embedded in `Note.blocks` JSON array map to type-safe `LessonBlock` variants.

```
0: text           ──> TextBlock (Available in Phase 1 Domain)
1: item           ──> PLANNED ItemBlock / CustomLessonBlock compatibility
2: image          ──> MediaReferenceBlock (Available in Phase 1 Domain)
3: diagram        ──> SceneReferenceBlock (Available in Phase 1 Domain)
4: shotDetail     ──> PLANNED CueInstructionBlock / CustomLessonBlock compatibility
5: section        ──> PLANNED SectionBlock / CustomLessonBlock compatibility
6: subSection     ──> PLANNED SubSectionBlock / CustomLessonBlock compatibility
7: headingText    ──> PLANNED HeadingBlock / CustomLessonBlock compatibility
8: dataTable      ──> PLANNED TableBlock / CustomLessonBlock compatibility
9: iconText       ──> PLANNED IconTextBlock / CustomLessonBlock compatibility
10: youtube       ──> MediaReferenceBlock (Available in Phase 1 Domain)
11: effetDiagram  ──> PLANNED EffetBlock / CustomLessonBlock compatibility
12: formula       ──> PLANNED FormulaBlock / CustomLessonBlock compatibility
13: animatedText  ──> PLANNED AnimatedTextBlock / CustomLessonBlock compatibility
```

| Index | `BlockType` Enum | Legacy Payload Description | Target `LessonBlock` Class | Status |
| :---: | :--- | :--- | :--- | :--- |
| **0** | `text` | Markdown / plain text string | `TextBlock` | **Available in Phase 1 Domain** |
| **1** | `item` | Bullet item list text string | PLANNED `ItemBlock` | *PLANNED TARGET (Phase 6)* |
| **2** | `image` | Local filesystem image path | `MediaReferenceBlock` | **Available in Phase 1 Domain** |
| **3** | `diagram` | Embedded diagram JSON string | `SceneReferenceBlock` | **Available in Phase 1 Domain** |
| **4** | `shotDetail` | ShotDetail JSON string | PLANNED `CueInstructionBlock` | *PLANNED TARGET (Phase 6)* |
| **5** | `section` | Chapter section heading string | PLANNED `SectionBlock` | *PLANNED TARGET (Phase 6)* |
| **6** | `subSection` | Sub-section heading string | PLANNED `SubSectionBlock` | *PLANNED TARGET (Phase 6)* |
| **7** | `headingText` | Styled heading text string | PLANNED `HeadingBlock` | *PLANNED TARGET (Phase 6)* |
| **8** | `dataTable` | Table data JSON string | PLANNED `TableBlock` | *PLANNED TARGET (Phase 6)* |
| **9** | `iconText` | Icon + text string | PLANNED `IconTextBlock` | *PLANNED TARGET (Phase 6)* |
| **10** | `youtube` | YouTube video URL string | `MediaReferenceBlock` | **Available in Phase 1 Domain** |
| **11** | `effetDiagram` | Spin diagram JSON string | PLANNED `EffetBlock` | *PLANNED TARGET (Phase 6)* |
| **12** | `formula` | Mathematical formula string | PLANNED `FormulaBlock` | *PLANNED TARGET (Phase 6)* |
| **13** | `animatedText` | Animated text script JSON string | PLANNED `AnimatedTextBlock` | *PLANNED TARGET (Phase 6)* |

> **Constraint:** `LessonBlock` MUST NOT store raw inline diagram JSON. All diagram structures are extracted into `vnext_scenes` and referenced via stable `sceneId` UUIDs.

---

## 3. Legacy Diagram JSON → `BilliardScene` Pipeline Boundary

Legacy diagram JSON documents (produced by `diagram_builder_page.dart` and encoded via `DiagramDocumentCodec`) pass through a clear architecture pipeline:

```text
Legacy Diagram JSON
        ↓
PLANNED LegacySceneImporter (Phase 4 / Phase 7)
        ↓
BilliardScene (Pure Dart Domain Entity)
        ↓
SceneMapper (Data Layer Mapper in lib/data/mappers/mappers.dart)
        ↓
SQLite Row Map (vnext_scenes Table)
```

### Real Legacy Diagram JSON Payload Keys:
```json
{
  "schemaVersion": 1,
  "system": 1,
  "viewType": 0,
  "white": [2.0, 6.0],
  "yellow": [1.5, 4.0],
  "red": [3.0, 2.0],
  "paths": {
    "white": [[2.0, 6.0], [1.0, 0.0]],
    "yellow": [],
    "red": [],
    "free": []
  },
  "freePathColors": [],
  "labels": [{"x": 2.0, "y": 6.0, "text": "Bi chủ", "color": 4294967295, "rotation": 0.0}],
  "cushionNumbers": [],
  "ghosts": [],
  "extraBalls": [],
  "effet": {"thickness": 0.5, "effet": [0.0, 0.5], "forceImage": "assets/images/Luc 2.png", "cueAngle": 15.0}
}
```

| Real Legacy JSON Key | Mapped `BilliardScene` Property | Domain Type | Mapping Transformation |
| :--- | :--- | :--- | :--- |
| `schemaVersion` | `version` | `int` | Retained for schema migration tracking |
| `white`, `yellow`, `red`, `extraBalls` | `balls` | `List<BallPosition>` | Legacy diamond coordinates `(x,y)` mapped to normalized `TablePoint(u,v)` where $u=x/4, v=y/8$ |
| `paths.white`, `yellow`, `red`, `free` | `trajectories` | `List<TrajectoryLine>` | Polyline points mapped to `TablePoint(u,v)` sequences |
| `labels`, `cushionNumbers` | `annotations` | `List<SceneAnnotation>` | Position mapped to `TablePoint(u,v)` + `text` string |
| `ghosts` | `balls` | `List<BallPosition>` | Mapped with `ballType: "ghost"` flag |
| `system` (`DiagramSystem` index) | `tableConfig` | `TableConfig` | Active system overlay ID stored in configuration |
| `effet` | `cueInstruction` | `CueInstruction?` | Tip offset $(dx, dy)$, power percentage |

---

## 4. Coordinate Transformation Path

Legacy code uses **Legacy Diamond Coordinates** ($x_{diamond} \approx 0..4$ on short rail, $y_{diamond} \approx 0..8$ on long rail). Renderer helper `Offset(x/4, y/4)` represents a renderer-relative/aspect-preserving ratio (`relativeX 0..1`, `relativeY 0..2`).

The vNext architecture formalizes the 4-tier strict coordinate pipeline:

$$\text{LegacyDiamondCoordinate } (x_{diamond}, y_{diamond}) \quad (0..4 \text{ short rail}, 0..8 \text{ long rail})$$
$$\downarrow \text{ (Normalize by rail diamond counts: } u = x/4, v = y/8)$$
$$\text{TablePoint } (u, v) \in [0,1] \times [0,1] \quad \text{--- PERSISTED IN DATABASE}$$
$$\downarrow \text{ (Multiply by physical table dimensions: } x_m = u \times \text{tableWidthMeters}, y_m = v \times \text{tableLengthMeters})$$
$$\text{PhysicsWorld } (x_m, y_m) \text{ in meters} \quad \text{--- USED BY PHYSICS ENGINE}$$
$$\downarrow \text{ (Viewport scaling, canvas orientation \& pan/zoom transform)}$$
$$\text{ScreenCoordinate } (x_{screen}, y_{screen}) \text{ in pixels} \quad \text{--- USED BY RENDERER ONLY}$$

> **Critical Rule:** Canvas pixels (`ScreenCoordinate`) are NEVER persisted to SQLite. Only normalized `TablePoint(u,v)` values are stored in `vnext_scenes`.

---

## 5. `ShotDetail` → `CueInstruction` Mapping & Current Domain Gaps

Legacy `ShotDetail` JSON payload vs Current `CueInstruction` Production Domain (`lib/domain/entities/entities.dart`):

| Legacy JSON Field | Legacy Data Type / Example | Current `CueInstruction` Field (`entities.dart`) | Current Domain Status |
| :--- | :--- | :--- | :--- |
| `effet[0]` | `double` (tip offset X -1.0 to 1.0) | `tipOffset.x` | **Mapped in Current Domain** |
| `effet[1]` | `double` (tip offset Y -1.0 to 1.0) | `tipOffset.y` | **Mapped in Current Domain** |
| `forceImage` | JSON key (e.g. `"assets/images/Luc 2.png"`) | `power: double` (normalized instructional power 0.0 to 1.0) | **DEFERRED DOMAIN GAP:** Numeric power mapping from asset path |
| `cueAngle` | `double` (cue elevation in degrees) | *None* (No cue elevation field in `CueInstruction`) | **DEFERRED DOMAIN GAP:** Deferred to Phase 15 |
| `thickness` | `double` (fraction of 8 parts, e.g. `4/8`) | *None* (No contact thickness field) | **DEFERRED DOMAIN GAP:** Deferred to Phase 6 |

> **JSON Persisted Field vs Flutter Widget Property & Power Contract:**
> - `forceImage`: JSON key stored inside legacy diagram/effet payloads (e.g. `"forceImage": "assets/images/Luc 2.png"`).
> - `forceImagePath`: Constructor property name in `ImpactIndicator` Flutter widget (`lib/widgets/shot_details.dart`).
> - `CueInstruction.power`: Represents **normalized instructional power** in range `[0.0, 1.0]` (`0.00` = zero, `0.25` = low, `0.50` = medium, `0.75` = high, `1.00` = normalized max). It is NOT physical cue speed ($m/s$) or percentage `[0, 100]`. Physical calibration belongs to Phase 15/16.

---

## 6. Number System Tier Distinction & Mapping

- **Legacy Architecture:** Conflates visual presets (`DiagramSystem` enum), article notes (`SystemDefaultNotes.getBoSoNotes()`), and hardcoded math logic into a single monolithic implementation.
- **Target vNext Architecture:** Explicitly separates Number Systems into three distinct tiers:
  1. **Visual System Overlay / Preset (`TableConfig`):** Visual diamond labels and rail overlays drawn on `BilliardScene` (`DiagramSystem` index: `standard`, `diamond`, `short3Cushion`, `shortLongShort`, `xohaibang`, `babangcha`).
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

## 7. Learning Progress Mapping & SharedPreferences Keys

- **Legacy Persistence:** Saved in `SharedPreferences` under key `completed_learning_notes` storing a string array of items in format `"$category:$id"` (e.g. `"coban:3"`).
- **Target vNext Representation:** `vnext_learning_progress` SQLite table:
  - `id`: Stable UUID primary key
  - `entity_id`: Stable UUID of target `Lesson`, `Technique`, or `NumberSystem` (`UNIQUE`)
  - `category`: Category identifier string
  - `is_completed`: Integer (`1` for completed, `0` for incomplete)
  - `completed_at`: ISO-8601 UTC timestamp string
- **PLANNED Progress Migrator:** A planned one-time migration utility reads `completed_learning_notes` from SharedPreferences and inserts corresponding rows into `vnext_learning_progress` matching the migrated entity UUIDs.

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
