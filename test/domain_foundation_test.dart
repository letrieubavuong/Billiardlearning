import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('Pure Dart Domain Foundation Tests (Phase 0)', () {
    test('BilliardScene entity can be instantiated independently of UI/DB', () {
      final now = DateTime.now();
      final sceneId = StableId.generate();

      final scene = BilliardScene(
        id: sceneId,
        name: 'Sample Three-Cushion Angle Shot',
        tableConfig: const TableConfig(
          type: 'carom_3c',
          widthMeters: 1.42,
          lengthMeters: 2.84,
        ),
        balls: const [
          BallPosition(
            id: 'ball_white',
            ballType: 'white',
            position: TablePoint(0.5, 0.75),
          ),
          BallPosition(
            id: 'ball_yellow',
            ballType: 'yellow',
            position: TablePoint(0.25, 0.5),
          ),
          BallPosition(
            id: 'ball_red',
            ballType: 'red',
            position: TablePoint(0.75, 0.25),
          ),
        ],
        trajectories: const [
          TrajectoryLine(
            id: 'traj_white',
            colorHex: '#FFFFFF',
            points: [
              TablePoint(0.5, 0.75),
              TablePoint(0.25, 0.5),
              TablePoint(0.0, 0.25),
              TablePoint(0.75, 0.25),
            ],
          ),
        ],
        annotations: const [
          SceneAnnotation(
            id: 'anno_1',
            text: 'Bi chủ chạm bi vàng 1/2 trái',
            position: TablePoint(0.5, 0.75),
          ),
        ],
        cueInstruction: const CueInstruction(
          power: 0.75,
          direction: Angle.fromRadians(0.7854), // ~45 deg
          tipOffset: Vec2(0.0, 0.5), // Top spin (áp phê áp phê trên)
        ),
        source: SceneSource.manual,
        status: SceneStatus.active,
        version: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Verify ID and identity
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      expect(
        uuidRegex.hasMatch(scene.id),
        isTrue,
        reason: 'Scene ID must be a valid UUID v4',
      );
      expect(scene.name, equals('Sample Three-Cushion Angle Shot'));

      // Verify table configuration
      expect(scene.tableConfig.type, equals('carom_3c'));
      expect(scene.tableConfig.widthMeters, equals(1.42));
      expect(scene.tableConfig.lengthMeters, equals(2.84));

      // Verify balls positions (normalized u, v in [0,1]^2)
      expect(scene.balls.length, equals(3));
      expect(scene.balls[0].ballType, equals('white'));
      expect(scene.balls[0].position.isWithinTable, isTrue);

      // Verify trajectories
      expect(scene.trajectories.length, equals(1));
      expect(scene.trajectories[0].points.length, equals(4));
      expect(
        scene.trajectories[0].points.every((p) => p.isWithinTable),
        isTrue,
      );

      // Verify annotations
      expect(scene.annotations.length, equals(1));
      expect(scene.annotations[0].text, equals('Bi chủ chạm bi vàng 1/2 trái'));

      // Verify cue instruction value object
      expect(scene.cueInstruction, isNotNull);
      expect(scene.cueInstruction!.power, equals(0.75));
      expect(scene.cueInstruction!.tipOffset, equals(const Vec2(0.0, 0.5)));

      // Verify state metadata
      expect(scene.source, equals(SceneSource.manual));
      expect(scene.status, equals(SceneStatus.active));
      expect(scene.isDeleted, isFalse);
      expect(scene.version, equals(1));
      expect(scene.createdAt, equals(now));
      expect(scene.updatedAt, equals(now));
    });

    test('Lesson entity supports structured sections and type-safe blocks', () {
      final now = DateTime.now();
      final lessonId = StableId.generate();
      final sceneId = StableId.generate();

      final lesson = Lesson(
        id: lessonId,
        chapterId: 'chapter_fundamentals',
        title: 'Kỹ thuật ngắm bi 3 băng cơ bản',
        subtitle: 'Phương pháp xác định điểm chạm bi mục tiêu',
        sections: [
          LessonSection(
            id: 'sec_1',
            title: 'Lý thuyết cơ bản',
            order: 1,
            blocks: [
              const TextBlock(
                id: 'blk_text_1',
                text: 'Hãy tập trung vào điểm ngắm trên bi mục tiêu.',
              ),
              SceneReferenceBlock(
                id: 'blk_scene_1',
                sceneId: sceneId,
                caption: 'Sơ đồ minh họa đường chạy bi chủ',
              ),
            ],
          ),
        ],
        status: LessonStatus.published,
        version: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(lesson.id, equals(lessonId));
      expect(lesson.sections.length, equals(1));
      expect(lesson.sections[0].blocks.length, equals(2));
      expect(lesson.sections[0].blocks[0].blockType, equals('text'));
      expect(lesson.sections[0].blocks[1].blockType, equals('sceneReference'));
    });

    test('Technique and NumberSystem entities instantiate correctly', () {
      final now = DateTime.now();

      final technique = Technique(
        id: StableId.generate(),
        name: 'Kỹ thuật Gôm Bi Cua-lê',
        groupName: 'Gôm bi',
        difficulty: 'hard',
        content: 'Chạm bi mục tiêu với ép phê cao...',
        createdAt: now,
        updatedAt: now,
      );

      expect(technique.difficulty, equals('hard'));

      final system = NumberSystem(
        id: StableId.generate(),
        name: 'Bộ số 50 (Diamond System)',
        expression: 'Cushion3 = Origin - Target',
        createdAt: now,
        updatedAt: now,
      );

      expect(system.expression, equals('Cushion3 = Origin - Target'));
    });
  });
}
