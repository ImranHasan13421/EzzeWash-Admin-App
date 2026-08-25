import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; // 1. Import OneSignal

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'features/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Supabase init
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 2. Enable OneSignal debug logs
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // 3. Initialize with your App ID
  OneSignal.initialize("2e24df5b-6024-428c-926e-641d10efe4f5");

  // 4. Prompt for notification permissions (Essential for Android 13+)
  OneSignal.Notifications.requestPermission(true);

  runApp(const MobileAdminApp());
}

final supabase = Supabase.instance.client;

class MobileAdminApp extends StatelessWidget {
  const MobileAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EzeeWash Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}