import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/accessibility_utils.dart';
import '../../core/utils/app_configuration.dart';
import '../bloc/language_manager/language_manager_bloc.dart';
import '../bloc/language_manager/language_manager_event.dart';
import '../bloc/session_manager/session_manager_bloc.dart';
import 'sign_to_text_screen.dart';
import 'text_to_sign_screen.dart';
import 'history_screen.dart';

/// Main navigation screen with bottom navigation bar
/// Manages navigation between Sign-to-Text, Text-to-Sign, and History screens
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // List of screens to display
  final List<Widget> _screens = const [
    SignToTextScreen(),
    TextToSignScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide LanguageManagerBloc at the navigation level
        // so it persists across screen switches
        BlocProvider(
          create: (context) =>
              sl<LanguageManagerBloc>()..add(const LoadSavedLanguage()),
        ),
        // Provide SessionManagerBloc at the navigation level
        // so history persists across screen switches
        BlocProvider(create: (context) => sl<SessionManagerBloc>()),
      ],
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: AppConfiguration.animationDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedFontSize: 14.0,
          unselectedFontSize: 12.0,
          // Ensure minimum touch target size
          iconSize: 28.0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sign_language),
              label: 'Sign to Text',
              tooltip: 'Record sign language and convert to text',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.text_fields),
              label: 'Text to Sign',
              tooltip: 'Convert text or speech to sign language',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
              tooltip: 'View communication history',
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) async {
    // Provide haptic feedback for navigation
    await AccessibilityUtils.provideHapticFeedback(
      type: HapticFeedbackType.selection,
    );

    setState(() {
      _currentIndex = index;
    });
  }
}
