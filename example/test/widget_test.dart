import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_deepseek_example/main.dart';

void main() {
  testWidgets('demo app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepSeekDemoApp());
    expect(find.text('flutter_deepseek'), findsOneWidget);
    expect(find.text('API key (memory only)'), findsOneWidget);
  });
}
