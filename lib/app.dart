import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF00529C);
    return MaterialApp.router(
      title: 'Nhattrinhgang Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandBlue, brightness: Brightness.light),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F7FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: brandBlue, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}