import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
          "SUPABASE_URL or SUPABASE_ANON_KEY is missing in .env file!");
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );

    debugPrint("Supabase Cloud Initialized Successfully!");
  } catch (e, stackTrace) {
    debugPrint("Initialization Error: $e");
    debugPrint("Stacktrace: $stackTrace");
  }

  runApp(const LawJunctionApp());
}

class LawJunctionApp extends StatelessWidget {
  const LawJunctionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Law Junction',
      debugShowCheckedModeBanner: false,

      // ✅ থিম সেটআপ (ডিজাইনের সাথে হুবহু মিল)
      theme: ThemeData(
        useMaterial3: true,

        // ১. ব্যাকগ্রাউন্ড কালার (গাঢ় নীল)
        scaffoldBackgroundColor: const Color(0xFF032836),

        // ২. প্রাইমারি ও সেকেন্ডারি কালার
        primaryColor: const Color(0xFFE5B25D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5B25D), // সোনালী (বাটন, আইকন)
          secondary: Color(0xFFE5B25D), // সোনালী
          surface: Color(0xFF0F2C3E), // কার্ড
          background: Color(0xFF032836), // ব্যাকগ্রাউন্ড
        ),

        // ৩. অ্যাপ বার
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF032836),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // ৪. কার্ড
        cardTheme: CardThemeData(
          color: const Color(0xFF0F2C3E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
        ),

        // ৫. ইনপুট ফিল্ড
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF07384A).withValues(alpha: 0.4),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIconColor: Colors.white70,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1B5368)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5B25D)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),

        // ৬. টেক্সট
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ৭. বটম নেভিগেশন বার
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF032836),
          selectedItemColor: Color(0xFFE5B25D),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // ৮. ফ্লোটিং অ্যাকশন বাটন
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE5B25D),
          foregroundColor: Color(0xFF032836),
        ),

        // ৯. এলিভেটেড বাটন
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5B25D),
            foregroundColor: const Color(0xFF032836),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),

      home: const AuthGate(),
    );
  }
}
