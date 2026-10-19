import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_deepseek_example/main.dart';

void main() {
  testWidgets('demo app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepSeekDemoApp());
    expect(find.text('flutter_deepseek'), findsOneWidget);
    expect(find.text('API key (memory only)'), findsOneWidget);
  });

  testWidgets('web search toggle is off by default and can be enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DeepSeekDemoApp());
    expect(find.text('Web search'), findsOneWidget);

    final toggle = find.byType(Switch).last;
    expect(tester.widget<Switch>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isTrue);
  });
}
