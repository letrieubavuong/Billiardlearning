# LEGACY COMPONENT MAP

This document classifies every legacy component and file in the codebase into one of five decisions:
- **KEEP:** Retained as-is or as foundational infrastructure.
- **ADAPT:** Modified or wrapped to interface with vNext domain structures without changing core UI/UX.
- **MIGRATE:** Converted into vNext data entities / domain structures via importer tools.
- **REWRITE:** Rebuilt from scratch in a future phase using clean architecture (Pure Dart domain + clean UI).
- **REMOVE-LATER:** Maintained during backward-compatibility phase, scheduled for removal ONLY after migration and tests pass.

---

## Component Classification Table

| Component/File | Current Role | Decision | Target | Notes |
| :--- | :--- | :---: | :--- | :--- |
| `lib/models/database_helper.dart` | SQLite helper & legacy DB open | **ADAPT** | Data layer helper (vNext + legacy co-existence) | Houses legacy `notes` table & v4 migrations. Must not call domain methods directly. |
| `lib/models/note_model.dart` | Legacy `Note` & `NoteBlock` data structure | **REMOVE-LATER** | `Lesson`, `Technique`, `NumberSystem`, `PersonalNote` | Kept for backward compatibility. **Replacement:** vNext Domain entities. **Migration Dependency:** Importer in Phase 6/17/18. **Data Compatibility:** Parsed via `NoteMapper`. |
| `lib/models/system_notes.dart` | Hardcoded default notes & number system content | **REMOVE-LATER** | Seed data / `NumberSystem` & `Lesson` entities | Hardcoded `getBoSoNotes()`. **Replacement:** SQLite seed migrations or JSON packages. **Migration Dependency:** Phase 17. **Data Compatibility:** Seed importer. |
| `lib/models/learning_progress.dart` | Legacy progress tracker (`category:intId`) | **MIGRATE** | `LearningProgressRecord` (`vnext_learning_progress`) | Legacy string keys mapped to stable entity IDs via migration script. |
| `lib/models/note_draft.dart` | SharedPreferences draft storage | **ADAPT** | Local draft cache / vNext `Lesson` draft repository | Adapted to store draft `Lesson` JSON structures. |
| `lib/models/image_block_data.dart` | Image metadata container | **MIGRATE** | `MediaAsset` entity | Maps raw image paths to `MediaAsset` with checksum and size bytes. |
| `lib/models/theme_manager.dart` | App theme & font scaling state | **KEEP** | App UI Infrastructure | Retained for global UI theme configuration. |
| `lib/widgets/billiard_diagram.dart` | Monolithic `CustomPainter` rendering table & balls | **REWRITE** | `SceneRenderer` (Phase 3) | **Replacement:** `SceneRenderer` Widget & pure Dart coordinate transforms. **Migration Dependency:** Phase 3. **Data Compatibility:** Operates on `BilliardScene`. |
| `lib/widgets/billiard_models.dart` | Legacy diagram data transfer objects | **MIGRATE** | `BilliardScene`, `Ball`, `Trajectory`, `Annotation` | Legacy JSON codec maps to `BilliardScene` domain entities via `SceneMapper`. |
| `lib/screens/diagram_builder_page.dart` | God-file diagram editor UI & state | **REWRITE** | `SceneEditor` (Phase 4) | **Replacement:** Modular `SceneEditorController` + `SceneEditorPage`. **Migration Dependency:** Phase 4. **Data Compatibility:** Edits `BilliardScene`. |
| `lib/screens/note_editor_page.dart` | Article block list editor UI | **REWRITE** | `LessonBuilder` (Phase 6) | **Replacement:** Modular `LessonBuilderPage`. **Migration Dependency:** Phase 6. **Data Compatibility:** Edits type-safe `LessonBlock`. |
| `lib/widgets/shot_details.dart` | Cue strike / effet input widget | **ADAPT** | `CueInstructionWidget` | UX retained, data output mapped to `CueInstruction` domain value object. |
| `lib/widgets/note_block_renderer.dart` | Renders article blocks | **ADAPT** | `LessonBlockWidget` | Adapted to render type-safe `LessonBlock` variants. |
| `lib/widgets/article_blocks.dart` | Article block UI implementations | **ADAPT** | `LessonBlock` UI components | Reuses layout and styling for vNext lesson content blocks. |
| `lib/widgets/note_image_block.dart` | Image block UI | **ADAPT** | `MediaReferenceBlockWidget` | Updated to display images via `MediaAsset` entity. |
| `lib/widgets/animated_article_block.dart` | Micro-animation wrapper for blocks | **KEEP** | UI Animation Utility | Reusable widget for card entrance animations. |
| `lib/widgets/animated_text_widget.dart` | Typewriter/fade text animation | **KEEP** | UI Component | Reusable typography widget. |
| `lib/widgets/youtube_player_widget.dart` | Embedded YouTube player | **KEEP** | UI Component | Reusable media playback widget. |
| `lib/screens/home_page.dart` | Main dashboard & navigation drawer | **ADAPT** | `MainNavigationScreen` | Navigates to both legacy and vNext screens during migration. |
| `lib/screens/bo_so_page.dart` | Number system list screen | **REWRITE** | `NumberSystemLibraryScreen` (Phase 17) | **Replacement:** Data-driven `NumberSystem` library screen. **Migration Dependency:** Phase 17. |
| `lib/screens/co_ban_page.dart` | Basic lessons list screen | **ADAPT** | `LessonCategoryScreen` | Loads both legacy `Note` and vNext `Lesson` items. |
| `lib/screens/gom_bi_page.dart` | Carom gathering techniques screen | **ADAPT** | `TechniqueCategoryScreen` | Displays techniques loaded from `SqliteTechniqueRepository`. |
| `lib/screens/ghi_chu_page.dart` | Personal notes screen | **ADAPT** | `PersonalNotesScreen` | Handles user-created personal notes. |
| `lib/screens/article_detail_page.dart` | Article reader screen | **ADAPT** | `LessonDetailScreen` | Reads type-safe `Lesson` and renders associated scenes. |
| `lib/screens/effet_diagram_builder_page.dart` | Spin/effet diagram editor screen | **ADAPT** | `CueInstructionEditorScreen` | Wraps spin point and cue angle creation UI. |
| `lib/screens/shot_detail_builder_page.dart` | Shot detail creation dialog | **ADAPT** | `CueInstructionDialog` | UI retained, outputs `CueInstruction`. |
| `lib/screens/welcome_page.dart` | Splash & welcome screen | **KEEP** | UI Screen | Retained as-is. |
| `lib/data/database/database_migrations.dart` | Central production SQLite migrations | **KEEP** | Core Data Infrastructure | Manages v1->v4+ database upgrades. |
| `lib/data/database/vnext_tables.dart` | DDL schema for vNext SQLite tables | **KEEP** | Core Data Infrastructure | Defines 8 vNext tables and indexes. |
| `lib/data/repositories/vnext_repositories.dart` | SQLite repository implementations | **KEEP** | Data Layer | Implements safe UPSERT & soft-delete for vNext entities. |

---

## Detailed REMOVE-LATER Justification Summary

1. **`Note` & `NoteBlock` (`lib/models/note_model.dart`):**
   - **Replacement:** Pure Dart domain entities `Lesson`, `Technique`, `NumberSystem`.
   - **Migration Dependency:** Importer utility executed during Phase 6, 17, and 18.
   - **Data Compatibility:** `NoteMapper` converts raw SQLite `notes` rows into `Lesson` entities without data loss.

2. **`DiagramSystem` Enum & `SystemDefaultNotes` (`lib/models/system_notes.dart`):**
   - **Replacement:** Data-driven `NumberSystem` domain entities and formulas.
   - **Migration Dependency:** Phase 17 (Number System Engine).
   - **Data Compatibility:** Hardcoded notes converted into JSON seed files or migrated into SQLite `vnext_number_systems` table.

3. **Monolithic `BilliardDiagramPainter` (`lib/widgets/billiard_diagram.dart`):**
   - **Replacement:** `SceneRenderer` widget powered by pure Dart coordinate transformations.
   - **Migration Dependency:** Phase 3 (Scene Renderer Refactor).
   - **Data Compatibility:** Accepts `BilliardScene` input, maintaining full visual parity with legacy diagrams.
