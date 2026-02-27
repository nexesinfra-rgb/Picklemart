import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picklemart/features/auth/presentation/login_screen.dart';
import 'package:picklemart/features/auth/application/auth_controller.dart';
import 'package:picklemart/features/auth/data/auth_repository.dart';

import '../../unit/auth/auth_controller_test.mocks.dart';

void main() {
  group('Login Screen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return ProviderScope(
        parent: container,
        child: MaterialApp.router(
          title: 'Test App',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          routerConfig: GoRouter(
            initialLocation: '/login',
            routes: [
              GoRoute(
                path: '/login',
                name: 'login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/home',
                name: 'home',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Home Screen')),
                    ),
              ),
              GoRoute(
                path: '/signup',
                name: 'signup',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Signup Screen')),
                    ),
              ),
              GoRoute(
                path: '/forgot',
                name: 'forgot',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Forgot Password Screen')),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Login'), findsNWidgets(2)); // AppBar title and button
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text("Don't have an account? Sign up"), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(TextButton), findsNWidgets(2));
      });

      testWidgets('should display app title in AppBar', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Pickle Mart'), findsOneWidget);
      });
    });

    group('Form Input', () {
      testWidgets('should accept email input', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should accept password input', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Assert
        expect(find.text('password123'), findsOneWidget);
      });

      testWidgets('should toggle password visibility', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty fields', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Enter email'), findsOneWidget);
        expect(find.text('Enter password'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid-email',
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Enter a valid email'), findsOneWidget);
      });

      testWidgets('should show validation error for short password', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, '123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Min 6 characters'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets(
        'should navigate to signup screen when signup link is tapped',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // Act
          await tester.tap(find.text("Don't have an account? Sign up"));
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Signup Screen'), findsOneWidget);
        },
      );

      testWidgets(
        'should navigate to forgot password screen when forgot password link is tapped',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // Act
          await tester.tap(find.text('Forgot password?'));
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Forgot Password Screen'), findsOneWidget);
        },
      );
    });

    group('Authentication Flow', () {
      testWidgets('should show loading state during login', (
        WidgetTester tester,
      ) async {
        // Arrange
        const mobile = '9876543210';
        const password = 'password123';
        final user = User(
          id: '1',
          appMetadata: {},
          userMetadata: {'name': 'Test User'},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        final authResponse = AuthResponse(session: session, user: user);

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobile,
            password: password,
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return authResponse;
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField).first, mobile);
        await tester.enterText(find.byType(TextFormField).last, password);
        await tester.tap(find.byType(FilledButton));
        await tester.pump(); // Don't wait for settle to catch loading state

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should navigate to home screen on successful login', (
        WidgetTester tester,
      ) async {
        // Arrange
        const mobile = '9876543210';
        const password = 'password123';
        final user = User(
          id: '1',
          appMetadata: {},
          userMetadata: {'name': 'Test User'},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        final authResponse = AuthResponse(session: session, user: user);

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobile,
            password: password,
          ),
        ).thenAnswer((_) async => authResponse);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField).first, mobile);
        await tester.enterText(find.byType(TextFormField).last, password);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Home Screen'), findsOneWidget);
      });

      testWidgets('should show error message on failed login', (
        WidgetTester tester,
      ) async {
        // Arrange
        const mobile = '9876543210';
        const password = 'wrongpassword';

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobile,
            password: password,
          ),
        ).thenThrow(const AuthException('Invalid credentials'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField).first, mobile);
        await tester.enterText(find.byType(TextFormField).last, password);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Invalid credentials'), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (
        WidgetTester tester,
      ) async {
        // Test mobile portrait
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Test mobile landscape
        await tester.binding.setSurfaceSize(const Size(812, 375));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Test tablet portrait
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Test tablet landscape
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        // Test desktop
        await tester.binding.setSurfaceSize(const Size(1440, 900));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Email'), findsOneWidget);
        expect(find.bySemanticsLabel('Password'), findsOneWidget);
        expect(find.bySemanticsLabel('Login'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });
    });
  });
}
