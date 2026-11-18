import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Input stays above simulated keyboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ChatLabApp());

    final input = find.byType(TextField);
    final send = find.widgetWithIcon(IconButton, Icons.arrow_upward);
    final before = tester.getRect(input);

    await tester.tap(input);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final after = tester.getRect(input);
    expect(after.bottom, lessThanOrEqualTo(500));
    expect(after.bottom, lessThan(before.bottom));
    expect(tester.getRect(send).bottom, lessThanOrEqualTo(500));
    expect(tester.takeException(), isNull);

    await tester.enterText(input, 'hello');
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    expect(
      find.text('메시지를 받았습니다. (로컬 모의 응답)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}