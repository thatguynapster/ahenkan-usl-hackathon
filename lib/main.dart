import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'core/lifecycle/app_lifecycle_manager.dart';
import 'presentation/pages/main_navigation_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.initializeDependencies();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    // Initialize lifecycle manager with required dependencies
    _lifecycleManager = di.sl<AppLifecycleManager>();
    _lifecycleManager.initialize();
  }

  @override
  void dispose() {
    // Dispose lifecycle manager
    _lifecycleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahenkan',
      theme: _buildAccessibleTheme(),
      home: const MainNavigationScreen(),
    );
  }

  /// Builds an accessible theme with proper contrast ratios and text sizes
  ThemeData _buildAccessibleTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,

      // Ensure minimum text sizes for readability (16sp minimum)
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
        bodyMedium: TextStyle(fontSize: 16.0, height: 1.5),
        bodySmall: TextStyle(fontSize: 14.0, height: 1.5),
        labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
      ),

      // Ensure proper touch targets for interactive elements
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Smooth animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Elevated button theme with proper sizing
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44.0, 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon button theme with proper sizing
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44.0, 44.0),
          iconSize: 24.0,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44.0, 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
