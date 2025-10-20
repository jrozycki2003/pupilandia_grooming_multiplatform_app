/// \file history.dart
/// \brief Strona historii wizyt użytkownika
/// 
/// Wyświetla listę nadchodzących i przeszłych wizyt z możliwością anulowania.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kubaproject/services/database.dart';
import 'package:kubaproject/services/shared_pref.dart';
import 'package:kubaproject/pages/book_appointment.dart';

/// \class HistoryPage
/// \brief Widget strony historii wizyt
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

/// \class _HistoryPageState
/// \brief Stan strony historii wizyt z animacjami
class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  String? currentUserEmail; ///< Email zalogowanego użytkownika
  String? currentUserName; ///< Imię zalogowanego użytkownika
  late AnimationController _animController; ///< Kontroler animacji

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// \brief Ładuje dane zalogowanego użytkownika
  Future<void> _loadUser() async {
    currentUserEmail = await SharedPreferenceHelper().getUserEmail();
    currentUserName = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  /// \brief Wyciąga datę rezerwacji z różnych formatów
  /// \param data Dane rezerwacji
  /// \return Data i czas rezerwacji lub null
  DateTime? _getScheduledDate(Map<String, dynamic> data) {
    if (data['scheduledAt'] is Timestamp) {
      return (data['scheduledAt'] as Timestamp).toDate();
    }
    try {
      final dateStr = data['date'] ?? '';
      final timeStr = data['time'] ?? '';
      if (dateStr.isEmpty || timeStr.isEmpty) return null;

      final dateParts = dateStr.split('/');
      final timeParts = timeStr.split(':');
      if (dateParts.length != 3 || timeParts.isEmpty) return null;

      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1].split(' ')[0]),
      );
    } catch (_) {
      return null;
    }
  }

  /// \brief Wyciąga czas trwania z danych rezerwacji
  /// \param data Dane rezerwacji
  /// \return Czas trwania w minutach
  int _getDuration(Map<String, dynamic> data) {
    final duration =
        data['totalDuration'] ??
        data['serviceDuration'] ??
        data['duration'] ??
        60;
    return duration is int ? duration : (duration as num).toInt();
  }

  /// \brief Wyciąga cenę z danych rezerwacji
  /// \param data Dane rezerwacji
  /// \return Cena usługi
  num _getPrice(Map<String, dynamic> data) {
    return data['totalPrice'] ?? data['servicePrice'] ?? data['price'] ?? 0;
  }

  /// \brief Wyciąga listę usług z danych rezerwacji
  /// \param data Dane rezerwacji
  /// \return Lista usług
  List<Map<String, dynamic>> _getServices(Map<String, dynamic> data) {
    if (data['services'] is List) {
      return (data['services'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [
      {
        'name': data['service'] ?? 'Usługa',
        'duration': _getDuration(data),
        'price': _getPrice(data),
      },
    ];
  }

  /// \brief Anuluje rezerwację po potwierdzeniu użytkownika
  /// \param bookingId Identyfikator rezerwacji
  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Odwołać wizytę?'),
            content: const Text('Czy na pewno chcesz odwołać tę wizytę?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nie'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8268DC),
                ),
                child: const Text('Tak', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await DatabaseMethods().deleteBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wizyta została odwołana.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _animController,
                curve: Curves.easeInOut,
              ),
              child: Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildBookingsList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Historia rezerwacji',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Nadchodzące'), Tab(text: 'Przeszłe')],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Booking').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || currentUserEmail == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final userBookings =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['Email'] ?? '') == currentUserEmail;
            }).toList();

        final now = DateTime.now();
        final upcoming =
            userBookings.where((d) {
                final date = _getScheduledDate(
                  d.data() as Map<String, dynamic>,
                );
                return date != null && date.isAfter(now);
              }).toList()
              ..sort((a, b) {
                final dateA =
                    _getScheduledDate(a.data() as Map<String, dynamic>)!;
                final dateB =
                    _getScheduledDate(b.data() as Map<String, dynamic>)!;
                return dateA.compareTo(dateB);
              });

        final past =
            userBookings.where((d) {
                final date = _getScheduledDate(
                  d.data() as Map<String, dynamic>,
                );
                return date == null || !date.isAfter(now);
              }).toList()
              ..sort((a, b) {
                final dateA =
                    _getScheduledDate(a.data() as Map<String, dynamic>) ??
                    DateTime(2000);
                final dateB =
                    _getScheduledDate(b.data() as Map<String, dynamic>) ??
                    DateTime(2000);
                return dateB.compareTo(dateA);
              });

        return TabBarView(
          children: [
            _buildBookingList(upcoming, isPast: false),
            _buildBookingList(past, isPast: true),
          ],
        );
      },
    );
  }

  Widget _buildBookingList(
    List<QueryDocumentSnapshot> docs, {
    required bool isPast,
  }) {
    if (docs.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPast ? Icons.history : Icons.event_available,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                isPast ? 'Brak przeszłych wizyt' : 'Brak nadchodzących wizyt',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildBookingCard(docs[index], isPast),
    );
  }

  Widget _buildBookingCard(QueryDocumentSnapshot doc, bool isPast) {
    final data = doc.data() as Map<String, dynamic>;
    final scheduledDate = _getScheduledDate(data);
    final duration = _getDuration(data);
    final price = _getPrice(data);
    final services = _getServices(data);
    final serviceNames = services
        .map((s) => s['name'] ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

    final dateStr =
        data['date'] ??
        (scheduledDate != null
            ? '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}'
            : '-');
    final timeStr =
        data['time'] ??
        (scheduledDate != null
            ? '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}'
            : '-');
    final endTime = scheduledDate?.add(Duration(minutes: duration));

    final now = DateTime.now();
    final isToday =
        scheduledDate != null &&
        scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.event, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceNames.isEmpty ? 'Wizyta' : serviceNames,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endTime != null
                          ? '$dateStr • $timeStr - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'
                          : '$dateStr • $timeStr',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${duration ~/ 60 > 0 ? '${duration ~/ 60}h ' : ''}${duration % 60}m',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.payments, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  price == 0
                      ? '-'
                      : (price is int
                          ? '$price zł'
                          : '${price.toStringAsFixed(2)} zł'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8268DC),
                  ),
                ),
              ],
            ),
          ),
          if (!isPast && !isToday) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(doc.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Odwołaj'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BookAppointmentPage(
                                editBookingId: doc.id,
                                prefill: {
                                  'date': scheduledDate,
                                  'hour': timeStr,
                                  'services': services,
                                },
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8268DC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Przełóż',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isPast)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FeedbackPage(
                                bookingId: doc.id,
                                currentUserEmail: currentUserEmail,
                                currentUserName: currentUserName,
                                services: services,
                              ),
                        ),
                      ),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Zostaw opinię'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  final String bookingId;
  final String? currentUserEmail;
  final String? currentUserName;
  final List<Map<String, dynamic>> services;

  const FeedbackPage({
    super.key,
    required this.bookingId,
    required this.currentUserEmail,
    required this.currentUserName,
    required this.services,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _submitting = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'bookingId': widget.bookingId,
        'email': widget.currentUserEmail,
        'name': widget.currentUserName,
        'services': widget.services,
        'comment': _controller.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Dziękujemy za opinię!'),
            ],
          ),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceNames = widget.services
        .map((s) => s['name'] ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

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
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animController,
              curve: Curves.easeInOut,
            ),
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF06292).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Twoja wizyta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                serviceNames.isEmpty ? 'Wizyta' : serviceNames,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Twoja opinia',
                          style: TextStyle(
                            fontSize: 18,
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
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: 'Napisz kilka słów o wizycie...',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 100),
                                child: Icon(
                                  Icons.rate_review_outlined,
                                  color: Color(0xFFF06292),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF06292).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submitting ? null : _submitFeedback,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child:
                                    _submitting
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Zapisz opinię',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Dodaj opinię',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
