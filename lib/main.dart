import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'presentation/bloc/session_manager/session_manager_bloc.dart';
// import 'presentation/pages/demo_screen.dart';
// import 'presentation/pages/sign_to_text_screen.dart';
import 'presentation/pages/text_to_sign_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.initializeDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionManagerBloc>(
      create: (context) => sl<SessionManagerBloc>(),
      child: MaterialApp(
        title: 'Ahenkan',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const TextToSignScreen(),
      ),
    );
  }
}
