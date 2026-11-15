import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('CampusTrack smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CampusTrackApp());

    // Verify app brand exists
    expect(find.text('CampusTrack'), findsWidgets);
  });
}
