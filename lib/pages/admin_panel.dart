/// \file admin_panel.dart
/// \brief Panel administratora do zarządzania systemem rezerwacji
///
/// Ten plik zawiera główny interfejs panelu administratora, który umożliwia
/// zarządzanie ogłoszeniami, poradami, usługami, pracownikami, galerią i rezerwacjami.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/pages/admin/admin_tips.dart';
import 'package:kubaproject/pages/admin/admin_services.dart';
import 'package:kubaproject/pages/admin/admin_groomers.dart';
import 'package:kubaproject/pages/admin/admin_gallery.dart';
import 'package:kubaproject/pages/admin/admin_bookings.dart';
import 'package:kubaproject/pages/admin/admin_announcements.dart';
import 'package:kubaproject/pages/admin/admin_clients.dart';
import 'package:kubaproject/pages/home.dart';

/// \class AdminPanel
/// \brief Główny widget panelu administratora
///
/// Stateful widget zarządzający nawigacją między różnymi sekcjami panelu administratora.
class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

/// \class _AdminPanelState
/// \brief Stan wewnętrzny dla AdminPanel
///
/// Zarządza weryfikacją uprawnień administratora oraz nawigacją między stronami.
class _AdminPanelState extends State<AdminPanel> {
  /// Indeks aktualnie wybranej strony w nawigacji
  int _selectedIndex = 0;

  /// Flaga sprawdzająca status weryfikacji dostępu
  /// true - weryfikacja w toku, false - weryfikacja zakończona
  bool _checkingAccess = true;

