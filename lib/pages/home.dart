/// \file home.dart
/// \brief Główna strona aplikacji Pupilandia
///
/// Kompleksowa strona główna z sekcjami: ogłoszenia, usługi, pracownicy,
/// galeria przed/po, porady, opinie, kontakt i mapa. Responsywny layout dla web i mobile.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kubaproject/pages/login.dart';
import 'package:kubaproject/pages/profile.dart';
import 'package:kubaproject/pages/history.dart';
import 'package:kubaproject/pages/admin_panel.dart';
import 'package:kubaproject/pages/employee_panel.dart';
import '../services/shared_pref.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database.dart';
import 'dart:async';
import 'package:kubaproject/pages/book_appointment.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kubaproject/pages/course.dart';
import 'package:kubaproject/pages/tip_detail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kubaproject/widgets/user_avatar.dart';
import 'package:kubaproject/utils/responsive_layout.dart';
import 'package:kubaproject/widgets/web_navbar.dart';
import 'package:kubaproject/widgets/web_animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// \class Home
/// \brief Widget głównej strony aplikacji
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

/// \class _BeforeAfterCard
/// \brief Widget karty porównania zdjęć "przed i po"
class _BeforeAfterCard extends StatelessWidget {
  final String beforeUrl;

  ///< URL zdjęcia "przed"
  final String afterUrl;

  ///< URL zdjęcia "po"
  final String title;

  ///< Tytuł wpisu
  final String description;

  ///< Opis wpisu

  const _BeforeAfterCard({
    required this.beforeUrl,
    required this.afterUrl,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek z gradientem
            if (title.isNotEmpty || description.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF06292).withOpacity(0.08),
                      const Color(0xFF8268DC).withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_fix_high,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Galeria PRZED/PO
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool isLarge = width >= 720;
                  final beforeCard = _GalleryImageCard(
                    url: beforeUrl,
                    label: 'PRZED',
                    labelGradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  );
                  final afterCard = _GalleryImageCard(
                    url: afterUrl,
                    label: 'PO',
                    labelGradient: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  );
                  if (isLarge) {
                    return Row(
                      children: [
                        Expanded(child: beforeCard),
                        const SizedBox(width: 20),
                        Container(
                          width: 2,
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: afterCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      beforeCard,
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      afterCard,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryImageCard extends StatefulWidget {
  final String url;
  final String label;
  final List<Color> labelGradient;

  const _GalleryImageCard({
    required this.url,
    required this.label,
    required this.labelGradient,
  });

  @override
  State<_GalleryImageCard> createState() => _GalleryImageCardState();
}

class _GalleryImageCardState extends State<_GalleryImageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.labelGradient.first.withOpacity(
                _isHovered ? 0.25 : 0.08,
              ),
              blurRadius: _isHovered ? 30 : 20,
              offset: Offset(0, _isHovered ? 12 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Obrazek
              if (widget.url.isNotEmpty)
                AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Image.network(
                    widget.url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(
                                    widget.labelGradient.first,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Ładowanie...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder:
                        (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[200]!],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Błąd ładowania',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[200]!],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_rounded,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Brak zdjęcia',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              // Gradient overlay - subtelny
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(_isHovered ? 0.15 : 0.25),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Label badge
              Positioned(
                left: 16,
                top: 16,
                child: AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: widget.labelGradient),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: widget.labelGradient.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.label == 'PO'
                              ? Icons.check_circle_rounded
                              : Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String? name, image;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String _selectedServiceFilter = 'Wszystkie';
  int _currentTabIndex = 0;
  bool _isAdmin = false;
  bool _isEmployee = false;

  String _formatPrice(dynamic price) {
    if (price == null) return '—';
    return price is int
        ? '$price zł'
        : '${(price as num).toStringAsFixed(2)} zł';
  }

  Widget _buildAnnouncements() {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseMethods().getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final items =
            docs.map((d) => d.data() as Map<String, dynamic>).where((data) {
              final startAt =
                  data['startAt'] is Timestamp
                      ? (data['startAt'] as Timestamp).toDate()
                      : null;
              final endAt =
                  data['endAt'] is Timestamp
                      ? (data['endAt'] as Timestamp).toDate()
                      : null;
              final started = startAt == null || !startAt.isAfter(now);
              final notEnded = endAt == null || !endAt.isBefore(now);
              return started && notEnded;
            }).toList();

        if (items.isEmpty) return const SizedBox.shrink();

        items.sort((a, b) {
          final pa = (a['pinned'] == true) ? 0 : 1;
          final pb = (b['pinned'] == true) ? 0 : 1;
          if (pa != pb) return pa - pb;
          final sa =
              a['startAt'] is Timestamp
                  ? (a['startAt'] as Timestamp).toDate()
                  : DateTime(2100);
          final sb =
              b['startAt'] is Timestamp
                  ? (b['startAt'] as Timestamp).toDate()
                  : DateTime(2100);
          return sa.compareTo(sb);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              items.map((data) {
                final title = (data['title'] ?? '').toString();
                final message = (data['message'] ?? '').toString();
                final pinned = data['pinned'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF06292).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Icon(
                        pinned ? Icons.push_pin : Icons.campaign,
                        color: const Color(0xFFF06292),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            if (message.isNotEmpty) ...[
                              if (title.isNotEmpty) const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    // Sprawdzenie uprawnień administratora w kolekcji "Admin"
    try {
      final user = FirebaseAuth.instance.currentUser;
      bool isAdmin = false;
      bool isEmployee = false;
      if (user != null) {
        final uid = user.uid;
        final email = user.email;
        
        // Sprawdź Admin - najpierw po email jako ID (zgodnie z regułami)
        if (email != null && email.isNotEmpty) {
          final docByEmail =
              await FirebaseFirestore.instance.collection('Admin').doc(email).get();
          if (docByEmail.exists) {
            isAdmin = true;
          } else {
            // Fallback: Sprawdź dokument po UID
            final docByUid =
                await FirebaseFirestore.instance.collection('Admin').doc(uid).get();
            if (docByUid.exists) {
              isAdmin = true;
            } else {
              // Ostatni fallback: query po polu email
              final q =
                  await FirebaseFirestore.instance
                      .collection('Admin')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
              isAdmin = q.docs.isNotEmpty;
            }
          }
        }
        
        // Sprawdzenie uprawnień pracownika w kolekcji "Employee"
        if (!isAdmin && email != null && email.isNotEmpty) {
          // Najpierw sprawdź po emailu jako ID dokumentu
          final docByEmail =
              await FirebaseFirestore.instance.collection('Employee').doc(email).get();
          if (docByEmail.exists) {
            isEmployee = true;
          } else {
            // Fallback: sprawdź po UID
            final docByUidEmployee =
                await FirebaseFirestore.instance.collection('Employee').doc(uid).get();
            if (docByUidEmployee.exists) {
              isEmployee = true;
            } else {
              // Ostatni fallback: query po polu email
              final qEmployee =
                  await FirebaseFirestore.instance
                      .collection('Employee')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
              isEmployee = qEmployee.docs.isNotEmpty;
            }
          }
        }
      }
      setState(() {
        _isAdmin = isAdmin;
        _isEmployee = isEmployee;
      });
    } catch (_) {
      // W przypadku błędu traktuj jako brak uprawnień
      setState(() {
        _isAdmin = false;
        _isEmployee = false;
      });
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isWebLayout = ResponsiveLayout.isWeb(context);

    if (isWebLayout) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [
            WebNavBar(
              currentIndex: _currentTabIndex,
              onTabChanged: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
            ),
            Expanded(child: _buildWebContent(isLoggedIn)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF06292).withOpacity(0.05),
                ],
              ),
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                    await _loadUserData();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF06292).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: UserAvatar(imageUrl: image, size: 36),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LogIn()),
                      ),
                  icon: const Icon(Icons.login),
                  label: const Text('Zaloguj się'),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFF06292),
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Color(0xFFF06292), width: 3),
                insets: EdgeInsets.symmetric(horizontal: 8),
              ),
              tabs: const [
                Tab(text: 'Strona Główna'),
                Tab(text: 'Usługi'),
                Tab(text: 'Porady'),
                Tab(text: 'Galeria'),
                Tab(text: 'Kontakt'),
              ],
            ),
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF06292).withOpacity(0.05),
                  const Color(0xFF8268DC).withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF06292).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: UserAvatar(imageUrl: image, size: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.home_outlined,
                      title: 'Strona Główna',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.calendar_today,
                      title: 'Rezerwacja',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookAppointmentPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Historia wizyt',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profil',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                        await _loadUserData();
                      },
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    if (_isAdmin)
                      _buildDrawerItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Panel Administratora',
                        color: const Color(0xFFF06292),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPanel(),
                            ),
                          );
                        },
                      ),
                    if (_isEmployee)
                      _buildDrawerItem(
                        icon: Icons.work,
                        title: 'Panel Pracowniczy',
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmployeePanel(),
                            ),
                          );
                        },
                      ),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Wyloguj',
                      color: Colors.redAccent,
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                        // Wyczyścić dane użytkownika z pamięci lokalnej
                        await SharedPreferenceHelper().saveUserName('');
                        await SharedPreferenceHelper().saveUserEmail('');
                        await SharedPreferenceHelper().saveUserImage('');
                        await SharedPreferenceHelper().saveUserId('');
                        if (!mounted) return;

