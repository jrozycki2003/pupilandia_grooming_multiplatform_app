/// \file daily_calendar.dart
/// \brief Strona kalendarza dziennego z dostępnymi terminami
/// 
/// Wyświetla calendar z godzinami pracy i zajętością terminów.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/services/database.dart';

/// \class DailyCalendarPage
/// \brief Widget strony kalendarza dziennego
class DailyCalendarPage extends StatefulWidget {
  const DailyCalendarPage({super.key});

  @override
  State<DailyCalendarPage> createState() => _DailyCalendarPageState();
}

/// \class _DailyCalendarPageState
/// \brief Stan strony kalendarza dziennego
class _DailyCalendarPageState extends State<DailyCalendarPage> {
  DateTime _selectedDate = DateTime.now(); ///< Wybrana data
  String? _selectedHour; ///< Wybrana godzina

  /// \brief Generuje listę przedziałów czasowych (co 15 minut, 8:00-19:00)
  /// \return Lista slotów czasowych w formacie "HH:MM"
  List<String> get _timeSlots {
    final slots = <String>[];
    for (var h = 8; h <= 19; h++) {
      for (var m = 0; m < 60; m += 15) {
        slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
        if (h == 19 && m == 0) break;
      }
    }
    return slots;
  }

  /// \brief Paleta kolorów dla wizualizacji
  final List<Color> _colors = [
    Color(0xFFF06292),
    Color(0xFF8268DC),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
  ];

  /// \brief Zwraca godziny pracy dla danej daty
  /// \param date Data do sprawdzenia
  /// \return String z godzinami pracy lub "Nieczynne"
  String _getWorkingHours(DateTime date) {
    final wd = date.weekday;
    if (wd == DateTime.sunday) return 'Nieczynne';
    if (wd == DateTime.saturday) return '09:00-16:00';
    return '09:00-18:00';
  }

  /// \brief Sprawdza czy godzina mieści się w godzinach pracy
  /// \param time Godzina w formacie "HH:MM"
  /// \param date Data do sprawdzenia
  /// \return true jeśli godzina jest w godzinach pracy
  bool _isTimeInWorkingHours(String time, DateTime date) {
    final wd = date.weekday;
    if (wd == DateTime.sunday) return false;
    final start = wd == DateTime.saturday ? '09:00' : '09:00';
    final end = wd == DateTime.saturday ? '16:00' : '18:00';
    return time.compareTo(start) >= 0 && time.compareTo(end) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kalendarz rezerwacji'),
      ),
      body: Column(
        children: [
          // Wybór daty
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEE, dd MMM yyyy', 'pl_PL').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' • ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')} - 19:00',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedHour = null;
                      });
                    }
                  },
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),

          // Kalendarz dzienny
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseMethods().getGroomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Brak dostępnych groomerów',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                final groomers = snapshot.data!.docs;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Nagłówek z pracownikami
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 80),
                            ...groomers.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final data = entry.value.data() as Map<String, dynamic>;
                              final firstName = data['firstName'] ?? '';
                              final lastName = data['lastName'] ?? '';
                              final name = '$firstName $lastName'.trim();
                              final color = _colors[idx % _colors.length];

                              return Expanded(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: color,
                                      child: Text(
                                        firstName.isNotEmpty ? firstName[0] : 'G',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name.isEmpty ? 'Groomer' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _getWorkingHours(_selectedDate),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Lista godzin z dostępnością
                      Expanded(
                        child: ListView.builder(
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final time = _timeSlots[index];
                            final isSelected = _selectedHour == time;

                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                color: isSelected ? const Color(0xFFFFEBF1) : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? const Color(0xFFD81B60) : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...groomers.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final color = _colors[idx % _colors.length];
                                    final inHours = _isTimeInWorkingHours(time, _selectedDate);

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: inHours ? () => setState(() => _selectedHour = time) : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(right: BorderSide(color: Colors.grey[300]!)),
                                            color: isSelected && inHours
                                                ? const Color(0xFFFFEBF1)
                                                : inHours
                                                    ? Colors.grey[50]
                                                    : Colors.grey[200],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              inHours ? Icons.check_circle_outline : Icons.block,
                                              color: inHours ? color : Colors.grey[400],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Przycisk rezerwacji
          if (_selectedHour != null)
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Wybrano: ${DateFormat('dd.MM.yyyy').format(_selectedDate)} o $_selectedHour'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Zarezerwuj wizytę'),
              ),
            ),
        ],
      ),
    );
  }
}
