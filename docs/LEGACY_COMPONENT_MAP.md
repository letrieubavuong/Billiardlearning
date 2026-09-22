# LEGACY COMPONENT MAP

This document classifies every legacy component and file in the codebase into one of five decisions:
- **KEEP:** Retained as-is or as foundational infrastructure.
- **ADAPT:** Modified or wrapped via staged extraction / facade pattern to interface with vNext domain structures without discarding proven UX/math.
- **MIGRATE:** Converted into vNext data entities / domain structures via importer tools.
- **REWRITE:** Rebuilt from scratch ONLY when no reusable legacy math/UX exists.
- **REMOVE-LATER:** Maintained during backward-compatibility phase, scheduled for removal ONLY after migration, parity tests, and vNext features pass.

> **Refinement Strategy:** Large legacy components (`billiard_diagram.dart`, `diagram_builder_page.dart`, `note_editor_page.dart`, `bo_so_page.dart`) are marked **ADAPT** (Staged Extraction + Facade Pattern). Proven UX behaviors (ball dragging, snapping to diamonds, path editing, free paths, labels, angles, ghost balls, undo/redo, gesture handling, timeline track editor) MUST BE PRESERVED and extracted into modular controllers/renderers.

---

## Component Classification Table

| Component/File | Current Role | Decision | Target | Staged Extraction & Parity Strategy |
| :--- | :--- | :---: | :--- | :--- |
| `lib/models/database_helper.dart` | SQLite helper & legacy DB open | **ADAPT** | Data layer helper (vNext + legacy co-existence) | Houses legacy `notes` table & v4 migrations. Must not call domain methods directly. |
| `lib/models/note_model.dart` | Legacy `Note` (`id`, `title`, `subtitle`, `blocks`, `date`, `color`) & `NoteBlock` (`content`, `type`) | **REMOVE-LATER** | PLANNED `Lesson`, `Technique`, `NumberSystem`, `Personal Note` | Kept for backward compatibility. **Replacement:** vNext Domain entities. **Migration Dependency:** PLANNED `LegacyNoteImporter` in Phase 6/17/18. |
| `lib/models/system_notes.dart` | Hardcoded default notes & number system content | **REMOVE-LATER** | Seed data / `NumberSystem` & `Lesson` entities | Hardcoded `getBoSoNotes()`. **Replacement:** SQLite seed migrations or JSON packages. **Migration Dependency:** Phase 17. |
| `lib/models/learning_progress.dart` | Legacy progress tracker (`completed_learning_notes` storing `"$category:$id"`) | **MIGRATE** | `LearningProgressRecord` (`vnext_learning_progress`) | Legacy string keys mapped to stable entity IDs via migration script. |
| `lib/models/note_draft.dart` | SharedPreferences draft storage (`note_draft_<id>`, `note_draft_new`) | **ADAPT** | Local draft cache / vNext `Lesson` draft repository | Adapted to store draft `Lesson` JSON structures. |
| `lib/models/image_block_data.dart` | Image metadata container | **MIGRATE** | `MediaAsset` entity | Maps raw image paths to `MediaAsset` with checksum and size bytes. |
| `lib/models/theme_manager.dart` | App theme & font scaling state (`selected_billiard_theme_id`) | **KEEP** | App UI Infrastructure | Retained for global UI theme configuration. |
| `lib/widgets/billiard_diagram.dart` | Monolithic widget & `CustomPainter` rendering table & balls | **ADAPT** | `SceneRenderer` (Phase 3) | **Staged Extraction:** Extract pure rendering math into `SceneRenderer` while preserving canvas drawing of balls, paths, labels, angles, ghost balls, and timeline animation. |
| `lib/widgets/billiard_models.dart` | Legacy diagram DTOs (`Ball`, `BallPath`, `BilliardLabel`, `BilliardAngle`, `ParsedBilliardLayout`) | **MIGRATE** | `BilliardScene`, `BallPlacement`, `Trajectory`, `Annotation` | Legacy diamond coordinates `Offset(x/4, y/4)` mapped to `TablePoint(u,v)` via PLANNED `LegacySceneImporter`. (Data layer `SceneMapper` handles `BilliardScene` ↔ SQLite Row). |
| `lib/screens/diagram_builder_page.dart` | Diagram editor UI & interactive state (~5400 lines) | **ADAPT** | `SceneEditor` (Phase 4) | **Staged Extraction:** Extract state management into `SceneEditorController` while preserving proven interaction tools (ball dragging, snap diamond, free paths, labels, angles, undo/redo). |
| `lib/screens/note_editor_page.dart` | Article block list editor UI (~3200 lines) | **ADAPT** | `LessonBuilder` (Phase 6) | **Staged Extraction:** Extract block list state into `LessonBuilderController` while preserving drag-to-reorder, block deletion, collapse/expand, and draft autosave UX. |
| `lib/widgets/shot_details.dart` | Cue strike / effet input widget (`thickness`, `effet`, `cueAngle`, widget property `forceImagePath` / JSON key `forceImage`) | **ADAPT** | `CueInstructionWidget` | UX retained, data output mapped to `CueInstruction` domain value object. |
| `lib/widgets/note_block_renderer.dart` | Renders article blocks | **ADAPT** | `LessonBlockWidget` | Adapted to render type-safe `LessonBlock` variants. |
| `lib/widgets/article_blocks.dart` | Article block UI implementations | **ADAPT** | `LessonBlock` UI components | Reuses layout and styling for vNext lesson content blocks. |
| `lib/widgets/note_image_block.dart` | Image block UI | **ADAPT** | `MediaReferenceBlockWidget` | Updated to display images via `MediaAsset` entity. |
| `lib/widgets/animated_article_block.dart` | Micro-animation wrapper for blocks | **KEEP** | UI Animation Utility | Reusable widget for card entrance animations. |
| `lib/widgets/animated_text_widget.dart` | Typewriter/fade text animation | **KEEP** | UI Component | Reusable typography widget. |
| `lib/widgets/youtube_player_widget.dart` | Embedded YouTube player | **KEEP** | UI Component | Reusable media playback widget. |
| `lib/screens/home_page.dart` | Main dashboard & navigation drawer | **ADAPT** | `MainNavigationScreen` | Navigates to both legacy and vNext screens during migration. |
| `lib/screens/bo_so_page.dart` | Number system list screen | **ADAPT** | `NumberSystemLibraryScreen` (Phase 17) | **Staged Extraction:** Adapt list UI to display data-driven `NumberSystem` entities loaded from `SqliteNumberSystemRepository`. |
| `lib/screens/co_ban_page.dart` | Basic lessons list screen | **ADAPT** | `LessonCategoryScreen` | Loads both legacy `Note` and vNext `Lesson` items. |
| `lib/screens/gom_bi_page.dart` | Carom gathering techniques screen | **ADAPT** | `TechniqueCategoryScreen` | Displays techniques loaded from `SqliteTechniqueRepository`. |
| `lib/screens/ghi_chu_page.dart` | Personal notes screen | **ADAPT** | `PersonalNotesScreen` | Handles user-created personal notes. |
| `lib/screens/article_detail_page.dart` | Article reader screen | **ADAPT** | `LessonDetailScreen` | Reads type-safe `Lesson` and renders associated scenes. |
| `lib/screens/effet_diagram_builder_page.dart` | Spin/effet diagram editor screen | **ADAPT** | `CueInstructionEditorScreen` | Wraps spin point and cue angle creation UI. |
| `lib/screens/shot_detail_builder_page.dart` | Shot detail creation dialog | **ADAPT** | `CueInstructionDialog` | UI retained, outputs `CueInstruction`. |
| `lib/screens/welcome_page.dart` | Splash & welcome screen | **KEEP** | UI Screen | Retained as-is. |
| `lib/data/database/database_migrations.dart` | Central production SQLite migrations | **KEEP** | Core Data Infrastructure | Manages v1->v4+ database upgrades. |
| `lib/data/database/vnext_tables.dart` | DDL schema for vNext SQLite tables | **KEEP** | Core Data Infrastructure | Defines 8 vNext tables and indexes. |
| `lib/data/repositories/vnext_repositories.dart` | SQLite repository implementations | **KEEP** | Data Layer | Implements safe UPSERT & soft-delete for vNext entities (`SceneMapper` in `lib/data/mappers/mappers.dart` maps `BilliardScene` ↔ SQLite Row). |

