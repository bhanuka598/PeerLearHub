import 'package:flutter_test/flutter_test.dart';

import 'package:peer_learn_hub/main.dart';

void main() {
  testWidgets('Peer Learn Hub loading screen loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PeerLearnHub());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nPeer Learn Hub'), findsOneWidget);
    expect(find.text('Open Skill Exchange Hub'), findsOneWidget);
    expect(find.text('Go to Login'), findsOneWidget);
  });
}
