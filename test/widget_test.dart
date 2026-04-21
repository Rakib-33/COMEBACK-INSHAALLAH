import 'package:flutter_test/flutter_test.dart';

import 'package:target_final/main.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const TargetFinalApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('COMEBACK'), findsWidgets);
  });
}