---

## Detailed REMOVE-LATER Justification Summary

1. **`Note` & `NoteBlock` (`lib/models/note_model.dart`):**
   - **Replacement:** Pure Dart domain entities `Lesson`, `Technique`, `NumberSystem`.
   - **Migration Dependency:** PLANNED `LegacyNoteImporter` utility executed during Phase 6, 17, and 18.
   - **Data Compatibility:** PLANNED `LegacyNoteImporter` converts raw SQLite `notes` rows into `Lesson` entities without data loss.

2. **`DiagramSystem` Enum & `SystemDefaultNotes` (`lib/models/system_notes.dart`):**
   - **Replacement:** Data-driven `NumberSystem` domain entities and formulas.
   - **Migration Dependency:** Phase 17 (Number System Engine).
   - **Data Compatibility:** Hardcoded notes converted into JSON seed files or migrated into SQLite `vnext_number_systems` table.

3. **Legacy Monolithic `BilliardDiagramPainter` (`lib/widgets/billiard_diagram.dart`):**
   - **Replacement:** Modularized `SceneRenderer` widget powered by pure Dart coordinate transformations.
   - **Migration Dependency:** Phase 3 (Scene Renderer Refactor).
   - **Data Compatibility:** Accepts `BilliardScene` input, maintaining full visual parity with legacy diagrams.
