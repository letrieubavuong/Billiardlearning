import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/data/diagram_document_codec.dart';
import 'package:libre2026/screens/diagram_builder_page.dart';
import 'package:libre2026/widgets/billiard_diagram.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('straight segment snaps both ends to diamond nodes', (
    tester,
  ) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.text('Đoạn thẳng').last);
    await tester.pump();
    await tester.tapAt(session.toGlobal(const Offset(0.2, 1.2)));
    await tester.tapAt(session.toGlobal(const Offset(3.7, 6.8)));
    await tester.pump();
    final data = await session.save(tester);

    expect(data['paths']['free'].single, [
      [0.0, 1.0],
      [4.0, 7.0],
    ]);
  });

  testWidgets('straight segment can be created by dragging', (tester) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.text('Đoạn thẳng').last);
    await tester.pump();
    await tester.dragFrom(
      session.toGlobal(const Offset(0.2, 1.2)),
      session.toGlobal(const Offset(3.7, 6.8)) -
          session.toGlobal(const Offset(0.2, 1.2)),
    );
    await tester.pump();
    final data = await session.save(tester);

    expect(data['paths']['free'].single, [
      [0.0, 1.0],
      [4.0, 7.0],
    ]);
  });

  testWidgets('straight segment can extend into numbered rail area', (
    tester,
  ) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.text('Đoạn thẳng').last);
    await tester.pump();
    await tester.dragFrom(
      session.toGlobal(const Offset(-0.3, 1)),
      session.toGlobal(const Offset(4.3, 7)) -
          session.toGlobal(const Offset(-0.3, 1)),
    );
    await tester.pump();
    final data = await session.save(tester);
    final segment = data['paths']['free'].single;

    expect(segment.first[0], lessThan(0));
    expect(segment.last[0], greaterThan(4));
    expect(segment.first[1], 1.0);
    expect(segment.last[1], 7.0);
  });

  testWidgets('trajectory points are editable while main balls stay fixed', (
    tester,
  ) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.text('Quỹ đạo').last);
    await tester.pump();
    await tester.tapAt(session.toGlobal(const Offset(2.5, 3)));
    await tester.pump();
    await tester.dragFrom(
      session.toGlobal(const Offset(2.5, 3)),
      session.toGlobal(const Offset(3.5, 3)) -
          session.toGlobal(const Offset(2.5, 3)),
    );
    await tester.pump();
    final data = await session.save(tester);

    expect(data['white'], [2.0, 2.0]);
    expect(data['yellow'], [1.0, 4.0]);
    expect(data['red'], [3.0, 6.0]);
    expect(data['paths']['white'].single[0], closeTo(3.5, 0.05));
  });

  testWidgets('main balls are draggable in trajectory mode', (tester) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.byIcon(Icons.route).last);
    await tester.pump();
    await tester.dragFrom(
      session.toGlobal(const Offset(2, 2)),
      session.toGlobal(const Offset(3, 2)) -
          session.toGlobal(const Offset(2, 2)),
    );
    await tester.pump();
    final data = await session.save(tester);

    expect(data['white'][0], closeTo(3.0, 0.2));
    expect(data['white'][1], closeTo(2.0, 0.2));
    expect(data['paths']['white'], isEmpty);
  });

  testWidgets('trajectory interaction stays inside the play area', (
    tester,
  ) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.byIcon(Icons.route).last);
    await tester.pump();

    await tester.tapAt(session.toGlobal(const Offset(-0.5, 3)));
    await tester.pump();
    await tester.tapAt(session.toGlobal(const Offset(2.5, 3)));
    await tester.pump();
    await tester.dragFrom(
      session.toGlobal(const Offset(2.5, 3)),
      session.toGlobal(const Offset(-1, 3)) -
          session.toGlobal(const Offset(2.5, 3)),
    );
    await tester.pump();
    final data = await session.save(tester);

    expect(data['paths']['white'], hasLength(1));
    expect(data['paths']['white'].single[0], 0.0);
  });

  testWidgets('label tool immediately enables placement on the table', (
    tester,
  ) async {
    final session = await _openDiagram(tester);
    await tester.tap(find.text('Nhãn'));
    await tester.pump();
    await tester.tapAt(session.toGlobal(const Offset(2, 4)));
    await tester.pumpAndSettle();

    expect(find.text('Nhập chữ hoặc số'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}

Future<_DiagramSession> _openDiagram(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  String? result;
  final initial = DiagramDocumentCodec.encode({
    'white': [2.0, 2.0],
    'yellow': [1.0, 4.0],
    'red': [3.0, 6.0],
    'viewType': 0,
    'system': 0,
    'paths': {
      'white': <dynamic>[],
      'yellow': <dynamic>[],
      'red': <dynamic>[],
      'free': <dynamic>[],
    },
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => DiagramBuilderPage(initialData: initial),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  final rect = tester.getRect(find.byType(BilliardDiagram).first);
  return _DiagramSession(rect, () => result);
}

class _DiagramSession {
  const _DiagramSession(this.rect, this.result);
  final Rect rect;
  final String? Function() result;

  Offset toGlobal(Offset diamond) {
    final width = rect.width - 8;
    final rail = width * (12 / 124);
    final spacing = (width - rail * 2) / 4;
    return rect.topLeft +
        Offset(
          4 + rail + diamond.dx * spacing,
          8 + rail + diamond.dy * spacing,
        );
  }

  Future<Map<String, dynamic>> save(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(result(), isNotNull);
    return DiagramDocumentCodec.decode(result()!);
  }
}
