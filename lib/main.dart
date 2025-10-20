/// \file main.dart
/// \brief Punkt wejścia aplikacji Pupilandia
/// 
/// Inicjalizuje Firebase, lokalizację i uruchamia aplikację.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kubaproject/pages/home.dart';
import 'package:kubaproject/pages/onboarding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kubaproject/services/notifications.dart';

import 'firebase_options.dart';

/// \brief Główna funkcja uruchamiająca aplikację
/// 
/// Inicjalizuje Firebase, powiadomienia i lokalizację polską.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationsService.initialize();
  // Initialize Polish locale data for DateFormat and set default locale
  await initializeDateFormatting('pl_PL');
  Intl.defaultLocale = 'pl_PL';
  runApp(const MyApp());
}

/// \class AuthChecker
/// \brief Widget sprawdzający stan autoryzacji użytkownika
/// 
/// Wyświetla odpowiedni ekran w zależności od stanu logowania.
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Ładowanie
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF06292)),
              ),
            ),
          );
        }

        // Jeśli użytkownik jest zalogowany
        if (snapshot.hasData && snapshot.data != null) {
          return const Home();
        }

        // Jeśli nie jest zalogowany
        // Na web NIE pokazujemy ekranu startowego (onboardingu)
        if (kIsWeb) {
          return const Home();
        }
        return const Onboarding();
      },
    );
  }
}

/// \class MyApp
/// \brief Główny widget aplikacji
/// 
/// Konfiguruje MaterialApp z motywem, lokalizacją i routing.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pupilandia',
      // Nazwa wyświetlana w menadżerze aplikacji
      debugShowCheckedModeBanner: false,
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [Locale('pl', 'PL'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF06292), // pink accent
          brightness: Brightness.light,
        ),
        primaryColor: const Color(0xFFF06292),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF06292),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFF06292)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF6F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF6F7FB),
          selectedColor: const Color(0xFFF06292),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ),
      home: const AuthChecker(),
    );
  }
}
