import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart';
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
        body: IndexedStack(index: _currentIndex, children: _screens),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sign_language),
              label: 'Sign to Text',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.text_fields),
              label: 'Text to Sign',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
