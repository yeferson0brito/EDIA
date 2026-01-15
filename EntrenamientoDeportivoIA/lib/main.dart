import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/rolbasic_screen.dart';
import 'screens/roltrainer.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/record_screen.dart';
import 'screens/hydration_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(), // La pantalla de inicio será el Splash
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/rolbasic': (context) => rolbasic(),
        '/roltrainer': (context) => roltrainer(),
        '/onboarding': (context) => OnboardingScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/record': (context) => const RecordScreen(),
        '/hydration': (context) => const HydrationScreen(),
      },
    );
  }
}
