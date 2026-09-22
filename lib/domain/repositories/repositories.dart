// Pure Dart Repository Contracts for Billiardlearning vNext Architecture

import '../entities/entities.dart';

abstract interface class VNextLessonRepository {
  Future<Lesson?> getById(String id);
  Future<List<Lesson>> list({bool includeDeleted = false});
  Future<void> save(Lesson lesson);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<void> purge(String id);
}

abstract interface class VNextSceneRepository {
  Future<BilliardScene?> getById(String id);
  Future<List<BilliardScene>> list({bool includeDeleted = false});
  Future<void> save(BilliardScene scene);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<void> purge(String id);
}

abstract interface class VNextTechniqueRepository {
  Future<Technique?> getById(String id);
  Future<List<Technique>> list();
  Future<void> save(Technique technique);
  Future<void> delete(String id);
}

abstract interface class VNextNumberSystemRepository {
  Future<NumberSystem?> getById(String id);
  Future<List<NumberSystem>> list();
  Future<void> save(NumberSystem system);
  Future<void> delete(String id);
}

abstract interface class VNextExerciseRepository {
  Future<Exercise?> getById(String id);
  Future<List<Exercise>> list();
  Future<void> save(Exercise exercise);
  Future<void> delete(String id);
}

abstract interface class VNextMediaRepository {
  Future<MediaAsset?> getById(String id);
  Future<List<MediaAsset>> list();
  Future<void> save(MediaAsset asset);
  Future<void> delete(String id);
}

abstract interface class VNextLearningProgressRepository {
  Future<LearningProgressRecord?> getByEntityId(String entityId);
  Future<List<LearningProgressRecord>> listAll();
  Future<void> saveProgress(LearningProgressRecord record);
}

abstract interface class VNextSimulationProfileRepository {
  Future<SimulationProfile?> getById(String id);
  Future<SimulationProfile?> getDefault();
  Future<List<SimulationProfile>> list();
  Future<void> save(SimulationProfile profile);
}
