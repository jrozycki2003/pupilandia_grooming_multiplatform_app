import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/login.dart';
import '../pages/profile.dart';
import '../pages/book_appointment.dart';
import '../pages/history.dart';
import '../widgets/user_avatar.dart';
import '../services/shared_pref.dart';
import 'package:kubaproject/pages/admin_panel.dart';
import 'package:kubaproject/pages/employee_panel.dart';
import 'dart:ui';

class WebNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const WebNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<WebNavBar> createState() => _WebNavBarState();
}

class _WebNavBarState extends State<WebNavBar> {
  String? name, image;
  bool _showUserMenu = false;
  bool _isAdmin = false;
  bool _isEmployee = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    try {
      final user = FirebaseAuth.instance.currentUser;
      bool isAdmin = false;
      bool isEmployee = false;
      if (user != null && user.email != null) {
        final email = user.email!;
        
        // Sprawdź Admin
        final adminDoc = await FirebaseFirestore.instance
            .collection('Admin')
            .doc(email)
            .get();
        isAdmin = adminDoc.exists;
        
        // Sprawdź Employee (tylko jeśli nie jest adminem)
        if (!isAdmin) {
          final employeeDoc = await FirebaseFirestore.instance
              .collection('Employee')
              .doc(email)
              .get();
          isEmployee = employeeDoc.exists;
        }
      }
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isEmployee = isEmployee;
        });
      }
    } catch (_) {
      if (mounted) setState(() { 
        _isAdmin = false;
        _isEmployee = false;
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFF06292).withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
              // Logo
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pupilandia',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
              // Navigation tabs
              Expanded(
                child: Row(
                  children: [
                    _NavItem(
                      title: 'Strona Główna',
                      icon: Icons.home_outlined,
                      isActive: widget.currentIndex == 0,
                      onTap: () => widget.onTabChanged(0),
                    ),
                    _NavItem(
                      title: 'Usługi',
                      icon: Icons.content_cut,
                      isActive: widget.currentIndex == 1,
                      onTap: () => widget.onTabChanged(1),
                    ),
                    _NavItem(
                      title: 'Porady',
                      icon: Icons.lightbulb_outline,
                      isActive: widget.currentIndex == 2,
                      onTap: () => widget.onTabChanged(2),
                    ),
                    _NavItem(
                      title: 'Galeria',
                      icon: Icons.photo_library_outlined,
                      isActive: widget.currentIndex == 3,
                      onTap: () => widget.onTabChanged(3),
                    ),
                    _NavItem(
                      title: 'Kontakt',
                      icon: Icons.contact_mail_outlined,
                      isActive: widget.currentIndex == 4,
                      onTap: () => widget.onTabChanged(4),
                    ),
                  ],
                ),
              ),
              // Admin button (web only, when logged in & admin)
              if (isLoggedIn && _isAdmin) ...[
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPanel()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06292).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF06292).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Color(0xFFF06292), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Panel Administratora',
                            style: TextStyle(
                              color: Color(0xFFF06292),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              // Employee button (web only, when logged in & employee)
              if (isLoggedIn && _isEmployee) ...[
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmployeePanel()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.work, color: Color(0xFF4CAF50), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Panel Pracowniczy',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              // User section
              if (isLoggedIn) ...[
                MouseRegion(
                  onEnter: (_) => setState(() => _showUserMenu = true),
                  onExit: (_) => setState(() => _showUserMenu = false),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _showUserMenu
                              ? const Color(0xFFF06292)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: UserAvatar(imageUrl: image, size: 32),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name ?? 'Użytkownik',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showUserMenu
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        );
                        await _loadUserData();
                      } else if (value == 'book') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookAppointmentPage(),
                          ),
                        );
                      } else if (value == 'history') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoryPage()),
                        );
                      } else if (value == 'logout') {
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: const [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Profil'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'book',
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 12),
                            Text('Zarezerwuj wizytę'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: const [
                            Icon(Icons.history, size: 20),
                            SizedBox(width: 12),
                            Text('Historia wizyt'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: const [
                            Icon(Icons.logout, size: 20, color: Colors.redAccent),
                            SizedBox(width: 12),
                            Text(
                              'Wyloguj',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogIn()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF06292).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.login, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Zaloguj się',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFFF06292).withOpacity(0.1)
                : _isHovered
                    ? const Color(0xFFF6F7FB)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive
                    ? const Color(0xFFF06292)
                    : _isHovered
                        ? const Color(0xFFF06292)
                        : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                  color: widget.isActive
                      ? const Color(0xFFF06292)
                      : _isHovered
                          ? Colors.black87
                          : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
