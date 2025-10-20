/// \file book_appointment.dart
/// \brief Strona rezerwacji wizyty
///
/// Kompleksowy system rezerwacji z wyborem usług, daty, godziny i groomera.
/// Obsługuje zarówno nowe rezerwacje jak i edycję istniejących.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kubaproject/services/database.dart';
import 'package:kubaproject/services/shared_pref.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:kubaproject/services/notifications.dart';

/// \class BookAppointmentPage
/// \brief Widget strony rezerwacji wizyty
class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({
    super.key,
    this.editBookingId,
    this.prefill,
    this.isAdmin = false,
  });

  final String? editBookingId;

  ///< ID rezerwacji do edycji (opcjonalne)
  final Map<String, dynamic>? prefill;

  ///< Dane wstępne dla formularza
  final bool isAdmin;

  ///< Czy używane w trybie admina

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

/// \class _BookAppointmentPageState
/// \brief Stan strony rezerwacji z pełną logiką rezerwacji
class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? name, image, email, userId;

  ///< Dane zalogowanego użytkownika
  final List<Map<String, dynamic>> _selectedServices = [];

  ///< Wybrane usługi
  final TextEditingController _notesController = TextEditingController();

  ///< Uwagi do rezerwacji
  final TextEditingController _adminNameController = TextEditingController();

  ///< Imię klienta (admin)
  final TextEditingController _adminEmailController = TextEditingController();

  ///< Email klienta (admin)

  DateTime _selectedDate = DateTime.now();

  ///< Wybrana data

  late DateTime _focusedDay;

  ///< Dzień w focus w kalendarzu
  late DateTime? _selectedDay;

  ///< Wybrany dzień w kalendarzu

  String? _selectedGroomerId;

  ///< ID wybranego groomera
  String? _selectedGroomerName;

  ///< Imię wybranego groomera

  /// \brief Zwraca godziny pracy dla danej daty
  /// \param date Data do sprawdzenia
  /// \return Mapa z godzinami 'start' i 'end' lub null dla niedzieli
  Map<String, String>? _workingHoursFor(DateTime date) {
    final wd = date.weekday;
    if (wd == DateTime.sunday) return null;
    if (wd == DateTime.saturday) return {'start': '09:00', 'end': '16:00'};
    return {'start': '09:00', 'end': '18:00'};
  }

  /// \brief Buduje sekcję danych klienta dla admina
  /// \return Widget z polami do wprowadzenia danych klienta
  Widget _buildAdminUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dane klienta (admin)',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _adminNameController,
                decoration: const InputDecoration(
                  labelText: 'Imię i nazwisko klienta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email klienta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<String>> _buildDailySlots(
    DateTime date, {
    int stepMinutes = 30,
  }) async {
    final wh = _workingHoursFor(date);
    if (wh == null) return [];
    DateTime parse(String hhmm) =>
        DateTime.parse('${date.toIso8601String().split('T')[0]}T$hhmm:00');
    final start = parse(wh['start']!);
    final end = parse(wh['end']!);
    final slots = <String>[];
    var t = start;
    while (t.isBefore(end)) {
      slots.add(
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
      );
      t = t.add(Duration(minutes: stepMinutes));
    }

    // Filter out slots where groomer is busy
    if (_selectedGroomerId != null) {
      final groomerBookings = await DatabaseMethods().getGroomerBookingsForDate(
        _selectedGroomerId!,
        date,
      );

      return slots.where((slot) {
        final slotTime = DateTime.parse(
          '${date.toIso8601String().split('T')[0]}T$slot:00',
        );
        final slotEnd = slotTime.add(Duration(minutes: _totalDurationMinutes));

        // Check if this slot conflicts with any booking
        for (final booking in groomerBookings) {
          final bookingStart = (booking['scheduledAt'] as Timestamp).toDate();
          final bookingEnd = (booking['endAt'] as Timestamp).toDate();

          // Check for overlap
          if (slotTime.isBefore(bookingEnd) && slotEnd.isAfter(bookingStart)) {
            return false; // Slot is busy
          }
        }
        return true; // Slot is available
      }).toList();
    }

    return slots;
  }

  String? _selectedHour;

  int get _totalDurationMinutes =>
      _selectedServices.fold<int>(0, (sum, s) => sum + (s['duration'] as int));
  num get _totalPrice =>
      _selectedServices.fold<num>(0, (sum, s) => sum + (s['price'] as num));

  Future<bool> _promptNotificationsPermission() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Włącz powiadomienia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chcesz otrzymać przypomnienie o wizycie 2 dni wcześniej? Włącz powiadomienia.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nie przegapisz wizyty – przypomnimy Ci o niej z wyprzedzeniem.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Może później'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok =
                            await NotificationsService.requestPermission();
                        if (ctx.mounted) Navigator.of(ctx).pop(ok);
                      },
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: const Text('Zezwól'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  String? _formatSelectedTimeRange() {
    if (_selectedHour == null || _totalDurationMinutes <= 0) return null;
    final parts = _selectedHour!.split(':');
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final end = start.add(Duration(minutes: _totalDurationMinutes));
    return '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
  }

  void _addService(Map<String, dynamic> svc) {
    final name = (svc['name'] ?? '').toString();
    if (_selectedServices.any((e) => e['name'] == name)) return;
    setState(() {
      _selectedServices.add({
        'name': name,
        'duration': (svc['duration'] ?? 60) as int,
        'price': (svc['price'] ?? 0),
      });
      _selectedHour = null;
    });
  }

  void _removeServiceAt(int index) {
    setState(() {
      _selectedServices.removeAt(index);
      _selectedHour = null;
    });
  }

  Future<void> _loadUser() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    email = await SharedPreferenceHelper().getUserEmail();
    userId = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  Future<void> _book() async {
    if (_selectedServices.isEmpty) {
      _showSnackBar('Dodaj co najmniej jedną usługę', isError: true);
      return;
    }

    if (_selectedGroomerId == null) {
      _showSnackBar('Wybierz groomera', isError: true);
      return;
    }

    if (_selectedHour == null) {
      _showSnackBar('Wybierz godzinę wizyty', isError: true);
      return;
    }

    final duration = _totalDurationMinutes;
    final isAvailable = await _isTimeSlotAvailable(_selectedHour!, duration);

    if (!isAvailable) {
      _showSnackBar(
        'Wybrany termin jest już zajęty. Wybierz inną godzinę.',
        isError: true,
      );
      return;
    }

    final parts = _selectedHour!.split(':');
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final end = start.add(Duration(minutes: duration));

    // pick user data depending on admin mode
    final bookingUsername =
        widget.isAdmin ? _adminNameController.text.trim() : (name ?? '');
    final bookingEmail =
        widget.isAdmin ? _adminEmailController.text.trim() : (email ?? '');

    if (widget.isAdmin && (bookingUsername.isEmpty || bookingEmail.isEmpty)) {
      _showSnackBar('Uzupełnij imię i email klienta', isError: true);
      return;
    }

    final booking = <String, dynamic>{
      'services':
          _selectedServices
              .map(
                (s) => {
                  'name': s['name'],
                  'duration': s['duration'],
                  'price': s['price'],
                },
              )
              .toList(),
      'totalDuration': duration,
      'totalPrice': _totalPrice,
      'date':
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      'time': _selectedHour,
      'Username': bookingUsername,
      'Image': image,
      'Email': bookingEmail,
      'notes': _notesController.text.trim(),
      'scheduledAt': Timestamp.fromDate(start),
      'endAt': Timestamp.fromDate(end),
      'groomerId': _selectedGroomerId,
      'groomerName': _selectedGroomerName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final editId = widget.editBookingId;
    if (editId != null && editId.isNotEmpty) {
      await DatabaseMethods().updateBooking(editId, {
        'services': booking['services'],
        'totalDuration': booking['totalDuration'],
        'totalPrice': booking['totalPrice'],
        'date': booking['date'],
        'time': booking['time'],
        'scheduledAt': booking['scheduledAt'],
        'endAt': booking['endAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await DatabaseMethods().addUserBooking(booking);
    }

    try {
      final reminderAt = start.subtract(const Duration(days: 2));
      if (reminderAt.isAfter(DateTime.now())) {
        var granted = await NotificationsService.isPermissionGranted();
        if (!granted && mounted) {
          granted = await _promptNotificationsPermission();
        }
        if (granted) {
          await NotificationsService.scheduleReminder(
            id: start.millisecondsSinceEpoch ~/ 1000,
            dateTime: reminderAt,
            title: 'Przypomnienie o wizycie',
            body:
                'Twoja wizyta: ${DateFormat('dd.MM.yyyy HH:mm').format(start)}. Do zobaczenia!',
          );
        }
      }
    } catch (_) {}

    if (!mounted) return;
    _showSnackBar('Wizyta została pomyślnie zarezerwowana! 🎉', isError: false);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = _selectedDay = _selectedDate = now;

    final p = widget.prefill;
    if (p != null) {
      final d = p['date'] as DateTime?;
      if (d != null) _selectedDate = _selectedDay = _focusedDay = d;
      _selectedHour = p['hour'] as String?;
      final services = p['services'] as List<dynamic>?;
      if (services != null) {
        _selectedServices.addAll(
          services.whereType<Map<String, dynamic>>().map(
            (s) => {
              'name': (s['name'] ?? '').toString(),
              'duration': (s['duration'] ?? 60) as int,
              'price': (s['price'] ?? 0),
            },
          ),
        );
      }
      // optional prefill of groomer for admin edit flow
      final preGroomerId = p['groomerId'] as String?;
      final preGroomerName = p['groomerName'] as String?;
      if (preGroomerId != null && preGroomerId.isNotEmpty) {
        _selectedGroomerId = preGroomerId;
        _selectedGroomerName = preGroomerName;
      }
      // optional prefill of user data if provided
      if (widget.isAdmin) {
        final preUserName = p['Username'] as String?;
        final preEmail = p['Email'] as String?;
        if (preUserName != null) _adminNameController.text = preUserName;
        if (preEmail != null) _adminEmailController.text = preEmail;
      }
    }
    _loadUser();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = _selectedDate = selectedDay;
      _focusedDay = focusedDay;
      _selectedHour = null;
    });
  }

  void _onPageChanged(DateTime focusedDay) =>
      setState(() => _focusedDay = focusedDay);

  Future<bool> _isTimeSlotAvailable(String time, int duration) async {
    if (_selectedGroomerId == null) return true;

    try {
      final startTime = DateTime.parse(
        '${_selectedDate.toIso8601String().split('T')[0]}T$time:00',
      );
      final endTime = startTime.add(Duration(minutes: duration));

      final bookings = await DatabaseMethods().getGroomerBookingsForDate(
        _selectedGroomerId!,
        _selectedDate,
      );

      for (var booking in bookings) {
        final bookingStart = (booking['scheduledAt'] as Timestamp).toDate();
        final bookingEnd = (booking['endAt'] as Timestamp).toDate();

        if (startTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<List<String>> _getAvailableHours() async {
    if (_selectedGroomerId == null || _selectedServices.isEmpty) {
      return _selectedGroomerId == null
          ? []
          : await _buildDailySlots(_selectedDate);
    }
    return await _buildDailySlots(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF06292).withOpacity(0.05),
              Colors.white,
              const Color(0xFF8268DC).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: kIsWeb ? 800 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.isAdmin) _buildAdminUserSection(),
                          _buildSelectedServices(),
                          const SizedBox(height: 24),
                          _buildGroomerSelection(),
                          const SizedBox(height: 24),
                          _buildCalendarSection(),
                          const SizedBox(height: 24),
                          _buildTimeSlots(),
                          const SizedBox(height: 24),
                          _buildNotesSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rezerwacja',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Umów wizytę dla swojego pupila',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Wybrane usługi',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedServices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedServices.length} ${_selectedServices.length == 1 ? "usługa" : "usługi"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_selectedServices.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Brak wybranych usług',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dodaj usługę aby rozpocząć',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                ..._selectedServices.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final dur = s['duration'] as int;
                  final price = s['price'];

                  return Column(
                    children: [
                      if (i > 0) Divider(height: 1, color: Colors.grey[200]),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          s['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text('${dur} min'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${price is num ? (price is int ? price.toString() : price.toStringAsFixed(2)) : price} zł',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFF06292),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeServiceAt(i),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              if (_selectedServices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF06292).withOpacity(0.1),
                        const Color(0xFF8268DC).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Łączna cena',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${_totalPrice == 0 ? '0' : (_totalPrice is int ? _totalPrice.toString() : (_totalPrice).toStringAsFixed(2))} zł',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Łączny czas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${_totalDurationMinutes} min',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showServicesBottomSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8268DC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Dodaj usługę'),
          ),
        ),
      ],
    );
  }

  Widget _buildGroomerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wybierz groomera',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseMethods().getGroomers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Brak dostępnych groomerów'),
              );
            }

            final groomers = snapshot.data!.docs;

            return Column(
              children:
                  groomers.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['firstName'] ?? '';
                    final lastName = data['lastName'] ?? '';
                    // Try both 'image' and 'imageUrl' fields
                    final image =
                        (data['image'] ?? data['imageUrl'] ?? '').toString();
                    final groomerId = doc.id;
                    final isSelected = _selectedGroomerId == groomerId;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGroomerId = groomerId;
                              _selectedGroomerName = '$firstName $lastName';
                              _selectedHour = null; // Reset time selection
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient:
                                  isSelected
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFFF06292),
                                          Color(0xFFEC407A),
                                        ],
                                      )
                                      : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFFF06292)
                                        : Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xFFF06292,
                                          ).withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isSelected
                                            ? Colors.white.withOpacity(0.3)
                                            : const Color(
                                              0xFFF06292,
                                            ).withOpacity(0.1),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            isSelected
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        image.isNotEmpty
                                            ? Image.network(
                                              image,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.low,
                                              cacheWidth: 120,
                                              cacheHeight: 120,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                );
                                              },
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                    color: Colors.grey.shade300,
                                                  ),
                                            )
                                            : Container(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                          .withOpacity(0.3)
                                                      : const Color(
                                                        0xFFF06292,
                                                      ).withOpacity(0.1),
                                              child: Icon(
                                                Icons.person,
                                                size: 32,
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFFF06292,
                                                        ),
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '$firstName $lastName',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wybierz datę',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            locale: 'pl_PL',
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (_) {},
            onPageChanged: _onPageChanged,
            startingDayOfWeek: StartingDayOfWeek.monday,
            enabledDayPredicate: (day) => day.weekday != DateTime.sunday,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF06292).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              todayDecoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(color: Colors.black87),
              defaultTextStyle: const TextStyle(color: Colors.black87),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Colors.black87,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.grey[600]),
              weekendStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_selectedGroomerId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.person_search, size: 32, color: Colors.grey[400]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Wybierz groomera, aby zobaczyć dostępne godziny.',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dostępne godziny',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (_formatSelectedTimeRange() != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF06292).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatSelectedTimeRange()!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF06292),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<String>>(
          future: _getAvailableHours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF06292)),
                ),
              );
            }

            final availableHours = snapshot.data ?? [];

            if (availableHours.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Brak dostępnych terminów',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wybierz inny dzień',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: availableHours.length,
              itemBuilder: (context, index) {
                final hour = availableHours[index];
                final isSelected = _selectedHour == hour;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHour = hour;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                              )
                              : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? Colors.transparent : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF06292,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                    ),
                    child: Center(
                      child: Text(
                        hour,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dodatkowe informacje',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Napisz dodatkowe uwagi lub preferencje...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(20),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, right: 12, top: 16),
                child: Icon(Icons.edit_note, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBookButton() {
    final isEnabled = _selectedServices.isNotEmpty && _selectedHour != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isEnabled ? _book : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF06292),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            widget.editBookingId != null
                ? 'Zaktualizuj wizytę'
                : 'Potwierdź rezerwację',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8268DC), Color(0xFF6B4FC3)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.spa,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wybierz usługi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Możesz wybrać wiele usług',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: DatabaseMethods().getServices(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF06292),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Błąd ładowania usług',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Brak dostępnych usług',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final Map<String, List<QueryDocumentSnapshot>> categorized =
                        {};
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final category = (data['category'] ?? 'Inne').toString();
                      if (!categorized.containsKey(category)) {
                        categorized[category] = [];
                      }
                      categorized[category]!.add(doc);
                    }

                    for (final category in categorized.keys) {
                      categorized[category]!.sort((a, b) {
                        final priceA =
                            (a.data() as Map<String, dynamic>)['price'] ?? 0;
                        final priceB =
                            (b.data() as Map<String, dynamic>)['price'] ?? 0;
                        final numA = priceA is num ? priceA : 0;
                        final numB = priceB is num ? priceB : 0;
                        return numB.compareTo(numA);
                      });
                    }

                    final categoryOrder = [
                      'Psy rasowe',
                      'Mały pies (do 3 kg)',
                      'Średni pies (3–10 kg)',
                      'Duży pies (powyżej 10 kg)',
                      'Koty',
                    ];

                    final List<Widget> items = [];
                    for (final category in categoryOrder) {
                      if (!categorized.containsKey(category)) continue;

                      String categoryIcon = '🐶';
                      Color categoryColor = const Color(0xFF8268DC);
                      if (category == 'Koty') {
                        categoryIcon = '🐱';
                        categoryColor = const Color(0xFFF06292);
                      }
                      if (category == 'Psy rasowe') {
                        categoryIcon = '🐕';
                        categoryColor = const Color(0xFF6B4FC3);
                      }

                      items.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor,
                                categoryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                categoryIcon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${categorized[category]!.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      for (final doc in categorized[category]!) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString();
                        final duration = (data['duration'] ?? 60) as int;
                        final price = (data['price'] ?? 0);
                        final isHighlighted = data['isHighlighted'] == true;
                        final already = _selectedServices.any(
                          (e) => e['name'] == name,
                        );

                        items.add(
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  already
                                      ? categoryColor.withOpacity(0.1)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    already ? categoryColor : Colors.grey[200]!,
                                width: already ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      already
                                          ? categoryColor
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  already ? Icons.check : Icons.add,
                                  color:
                                      already ? Colors.white : Colors.grey[600],
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight:
                                      isHighlighted
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                  fontSize: isHighlighted ? 15 : 14,
                                  color:
                                      already ? categoryColor : Colors.black87,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${duration} min',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${price is num ? (price is int ? price.toString() : price.toStringAsFixed(2)) : price} zł',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                              onTap: () {
                                _addService({
                                  'name': name,
                                  'duration': duration,
                                  'price': price,
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        );
                      }
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: items,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() {}));
  }
}
