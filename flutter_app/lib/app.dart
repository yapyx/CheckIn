import 'package:flutter/material.dart';

import 'screens/checkin_home.dart';

class CheckInApp extends StatelessWidget {
  const CheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CheckIn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B63C9),
          primary: const Color(0xFF0B63C9),
          secondary: const Color(0xFF69ADFF),
          error: const Color(0xFFDC151B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamily: 'Inter',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFF9CA8B8)),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
      ),
      home: const CheckInHome(),
    );
  }
}
