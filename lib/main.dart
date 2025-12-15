import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

import 'services/ai_feedback_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Background services temporarily disabled due to Android build issues
  // Notifications will be re-enabled later

  // Prefetch daily tips if user is logged in
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Don't await this, let it run in background to not block UI
      AIFeedbackService(user.uid).generateDailyTipsBatch();
    }
  } catch (e) {
    print('Error prefetching tips: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A2F1F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MariApp());
}

class MariApp extends StatelessWidget {
  const MariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mari - Almanca Öğrenme Asistanı',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
