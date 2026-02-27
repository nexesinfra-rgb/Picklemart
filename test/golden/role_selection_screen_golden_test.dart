import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/auth/presentation/role_selection_screen.dart';

void main() {
  group('RoleSelectionScreen Golden Tests', () {
    testWidgets('role selection screen mobile portrait', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_mobile_portrait.png'),
      );
    });

    testWidgets('role selection screen mobile landscape', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_mobile_landscape.png'),
      );
    });

    testWidgets('role selection screen tablet portrait', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_tablet_portrait.png'),
      );
    });

    testWidgets('role selection screen tablet landscape', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_tablet_landscape.png'),
      );
    });

    testWidgets('role selection screen desktop', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_desktop.png'),
      );
    });
  });
}
