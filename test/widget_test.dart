import 'package:flutter_test/flutter_test.dart';

import 'package:peer_learn_hub/main.dart';

void main() {
  testWidgets('PeerLearnHub splash then shows the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PeerLearnHub());
    await tester.pump();

    expect(find.text('PeerLearnHub'), findsOneWidget);
    expect(find.text('Preparing your learning space'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('PeerLearnHub'), findsOneWidget);
    expect(find.text('Learn. Share. Grow.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    expect(
      find.text('Learn skills. Connect with people. Grow together.'),
      findsOneWidget,
    );
  });
}
