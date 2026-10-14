// SAFAR Commuter App Tests
// Verifies core journey planning flow: Home -> Stop Search -> Journey Results -> Journey Details -> Disruption Alerts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/main.dart';
import 'package:safar/screens/disruption_alert_screen.dart';
import 'package:safar/screens/home_screen.dart';
import 'package:safar/screens/journey_details_screen.dart';
import 'package:safar/screens/journey_results_screen.dart';
import 'package:safar/screens/splash_3d_screen.dart';
import 'package:safar/screens/stop_search_screen.dart';
import 'package:safar/widgets/interactive_3d_hero.dart';

void main() {
  testWidgets('SAFAR Core Flow: Home -> Journey Results -> Journey Details', (
    WidgetTester tester,
  ) async {
    // Configure phone display dimensions (Motorola Edge 50 Pro)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Build SAFAR App and trigger initial frame
    await tester.pumpWidget(const SafarApp(showSplash: false));
    await tester.pump(const Duration(milliseconds: 100));

    // 2. Verify Home Screen branding and elements
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('SAFAR'), findsOneWidget);
    expect(find.text('Chennai'), findsOneWidget);
    expect(find.text('Find My Journey'), findsOneWidget);
    expect(find.text('Tambaram'), findsWidgets);
    expect(find.text('Frequent Commutes'), findsOneWidget);

    // 3. Tap 'Find My Journey' to open Journey Results
    await tester.ensureVisible(find.text('Find My Journey'));
    await tester.tap(find.text('Find My Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 4. Verify Journey Results Screen
    expect(find.byType(JourneyResultsScreen), findsOneWidget);
    expect(find.text('Fastest'), findsWidgets);
    expect(find.text('Fewest Transfers'), findsWidgets);
    expect(find.text('Cheapest'), findsWidgets);

    // 5. Tap on the first Journey card to open Journey Details
    await tester.tap(find.text('Fastest Direct'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 6. Verify Journey Timeline Details
    expect(find.byType(JourneyDetailsScreen), findsOneWidget);
    expect(find.text('Journey Timeline'), findsOneWidget);
    expect(
      find.text('Check Service Alerts & Disruption Recovery'),
      findsOneWidget,
    );

    // 7. Open Disruption Alerts & Recovery from timeline
    await tester.tap(find.text('Check Service Alerts & Disruption Recovery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 8. Verify Disruption Alert Screen
    expect(find.byType(DisruptionAlertScreen), findsOneWidget);
    expect(find.text('Alerts'), findsWidgets);
    expect(find.textContaining('MRTS Track Renewal'), findsOneWidget);
  });

  testWidgets(
    'SAFAR Search Preferences: Select date, time and priority constraints',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SafarApp(showSplash: false));
      await tester.pump(const Duration(milliseconds: 100));

      // Check preference controls exist on Home Screen
      expect(find.text('Fastest'), findsOneWidget);
      expect(find.text('Fewest Transfers'), findsOneWidget);
      expect(find.text('Cheapest'), findsOneWidget);

      // Switch preference to Cheapest
      await tester.tap(find.text('Cheapest'));
      await tester.pump(const Duration(milliseconds: 100));

      // Open Advanced constraints
      await tester.tap(find.text('More options (Transfers, Budget)'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Transfers:'), findsOneWidget);
      expect(find.text('Max Fare:'), findsOneWidget);
      expect(find.text('Direct only (0)'), findsOneWidget);
      expect(find.text('≤ ₹25'), findsOneWidget);

      // Select Direct only
      await tester.tap(find.text('Direct only (0)'));
      await tester.pump(const Duration(milliseconds: 100));

      // Proceed to search
      await tester.ensureVisible(find.text('Find My Journey'));
      await tester.tap(find.text('Find My Journey'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(JourneyResultsScreen), findsOneWidget);
    },
  );

  testWidgets('SAFAR Stop Search: Searching stations and filtering by mode', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SafarApp(showSplash: false));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on "From" tile to open Stop Search
    await tester.tap(find.text('From'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(StopSearchScreen), findsOneWidget);
    expect(find.text('Select Origin (From)'), findsOneWidget);

    // Enter search query "Guindy"
    await tester.enterText(find.byType(TextField), 'Guindy');
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.widgetWithText(ListTile, 'Guindy'), findsOneWidget);
    expect(find.text('GDY'), findsOneWidget);

    // Select Guindy from search results
    await tester.tap(find.widgetWithText(ListTile, 'Guindy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Returned to Home screen with Guindy selected
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Guindy'), findsWidgets);
  });

  testWidgets(
    'SAFAR Metro Hero: 2.5D Animated Metro and Closed-loop Track rendering',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SafarApp(showSplash: false));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify MetroHero / Interactive3DHero presence on Home Screen
      expect(find.byType(Interactive3DHero), findsOneWidget);

      // 2. Verify text overlay badges are removed for minimal crowding
      expect(find.text('CMRL Hub'), findsNothing);
      expect(find.text('CMRL Metro • Normal Service'), findsNothing);

      // 3. Verify pan/drag interaction on the 2.5D hero
      final heroFinder = find.byType(Interactive3DHero);
      await tester.drag(heroFinder, const Offset(30, -20));
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Advance time to verify smooth train animation around the closed loop
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 8));

      // 5. Ensure no overflow or layout errors occurred
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SAFAR 3D Splash Screen: renders 3D transit branding and Skip action',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SafarApp(showSplash: true));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify 3D Splash Screen elements
      expect(find.byType(Splash3DScreen), findsOneWidget);
      expect(find.text('CHENNAI 3D TRANSIT'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('SAFAR'), findsOneWidget);

      // 2. Tap Skip to immediately transition to Home screen
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Verify Home Screen is visible
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Find My Journey'), findsOneWidget);
    },
  );
}
