import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/core/auth/welcome_store.dart';
import 'package:peer_learn_hub/core/router/app_router.dart';
import 'package:peer_learn_hub/features/skill_provider/services/session_automation_service.dart';
import 'package:peer_learn_hub/main.dart';
import 'package:peer_learn_hub/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PeerLearnHub splash then shows the welcome screen', (
    WidgetTester tester,
  ) async {
    SplashScreen.hasCompleted = false;
    WelcomeStore.seen = false;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PeerLearnHub());
    await tester.pump();

    expect(find.text('PeerLearnHub'), findsOneWidget);
    expect(find.text('Preparing your learning space'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('PeerLearnHub'), findsOneWidget);
    expect(find.text('Learn. Share. Grow.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('later launches open the login screen instead of welcome', (
    WidgetTester tester,
  ) async {
    SplashScreen.hasCompleted = false;
    WelcomeStore.seen = true;
    SharedPreferences.setMockInitialValues({
      'peerlearnhub_welcome_seen': true,
    });
    RouterClass.router.go('/');
    await tester.pumpWidget(const PeerLearnHub());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(find.text('I already have an account'), findsNothing);
  });

  testWidgets('auth back buttons return to the previous screen', (
    WidgetTester tester,
  ) async {
    SplashScreen.hasCompleted = true;
    RouterClass.router.go('/welcome');
    await tester.pumpWidget(const PeerLearnHub());
    await tester.pumpAndSettle();

    await _tap(tester, find.text('I already have an account'));
    expect(find.text('Welcome back'), findsOneWidget);

    await _tap(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('I already have an account'), findsOneWidget);

    await _tap(tester, find.text('Get Started'));
    expect(find.text('Create your account'), findsOneWidget);

    await _tap(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
    expect(find.text('Create your account'), findsNothing);
    expect(find.text('Get Started'), findsOneWidget);

    await _tap(tester, find.text('I already have an account'));
    await _tap(tester, find.text('Forgot password?'));
    expect(find.text('Forgot Password?'), findsOneWidget);

    await _tap(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
    expect(find.text('Forgot Password?'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  test('moderator login resolves to the moderator dashboard route', () {
    AppAuth.instance.setRoleFromApi('moderator');

    expect(AppAuth.instance.currentRole, AppUserRole.moderator);
    expect(AppAuth.instance.getHomeRoute(), '/moderation');

    AppAuth.instance.setRole(AppUserRole.student);
    SessionAutomationService.instance.stop();
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
