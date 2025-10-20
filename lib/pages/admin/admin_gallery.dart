/// \file admin_gallery.dart
/// \brief Moduł zarządzania galerią zdjęć "przed i po"
///
/// Umożliwia dodawanie i usuwanie porównań zdjęć przedstawiających efekty pracy.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

/// \class AdminGalleryPage
/// \brief Widget strony zarządzania galerią
///
/// Wyświetla galerię porównań "przed i po" oraz umożliwia:
/// - Dodawanie nowych par zdjęć
/// - Usuwanie istniejących wpisów
class AdminGalleryPage extends StatefulWidget {
  final bool isEmployee;
  const AdminGalleryPage({super.key, this.isEmployee = false});

  @override
  State<AdminGalleryPage> createState() => _AdminGalleryPageState();
}

/// \class _AdminGalleryPageState
/// \brief Stan dla strony zarządzania galerią
class _AdminGalleryPageState extends State<AdminGalleryPage> {
  /// Instancja do obsługi operacji na bazie danych
  final DatabaseMethods _db = DatabaseMethods();

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
                // Ikona sekcji z fioletowym tłem
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF9C27B0),
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
                        'Zarządzanie Galerią',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dodawaj i usuwaj zdjęcia "przed i po"',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Przycisk dodawania nowych zdjęć
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Dodaj Zdjęcia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
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
          // Lista wpisów w galerii
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Nasłuchuj zmian w kolekcji galerii w czasie rzeczywistym
              stream: _db.getGalleryBeforeAfter(),
              builder: (context, snapshot) {
                // Pokaż wskaźnik ładowania podczas pobierania
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Jeśli brak zdjęć, pokaż pusty stan
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Brak zdjęć w galerii',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kliknij "Dodaj Zdjęcia", aby dodać pierwsze zdjęcia',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Wyświetl listę wpisów galerii
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildGalleryCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Buduje kartę pojedynczego wpisu w galerii
  ///
  /// Karta składa się z:
  /// - Nagłówka z tytułem, opisem i przyciskiem usuwania
  /// - Dwóch zdjęć obok siebie: "PRZED" i "PO"
  /// - Badge z gradientem nad każdym zdjęciem
  ///
  /// \param id Identyfikator wpisu w bazie danych
  /// \param data Dane wpisu (URL zdjęć, tytuł, opis)
  /// \return Widget reprezentujący wpis galerii
  Widget _buildGalleryCard(String id, Map<String, dynamic> data) {
    // Bezpiecznie pobierz dane
    final beforeUrl = data['imageBefore'] ?? '';
    final afterUrl = data['imageAfter'] ?? '';
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Nagłówek z akcjami
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tytuł (jeśli istnieje)
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      // Opis (jeśli istnieje)
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Przycisk usuwania - tylko dla admina
                if (!widget.isEmployee)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, id),
                  ),
              ],
            ),
          ),
          // Zdjęcia przed i po
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Zdjęcie przed
                Expanded(
                  child: Column(
                    children: [
                      // Badge "PRZED" z czerwonym gradientem
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PRZED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Zdjęcie w kwadratowym kontenerze
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1, // Proporcje 1:1 (kwadrat)
                          child:
                              beforeUrl.isNotEmpty
                                  ? Image.network(
                                    beforeUrl,
                                    fit: BoxFit.cover,
                                    // Obsługa błędu ładowania
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Zdjęcie po
                Expanded(
                  child: Column(
                    children: [
                      // Badge "PO" z zielonym gradientem
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Zdjęcie w kwadratowym kontenerze
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child:
                              afterUrl.isNotEmpty
                                  ? Image.network(
                                    afterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Wyświetla dialog dodawania nowych zdjęć
  ///
  /// Otwiera _GalleryDialog do wyboru i przesłania zdjęć "przed" i "po"
  ///
  /// \param context Kontekst buildera
  void _showAddDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _GalleryDialog());
  }

  /// \brief Wyświetla dialog potwierdzenia usunięcia
  ///
  /// Po potwierdzeniu wywołuje DatabaseMethods.deleteGalleryItem()
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator wpisu do usunięcia
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Usuń zdjęcia'),
            content: const Text(
              'Czy na pewno chcesz usunąć te zdjęcia z galerii?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Usuń wpis z bazy danych
                  await _db.deleteGalleryItem(id);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Usuń'),
              ),
            ],
          ),
    );
  }
}

/// \class _GalleryDialog
/// \brief Dialog do dodawania nowych zdjęć do galerii
///
/// Umożliwia:
/// - Wybór dwóch zdjęć z galerii urządzenia
/// - Podgląd wybranych zdjęć
/// - Przesłanie do Firebase Storage
/// - Zapisanie URL-i do Firestore
class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog();

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

/// \class _GalleryDialogState
/// \brief Stan dialogu galerii
class _GalleryDialogState extends State<_GalleryDialog> {
  /// Klucz formularza (obecnie nieużywany, ale będzie na przyszłość)
  final _formKey = GlobalKey<FormState>();

  // Zmienne dla platform nie-webowych (Mobile/Desktop)
  /// Plik zdjęcia "przed" na platformach natywnych
  File? _beforeImage;

  /// Plik zdjęcia "po" na platformach natywnych
  File? _afterImage;

  // Zmienne dla platformy webowej
  /// Bajty zdjęcia "przed" na platformie web
  Uint8List? _beforeBytes;

  /// Bajty zdjęcia "po" na platformie web
  Uint8List? _afterBytes;

  /// Status ładowania (podczas przesyłania)
  bool _isLoading = false;

  /// \brief Otwiera selektor zdjęcia
  ///
  /// Proces różni się w zależności od platformy:
  /// - Web: Przechowuje bajty w Uint8List
  /// - Mobile/Desktop: Przechowuje ścieżkę do pliku
  ///
  /// \param isBefore true dla zdjęcia "przed", false dla "po"
  Future<void> _pickImage(bool isBefore) async {
    final picker = ImagePicker();
    // Otwórz galerię zdjęć
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Platforma web - przeczytaj jako bajty
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isBefore) {
            _beforeBytes = bytes;
            _beforeImage = null; // Wyczyść file
          } else {
            _afterBytes = bytes;
            _afterImage = null;
          }
        });
      } else {
        // Platforma mobile/desktop - użyj ścieżki do pliku
        setState(() {
          if (isBefore) {
            _beforeImage = File(pickedFile.path);
            _beforeBytes = null; // Wyczyść bajty
          } else {
            _afterImage = File(pickedFile.path);
            _afterBytes = null;
          }
        });
      }
    }
  }

  /// \brief Przesyła zdjęcie do Firebase Storage
  ///
  /// Proces:
  /// 1. Generuje unikalną nazwę pliku z timestampem
  /// 2. Tworzy referencję w Firebase Storage
  /// 3. Przesyła dane (bajty dla web, plik dla native)
  /// 4. Pobiera i zwraca URL pobierania
  ///
  /// \param prefix Prefiks nazwy pliku ('before_' lub 'after_')
  /// \param bytes Bajty zdjęcia dla platformy web
  /// \param file Plik zdjęcia dla platform natywnych
  /// \return URL przesłanego zdjęcia lub null w przypadku błędu
  Future<String?> _uploadImage({
    required String prefix,
    Uint8List? bytes,
    File? file,
  }) async {
    try {
      // Generuj unikalną nazwę gallery/prefix_timestamp.jpg
      final fileName =
          'gallery/$prefix${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb && bytes != null) {
        // Web - prześlij bajty z metadanymi
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else if (file != null) {
        // Native - prześlij plik
        await ref.putFile(file);
      } else {
        return null; // Brak danych do przesłania
      }

      // Pobierz URL pobierania
      return await ref.getDownloadURL();
    } catch (e) {
      // Wyświetl błąd użytkownikowi
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd przesyłania zdjęcia: $e')));
      }
      return null;
    }
  }

  /// \brief Zapisuje zdjęcia do galerii
  ///
  /// Proces:
  /// 1. Walidacja - sprawdź czy oba zdjęcia są wybrane
  /// 2. Prześlij oba zdjęcia do Storage
  /// 3. Zapisz URL-e do Firestore
  /// 4. Zamknij dialog i pokaż komunikat sukcesu
  Future<void> _save() async {
    // Walidacja - oba zdjęcia są wymagane
    if ((_beforeImage == null && _beforeBytes == null) ||
        (_afterImage == null && _afterBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dodaj oba zdjęcia (przed i po)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Pokaż wskaźnik ładowania
    setState(() => _isLoading = true);

    try {
      // Prześlij oba zdjęcia równolegle
      final beforeUrl = await _uploadImage(
        prefix: 'before_',
        bytes: _beforeBytes,
        file: _beforeImage,
      );
      final afterUrl = await _uploadImage(
        prefix: 'after_',
        bytes: _afterBytes,
        file: _afterImage,
      );

      // Sprawdź czy przesyłanie się powiodło
      if (beforeUrl == null || afterUrl == null) {
        throw Exception('Błąd przesyłania zdjęć');
      }

      // Przygotuj dane do zapisu w Firestore
      final galleryData = {
        'imageBefore': beforeUrl,
        'imageAfter': afterUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Zapisz do bazy danych
      await DatabaseMethods().addGalleryItem(galleryData);

      // Jeśli sukces to zamknij dialog i pokaż komunikat
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zdjęcia dodane do galerii'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Obsłuż błędy
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Ukryj wskaźnik ładowania
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dostosuj szerokość dialogu do rozmiaru ekranu
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 700 ? 600.0 : screenWidth * 0.9;

    return AlertDialog(
      title: const Text('Dodaj Zdjęcia do Galerii'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Sekcja wyboru zdjęć
                Row(
                  children: [
                    // Zdjęcie przed
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PRZED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Klikalne pole do wyboru zdjęcia
                          GestureDetector(
                            onTap: () => _pickImage(true),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  // Fioletowa ramka gdy zdjęcie wybrane
                                  color:
                                      _beforeImage != null ||
                                              _beforeBytes != null
                                          ? const Color(0xFF9C27B0)
                                          : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child:
                                  _beforeBytes != null
                                      // Podgląd dla web
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _beforeBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : _beforeImage != null
                                      // Podgląd dla native
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _beforeImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      // Placeholder gdy brak zdjęcia
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Dodaj zdjęcie',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Zdjęcie po
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _afterBytes != null || _afterImage != null
                                          ? const Color(0xFF9C27B0)
                                          : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child:
                                  _afterBytes != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _afterBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : _afterImage != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _afterImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Dodaj zdjęcie',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Przycisk anulowania
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        // Przycisk zapisu (pokazuje spinner podczas ładowania)
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Dodaj'),
        ),
      ],
    );
  }
}
