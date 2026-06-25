// lib/main.dart
// Entry point. Wraps the entire app in ProviderScope so Riverpod works
// throughout the widget tree without any boilerplate per-widget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/story_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — keeps layout predictable on all Android devices
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Extend content behind the status bar for the gradient effect
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    // ProviderScope is the root of Riverpod's dependency graph
    const ProviderScope(
      child: AiStoryBuddyApp(),
    ),
  );
}

class AiStoryBuddyApp extends StatelessWidget {
  const AiStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Story Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          brightness: Brightness.light,
        ),
        // Base text theme — child-friendly, round sans-serif
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
          ),
        ),
        // Ensure all buttons have rounded corners
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),
      home: const StoryScreen(),
    );
  }
}
