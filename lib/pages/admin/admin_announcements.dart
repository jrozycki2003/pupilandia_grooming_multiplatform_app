/// \file admin_announcements.dart
/// \brief Moduł zarządzania ogłoszeniami w panelu administratora
/// 
/// Umożliwia dodawanie, edycję i usuwanie ogłoszeń wyświetlanych na stronie głównej.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kubaproject/services/database.dart';
import 'package:intl/intl.dart';

/// \class AdminAnnouncementsPage
/// \brief Widget strony zarządzania ogłoszeniami
class AdminAnnouncementsPage extends StatefulWidget {
  final bool isEmployee;
  const AdminAnnouncementsPage({super.key, this.isEmployee = false});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

/// \class _AdminAnnouncementsPageState
/// \brief Stan dla strony zarządzania ogłoszeniami
class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final _db = DatabaseMethods(); ///< Instancja do obsługi bazy danych

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Color(0xFFF06292),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ogłoszenia na stronę główną',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dodawaj komunikaty, np. o przerwie lub zamknięciu salonu',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj ogłoszenie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Brak ogłoszeń', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Buduje kartę pojedynczego ogłoszenia
  /// \param id Identyfikator ogłoszenia w bazie danych
  /// \param data Dane ogłoszenia
  /// \return Widget reprezentujący ogłoszenie
  Widget _buildCard(String id, Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    final startAt = data['startAt'] is Timestamp ? (data['startAt'] as Timestamp).toDate() : null;
    final endAt = data['endAt'] is Timestamp ? (data['endAt'] as Timestamp).toDate() : null;
    final pinned = data['pinned'] == true;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF06292).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(pinned ? Icons.push_pin : Icons.campaign, color: const Color(0xFFF06292)),
        ),
        title: Text(title.isEmpty ? 'Bez tytułu' : title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if (message.isNotEmpty) Text(message),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text('${startAt != null ? df.format(startAt) : 'od teraz'}'),
                if (endAt != null) ...[
                  const SizedBox(width: 8),
                  const Text('–'),
                  const SizedBox(width: 8),
                  Text(df.format(endAt)),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditDialog(context, id: id, data: data),
            ),
            if (!widget.isEmployee)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, id, title),
              ),
          ],
        ),
      ),
    );
  }

  /// \brief Wyświetla dialog potwierdzenia usunięcia
  /// \param context Kontekst buildera
  /// \param id Identyfikator ogłoszenia
  /// \param title Tytuł ogłoszenia
  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń ogłoszenie'),
        content: Text('Czy na pewno chcesz usunąć "${title.isEmpty ? 'Bez tytułu' : title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteAnnouncement(id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  /// \brief Wyświetla dialog dodawania/edycji ogłoszenia
  /// \param context Kontekst buildera
  /// \param id Opcjonalny identyfikator ogłoszenia (dla edycji)
  /// \param data Opcjonalne dane ogłoszenia (dla edycji)
  void _showAddEditDialog(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementDialog(id: id, data: data),
    );
  }
}

/// \class _AnnouncementDialog
/// \brief Dialog do dodawania i edycji ogłoszenia
class _AnnouncementDialog extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? data;
  const _AnnouncementDialog({this.id, this.data});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

/// \class _AnnouncementDialogState
/// \brief Stan dialogu ogłoszenia
class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  bool _pinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _titleController.text = (widget.data!['title'] ?? '').toString();
      _messageController.text = (widget.data!['message'] ?? '').toString();
      _pinned = widget.data!['pinned'] == true;
      if (widget.data!['startAt'] is Timestamp) {
        _startAt = (widget.data!['startAt'] as Timestamp).toDate();
      }
      if (widget.data!['endAt'] is Timestamp) {
        _endAt = (widget.data!['endAt'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// \brief Otwiera selektor daty i czasu
  /// \param isStart Czy wybieramy datę rozpoczęcia (true) czy zakończenia (false)
  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final init = isStart ? (_startAt ?? now) : (_endAt ?? now.add(const Duration(hours: 1)));
    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startAt = dt;
        if (_endAt != null && _endAt!.isBefore(_startAt!)) {
          _endAt = _startAt!.add(const Duration(hours: 1));
        }
      } else {
        _endAt = dt;
      }
    });
  }

  /// \brief Zapisuje ogłoszenie do bazy danych
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ustaw datę rozpoczęcia')), 
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'startAt': Timestamp.fromDate(_startAt!),
        if (_endAt != null) 'endAt': Timestamp.fromDate(_endAt!),
        'pinned': _pinned,
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.id == null) 'createdAt': FieldValue.serverTimestamp(),
      };
      final db = DatabaseMethods();
      if (widget.id == null) {
        await db.addAnnouncement(data);
      } else {
        await db.updateAnnouncement(widget.id!, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 520.0 : screenWidth * 0.9;

    return AlertDialog(
      title: Text(widget.id == null ? 'Dodaj ogłoszenie' : 'Edytuj ogłoszenie'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Tytuł'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Treść',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wpisz treść' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(isStart: true),
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(_startAt == null ? 'Ustaw start' : 'Start: ${df.format(_startAt!)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(isStart: false),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: Text(_endAt == null ? 'Ustaw koniec (opcjonalnie)' : 'Koniec: ${df.format(_endAt!)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                  title: const Text('Przypięte'),
                  subtitle: const Text('Wyświetlane w pierwszej kolejności'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Anuluj')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF06292)),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.id == null ? 'Dodaj' : 'Zapisz'),
        ),
      ],
    );
  }
}
