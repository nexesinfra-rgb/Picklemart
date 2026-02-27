import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/main.dart';

void main() {
  group('PickleMartApp Widget Tests', () {
    testWidgets('should render app with correct title', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      expect(find.text('Pickle Mart'), findsOneWidget);
    });

    testWidgets('should have MaterialApp.router with correct configuration', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Pickle Mart'));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.routerConfig, isNotNull);
    });

    testWidgets('should navigate to splash screen initially', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);

      // Wait for navigation to complete
      await tester.pumpAndSettle();

      // Should show splash screen initially
      expect(find.text('Pickle Mart'), findsOneWidget);
    });

    testWidgets('should have ProviderScope wrapping the app', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      expect(find.byType(ProviderScope), findsOneWidget);
      expect(find.byType(PickleMartApp), findsOneWidget);
    });

    testWidgets('should have theme applied', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('should have router configuration', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: PickleMartApp()));

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routerConfig, isA<GoRouter>());
    });
  });
}
