import 'package:flutter_test/flutter_test.dart';
import 'package:tradelink/main.dart';

void main() {
  testWidgets('TradelinkApp smoke test', (WidgetTester tester) async {
    // Build TradelinkApp widget and trigger a frame
    await tester.pumpWidget(const TradelinkApp());

    // Verify app title renders
    expect(find.text('TRADELINK'), findsOneWidget);
  });
}
