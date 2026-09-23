import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/data/diagram_document_codec.dart';
import 'package:libre2026/data/note_document_codec.dart';
import 'package:libre2026/data/note_repository.dart';
import 'package:libre2026/models/note_model.dart';
import 'package:libre2026/models/image_block_data.dart';
import 'package:libre2026/screens/co_ban_page.dart';
import 'package:libre2026/screens/note_editor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('note codec round-trips a versioned document', () {
    final source = Note(
      id: 7,
      title: 'Test',
      blocks: [NoteBlock(content: 'Nội dung', type: BlockType.text)],
      date: DateTime.utc(2026),
    );

    final decoded = NoteDocumentCodec.decode(NoteDocumentCodec.encode(source));

    expect(decoded.id, 7);
    expect(decoded.title, 'Test');
    expect(decoded.blocks.single.content, 'Nội dung');
  });

  test('diagram codec rejects unsupported versions', () {
    expect(
      () => DiagramDocumentCodec.decode('{"schemaVersion":99}'),
      throwsFormatException,
    );
  });

  test('image block data supports metadata and legacy sources', () {
    const image = ImageBlockData(
      source: 'https://example.com/shot.jpg',
      caption: 'Thế bi mẫu',
      altText: 'Ba bi nằm giữa bàn',
      fit: 'cover',
    );

    final decoded = ImageBlockData.decode(image.encode());
    expect(decoded.source, image.source);
    expect(decoded.caption, image.caption);
    expect(decoded.altText, image.altText);
    expect(decoded.fit, 'cover');

    final legacy = ImageBlockData.decode('C:/old/image.jpg');
    expect(legacy.source, 'C:/old/image.jpg');
    expect(legacy.caption, isEmpty);
  });

  testWidgets('category screen loads through injected repository', (
    tester,
  ) async {
    final repository = _FakeNoteRepository();
    await tester.pumpWidget(
      MaterialApp(home: CoBanPage(repository: repository)),
    );
    await tester.pump();

    expect(repository.requestedCategories, ['coban']);
    expect(find.text('Bài từ repository'), findsOneWidget);
  });

  testWidgets('category search filters note content', (tester) async {
    final repository = _FakeNoteRepository();
    await tester.pumpWidget(
      MaterialApp(home: CoBanPage(repository: repository)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'không tồn tại');
    await tester.pump();

    expect(find.text('Bài từ repository'), findsNothing);
  });

  testWidgets('note editor automatically saves a draft', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: NoteEditorPage()));
    await tester.enterText(find.byType(TextField).first, 'Bản nháp tự động');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('note_draft_new'), contains('Bản nháp tự động'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('note editor can collapse and undo block removal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: NoteEditorPage()));

    expect(find.widgetWithText(TextField, 'Nhập văn bản...'), findsOneWidget);
    await tester.tap(find.byTooltip('Thu gọn khối'));
    await tester.pump();
    expect(find.text('Đoạn văn'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nhập văn bản...'), findsNothing);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    expect(find.text('Đoạn văn'), findsNothing);

    await tester.tap(find.byTooltip('Hoàn tác thao tác khối'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Nhập văn bản...'), findsOneWidget);

    await tester.tap(find.byTooltip('Làm lại thao tác khối'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Nhập văn bản...'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('note editor warns before leaving with unsaved changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const NoteEditorPage()),
            ),
            child: const Text('Mở trình chỉnh sửa'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở trình chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nội dung chưa lưu');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Rời trình chỉnh sửa?'), findsOneWidget);

    await tester.tap(find.text('Tiếp tục chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  test('domain layer does not import flutter, sqflite or dart:ui', () {
    final domainDir = Directory('lib/domain');
    expect(domainDir.existsSync(), isTrue);

    final forbiddenImports = [
      'package:flutter/',
      'package:sqflite/',
      'package:sqflite_common_ffi/',
      'dart:ui',
    ];

    final forbiddenSymbols = [
      'Color',
      'Offset',
      'Canvas',
      'Paint',
      'Widget',
      'BuildContext',
    ];

    final files = domainDir.listSync(recursive: true).whereType<File>();
    for (final file in files) {
      if (file.path.endsWith('.dart')) {
        final content = file.readAsStringSync();
        for (final importStr in forbiddenImports) {
          expect(
            content.contains("import '$importStr"),
            isFalse,
            reason: '${file.path} must not import $importStr',
          );
        }
        for (final symbol in forbiddenSymbols) {
          // Verify forbidden symbols are not used as types or constructors
          final regex = RegExp('\\b$symbol\\b');
          expect(
            regex.hasMatch(content),
            isFalse,
            reason: '${file.path} must not use Flutter UI symbol $symbol',
          );
        }
      }
    }
  });

  test(
    'rendering layer does not import sqflite, repositories or database data sources',
    () {
      final renderingDir = Directory('lib/rendering');
      expect(renderingDir.existsSync(), isTrue);

      final forbiddenImports = [
        'package:sqflite/',
        'package:sqflite_common_ffi/',
        'package:shared_preferences/',
        'data/database',
        'data/repositories',
      ];

      final files = renderingDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (file.path.endsWith('.dart')) {
          final content = file.readAsStringSync();
          for (final importStr in forbiddenImports) {
            expect(
              content.contains(importStr),
              isFalse,
              reason: '${file.path} must not import $importStr',
            );
          }
        }
      }
    },
  );

  test(
    'application/scene_editor layer does not import flutter, sqflite or dart:ui',
    () {
      final editorDir = Directory('lib/application/scene_editor');
      expect(editorDir.existsSync(), isTrue);

      final forbiddenImports = [
        'package:flutter/',
        'dart:ui',
        'package:sqflite/',
        'package:sqflite_common_ffi/',
      ];

      final forbiddenSymbols = [
        'Color',
        'Offset',
        'Canvas',
        'Widget',
        'BuildContext',
      ];

      final files = editorDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (file.path.endsWith('.dart')) {
          final content = file.readAsStringSync();
          for (final importStr in forbiddenImports) {
            expect(
              content.contains("import '$importStr"),
              isFalse,
              reason: '${file.path} must not import $importStr',
            );
          }
          for (final symbol in forbiddenSymbols) {
            final regex = RegExp('\\b$symbol\\b');
            expect(
              regex.hasMatch(content),
              isFalse,
              reason: '${file.path} must not use Flutter UI symbol $symbol',
            );
          }
        }
      }
    },
  );

  test('analysis_options.yaml does not contain platform exclusions', () {
    final result = Process.runSync('git', ['show', ':analysis_options.yaml']);
    final content = result.exitCode == 0
        ? (result.stdout as String)
        : File('analysis_options.yaml').readAsStringSync();

    expect(
      content.contains('android/**'),
      isFalse,
      reason: 'analysis_options.yaml must not exclude android/**',
    );
    expect(
      content.contains('ios/**'),
      isFalse,
      reason: 'analysis_options.yaml must not exclude ios/**',
    );
    expect(
      content.contains('windows/**'),
      isFalse,
      reason: 'analysis_options.yaml must not exclude windows/**',
    );
    expect(
      content.contains('build/**'),
      isFalse,
      reason: 'analysis_options.yaml must not exclude build/**',
    );
  });
}

class _FakeNoteRepository implements NoteRepository {
  final requestedCategories = <String>[];

  @override
  Future<List<Note>> getByCategory(String category) async {
    requestedCategories.add(category);
    return [
      Note(
        id: 1,
        title: 'Bài từ repository',
        blocks: const [],
        date: DateTime.utc(2026),
      ),
    ];
  }

  @override
  Future<void> backup(String targetPath) async {}

  @override
  Future<int> delete(int id) async => 1;

  @override
  Future<Note> insert(String category, Note note) async => note;

  @override
  Future<void> resetAllDefaults() async {}

  @override
  Future<void> resetCategory(String category, List<Note> defaults) async {}

  @override
  Future<void> restore(String sourcePath) async {}

  @override
  Future<int> update(Note note) async => 1;
}