                        // Przeładuj stronę główną (działa na web i mobile)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const Home()),
                          (_) => false,
                        );
                      },
                    ),
                  ] else ...[
                    _buildDrawerItem(
                      icon: Icons.login,
                      title: 'Zaloguj się',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LogIn()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: TabBarView(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PromoImageCard(
                      asset: 'images/main_baner.jpg',
                      showPromoOverlay: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildAnnouncements(),
                          const SizedBox(height: 16),
                          if (isLoggedIn) ...[
                            const _SectionHeader(
                              title: 'Nadchodzące wizyty',
                              icon: Icons.event,
                            ),
                            const SizedBox(height: 12),
                            UpcomingAppointmentsList(),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF06292),
                                    Color(0xFFEC407A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF06292,
                                    ).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const BookAppointmentPage(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Zarezerwuj wizytę',
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
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LogIn(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.login),
                                label: const Text(
                                  'Zaloguj się, by zarezerwować wizytę',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // Opinie klientów - pełna szerokość
                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Opinie klientów',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CustomerReviews(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GroomersSection(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.school, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kurs groomerski',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Zostań groomerem – praktyczny kurs z certyfikatem. Małe grupy, dużo praktyki.',
                                  style: TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CoursePage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8268DC),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.school),
                                    label: const Text(
                                      'Zobacz szczegóły kursu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _SectionHeader(
                            title: 'Lokalizacja i kontakt',
                            icon: Icons.place,
                          ),
                          const SizedBox(height: 12),
                          _LocationContact(),
                          const SizedBox(height: 16),
                          const _SocialMediaMenu(),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset('images/baner.jpg', fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            '🐕 Pakiety dla psów rasowych',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: DatabaseMethods().getServices(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final breedDocs =
                                  snapshot.data!.docs.where((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return data['category'] == 'Psy rasowe';
                                  }).toList();

                              // Sort by price descending
                              breedDocs.sort((a, b) {
                                final priceA =
                                    (a.data()
                                        as Map<String, dynamic>)['price'] ??
                                    0;
                                final priceB =
                                    (b.data()
                                        as Map<String, dynamic>)['price'] ??
                                    0;
                                final numA = priceA is num ? priceA : 0;
                                final numB = priceB is num ? priceB : 0;
                                return numB.compareTo(numA);
                              });

                              if (breedDocs.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: breedDocs.length,
                                  itemBuilder: (context, index) {
                                    final data =
                                        breedDocs[index].data()
                                            as Map<String, dynamic>;
                                    final name =
                                        (data['name'] ?? '').toString();
                                    final duration =
                                        (data['duration'] ?? 60) as int;
                                    final price = (data['price'] ?? 0);
                                    final description =
                                        (data['description'] ?? '').toString();
                                    final image =
                                        (data['image'] ?? '').toString();

                                    final priceStr =
                                        price is num
                                            ? (price is int
                                                ? '$price zł'
                                                : '${price.toStringAsFixed(2)} zł')
                                            : '$price zł';

                                    return Container(
                                      width: 280,
                                      margin: EdgeInsets.only(
                                        right:
                                            index < breedDocs.length - 1
                                                ? 12
                                                : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Background image or gradient
                                          if (image.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                image,
                                                fit: BoxFit.cover,
                                                filterQuality:
                                                    FilterQuality.low,
                                                cacheWidth: 560,
                                                cacheHeight: 360,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  progress,
                                                ) {
                                                  if (progress == null)
                                                    return child;
                                                  return Container(
                                                    color: Colors.grey[200],
                                                  );
                                                },
                                                errorBuilder:
                                                    (_, __, ___) => Container(
                                                      color: Colors.grey[300],
                                                    ),
                                              ),
                                            )
                                          else
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF8268DC),
                                                    const Color(0xFF6B4FC3),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          // Dark overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          // Content
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.pets,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$duration min',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    const Icon(
                                                      Icons.payments,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      priceStr,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: Text(
                                                    description,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                    maxLines: 4,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _ServiceFiltersSection(
                            currentFilter: _selectedServiceFilter,
                            onFilterChanged: (filter) {
                              setState(() {
                                _selectedServiceFilter = filter;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: DatabaseMethods().getServices(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text('Błąd ładowania usług'),
                                );
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F7FB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text('Brak usług w bazie.'),
                                  ),
                                );
                              }

                              // Group services by category
                              final Map<String, List<QueryDocumentSnapshot>>
                              categorized = {};
                              for (final doc in docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category =
                                    (data['category'] ?? 'Inne').toString();
                                if (!categorized.containsKey(category)) {
                                  categorized[category] = [];
                                }
                                categorized[category]!.add(doc);
                              }

                              for (final category in categorized.keys) {
                                categorized[category]!.sort((a, b) {
                                  final priceA =
                                      (a.data()
                                          as Map<String, dynamic>)['price'] ??
                                      0;
                                  final priceB =
                                      (b.data()
                                          as Map<String, dynamic>)['price'] ??
                                      0;
                                  final numA = priceA is num ? priceA : 0;
                                  final numB = priceB is num ? priceB : 0;
                                  return numB.compareTo(numA); // descending
                                });
                              }

                              // Define category order
                              final categoryOrder = [
                                'Mały pies (do 3 kg)',
                                'Średni pies (3–10 kg)',
                                'Duży pies (powyżej 10 kg)',
                                'Koty',
                              ];

                              // Filter categories based on selection
                              List<String> filteredCategories;
                              if (_selectedServiceFilter == 'Wszystkie') {
                                filteredCategories = categoryOrder;
                              } else if (_selectedServiceFilter ==
                                  'Mały pies') {
                                filteredCategories = ['Mały pies (do 3 kg)'];
                              } else if (_selectedServiceFilter ==
                                  'Średni pies') {
                                filteredCategories = ['Średni pies (3–10 kg)'];
                              } else if (_selectedServiceFilter ==
                                  'Duży pies') {
                                filteredCategories = [
                                  'Duży pies (powyżej 10 kg)',
                                ];
                              } else if (_selectedServiceFilter == 'Koty') {
                                filteredCategories = ['Koty'];
                              } else {
                                filteredCategories = categoryOrder;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    filteredCategories.map((category) {
                                      if (!categorized.containsKey(category)) {
                                        return const SizedBox.shrink();
                                      }

                                      final categoryDocs =
                                          categorized[category]!;
                                      String categoryIcon = '🐶';
                                      if (category == 'Koty')
                                        categoryIcon = '🐱';

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFFF06292,
                                                  ).withOpacity(0.1),
                                                  const Color(
                                                    0xFF8268DC,
                                                  ).withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  categoryIcon,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...categoryDocs.map((doc) {
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final name =
                                                (data['name'] ?? '').toString();
                                            final duration =
                                                (data['duration'] ?? 60) as int;
                                            final price = (data['price'] ?? 0);
                                            final description =
                                                (data['description'] ?? '')
                                                    .toString();
                                            final note =
                                                (data['note'] ?? '').toString();

                                            final priceStr =
                                                price is num
                                                    ? (price is int
                                                        ? '${price.toString()} zł'
                                                        : '${price.toStringAsFixed(2)} zł')
                                                    : '${price} zł';

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF6F7FB,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.schedule,
                                                          size: 18,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          '$duration min',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                      0xFF8268DC,
                                                                    ),
                                                                    Color(
                                                                      0xFF6B4FC3,
                                                                    ),
                                                                  ],
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            priceStr,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (description
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      description,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                  if (note.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'ℹ️ $note',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          const SizedBox(height: 8),
                                        ],
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Porady tab
              _TipsTab(),
              // Galeria tab
              _GalleryTab(),
              // Kontakt tab
              _ContactTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFFF06292)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? const Color(0xFFF06292), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWebContent(bool isLoggedIn) {
    final List<Widget> tabs = [
      _buildHomeTab(isLoggedIn),
      _buildServicesTab(),
      const _TipsTab(),
      const _GalleryTab(),
      const _ContactTab(),
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: tabs[_currentTabIndex],
        ),
      ),
    );
  }

  Widget _buildHomeTab(bool isLoggedIn) {
    return SingleChildScrollView(
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder:
                (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
            children: [
              Padding(
                padding: ResponsiveLayout.getPagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ResponsiveLayout.isWeb(context))
                      HoverScale(
                        scale: 1.02,
                        child: SizedBox(
                          width: double.infinity,
                          height: 320,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'images/main_baner.jpg',
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const _PromoImageCard(
                        asset: 'images/main_baner.jpg',
                        showPromoOverlay: true,
                      ),
                    const SizedBox(height: 32),
                    _buildAnnouncements(),
                    const SizedBox(height: 16),
                    if (isLoggedIn) ...[
                      const _SectionHeader(
                        title: 'Nadchodzące wizyty',
                        icon: Icons.event,
                      ),
                      const SizedBox(height: 16),
                      UpcomingAppointmentsList(),
                      const SizedBox(height: 24),
                      _HoverButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookAppointmentPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Zarezerwuj wizytę',
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
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: _HoverButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LogIn()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Zaloguj się, by zarezerwować wizytę',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Opinie klientów – przeniesione do sekcji ze stałymi paddingami
              Padding(
                padding: ResponsiveLayout.getPagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opinie klientów',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CustomerReviews(),
                    const SizedBox(height: 32),
                    const _GroomersSection(),
                    const SizedBox(height: 32),
                    _HoverButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CoursePage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8268DC).withOpacity(0.1),
                              const Color(0xFF6B4FC3).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8268DC).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8268DC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Kurs groomerski',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Zostań groomerem – praktyczny kurs z certyfikatem. Małe grupy, dużo praktyki.',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF8268DC),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _SectionHeader(
                      title: 'Lokalizacja i kontakt',
                      icon: Icons.place,
                    ),
                    const SizedBox(height: 16),
                    _LocationContact(),
                    const SizedBox(height: 24),
                    const _SocialMediaMenu(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return SingleChildScrollView(
      child: AnimationLimiter(
        child: Padding(
          padding: ResponsiveLayout.getPagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder:
                  (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
              children: [
                HoverScale(
                  scale: 1.02,
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('images/baner.jpg', fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Pakiety dla psów rasowych',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: DatabaseMethods().getServices(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final breedDocs =
                        snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['category'] == 'Psy rasowe';
                        }).toList();

                    breedDocs.sort((a, b) {
                      final priceA =
                          (a.data() as Map<String, dynamic>)['price'] ?? 0;
                      final priceB =
                          (b.data() as Map<String, dynamic>)['price'] ?? 0;
                      final numA = priceA is num ? priceA : 0;
                      final numB = priceB is num ? priceB : 0;
                      return numB.compareTo(numA);
                    });

                    if (breedDocs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final scrollController = ScrollController();
                    return SizedBox(
                      height: 240,
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.builder(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.only(
                            right: 24,
                            bottom: 12,
                            left: 4,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: breedDocs.length,
                          itemBuilder: (context, index) {
                            final data =
                                breedDocs[index].data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '').toString();
                            final duration = (data['duration'] ?? 60) as int;
                            final price = (data['price'] ?? 0);
                            final description =
                                (data['description'] ?? '').toString();
                            final image = (data['image'] ?? '').toString();

                            final priceStr =
                                price is num
                                    ? (price is int
                                        ? '$price zł'
                                        : '${price.toStringAsFixed(2)} zł')
                                    : '$price zł';

                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == breedDocs.length - 1 ? 0 : 16,
                              ),
                              child: _HoverServiceCard(
                                name: name,
                                duration: duration,
                                price: priceStr,
                                description: description,
                                imageUrl: image,
                                isLast: index == breedDocs.length - 1,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _ServiceFiltersSection(
                  currentFilter: _selectedServiceFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedServiceFilter = filter;
                    });
                  },
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: DatabaseMethods().getServices(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Błąd ładowania usług'));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Brak usług w bazie.')),
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
                      'Mały pies (do 3 kg)',
                      'Średni pies (3–10 kg)',
                      'Duży pies (powyżej 10 kg)',
                      'Koty',
                    ];

                    List<String> filteredCategories;
                    if (_selectedServiceFilter == 'Wszystkie') {
                      filteredCategories = categoryOrder;
                    } else if (_selectedServiceFilter == 'Mały pies') {
                      filteredCategories = ['Mały pies (do 3 kg)'];
                    } else if (_selectedServiceFilter == 'Średni pies') {
                      filteredCategories = ['Średni pies (3–10 kg)'];
                    } else if (_selectedServiceFilter == 'Duży pies') {
                      filteredCategories = ['Duży pies (powyżej 10 kg)'];
                    } else if (_selectedServiceFilter == 'Koty') {
                      filteredCategories = ['Koty'];
                    } else {
                      filteredCategories = categoryOrder;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          filteredCategories.map((category) {
                            if (!categorized.containsKey(category)) {
                              return const SizedBox.shrink();
                            }

                            final categoryDocs = categorized[category]!;
                            String categoryIcon = '🐶';
                            if (category == 'Koty') categoryIcon = '🐱';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFFF06292,
                                        ).withOpacity(0.1),
                                        const Color(
                                          0xFF8268DC,
                                        ).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        categoryIcon,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final spacing = 16.0;
                                    final int columns =
                                        ResponsiveLayout.getGridCrossAxisCount(
                                          context,
                                          mobile: 1,
                                          tablet: 2,
                                          desktop: 3,
                                        );
                                    final double availableWidth =
                                        constraints.maxWidth;
                                    final double totalSpacing =
                                        columns > 1
                                            ? spacing * (columns - 1)
                                            : 0;
                                    final double itemWidth =
                                        columns <= 1
                                            ? availableWidth
                                            : (availableWidth - totalSpacing) /
                                                columns;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: 16,
                                      children: [
                                        for (final doc in categoryDocs)
                                          () {
                                            final map =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final serviceName =
                                                (map['name'] ?? '').toString();
                                            final isLargeDogCategory =
                                                category ==
                                                'Duży pies (powyżej 25 kg)';
                                            final bool shouldToggle =
                                                isLargeDogCategory
                                                    ? serviceName
                                                        .toLowerCase()
                                                        .contains(
                                                          'pełna pielęgnacja',
                                                        )
                                                    : true;
                                            return SizedBox(
                                              width: itemWidth,
                                              child: _ServiceDetailTile(
                                                name: serviceName,
                                                duration:
                                                    ((map['duration'] ?? 60)
                                                        as int),
                                                price: _formatPrice(
                                                  map['price'],
                                                ),
                                                description:
                                                    (map['description'] ?? '')
                                                        .toString(),
                                                note:
                                                    (map['note'] ?? '')
                                                        .toString(),
                                                showToggle: shouldToggle,
                                                expandedInitially: false,
                                              ),
                                            );
                                          }(),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceDetailTile extends StatefulWidget {
  final String name;
  final int duration;
  final String price;
  final String description;
  final String note;
  final bool showToggle;
  final bool expandedInitially;

  const _ServiceDetailTile({
    required this.name,
    required this.duration,
    required this.price,
    required this.description,
    required this.note,
    this.showToggle = true,
    this.expandedInitially = false,
  });

  @override
  State<_ServiceDetailTile> createState() => _ServiceDetailTileState();
}

class _ServiceDetailTileState extends State<_ServiceDetailTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandedInitially;
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = widget.description.trim().isNotEmpty;
    final hasNote = widget.note.trim().isNotEmpty;
    return _HoverCard(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ChipInfo(
                            icon: Icons.schedule,
                            label: '${widget.duration} min',
                          ),
                          _ChipInfo(
                            icon: Icons.payments,
                            label: widget.price,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8268DC), Color(0xFF6B4FC3)],
                            ),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.showToggle && (hasDescription || hasNote))
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _isExpanded
                                  ? const Color(0xFFF06292)
                                  : Colors.grey.withOpacity(0.2),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Zwiń' : 'Szczegóły',
                            style: TextStyle(
                              color:
                                  _isExpanded
                                      ? const Color(0xFFF06292)
                                      : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color:
                                _isExpanded
                                    ? const Color(0xFFF06292)
                                    : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (hasDescription || hasNote)
              (widget.showToggle)
                  ? AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDescription)
                            Text(
                              widget.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          if (hasNote) ...[
                            const SizedBox(height: 10),
                            Text(
                              'ℹ️ ${widget.note}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    crossFadeState:
                        _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  )
                  : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDescription)
                          Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        if (hasNote) ...[
                          const SizedBox(height: 10),
                          Text(
                            'ℹ️ ${widget.note}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient? gradient;
  final TextStyle? labelStyle;

  const _ChipInfo({
    required this.icon,
    required this.label,
    this.gradient,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? const Color(0xFFF6F7FB) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(10),
    );
    final textStyle =
        labelStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: gradient == null ? Colors.grey[600] : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

// Using shared UserAvatar from widgets/user_avatar.dart

class UpcomingAppointmentsList extends StatefulWidget {
  @override
  State<UpcomingAppointmentsList> createState() =>
      _UpcomingAppointmentsListState();
}

class _UpcomingAppointmentsListState extends State<UpcomingAppointmentsList> {
  String? email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    email = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  DateTime? _extractScheduledAt(Map<String, dynamic> data) {
    final v = data['scheduledAt'];
    if (v is Timestamp) return v.toDate();
    try {
      final dateStr = (data['date'] ?? '') as String;
      final timeStr = (data['time'] ?? '') as String;
      if (dateStr.isEmpty || timeStr.isEmpty) return null;
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      final day = int.tryParse(parts[0]) ?? 1;
      final month = int.tryParse(parts[1]) ?? 1;
      final year = int.tryParse(parts[2]) ?? DateTime.now().year;
      final timeOfDay = TimeOfDay(
        hour: int.tryParse(timeStr.split(':').first) ?? 0,
        minute: int.tryParse(timeStr.split(':')[1].split(' ').first) ?? 0,
      );
      return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
    } catch (_) {
      return null;
    }
  }

  String _formatHM(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int _extractDurationMinutes(Map<String, dynamic> data) {
    final v =
        data['totalDuration'] ?? data['serviceDuration'] ?? data['duration'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 60;
  }

  num _extractTotalPrice(Map<String, dynamic> data) {
    final v = data['totalPrice'] ?? data['servicePrice'] ?? data['price'];
    if (v is num) return v;
    return 0;
  }

  List<Map<String, dynamic>> _extractServices(Map<String, dynamic> data) {
    final s = data['services'];
    if (s is List) {
      return s.whereType<Map<String, dynamic>>().toList();
    }
    // Fallback dla starszych wpisów
    final name = (data['service'] ?? 'Usługa').toString();
    final duration = _extractDurationMinutes(data);
    final price = _extractTotalPrice(data);
    return [
      {'name': name, 'duration': duration, 'price': price},
    ];
  }

  Future<void> _confirmCancel(String bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFF06292).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Odwołać wizytę?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Czy na pewno chcesz odwołać tę wizytę? Ta operacja jest nieodwracalna.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Anuluj',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Odwołaj wizytę',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (ok == true) {
      await DatabaseMethods().deleteBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wizyta odwołana.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (email == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return StreamBuilder(
      stream: DatabaseMethods().getUpcomingBookings(email!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docsAll = (snapshot.data as QuerySnapshot).docs;
        final now = DateTime.now();
        final docs =
            docsAll.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final dt = _extractScheduledAt(data);
                return dt != null && dt.isAfter(now);
              }).toList()
              ..sort((a, b) {
                final ad =
                    _extractScheduledAt(a.data() as Map<String, dynamic>)!;
                final bd =
                    _extractScheduledAt(b.data() as Map<String, dynamic>)!;
                return ad.compareTo(bd);
              });

        if (docs.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF06292).withOpacity(0.1),
                    const Color(0xFF8268DC).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF06292).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF06292).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_available,
                      size: 48,
                      color: Color(0xFFF06292),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Brak nadchodzących wizyt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Umów pierwszą wizytę dla swojego pupila!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children:
              docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final dt = _extractScheduledAt(data);
                final now = DateTime.now();
                final isToday =
                    dt != null &&
                    dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day;
                final durationMin = _extractDurationMinutes(data);
                final endDt = dt?.add(Duration(minutes: durationMin));
                final services = _extractServices(data);
                final serviceNames = services
                    .map((s) => (s['name'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .join(', ');
                final totalPrice = _extractTotalPrice(data);
                final date =
                    (data['date'] ??
                            (dt != null
                                ? '${dt.day}/${dt.month}/${dt.year}'
                                : '-'))
                        as String;
                final time =
                    (data['time'] ?? (dt != null ? _formatHM(dt) : '-'))
                        as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        const Color(0xFFF06292).withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border:
                        isToday
                            ? Border.all(
                              color: const Color(0xFFF06292),
                              width: 2,
                            )
                            : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header z gradient
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isToday
                                      ? [
                                        const Color(0xFFF06292),
                                        const Color(0xFFEC407A),
                                      ]
                                      : [
                                        const Color(0xFF8268DC),
                                        const Color(0xFF6B4FC3),
                                      ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serviceNames.isEmpty
                                          ? 'Wizyta'
                                          : serviceNames,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'DZISIAJ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Data i czas
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F7FB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Color(0xFFF06292),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          endDt != null
                                              ? '$time - ${_formatHM(endDt)}'
                                              : time,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Czas trwania i cena
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F7FB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            size: 18,
                                            color: Color(0xFF8268DC),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(durationMin ~/ 60) > 0 ? '${durationMin ~/ 60}h ' : ''}${durationMin % 60}min',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8268DC),
                                            Color(0xFF6B4FC3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.payments,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            totalPrice == 0
                                                ? 'Bezpłatne'
                                                : (totalPrice is int
                                                    ? '${totalPrice} zł'
                                                    : '${totalPrice.toStringAsFixed(2)} zł'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isToday) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          await _confirmCancel(d.id);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                          foregroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Odwołaj',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final prefill = {
                                            'date': dt,
                                            'hour': time,
                                            'services': services,
                                          };
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => BookAppointmentPage(
                                                    editBookingId: d.id,
                                                    prefill: prefill,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF06292,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.edit_calendar,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Przełóż',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CustomerReviews extends StatefulWidget {
  @override
  State<_CustomerReviews> createState() => _CustomerReviewsState();
}

class _CustomerReviewsState extends State<_CustomerReviews> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: StreamBuilder(
            stream: DatabaseMethods().getReviews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Nie udało się pobrać opinii'));
              }
              final docs = (snapshot.data as QuerySnapshot?)?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Brak opinii. Bądź pierwszym!'),
                  ),
                );
              }
              return PageView.builder(
                controller: _pageController,
                padEnds: false,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final reviewer = (data['reviewer'] ?? '') as String;
                  final comment = (data['comment'] ?? '') as String;
                  return Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            comment,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '- ${reviewer.split(' ').first}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const _AddReviewPage(),
                  fullscreenDialog: true,
                ),
              );
              if (created == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dziękujemy za opinię!')),
                );
              }
            },
            child: const Text(
              'Dodaj opinię',
              style: TextStyle(
                color: Color(0xFF8268DC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationContact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.black87),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "ul. Przykładowa 2, 41-407 Imielin",
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                "Pon-Pt: 9:00-18:00, Sob: 9:00-16:00",
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                "+48 517 800 442",
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialMediaMenu extends StatelessWidget {
  const _SocialMediaMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Obserwuj nas w social media',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BrandIcon(
                icon: FontAwesomeIcons.facebookF,
                color: const Color(0xFF1877F2),
                label: 'Facebook',
                url: 'https://www.facebook.com',
              ),
              const SizedBox(width: 12),
              _BrandIcon(
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE1306C),
                label: 'Instagram',
                url: 'https://www.instagram.com',
              ),
              const SizedBox(width: 12),
              _BrandIcon(
                icon: FontAwesomeIcons.tiktok,
                color: Colors.black,
                label: 'TikTok',
                url: 'https://www.tiktok.com',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String url;

  const _BrandIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoImageCard extends StatelessWidget {
  final String asset;
  final bool showPromoOverlay;
  const _PromoImageCard({required this.asset, this.showPromoOverlay = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Image.asset(
        asset,
        width: double.infinity,
        height: 140,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _AddReviewPage extends StatefulWidget {
  const _AddReviewPage();

  @override
  State<_AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<_AddReviewPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _commentController.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
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
                                  color: const Color(
                                    0xFFF06292,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 32),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Twoja opinia pomoże innym!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
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
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Twoje imię',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFFF06292),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Podaj swoje imię'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            child: TextFormField(
                              controller: _commentController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                labelText: 'Twoja opinia',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 80),
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
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Wpisz treść opinii'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8268DC), Color(0xFF6B4FC3)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8268DC,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  final name = _nameController.text.trim();
                                  final comment =
                                      _commentController.text.trim();
                                  try {
                                    await DatabaseMethods().addReview({
                                      'reviewer': name,
                                      'comment': comment,
                                    });
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 12),
                                            Text('Opinia została dodana!'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green[400],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Nie udało się zapisać opinii. Spróbuj ponownie.',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red[400],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Dodaj opinię',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroomersSection extends StatelessWidget {
  const _GroomersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Nasi specjaliści', icon: Icons.people),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseMethods().getGroomers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Błąd ładowania zespołu: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('Brak profili groomerek.');
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final first = (data['firstName'] ?? '').toString();
                final last = (data['lastName'] ?? '').toString();
                final phone = (data['phone'] ?? '').toString();
                // Try both 'image' and 'imageUrl' fields
                final imageUrl =
                    (data['image'] ?? data['imageUrl'] ?? '').toString();
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child:
                            imageUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$first $last',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(phone.isEmpty ? '-' : phone),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: SingleChildScrollView(
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder:
                  (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
              children: [
                const _SectionHeader(title: 'Lokalizacja', icon: Icons.map),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: HoverElevation(
                    elevation: 25,
                    borderRadius: BorderRadius.circular(20),
                    child: const _GoogleMapWidget(),
                  ),
                ),
                const SizedBox(height: 32),
                const _SalonGallery(),
                const SizedBox(height: 16),
                const _SectionHeader(
                  title: 'Godziny pracy',
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 12),
                _WorkingHoursTable(
                  hours: const {
                    'Poniedziałek': '09:00 - 18:00',
                    'Wtorek': '09:00 - 18:00',
                    'Środa': '09:00 - 18:00',
                    'Czwartek': '09:00 - 18:00',
                    'Piątek': '09:00 - 18:00',
                    'Sobota': '09:00 - 16:00',
                    'Niedziela': 'Zamknięte',
                  },
                ),
                const SizedBox(height: 16),
                const _GroomersSection(),
                const SizedBox(height: 16),
                const _SectionHeader(
                  title: 'Kontakt',
                  icon: Icons.support_agent,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Salon Groomerski Pupilandia',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text('ul. Przykładowa 2, 41-407 Imielin'),
                      SizedBox(height: 8),
                      Text('Pon-Pt: 9:00-18:00, Sob: 9:00-16:00'),
                      SizedBox(height: 8),
                      Text('Telefon: +48 517 800 442'),
                      SizedBox(height: 8),
                      Text('E-mail: kontakt@pupilandia.pl'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SocialMediaMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMapWidget extends StatefulWidget {
  const _GoogleMapWidget();

  @override
  State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<_GoogleMapWidget> {
  late GoogleMapController mapController;

  static const LatLng _salonLocation = LatLng(
    50.147218200131164,
    19.184415307742835,
  );

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _salonLocation,
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('salon'),
                  position: _salonLocation,
                  infoWindow: const InfoWindow(
                    title: 'Salon Groomerski Pupilandia',
                    snippet: 'ul. Przykładowa 2, 41-407 Imielin',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRose,
                  ),
                ),
              },
              mapType: MapType.normal,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonGallery extends StatelessWidget {
  const _SalonGallery();

  @override
  Widget build(BuildContext context) {
    final salonImages = [
      'images/saloon1.jpg',
      'images/saloon2.jpg',
      'images/saloon3.jpg',
      'images/saloon4.jpg',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final double height = 240;
        if (isWide) {
          // Jedna pozioma linia, obrazy rozszerzają się by zająć całą szerokość
          return SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < salonImages.length; i++) ...[
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i < salonImages.length - 1 ? 12 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          salonImages[i],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF06292).withOpacity(0.2),
                                      const Color(0xFF8268DC).withOpacity(0.2),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    size: 48,
                                    color: Color(0xFFF06292),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Węższe ekrany: poziomy scroll, ale nadal pełna szerokość kontenera
        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: salonImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    salonImages[index],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF06292).withOpacity(0.2),
                                const Color(0xFF8268DC).withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 48,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _WorkingHoursTable extends StatelessWidget {
  final Map<String, String> hours;
  const _WorkingHoursTable({required this.hours});

  @override
  Widget build(BuildContext context) {
    final rows = hours.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1.0)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (final e in rows)
            TableRow(
              children: [
                _HoursCell(label: e.key, isHeader: true),
                _HoursCell(label: e.value),
              ],
            ),
        ],
      ),
    );
  }
}

class _HoursCell extends StatelessWidget {
  final String label;
  final bool isHeader;
  const _HoursCell({required this.label, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        gradient:
            isHeader
                ? LinearGradient(
                  colors: [
                    const Color(0xFFF06292).withOpacity(0.1),
                    const Color(0xFF8268DC).withOpacity(0.1),
                  ],
                )
                : null,
        color: isHeader ? null : const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
          color: Colors.black87,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _GalleryTab extends StatelessWidget {
  const _GalleryTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            child: const _SectionHeader(
              title: 'Galeria',
              icon: Icons.photo_library_outlined,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseMethods().getGalleryBeforeAfter(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Błąd ładowania galerii'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Brak zdjęć PRZED/PO'));
                }
                return AnimationLimiter(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final beforeUrl = (data['imageBefore'] ?? '').toString();
                      final afterUrl = (data['imageAfter'] ?? '').toString();
                      final title = (data['title'] ?? '').toString();
                      final description =
                          (data['description'] ?? '').toString();
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: HoverScale(
                              scale: 1.02,
                              child: _BeforeAfterCard(
                                beforeUrl: beforeUrl,
                                afterUrl: afterUrl,
                                title: title,
                                description: description,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab();

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'brush':
        return Icons.brush;
      case 'eco':
        return Icons.eco_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'info':
        return Icons.info_outline;
      case 'event':
        return Icons.event_note;
      default:
        return Icons.tips_and_updates_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            child: const Text(
              'Porady i aktualności',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: DatabaseMethods().getTips(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Nie udało się pobrać porad.'),
                  );
                }
                final docs = (snapshot.data as QuerySnapshot?)?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Brak porad. Wróć później!',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return AnimationLimiter(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 20,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '') as String;
                      final subtitle = (data['subtitle'] ?? '') as String;
                      final iconName = (data['icon'] ?? '') as String?;
                      final icon = _iconFromName(iconName);
                      final imageUrl =
                          (data['image'] ?? data['imageUrl'] ?? '').toString();
                      final content =
                          (data['content'] ?? data['body'] ?? '').toString();
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => TipDetailPage(
                                          title: title,
                                          content: content,
                                          imageUrl:
                                              imageUrl.isNotEmpty
                                                  ? imageUrl
                                                  : null,
                                        ),
                                  ),
                                );
                              },
                              child: _TipCard(
                                title: title,
                                subtitle: subtitle,
                                icon: icon,
                                imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;

  const _TipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  _isHovered
                      ? const Color(0xFFF06292).withOpacity(0.15)
                      : Colors.black.withOpacity(0.06),
              blurRadius: _isHovered ? 16 : 15,
              offset: Offset(0, _isHovered ? 5 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              if (widget.imageUrl != null)
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF06292),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder:
                        (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF06292).withOpacity(0.3),
                                const Color(0xFF8268DC).withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                  ),
                )
              else
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF06292).withOpacity(0.3),
                        const Color(0xFF8268DC).withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 48),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient:
                        _isHovered
                            ? const LinearGradient(
                              colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                            )
                            : null,
                    color: _isHovered ? null : const Color(0xFFF6F7FB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: _isHovered ? Colors.white : const Color(0xFFF06292),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hover widgets for web
class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverButton({required this.child, required this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              boxShadow:
                  _isHovered
                      ? [
                        BoxShadow(
                          color: const Color(0xFFF06292).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                      : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;

  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _HoverServiceCard extends StatefulWidget {
  final String name;
  final int duration;
  final String price;
  final String description;
  final String imageUrl;
  final bool isLast;

  const _HoverServiceCard({
    required this.name,
    required this.duration,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.isLast = false,
  });

  @override
  State<_HoverServiceCard> createState() => _HoverServiceCardState();
}

class _HoverServiceCardState extends State<_HoverServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 300,
        height: 280,
        margin: EdgeInsets.only(right: widget.isLast ? 0 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (widget.imageUrl.isNotEmpty)
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  width: 300,
                  height: 280,
                  filterQuality: FilterQuality.low,
                  cacheWidth: 600,
                  cacheHeight: 400,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 300,
                      height: 280,
                      color: Colors.grey[200],
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 300,
                        height: 280,
                        color: Colors.grey[300],
                      ),
                )
              else
                Container(
                  width: 300,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8268DC),
                        const Color(0xFF6B4FC3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pets, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.duration} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        child: Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget z filtrami usług
class _ServiceFiltersSection extends StatefulWidget {
  final Function(String) onFilterChanged;
  final String currentFilter;

  const _ServiceFiltersSection({
    required this.onFilterChanged,
    required this.currentFilter,
  });

  @override
  State<_ServiceFiltersSection> createState() => _ServiceFiltersSectionState();
}

class _ServiceFiltersSectionState extends State<_ServiceFiltersSection> {
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Wszystkie', 'icon': Icons.grid_view, 'color': Color(0xFFF06292)},
    {'name': 'Mały pies', 'icon': Icons.pets, 'color': Color(0xFF4CAF50)},
    {'name': 'Średni pies', 'icon': Icons.pets, 'color': Color(0xFF2196F3)},
    {'name': 'Duży pies', 'icon': Icons.pets, 'color': Color(0xFF9C27B0)},
    {'name': 'Koty', 'icon': Icons.pets, 'color': Color(0xFFFF9800)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wszystkie usługi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _filters.map((filter) {
                  final isSelected = widget.currentFilter == filter['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : filter['color'],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            filter['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: filter['color'] as Color,
                      side: BorderSide(
                        color:
                            isSelected
                                ? filter['color'] as Color
                                : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onSelected: (selected) {
                        widget.onFilterChanged(filter['name'] as String);
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
