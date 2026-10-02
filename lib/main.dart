import 'package:flutter/material.dart';
import 'navigation/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MamedApp());
}

class MAMEDAppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        primary: const Color(0xFF1976D2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE3F2FD),
        foregroundColor: Color(0xFF0D47A1),
        elevation: 0,
      ),
    );
  }
}

class MamedApp extends StatelessWidget {
  const MamedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAMED',
      debugShowCheckedModeBanner: false,
      theme: MAMEDAppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}
