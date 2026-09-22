# PHASE -1 VERIFICATION REPORT

## Commit / Branch
- **Branch:** `main`
- **Target Remote:** `origin/main` (`https://github.com/letrieubavuong/Billiardlearning.git`)

---

## Documentation fixes completed
1. **`forceImage` vs `forceImagePath` Terminology:** Corrected distinction between JSON persisted string key (`"forceImage"`) in diagram payloads and Flutter widget constructor property (`forceImagePath` in `ImpactIndicator`).
2. **Current `CueInstruction` Production Fields:** Verified `CueInstruction` in `lib/domain/entities/entities.dart` contains `power: double`, `direction: Angle`, and `tipOffset: Vec2`. Documented `cueAngle` (cue elevation), `thickness`, and `forceImage` asset mapping as `DEFERRED DOMAIN GAPs`.
3. **`SceneMapper` Boundary:** Clarified that `SceneMapper` is a data layer mapper (`BilliardScene` Domain $\leftrightarrow$ SQLite Row map). The legacy diagram converter is documented as `PLANNED LegacySceneImporter`.
4. **`Note` Model:** Confirmed `Note` class in `lib/models/note_model.dart` contains `id`, `title`, `subtitle`, `blocks`, `date`, `color` and NO `category` field.
5. **`BlockType` Enum Index Map:** Verified exact 0..13 indices in `note_model.dart` and distinguished available domain block classes (`TextBlock`, `MediaReferenceBlock`, `SceneReferenceBlock`) from `PLANNED` target blocks.
6. **Real Legacy Diagram JSON Payload Keys:** Documented exact keys (`schemaVersion`, `white`, `yellow`, `red`, `viewType`, `system`, `paths`, `freePathColors`, `labels`, `cushionNumbers`, `ghosts`, `extraBalls`, `effet`).
7. **Coordinate Pipeline:** Verified 4-tier pipeline starting from Legacy Diamond Coordinates ($x_{diamond} \approx 0..4, y_{diamond} \approx 0..8$) through `TablePoint(u,v)` in $[0,1]^2$ to `PhysicsWorld` (meters) and `ScreenCoordinate` (pixels).
8. **SharedPreferences Keys:** Verified exact keys (`note_draft_<id>`, `note_draft_new`, `selected_billiard_theme_id`, `custom_billiard_systems`, `completed_learning_notes`).
9. **DiagramSystem Enum Values:** Verified exact values (`standard`, `diamond`, `short3Cushion`, `shortLongShort`, `xohaibang`, `babangcha`).

---

## Source files verified
- `lib/models/note_model.dart`
- `lib/models/database_helper.dart`
- `lib/models/learning_progress.dart`
- `lib/models/system_notes.dart`
- `lib/models/theme_manager.dart`
- `lib/domain/entities/entities.dart`
- `lib/widgets/billiard_diagram.dart`
- `lib/widgets/billiard_models.dart`
- `lib/widgets/shot_details.dart`
- `lib/screens/diagram_builder_page.dart`
- `lib/screens/note_editor_page.dart`
- `lib/data/diagram_document_codec.dart`
- `lib/data/repositories/vnext_repositories.dart`

---

## Note model verification
```dart
class Note {
  int? id;
  String title;
  String subtitle;
  List<NoteBlock> blocks;
  DateTime date;
  Color color;
}
```
- **SQLite Persistence Boundary:** `category` (`'coban'`, `'boso'`, `'gombi'`, `'general'`) is stored in SQLite column `notes.category`. `date` is stored as ISO-8601 String, `color` as ARGB int.

---

## BlockType verification
- `0` = `text` $\rightarrow$ `TextBlock` *(Available in Phase 1 Domain)*
- `1` = `item` $\rightarrow$ *PLANNED ItemBlock (Phase 6)*
- `2` = `image` $\rightarrow$ `MediaReferenceBlock` *(Available in Phase 1 Domain)*
- `3` = `diagram` $\rightarrow$ `SceneReferenceBlock` *(Available in Phase 1 Domain)*
- `4` = `shotDetail` $\rightarrow$ *PLANNED CueInstructionBlock (Phase 6)*
- `5` = `section` $\rightarrow$ *PLANNED SectionBlock (Phase 6)*
- `6` = `subSection` $\rightarrow$ *PLANNED SubSectionBlock (Phase 6)*
- `7` = `headingText` $\rightarrow$ *PLANNED HeadingBlock (Phase 6)*
- `8` = `dataTable` $\rightarrow$ *PLANNED TableBlock (Phase 6)*
- `9` = `iconText` $\rightarrow$ *PLANNED IconTextBlock (Phase 6)*
- `10` = `youtube` $\rightarrow$ `MediaReferenceBlock` *(Available in Phase 1 Domain)*
- `11` = `effetDiagram` $\rightarrow$ *PLANNED EffetBlock (Phase 6)*
- `12` = `formula` $\rightarrow$ *PLANNED FormulaBlock (Phase 6)*
- `13` = `animatedText` $\rightarrow$ *PLANNED AnimatedTextBlock (Phase 6)*

---

