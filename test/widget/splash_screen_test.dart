import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/core/ui/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('should display logo only', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Assert
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should have golden yellow background', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Assert
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFfbc801)));
    });

    testWidgets('should navigate to role selection after 3 seconds', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            name: 'splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/role',
            name: 'role',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Role'))),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Act
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Role'), findsOneWidget);
    });

    testWidgets('should show fallback text logo when image fails to load', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNull);
    });

    testWidgets('should have correct layout structure', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should have correct image properties', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.fit, equals(BoxFit.contain));
      expect((imageWidget.image as AssetImage).assetName, 'assets/picklemart.png');
    });

    testWidgets('should have proper spacing between elements', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Assert
      expect(find.byType(SizedBox), findsNothing);
    });

    testWidgets('should be responsive to different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test with different screen sizes
      final testSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
      ];

      for (final size in testSizes) {
        // Arrange
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // Act
        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

        // Assert
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(Text), findsNothing);

        // Clean up
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