  /// Klucz dla Scaffold umożliwiający kontrolę drawera programowo
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Rozpocznij weryfikację uprawnień administratora przy inicjalizacji
    _verifyAdminAccess();
  }

  /// \brief Weryfikuje uprawnienia administratora
  ///
  /// Sprawdza czy zalogowany użytkownik znajduje się w kolekcji Admin w Firestore.
  /// Proces weryfikacji:
  /// 1. Pobiera aktualnie zalogowanego użytkownika z Firebase Auth
  /// 2. Sprawdza dokument Admin/{email} (główna metoda)
  /// 3. Jeśli nie znaleziono, sprawdza Admin/{uid} (fallback)
  /// 4. Jeśli nie znaleziono, sprawdza pole 'email' w kolekcji Admin (dodatkowy fallback)
  /// 5. W przypadku braku uprawnień - wyświetla komunikat i wraca do poprzedniego ekranu
  Future<void> _verifyAdminAccess() async {
    try {
      // Pobierz aktualnie zalogowanego użytkownika
      final user = FirebaseAuth.instance.currentUser;
      bool allowed = false;

      if (user != null) {
        final uid = user.uid;
        final email = user.email;

        // METODA 1: Sprawdź dokument po emailu (zgodne z regułami Firestore)
        if (email != null && email.isNotEmpty) {
          final byEmail =
              await FirebaseFirestore.instance
                  .collection('Admin')
                  .doc(email)
                  .get();
          if (byEmail.exists) {
            allowed = true;
          }
        }

        // METODA 2 i 3: Fallback dla kompatybilności wstecznej
        if (!allowed) {
          // Sprawdź dokument po UID
          final docByUid =
              await FirebaseFirestore.instance
                  .collection('Admin')
                  .doc(uid)
                  .get();
          if (docByUid.exists) {
            allowed = true;
          } else if (email != null && email.isNotEmpty) {
            // Sprawdź query po polu email
            final q =
                await FirebaseFirestore.instance
                    .collection('Admin')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();
            allowed = q.docs.isNotEmpty;
          }
        }
      }

      // Sprawdź czy widget jest nadal zamontowany przed aktualizacją UI
      if (!mounted) return;

      if (!allowed) {
        // Brak uprawnień - wyświetl komunikat i wróć
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak uprawnień do Panelu Administratora'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Dostęp przyznany - zakończ proces weryfikacji
        setState(() {
          _checkingAccess = false;
        });
      }
    } catch (_) {
      // Obsłuż błędy podczas weryfikacji
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się zweryfikować uprawnień'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  /// Lista dostępnych stron w panelu administratora
  final List<Widget> _pages = [
    const AdminAnnouncementsPage(), // Zarządzanie ogłoszeniami
    const AdminTipsPage(), // Zarządzanie poradami
    const AdminServicesPage(), // Zarządzanie usługami
    const AdminGroomersPage(), // Zarządzanie pracownikami
    const AdminGalleryPage(), // Zarządzanie galerią
    const AdminBookingsPage(), // Zarządzanie rezerwacjami
    const AdminClientsPage(), // Lista klientów
  ];

  /// Lista elementów nawigacyjnych z ikonami i kolorami
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      label: 'Ogłoszenia',
      color: Color(0xFFF06292),
    ),
    _NavItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Porady',
      color: Color(0xFFFF9800),
    ),
    _NavItem(
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa,
      label: 'Usługi',
      color: Color(0xFF4CAF50),
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Pracownicy',
      color: Color(0xFF2196F3),
    ),
    _NavItem(
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library,
      label: 'Galeria',
      color: Color(0xFF9C27B0),
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Rezerwacje',
      color: Color(0xFFF06292),
    ),
    _NavItem(
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      label: 'Klienci',
      color: Color(0xFF2196F3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Jeśli weryfikacja w toku, pokaż wskaźnik ładowania
    if (_checkingAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Określ czy urządzenie to desktop (szerokość >= 900px)
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        // Pokaż przycisk menu tylko na mobile
        leading:
            isDesktop
                ? null
                : IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
        automaticallyImplyLeading: !isDesktop,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikona panelu z gradientem
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFEC407A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Panel Administratora',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      // Drawer tylko dla mobile, na desktop sidebar jest wbudowany
      drawer: isDesktop ? null : _buildDrawer(),
      body:
          isDesktop
              ? Row(
                children: [
                  // Sidebar dla desktop - zawsze widoczny
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: _buildSidebarContent(),
                  ),
                  // Główna zawartość - aktualnie wybrana strona
                  Expanded(child: _pages[_selectedIndex]),
                ],
              )
              : _pages[_selectedIndex], // Na mobile tylko zawartość
    );
  }

  /// \brief Buduje drawer (menu boczne) dla wersji mobilnej
  /// \return Widget zawierający drawer z nawigacją
  Widget _buildDrawer() {
    return Drawer(
      child: Container(color: Colors.white, child: _buildSidebarContent()),
    );
  }

  /// \brief Buduje zawartość bocznego menu nawigacyjnego
  ///
  /// Menu składa się z:
  /// - Listy elementów nawigacyjnych (Ogłoszenia, Porady, Usługi, etc.)
  /// - Przycisku powrotu do menu użytkownika na dole
  ///
  /// \return Widget z listą opcji nawigacyjnych i przyciskiem powrotu
  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Lista elementów nawigacyjnych
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              return _buildNavItem(item, index, isSelected);
            },
          ),
        ),
        // Przycisk powrotu do menu użytkownika
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Przejdź do strony głównej i wyczyść stos nawigacji
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Home()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Powrót do menu użytkownika'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// \brief Buduje pojedynczy element nawigacji
  ///
  /// Element zmienia wygląd w zależności od tego czy jest wybrany:
  /// - Wybrany: wypełnione tło w kolorze sekcji, pogrubiona czcionka, aktywna ikona
  /// - Niewybrany: przezroczyste tło, normalna czcionka, outline ikona
  ///
  /// Po kliknięciu:
  /// - Zmienia aktywną stronę
  /// - Na mobile zamyka drawer
  ///
  /// \param item Obiekt _NavItem z danymi elementu (ikony, etykieta, kolor)
  /// \param index Indeks elementu w liście nawigacyjnej
  /// \param isSelected Czy element jest aktualnie wybrany
  /// \return Widget reprezentujący element nawigacji
  Widget _buildNavItem(_NavItem item, int index, bool isSelected) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Zmień aktywną stronę
            setState(() {
              _selectedIndex = index;
            });
            // Zamknij drawer na mobile po wyborze
            if (!isDesktop && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              // Tło - jeśli wybrany to kolor sekcji z przezroczystością
              color:
                  isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              // Ramka - jeśli wybrany to kolor sekcji
              border: Border.all(
                color:
                    isSelected
                        ? item.color.withOpacity(0.3)
                        : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Ikona - wypełniona gdy wybrana, outline gdy nie
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? item.color : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 16),
                // Etykieta - pogrubiona gdy wybrana
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? item.color : Colors.grey[700],
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// \class _NavItem
/// \brief Klasa pomocnicza reprezentująca element nawigacji
///
/// Przechowuje wszystkie dane potrzebne do wyrenderowania
/// elementu menu nawigacyjnego:
/// - icon: Ikona w stylu outline (dla niewybranego stanu)
/// - activeIcon: Ikona wypełniona (dla wybranego stanu)
/// - label: Tekst etykiety
/// - color: Kolor akcentu dla tego elementu
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
