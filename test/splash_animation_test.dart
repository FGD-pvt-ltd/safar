import 'package:flutter_test/flutter_test.dart';
import 'package:safar/main.dart';
import 'package:safar/screens/home_screen.dart';
import 'package:safar/screens/splash_3d_screen.dart';

void main() {
  testWidgets(
    'Living city splash screen auto-shifts to main page at 5 seconds without pressing skip',
    (tester) async {
      await tester.pumpWidget(const SafarApp(showSplash: true));
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Splash3DScreen elements
      expect(find.byType(Splash3DScreen), findsOneWidget);
      expect(find.text('CHENNAI 3D TRANSIT'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('SAFAR'), findsOneWidget);

      // 2. Advance time by 3 seconds: should STILL be on splash screen (since duration is 5s)
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(Splash3DScreen), findsOneWidget);
      expect(find.byType(SafarMainContainer), findsNothing);

      // 3. Advance time to complete the 5 seconds total (2 more seconds + transition)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 450));

      // 4. Verify it shifted to the main page automatically without pressing skip
      expect(find.byType(SafarMainContainer), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Splash3DScreen), findsNothing);
    },
  );

  testWidgets(
    'Splash screen transitions immediately when Skip is tapped before 5 seconds',
    (tester) async {
      await tester.pumpWidget(const SafarApp(showSplash: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Splash3DScreen), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap skip immediately
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Verify immediate transition to main page
      expect(find.byType(SafarMainContainer), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
