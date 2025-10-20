/// \file admin_bookings.dart
/// \brief Moduł zarządzania rezerwacjami w panelu administratora
///
/// Umożliwia przeglądanie, dodawanie, edycję i usuwanie rezerwacji klientów.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/services/database.dart';
import 'package:kubaproject/pages/book_appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// \class AdminBookingsPage
/// \brief Widget strony zarządzania rezerwacjami
///
/// Główny interfejs do zarządzania rezerwacjami, składający się z:
/// - Kalendarza do wyboru dnia
/// - Listy rezerwacji dla wybranego dnia
/// - Opcji dodawania, edycji, anulowania i usuwania rezerwacji
class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

/// \class _AdminBookingsPageState
/// \brief Stan dla strony zarządzania rezerwacjami
class _AdminBookingsPageState extends State<AdminBookingsPage> {
  /// Instancja do obsługi operacji na bazie danych
  final DatabaseMethods _db = DatabaseMethods();

  /// Aktualnie wybrany dzień w kalendarzu (domyślnie dzisiaj)
  DateTime _selectedDay = DateTime.now();

  /// Dzień, na którym skupiony jest kalendarz (do przewijania)
  DateTime _focusedDay = DateTime.now();

  /// Format wyświetlania kalendarza (tydzień/miesiąc/2 tygodnie)
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Sekcja nagłówka
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ikona sekcji z zaokrąglonym tłem
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFF06292),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Tytuł i opis sekcji
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel Rezerwacji',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Zarządzaj rezerwacjami klientów',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Przycisk dodawania nowej rezerwacji
                ElevatedButton.icon(
                  onPressed: () => _showAddBookingDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj Rezerwację'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Kalendarz
          Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              // Określ który dzień jest zaznaczony
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              // Callback przy zmianie formatu kalendarza (tydzień/miesiąc)
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              // Callback przy wyborze dnia
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              // Stylizacja kalendarza
              calendarStyle: CalendarStyle(
                // Styl dla zaznaczonego dnia
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFF06292),
                  shape: BoxShape.circle,
                ),
                // Styl dla dzisiejszego dnia
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFF06292).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                // Styl dla znaczników (dni z rezerwacjami)
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFF06292),
                  shape: BoxShape.circle,
                ),
              ),
              // Stylizacja nagłówka kalendarza
              headerStyle: const HeaderStyle(
                formatButtonVisible: true, // Pokaż przycisk zmiany formatu
                titleCentered: true, // Wycentruj tytuł miesiąca
                formatButtonShowsNext:
                    false, // Przycisk formatu nie pokazuje następnego
              ),
            ),
          ),
          // Lista rezerwacji
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek listy z datą
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rezerwacje na ${DateFormat('dd MMMM yyyy', 'pl_PL').format(_selectedDay)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Lista rezerwacji pobrana z bazy danych
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      // Pobierz rezerwacje dla wybranego dnia
                      future: _db.getBookingsForDate(_selectedDay),
                      builder: (context, snapshot) {
                        // Pokaż wskaźnik ładowania podczas pobierania
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Jeśli brak rezerwacji, pokaż pusty stan
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Brak rezerwacji na ten dzień',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Posortuj rezerwacje według godziny
                        final bookings = snapshot.data!;
                        bookings.sort((a, b) {
                          final timeA = a['time'] ?? '';
                          final timeB = b['time'] ?? '';
                          return timeA.compareTo(timeB);
                        });

                        // Wyświetl listę rezerwacji
                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: bookings.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildBookingCard(bookings[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Buduje kartę pojedynczej rezerwacji
  ///
  /// Karta wyświetla:
  /// - Godzinę rezerwacji (w kolorowym badge)
  /// - Nazwę usługi
  /// - Dane klienta (imię, email)
  /// - Przypisanego pracownika
  /// - Menu z opcjami: Edytuj, Anuluj, Usuń
  ///
  /// \param booking Dane rezerwacji z bazy danych
  /// \return Widget reprezentujący rezerwację
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id'] ?? '';

    // Pobierz nazwę usługi (obsługa starego i nowego formatu)
    String service = booking['Service'] ?? '';
    if (service.isEmpty) {
      // Nowy format - usługa w liście 'services'
      final services = booking['services'];
      if (services is List && services.isNotEmpty) {
        final first = services.first;
        if (first is Map && first['name'] != null) {
          service = first['name'].toString();
        }
      }
    }
    service = service.isEmpty ? 'Brak usługi' : service;

    // Pobierz inne dane rezerwacji
    final time = booking['time'] ?? '';
    final userName = booking['Username'] ?? 'Brak nazwy';
    final userEmail = booking['Email'] ?? '';
    final groomerName = booking['groomerName'] ?? 'Brak pracownika';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge z godziną rezerwacji
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Menu z opcjami akcji
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditBookingDialog(context, id, booking);
                        break;
                      case 'cancel':
                        _confirmCancelBooking(context, id, userName, time);
                        break;
                      case 'delete':
                        _confirmDeleteBooking(context, id, userName, time);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        // Opcja edycji
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edytuj'),
                            ],
                          ),
                        ),
                        // Opcja anulowania (zmienia status)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                size: 20,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Text('Anuluj'),
                            ],
                          ),
                        ),
                        // Opcja usunięcia (usuwa z bazy)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Usuń'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Nazwa usługi
            Row(
              children: [
                Icon(Icons.spa, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Dane klienta
            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      // Email (jeśli istnieje)
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Przypisany pracownik
            Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Pracownik: $groomerName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// \brief Otwiera stronę dodawania nowej rezerwacji
  ///
  /// Przekierowuje do BookAppointmentPage w trybie administratora
  /// z predefiniowaną datą (aktualnie wybrany dzień w kalendarzu)
  ///
  /// \param context Kontekst buildera
  Future<void> _showAddBookingDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BookAppointmentPage(
              isAdmin: true, // Tryb administratora
              prefill: {
                'date': _selectedDay, // Predefiniuj datę
              },
            ),
      ),
    );
    // Odśwież listę po powrocie
    if (mounted) setState(() {});
  }

  /// \brief Otwiera stronę edycji rezerwacji
  ///
  /// Proces:
  /// 1. Parsuj datę z różnych formatów (Timestamp lub String)
  /// 2. Przygotuj dane do predefiniowania formularza
  /// 3. Otwórz BookAppointmentPage w trybie edycji
  /// 4. Odśwież listę po powrocie
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator rezerwacji do edycji
  /// \param data Dane rezerwacji
  Future<void> _showEditBookingDialog(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    DateTime? date;
    try {
      // Spróbuj pobrać datę z Timestamp
      if (data['scheduledAt'] != null) {
        date = (data['scheduledAt'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        // Parsuj datę ze Stringa (format: dd/MM/yyyy)
        final parts = (data['date'] as String).split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]), // rok
            int.parse(parts[1]), // miesiąc
            int.parse(parts[0]), // dzień
          );
        }
      }
    } catch (_) {
      // Jeśli parsowanie się nie powiedzie, użyj wybranej daty
    }

    // Przygotuj dane do predefiniowania formularza
    final prefill = <String, dynamic>{
      'date': date ?? _selectedDay,
      'hour': data['time'],
      'services': (data['services'] is List) ? data['services'] : null,
      'groomerId': data['groomerId'],
      'groomerName': data['groomerName'],
      'Username': data['Username'],
      'Email': data['Email'],
    };

    // Otwórz stronę edycji
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BookAppointmentPage(
              isAdmin: true,
              editBookingId: id, // Tryb edycji - przekaż ID
              prefill: prefill,
            ),
      ),
    );
    // Odśwież listę po powrocie
    if (mounted) setState(() {});
  }

  /// \brief Wyświetla dialog potwierdzenia anulowania rezerwacji
  ///
  /// Anulowanie zmienia status rezerwacji na 'cancelled' bez usuwania z bazy.
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator rezerwacji
  /// \param userName Imię użytkownika (do wyświetlenia w dialogu)
  /// \param time Godzina rezerwacji (do wyświetlenia w dialogu)
  void _confirmCancelBooking(
    BuildContext context,
    String id,
    String userName,
    String time,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Anuluj Rezerwację'),
            content: Text(
              'Czy na pewno chcesz anulować rezerwację $userName o $time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nie'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Zaktualizuj status na 'cancelled'
                  await _db.updateBooking(id, {'status': 'cancelled'});
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Odśwież listę
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Anuluj Rezerwację'),
              ),
            ],
          ),
    );
  }

  /// \brief Wyświetla dialog potwierdzenia usunięcia rezerwacji
  ///
  /// Usunięcie trwale usuwa rezerwację z bazy danych.
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator rezerwacji
  /// \param userName Imię użytkownika (do wyświetlenia w dialogu)
  /// \param time Godzina rezerwacji (do wyświetlenia w dialogu)
  void _confirmDeleteBooking(
    BuildContext context,
    String id,
    String userName,
    String time,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Usuń Rezerwację'),
            content: Text(
              'Czy na pewno chcesz usunąć rezerwację $userName o $time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nie'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Usuń rezerwację z bazy danych
                  await _db.deleteBooking(id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Odśwież listę
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Usuń'),
              ),
            ],
          ),
    );
  }
}
