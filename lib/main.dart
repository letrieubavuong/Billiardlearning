import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'models/theme_manager.dart';
import 'models/learning_progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();
  await LearningProgress.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BilliardTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Billiard Libre',
          debugShowCheckedModeBanner: false,
          theme: currentTheme.toThemeData(),
          themeMode: ThemeMode.dark,
          home: const WelcomePage(),
        );
      },
    );
  }
}
