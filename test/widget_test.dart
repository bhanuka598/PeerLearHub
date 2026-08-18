import 'package:flutter_test/flutter_test.dart';

import 'package:peer_learn_hub/main.dart';

void main() {
  testWidgets('PeerLearHub dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PeerLearHubApp());
    await tester.pumpAndSettle();

    expect(find.text('Skill Provider Dashboard'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Lesson Overview'), findsOneWidget);
    expect(find.text('Create New Lesson'), findsOneWidget);
  });
}
