// Pure Dart Scene Editor Exceptions
// Part of Phase 4A Scene Editor Core Architecture

abstract class SceneEditorException implements Exception {
  final String message;
  const SceneEditorException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class SceneEditorTargetNotFoundException extends SceneEditorException {
  const SceneEditorTargetNotFoundException(String message) : super(message);
}

class SceneEditorInvalidOperationException extends SceneEditorException {
  const SceneEditorInvalidOperationException(String message) : super(message);
}
