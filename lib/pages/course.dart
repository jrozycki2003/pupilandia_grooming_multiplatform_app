/// \file course.dart
/// \brief Strona prezentująca kurs groomerski
/// 
/// Zawiera informacje o programie, cenie i kontakcie dla kursu groomingu.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kubaproject/pages/daily_calendar.dart';

/// \class CoursePage
/// \brief Widget strony kursu groomerskiego
class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pink = const Color(0xFFF06292);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Kurs groomerski')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 700 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek i opis
              const Text(
                'Zostań groomerem – kompleksowy kurs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Praktyczny kurs przygotowujący do samodzielnej pracy groomera. Małe grupy, dużo praktyki, nowoczesne techniki pielęgnacji.',
                style: TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Informacja o certyfikacie
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Po ukończeniu kursu uczestnik otrzymuje imienny certyfikat potwierdzający zdobyte umiejętności.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Program kursu
              const Text(
                'Program kursu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _programItem('Podstawy pielęgnacji i BHP w salonie'),
              _programItem('Anatomia skóry i sierści, rodzaje sierści'),
              _programItem('Dobór kosmetyków i narzędzi'),
              _programItem('Techniki kąpieli, suszenia i rozczesywania'),
              _programItem('Strzyżenie i trymowanie – techniki praktyczne'),
              _programItem('Praca z trudnymi zwierzętami – bezpieczeństwo'),
              _programItem('Organizacja pracy i obsługa klienta'),

              const SizedBox(height: 20),

              // Cena kursu
              const Text(
                'Cena kursu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '5500 zł (zawiera materiały szkoleniowe i certyfikat)',
                  style: TextStyle(color: Colors.black87),
                ),
              ),

              const SizedBox(height: 20),

              // Zapisy – kontakt
              const Text(
                'Zapisy i kontakt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SelectableText('Telefon: +48 123 456 789'),
                    SizedBox(height: 8),
                    SelectableText('E-mail: kurs@pupilandia.pl'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}

/// \brief Tworzy element listy programu kursu
/// \param text Treść punktu programu
/// \return Widget reprezentujący element
Widget _programItem(String text) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.black54, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );
}

/// \brief Tworzy element listy daty kursu
/// \param text Informacja o dacie
/// \return Widget reprezentujący element daty
Widget _dateItem(String text) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_available, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ),
  );
}
