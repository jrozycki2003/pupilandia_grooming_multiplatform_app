/// \file onboarding.dart
/// \brief Ekran powitalny aplikacji
/// 
/// Wyświetlany przy pierwszym uruchomieniu na urządzeniach mobilnych.

import 'package:flutter/material.dart';

import 'home.dart';

/// \class Onboarding
/// \brief Widget ekranu powitalnego
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

/// \class _OnboardingState
/// \brief Stan ekranu powitalnego
class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    final pink = const Color(0xFFF06292);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Illustration
              Expanded(
                child: Center(
                  child: Image.asset('images/barber.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Szczęśliwy zwierzak, \nzadowolony właściciel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Text(
                'Twój pupil zasługuje na najlepszą pielęgnację',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              // Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Home()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Rozpocznij',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

