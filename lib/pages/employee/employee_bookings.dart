/// \file employee_bookings.dart
/// \brief Widok rezerwacji dla pracownika w stylu planu lekcji
///
/// Wyświetla tygodniowy harmonogram rezerwacji dla wybranego pracownika

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeBookingsPage extends StatefulWidget {
  const EmployeeBookingsPage({super.key});

  @override
  State<EmployeeBookingsPage> createState() => _EmployeeBookingsPageState();
}

class _EmployeeBookingsPageState extends State<EmployeeBookingsPage> {
  String? _selectedGroomerId;
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  List<Map<String, dynamic>> _groomers = [];
  bool _loading = true;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static DateTime _getWeekStart(DateTime date) {
    // Poniedziałek jako pierwszy dzień tygodnia
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadGroomers();
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    return _selectedWeekStart.year == currentWeekStart.year &&
        _selectedWeekStart.month == currentWeekStart.month &&
        _selectedWeekStart.day == currentWeekStart.day;
  }

  String _formatTimeRange(String startTime, int durationMinutes) {
    try {
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final startMinutes = hour * 60 + minute;
        final endMinutes = startMinutes + durationMinutes;

        final endHour = (endMinutes ~/ 60) % 24;
        final endMinute = endMinutes % 60;

        return '$startTime - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} ($durationMinutes min)';
      }
    } catch (e) {
      // Jeśli parsowanie się nie powiedzie
    }
    return '$startTime ($durationMinutes min)';
  }

  Future<void> _loadGroomers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('groomers').get();

      setState(() {
        _groomers =
            snapshot.docs.map((doc) {
              final data = doc.data();
              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final fullName = '$firstName $lastName'.trim();

              return {
                'id': doc.id,
                'name': fullName.isEmpty ? 'Bez nazwy' : fullName,
                ...data,
              };
            }).toList();

        if (_groomers.isNotEmpty && _selectedGroomerId == null) {
          _selectedGroomerId = _groomers[0]['id'];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_groomers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(child: Text('Brak pracowników w systemie')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekSelector(),
          Expanded(child: _buildWeeklySchedule()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final padding =
        _isAndroid ? const EdgeInsets.all(12) : const EdgeInsets.all(24);
    final iconSize = _isAndroid ? 24.0 : 32.0;
    final titleFontSize = _isAndroid ? 14.0 : 16.0;
    final subtitleFontSize = _isAndroid ? 12.0 : 14.0;
    final dropdownFontSize = _isAndroid ? 13.0 : 16.0;
    final dropdownPadding =
        _isAndroid
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Container(
      padding: padding,
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
          Icon(
            Icons.calendar_month,
            color: const Color(0xFF4CAF50),
            size: iconSize,
          ),
          SizedBox(width: _isAndroid ? 8 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harmonogram',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (!_isAndroid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tygodniowy plan wizyt',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: dropdownPadding,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(_isAndroid ? 8 : 12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedGroomerId,
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: const Color(0xFF4CAF50),
                size: _isAndroid ? 20 : 24,
              ),
              style: TextStyle(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: dropdownFontSize,
              ),
              items:
                  _groomers.map((groomer) {
                    return DropdownMenuItem<String>(
                      value: groomer['id'] as String,
                      child: Text(groomer['name'] ?? 'Bez nazwy'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroomerId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final padding =
        _isAndroid
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final fontSize = _isAndroid ? 14.0 : 18.0;
    final badgeFontSize = _isAndroid ? 10.0 : 12.0;
    final iconSize = _isAndroid ? 20.0 : 24.0;

    return Container(
      padding: padding,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.subtract(
                  const Duration(days: 7),
                );
              });
            },
          ),
          Column(
            children: [
              Text(
                '${DateFormat('d MMM', 'pl_PL').format(_selectedWeekStart)} - ${DateFormat('d MMM yyyy', 'pl_PL').format(_selectedWeekStart.add(const Duration(days: 6)))}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isCurrentWeek())
                Container(
                  margin: EdgeInsets.only(top: _isAndroid ? 2 : 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: _isAndroid ? 8 : 12,
                    vertical: _isAndroid ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(_isAndroid ? 8 : 12),
                  ),
                  child: Text(
                    'Bieżący tydzień',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: iconSize),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _selectedWeekStart = _selectedWeekStart.add(
                  const Duration(days: 7),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    if (_selectedGroomerId == null) {
      return const Center(child: Text('Wybierz pracownika'));
    }

    // Znajdź imię i nazwisko wybranego groomera
    final selectedGroomer = _groomers.firstWhere(
      (g) => g['id'] == _selectedGroomerId,
      orElse: () => {},
    );
    final selectedGroomerName = selectedGroomer['name'] ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Booking').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Brak danych'));
        }

        // Filtruj rezerwacje dla wybranego groomera
        // Używamy pól groomerId i groomerName zamiast Groomer
        final filteredDocs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final groomerId = data['groomerId'] ?? '';
              final groomerName = data['groomerName'] ?? '';

              // Sprawdź czy groomerId lub groomerName pasuje
              return groomerId == _selectedGroomerId ||
                  groomerName == selectedGroomerName;
            }).toList();

        // Parsuj rezerwacje
        final bookings = _parseBookings(filteredDocs);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(child: _buildScheduleTable(bookings)),
        );
      },
    );
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _parseBookings(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> schedule = {};

    for (int i = 0; i < 7; i++) {
      final date = _selectedWeekStart.add(Duration(days: i));
      final dateKey = DateFormat('dd/MM/yyyy').format(date);
      schedule[dateKey] = {};

      for (int hour = 8; hour <= 18; hour++) {
        final timeKey = '${hour.toString().padLeft(2, '0')}:00';
        schedule[dateKey]![timeKey] = [];
      }
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['date'] as String?;
      final time = data['time'] as String?;

      if (date != null && time != null) {
        try {
          final parts = date.split('/');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = parts[1].padLeft(2, '0');
            final year = parts[2];
            final normalizedDate = '$day/$month/$year';
            final timeParts = time.split(':');
            if (timeParts.length >= 1) {
              final hour = int.tryParse(timeParts[0]);
              if (hour != null) {
                final timeKey = '${hour.toString().padLeft(2, '0')}:00';

                if (schedule.containsKey(normalizedDate) &&
                    schedule[normalizedDate]!.containsKey(timeKey)) {
                  String serviceText = 'Brak usługi';
                  final services = data['services'];
                  if (services is List && services.isNotEmpty) {
                    serviceText = services
                        .map((s) => s['name'] ?? s.toString())
                        .join(', ');
                  } else if (services is String) {
                    serviceText = services;
                  }

                  final totalDuration = data['totalDuration'] ?? 60;

                  final bookingData = {
                    'id': doc.id,
                    'name': data['Username'] ?? data['Name'] ?? 'Brak nazwy',
                    'email': data['Email'] ?? '',
                    'service': serviceText,
                    'time': time,
                    'duration': totalDuration,
                    'notes': data['notes'] ?? '',
                    'totalPrice': data['totalPrice'] ?? 0,
                    'allData': data,
                  };

                  schedule[normalizedDate]![timeKey]!.add(bookingData);
                }
              }
            }
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return schedule;
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Szczegóły rezerwacji',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('Klient', booking['name'], Icons.person),
                    _buildDetailRow('Email', booking['email'], Icons.email),
                    _buildDetailRow(
                      'Godzina rozpoczęcia',
                      booking['time'],
                      Icons.access_time,
                    ),
                    _buildDetailRow(
                      'Czas trwania',
                      _formatTimeRange(booking['time'], booking['duration']),
                      Icons.timer,
                    ),
                    _buildDetailRow('Usługi', booking['service'], Icons.spa),
                    _buildDetailRow(
                      'Cena',
                      '${booking['totalPrice']} zł',
                      Icons.payments,
                    ),
                    if (booking['notes'] != null &&
                        booking['notes'].toString().isNotEmpty)
                      _buildDetailRow('Notatki', booking['notes'], Icons.note),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable(
    Map<String, Map<String, List<Map<String, dynamic>>>> schedule,
  ) {
    final hourCellWidth = _isAndroid ? 40.0 : 80.0;
    final dayCellWidth = _isAndroid ? 100.0 : 200.0;
    final rowHeight = _isAndroid ? 50.0 : 80.0;

    final weekDays = List.generate(
      7,
      (i) => _selectedWeekStart.add(Duration(days: i)),
    );
    final hours = List.generate(11, (i) => 8 + i);

    return Container(
      margin: EdgeInsets.all(_isAndroid ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: hourCellWidth,
                height: _isAndroid ? 40 : 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      _isAndroid ? 'Godz.' : 'Godzina',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _isAndroid ? 10 : 14,
                      ),
                    ),
                  ),
                ),
              ),
              ...weekDays.map((date) {
                final isToday =
                    DateFormat('dd/MM/yyyy').format(date) ==
                    DateFormat('dd/MM/yyyy').format(DateTime.now());
                return SizedBox(
                  width: dayCellWidth,
                  height: _isAndroid ? 40 : 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isToday
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : Colors.grey[100],
                      border: Border.all(
                        color:
                            isToday
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[300]!,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isAndroid
                              ? DateFormat(
                                'EEE',
                                'pl_PL',
                              ).format(date).substring(0, 2)
                              : DateFormat('EEE', 'pl_PL').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _isAndroid ? 10 : 14,
                            color:
                                isToday
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black87,
                          ),
                        ),
                        if (!_isAndroid)
                          Text(
                            DateFormat('d MMM', 'pl_PL').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isToday
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[600],
                            ),
                          )
                        else
                          Text(
                            DateFormat('d/M', 'pl_PL').format(date),
                            style: TextStyle(
                              fontSize: 9,
                              color:
                                  isToday
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          // Wiersze z godzinami
          ...hours.map((hour) {
            return Row(
              children: [
                SizedBox(
                  width: hourCellWidth,
                  height: rowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: _isAndroid ? 9 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // Komórki dla każdego dnia
                ...weekDays.map((date) {
                  final dateKey = DateFormat('dd/MM/yyyy').format(date);
                  final timeKey = '${hour.toString().padLeft(2, '0')}:00';
                  final bookingsForSlot = schedule[dateKey]?[timeKey] ?? [];

                  return Container(
                    width: dayCellWidth,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.none,
                    child:
                        bookingsForSlot.isEmpty
                            ? const SizedBox()
                            : Stack(
                              clipBehavior: Clip.none,
                              children:
                                  bookingsForSlot.map((booking) {
                                    final duration = booking['duration'] as int;
                                    final startTime = booking['time'] as String;

                                    int startMinutes = 0;
                                    try {
                                      final parts = startTime.split(':');
                                      if (parts.length >= 2) {
                                        startMinutes = int.parse(parts[1]);
                                      }
                                    } catch (_) {}

                                    final topOffset =
                                        (startMinutes / 60.0) * rowHeight;
                                    final bookingHeight =
                                        (duration / 60.0) * rowHeight;

                                    return Positioned(
                                      top: topOffset,
                                      left: 4,
                                      right: 4,
                                      height: bookingHeight,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap:
                                              () =>
                                                  _showBookingDetails(booking),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: _isAndroid ? 3 : 5,
                                              vertical: _isAndroid ? 2 : 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4CAF50,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _isAndroid ? 4 : 6,
                                                  ),
                                              border: Border.all(
                                                color: const Color(0xFF4CAF50),
                                                width: _isAndroid ? 0.5 : 1.0,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        booking['time'],
                                                        style: TextStyle(
                                                          fontSize:
                                                              _isAndroid
                                                                  ? 7
                                                                  : 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                            0xFF4CAF50,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                _isAndroid
                                                                    ? 2
                                                                    : 4,
                                                            vertical:
                                                                _isAndroid
                                                                    ? 0.5
                                                                    : 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF4CAF50,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              _isAndroid
                                                                  ? 3
                                                                  : 6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${booking['duration']}min',
                                                        style: TextStyle(
                                                          fontSize:
                                                              _isAndroid
                                                                  ? 6
                                                                  : 8,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  booking['name'],
                                                  style: TextStyle(
                                                    fontSize:
                                                        _isAndroid ? 8 : 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (duration > 60) ...[
                                                  const SizedBox(height: 1),
                                                  Flexible(
                                                    child: Text(
                                                      booking['service'],
                                                      style: TextStyle(
                                                        fontSize:
                                                            _isAndroid ? 7 : 10,
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 4,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    booking['service'],
                                                    style: TextStyle(
                                                      fontSize:
                                                          _isAndroid ? 7 : 9,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const Spacer(),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.payments,
                                                      size: _isAndroid ? 7 : 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${booking['totalPrice']}zł',
                                                      style: TextStyle(
                                                        fontSize:
                                                            _isAndroid ? 7 : 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
