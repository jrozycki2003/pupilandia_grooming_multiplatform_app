/// \file profile.dart
/// \brief Strona profilu użytkownika
/// 
/// Umożliwia edycję danych profilu, zmianę zdjęcia i wylogowanie.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kubaproject/services/database.dart';
import 'package:kubaproject/services/shared_pref.dart';
import 'package:kubaproject/widgets/user_avatar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// \class ProfilePage
/// \brief Widget strony profilu użytkownika
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// \class _ProfilePageState
/// \brief Stan strony profilu z animacjami
class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? name; ///< Imię użytkownika
  String? email; ///< Email użytkownika
  String? imageUrl; ///< URL zdjęcia profilowego
  String? userId; ///< ID użytkownika
  bool _isUploading = false; ///< Status uploadowania zdjęcia
  final _nameController = TextEditingController();
  bool _isEditingName = false; ///< Stan edycji imienia
  late AnimationController _animController;
  late Animation<double> _fadeAnimation; ///< Animacja fade-in

  /// \brief Ładuje dane użytkownika z lokalnych preferencji
  Future<void> _loadUserData() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    imageUrl = await SharedPreferenceHelper().getUserImage();
    userId = await SharedPreferenceHelper().getUserId();
    _nameController.text = name ?? '';
    setState(() {});
  }

  /// \brief Sprawdza i żąda uprawnień jeśli potrzebne
  /// \param permission Typ uprawnienia do sprawdzenia
  /// \return true jeśli uprawnienie jest przyznane
  Future<bool> _ensurePermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (!mounted) return false;

    if (status.isPermanentlyDenied) {
      final open = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Wymagane uprawnienia'),
              content: const Text(
                'Aby kontynuować, przyznaj uprawnienia w ustawieniach aplikacji.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Otwórz ustawienia'),
                ),
              ],
            ),
      );
      if (open == true) await openAppSettings();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Brak uprawnień.')));
    }
    return false;
  }

  /// \brief Obsługuje kliknięcie zmiany avatara
  /// 
  /// Na web - otwiera file picker, na mobile - pokazuje bottom sheet z opcjami.
  Future<void> _onChangeAvatarTap() async {
    if (_isUploading) return;
    if (!mounted) return;

    // Na webbie używamy bezpośrednio file pickera
    if (kIsWeb) {
      await _pickAndUpload(ImageSource.gallery);
      return;
    }

    // Na mobile pokazujemy bottom sheet z opcjami
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Wybierz z galerii'),
                onTap: () async {
                  Navigator.pop(context);
                  var ok = await _ensurePermission(Permission.photos);
                  if (!ok && Platform.isAndroid) {
                    ok = await _ensurePermission(Permission.storage);
                  }
                  if (ok) await _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Zrób zdjęcie'),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _ensurePermission(Permission.camera)) {
                    await _pickAndUpload(ImageSource.camera);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      userId ??= await SharedPreferenceHelper().getUserId();
      final uid = currentUser?.uid ?? userId;

      if (uid == null || uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Musisz być zalogowany, aby przesłać zdjęcie.'),
            ),
          );
        }
        return;
      }
      setState(() => _isUploading = true);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid/$ts.jpg');
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await DatabaseMethods().updateUserImage(uid, url);
      await SharedPreferenceHelper().saveUserImage(url);
      setState(() => imageUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zaktualizowano zdjęcie profilowe.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final msg =
            e.code == 'permission-denied'
                ? 'Brak uprawnień do zapisu. Upewnij się, że jesteś zalogowany.'
                : 'Błąd Firebase: ${e.message ?? e.code}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się otworzyć aparatu/galerii: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _nameController.dispose();
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: kIsWeb ? 700 : double.infinity,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(),
                            const SizedBox(height: 30),
                            _buildProfileDetails(),
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
            'Profil',
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFEC407A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: UserAvatar(imageUrl: imageUrl, size: 90),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _onChangeAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8268DC), Color(0xFF6B4FC3)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8268DC).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Szczegóły Profilu',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (!_isEditingName)
          _ProfileItem(
            title: 'Imię',
            value: name ?? '-',
            onTap: () {
              setState(() {
                _isEditingName = true;
                _nameController.text = name ?? '';
              });
            },
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imię',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Wpisz imię i nazwisko',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingName = false;
                        });
                      },
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        if (newName.isEmpty || userId == null) {
                          setState(() => _isEditingName = false);
                          return;
                        }
                        try {
                          await DatabaseMethods().updateUserName(
                            userId!,
                            newName,
                          );
                          await SharedPreferenceHelper().saveUserName(newName);
                          setState(() {
                            name = newName;
                            _isEditingName = false;
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Zaktualizowano dane profilu.'),
                            ),
                          );
                        } catch (_) {
                          if (mounted) setState(() => _isEditingName = false);
                        }
                      },
                      child: const Text('Zapisz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        _ProfileItem(title: 'Email', value: email ?? '-'),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _ProfileItem({required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 16, color: Colors.black45),
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
