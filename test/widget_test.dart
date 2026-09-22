// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:libre2026/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hiển thị màn hình chào và mở trang chính', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Billiard 3C - Libre'), findsOneWidget);
    expect(find.text('BẮT ĐẦU HỌC NGAY'), findsOneWidget);

    await tester.tap(find.text('BẮT ĐẦU HỌC NGAY'));
    // Home contains repeating animations, so pumpAndSettle would never reach
    // an animation-free frame.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Kỹ thuật cơ bản'), findsWidgets);
  });
}