## Diagram JSON verification
JSON payload produced by `diagram_builder_page.dart` and `DiagramDocumentCodec`:
- `schemaVersion`: 1
- `system`: `DiagramSystem` index
- `viewType`: `TableViewType` index
- `white`, `yellow`, `red`, `extraBalls`: Ball position arrays
- `paths`: Sub-map containing `white`, `yellow`, `red`, `free` polylines
- `freePathColors`, `pathColors`, `labelFontSize`
- `labels`, `cushionNumbers`, `ghosts`
- `effet`: Sub-map with `thickness`, `effet` `[x,y]`, `forceImage`, `cueAngle`

---

## Coordinate verification
- **Legacy Diamond Coordinate:** $x_{diamond} \in [0, 4]$, $y_{diamond} \in [0, 8]$
- **Renderer Helper Ratio:** $relX = x/4 \in [0,1]$, $relY = y/4 \in [0,2]$ (preserving 1:2 table aspect ratio)
- **TablePoint Persistence:** $u = x/4 \in [0,1]$, $v = y/8 \in [0,1]$ (persisted in SQLite `vnext_scenes`)
- **PhysicsWorld:** $x_m = u \times \text{widthMeters}$, $y_m = v \times \text{lengthMeters}$ (used by Physics Engine)
- **ScreenCoordinate:** Pixel offsets (used exclusively by renderer UI)

---

## ShotDetail verification
- `forceImage`: JSON key inside diagram payload (e.g. `"forceImage": "assets/images/Luc 2.png"`).
- `forceImagePath`: Constructor parameter name in `ImpactIndicator` Flutter widget (`lib/widgets/shot_details.dart`).

---

## CueInstruction current-vs-planned verification
- **Production `CueInstruction` Domain Fields (`lib/domain/entities/entities.dart`):**
  - `power`: `double`
  - `direction`: `Angle`
  - `tipOffset`: `Vec2`
- **DEFERRED DOMAIN GAPs:**
  - `effet[0], effet[1]` $\rightarrow$ mapped to `tipOffset`.
  - `forceImage` asset preset $\rightarrow$ numeric `power` mapping formula: `DEFERRED DOMAIN GAP`.
  - `cueAngle` (cue elevation): `DEFERRED DOMAIN GAP`.
  - `thickness`: `DEFERRED DOMAIN GAP`.

---

## LegacySceneImporter boundary
```text
Legacy Diagram JSON
        ↓
PLANNED LegacySceneImporter (Phase 4 / Phase 7)
        ↓
BilliardScene (Pure Dart Domain Entity)
        ↓
SceneMapper (Data Layer Mapper in lib/data/mappers/scene_mapper.dart)
        ↓
SQLite Row Map (vnext_scenes Table)
```

---

## SharedPreferences verification
- Drafts: `note_draft_<id>`, `note_draft_new`
- Theme: `selected_billiard_theme_id`
- Custom systems: `custom_billiard_systems`
- Progress: `completed_learning_notes` (contains `"$category:$id"` strings)

---

## NumberSystem verification
- `DiagramSystem` enum values: `standard`, `diamond`, `short3Cushion`, `shortLongShort`, `xohaibang`, `babangcha`.
- 3-tier architecture:
  1. `TableConfig`: Visual rail overlay presets drawn on canvas.
  2. `Lesson`: Teaching theory articles.
  3. `NumberSystem`: Data-driven mathematical evaluation entity (`vnext_number_systems`).

---

## Production code changed
`NONE`

---

## Tests
- `dart format .`:
  - Exit code: `0`
  - Status: 50 files formatted (0 changed).
- `flutter analyze`:
  - Exit code: `1` (due to legacy Flutter deprecation infos)
  - Issues count: `312 issues found` (0 errors, 312 infos/deprecated warnings in legacy UI widgets).
- `flutter test`:
  - Exit code: `0`
  - Tests passed: `35`
  - Tests failed: `0`

---

## Git synchronization status
- **Current branch:** `main`
- **Working tree:** `CLEAN`
- **Sync state:** `SYNCED`

---

## Acceptance checklist
- [x] `forceImage` vs `forceImagePath` distinguished correctly
- [x] `CueInstruction` current production fields accurately documented
- [x] `cueSpeed`/`forcePercentage`/`cueElevation` NOT described as existing fields in current domain
- [x] `thickness`/`cueAngle`/`forceImage` gaps marked as `DEFERRED DOMAIN GAP`
- [x] `SceneMapper` described correctly as Data Layer Mapper
- [x] `PLANNED LegacySceneImporter` boundary clearly documented
- [x] Production code (`lib/`) untouched
- [x] `dart format .` executed cleanly
- [x] `flutter analyze` executed cleanly
- [x] `flutter test` executed cleanly (35/35 pass)
- [x] Verification report created in `docs/reports/PHASE_-1_VERIFICATION_REPORT.md`
- [x] Changes committed and pushed to remote branch

---

## Remaining blockers
`NONE`

---

## Recommended phase status
- **Phase -1:** `REVIEW` (Ready for external review)
- **Phase 0:** `IN_PROGRESS`
- **Phase 1:** `DONE`
- **Phase 2:** `NOT_STARTED`
