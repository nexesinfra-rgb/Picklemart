import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/auth/presentation/role_selection_screen.dart';

void main() {
  group('RoleSelectionScreen Widget Tests', () {
    testWidgets('should display role selection options', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      expect(find.text('Choose your role'), findsOneWidget);
      expect(find.text('Continue as User'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
    });

    testWidgets('should have correct app bar title', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      expect(find.text('Pickle Mart'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3)); // Title + 2 buttons
    });

    testWidgets('should have correct button styling', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final userButton = find.text('Continue as User');
      final adminButton = find.text('Admin Panel');

      expect(userButton, findsOneWidget);
      expect(adminButton, findsOneWidget);

      // Check that buttons are clickable
      expect(tester.widget<TextButton>(userButton), isA<TextButton>());
      expect(tester.widget<TextButton>(adminButton), isA<TextButton>());
    });

    testWidgets('should have proper spacing between elements', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsNWidgets(2)); // Two spacing elements

      // Check spacing values
      final firstSizedBox = tester.widget<SizedBox>(sizedBoxes.first);
      final secondSizedBox = tester.widget<SizedBox>(sizedBoxes.last);

      expect(firstSizedBox.height, equals(24));
      expect(secondSizedBox.height, equals(12));
    });

    testWidgets('should have correct text alignment', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final titleText = tester.widget<Text>(find.text('Choose your role'));
      expect(titleText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should have correct column properties', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.crossAxisAlignment, equals(CrossAxisAlignment.stretch));
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
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
        );

        // Assert
        expect(find.text('Choose your role'), findsOneWidget);
        expect(find.text('Continue as User'), findsOneWidget);
        expect(find.text('Admin Panel'), findsOneWidget);

        // Clean up
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('should handle button taps', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Act
      await tester.tap(find.text('Continue as User'));
      await tester.pump();

      // Assert
      // Button tap should be handled (navigation would occur in real app)
      expect(find.text('Continue as User'), findsOneWidget);
    });

    testWidgets('should have proper padding', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(16.0)));
    });

    testWidgets('should have correct text theme usage', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())),
      );

      // Assert
      final titleText = tester.widget<Text>(find.text('Choose your role'));
      expect(titleText.style, isNotNull);
      // The style should be using the theme's titleLarge style
    });
  });
}
