// Pure Dart Legacy Scene Bridge for Phase 4C
// Bidirectional adapter bridging legacy diagram JSON strings and vNext BilliardScene objects.

import '../../data/diagram_document_codec.dart';
import '../entities/entities.dart';
import 'legacy_scene_exporter.dart';
import 'legacy_scene_importer.dart';

class LegacySceneBridge {
  const LegacySceneBridge._();

  /// Converts a legacy diagram JSON string [initialData] into a canonical vNext [BilliardScene].
  static BilliardScene initialDataToScene(
    String initialData, {
    String? sceneName,
  }) {
    final map = DiagramDocumentCodec.decode(initialData);
    final importResult = LegacySceneImporter.importJsonMap(
      map,
      sceneName: sceneName,
    );
    return importResult.scene;
  }

  /// Converts a canonical vNext [BilliardScene] into a legacy diagram JSON string.
  static String sceneToLegacyJson(BilliardScene scene) {
    final map = LegacySceneExporter.exportJsonMap(scene);
    return DiagramDocumentCodec.encode(map);
  }
}
