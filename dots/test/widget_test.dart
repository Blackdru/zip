import 'package:flutter_test/flutter_test.dart';
import 'package:dots_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DotsApp(),
    );

    expect(find.text('DOTS'), findsOneWidget);
  });
}
