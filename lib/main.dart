import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/config/environment.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/supabase_test_service.dart';

// Global navigator key for accessing ScaffoldMessenger from service layer
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('✅ Firebase initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Firebase initialization error: $e');
      print(
        '   FCM notifications will not work without Firebase initialization',
      );
    }
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
    // Enable Supabase debug logging only in debug mode
    debug: kDebugMode,
  );
  if (kDebugMode) {
    final connected = await SupabaseTestService.testConnection();
    final info = await SupabaseTestService.getConnectionInfo();
    print('✅ Supabase initialized. Connected: $connected, Info: $info');
  }

  // Initialize FCM service after Supabase is initialized
  // Note: We don't request permission here to comply with Google Play Store policies.
  // Permission will be requested contextually (after login or when user enables notifications).
  try {
    final supabase = Supabase.instance.client;
    final fcmService = FcmService();
    await fcmService.initialize(supabase, requestPermissionNow: false);
    if (kDebugMode) {
      print(
        '✅ FCM service initialized (permission will be requested contextually)',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ FCM service initialization error: $e');
      print('   Push notifications may not work');
    }
  }

  runApp(const ProviderScope(child: PickleMartApp()));
}

class PickleMartApp extends ConsumerWidget {
  const PickleMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appTheme = ref.watch(appThemeProvider);

    // Initialize app lifecycle service (handles foreground/background states)
    ref.watch(appLifecycleServiceProvider);

    return MaterialApp.router(
      title: 'Pickle Mart',
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appTheme.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
