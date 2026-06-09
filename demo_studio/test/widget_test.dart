import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_deepseek_studio/main.dart';

void main() {
  testWidgets('studio app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const StudioDemoApp());
    expect(find.text('DeepSeek Studio'), findsOneWidget);
  });
}
