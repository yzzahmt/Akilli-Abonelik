import 'package:flutter_test/flutter_test.dart';
import 'package:abonetakip/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SubsTrackApp());
    expect(find.byType(SubsTrackApp), findsOneWidget);
  });
}
