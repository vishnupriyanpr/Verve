

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'package:provider/provider.dart';
import 'progress_provider.dart';
import 'home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import for localization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Gemini
  Gemini.init(apiKey: "AIzaSyCswZ82FR-PQhLMmRtTfs1BworS1u-JH8U");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()), // Add ProgressProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Disable debug banner
        title: 'Verve',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
          useMaterial3: true,
        ),
        // Set up localization
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('ar', ''), // Arabic
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Set initial locale based on the device's locale or default to English
        locale: Locale('en', ''), // You can set this dynamically as per your preference
        initialRoute: '/', // Set initial route
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

