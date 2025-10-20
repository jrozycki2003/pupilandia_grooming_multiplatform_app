/// \file admin_groomers.dart
/// \brief Moduł zarządzania pracownikami salonu
///
/// Umożliwia dodawanie, edycję i usuwanie profili pracowników.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// \class AdminGroomersPage
/// \brief Widget strony zarządzania pracownikami
///
/// Wyświetla pracowników w siatce kart (GridView) i umożliwia:
/// - Dodawanie nowych pracowników z profilami
/// - Edycję danych kontaktowych i zdjęć
/// - Usuwanie pracowników z bazy
class AdminGroomersPage extends StatefulWidget {
  const AdminGroomersPage({super.key});

  @override
  State<AdminGroomersPage> createState() => _AdminGroomersPageState();
}

/// \class _AdminGroomersPageState
/// \brief Stan dla strony zarządzania pracownikami
class _AdminGroomersPageState extends State<AdminGroomersPage> {
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
                // Ikona sekcji z niebieskim tłem
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Color(0xFF2196F3),
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
                        'Zarządzanie Pracownikami',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dodawaj, edytuj i usuwaj pracowników salonu',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Przycisk dodawania nowego pracownika
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Dodaj Pracownika'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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
          // Siatka pracowników
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Nasłuchuj zmian w kolekcji pracowników w czasie rzeczywistym
              stream: _db.getGroomers(),
              builder: (context, snapshot) {
                // Pokaż wskaźnik ładowania podczas pobierania
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Jeśli brak pracowników, pokaż pusty stan
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Brak pracowników',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kliknij "Dodaj Pracownika", aby dodać pierwszego pracownika',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Wyświetl pracowników w siatce
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350, // Maksymalna szerokość karty
                    childAspectRatio:
                        0.85, // Proporcje karty (szerokość/wysokość)
                    crossAxisSpacing: 16, // Odstęp poziomy
                    mainAxisSpacing: 16, // Odstęp pionowy
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildGroomerCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Buduje kartę pojedynczego pracownika
  ///
  /// Karta wyświetla:
  /// - Zdjęcie profilowe (okrągłe, 100x100px)
  /// - Imię i nazwisko (pogrubione)
  /// - Telefon (z ikoną)
  /// - Przyciski edycji (niebieski) i usuwania (czerwony) w nagłówku
  ///
  /// UWAGA: Pole email zostało usunięte z UI zgodnie z wymaganiami
  ///
  /// \param id Identyfikator pracownika w bazie danych
  /// \param data Dane pracownika (imię, nazwisko, telefon, zdjęcie)
  /// \return Widget reprezentujący profil pracownika
  Widget _buildGroomerCard(String id, Map<String, dynamic> data) {
    // Bezpiecznie pobierz dane z różnymi fallbackami
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final phone = data['phone'] ?? '';

    // Obsługa różnych nazw pól dla URL zdjęcia (kompatybilność wsteczna)
    final imageUrl =
        (data['image'] ?? data['Image'] ?? data['imageUrl'] ?? '').toString();

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
      ),
      child: Column(
        children: [
          // Nagłówek z akcjami
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Przycisk edycji
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                  onPressed:
                      () => _showAddEditDialog(context, id: id, data: data),
                ),
                const SizedBox(width: 8),
                // Przycisk usuwania
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                  onPressed:
                      () => _confirmDelete(context, id, '$firstName $lastName'),
                ),
              ],
            ),
          ),
          // Zdjęcie profilowe
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  // Zdjęcie z sieci (okrągłe)
                  ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      // Obsługa błędu ładowania, wtedy pokaż ikonę zamiast zdjęcia
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: const Color(0xFF2196F3).withOpacity(0.08),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                    ),
                  )
                else
                  // Placeholder gdy brak zdjęcia
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2196F3).withOpacity(0.08),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Imię i nazwisko
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$firstName $lastName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Maksymalnie 2 linie
              overflow: TextOverflow.ellipsis, // Dodaj ... jeśli za długie
            ),
          ),
          const SizedBox(height: 8),
          // Telefon
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      phone,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// \brief Wyświetla dialog dodawania/edycji pracownika
  ///
  /// Otwiera _GroomerDialog z opcjonalnymi danymi do edycji.
  /// Jeśli id i data są null, dialog działa w trybie dodawania.
  ///
  /// \param context Kontekst buildera
  /// \param id Opcjonalny identyfikator pracownika (dla edycji)
  /// \param data Opcjonalne dane pracownika (dla edycji)
  void _showAddEditDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) {
    showDialog(
      context: context,
      builder: (context) => _GroomerDialog(id: id, data: data),
    );
  }

  /// \brief Wyświetla dialog potwierdzenia usunięcia
  ///
  /// Po potwierdzeniu wywołuje DatabaseMethods.deleteGroomer()
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator pracownika do usunięcia
  /// \param name Imię i nazwisko (do wyświetlenia w dialogu)
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Usuń Pracownika'),
            content: Text('Czy na pewno chcesz usunąć pracownika "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Usuń pracownika z bazy danych
                  await _db.deleteGroomer(id);
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

/// \class _GroomerDialog
/// \brief Dialog do dodawania i edycji profilu pracownika
///
/// Formularz zawiera:
/// - Zdjęcie profilowe (klikalne do zmiany)
/// - Pole imienia (wymagane)
/// - Pole nazwiska (wymagane)
/// - Pole telefonu (opcjonalne)
///
/// UWAGA: Pole email zostało usunięte zgodnie z wymaganiami
class _GroomerDialog extends StatefulWidget {
  final String? id; // null = dodawanie, wartość = edycja
  final Map<String, dynamic>? data; // Dane do edycji (jeśli tryb edycji)

  const _GroomerDialog({this.id, this.data});

  @override
  State<_GroomerDialog> createState() => _GroomerDialogState();
}

/// \class _GroomerDialogState
/// \brief Stan dialogu pracownika
class _GroomerDialogState extends State<_GroomerDialog> {
  /// Klucz formularza do walidacji
  final _formKey = GlobalKey<FormState>();

  /// Kontrolery dla pól tekstowych
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  /// URL istniejącego zdjęcia (dla trybu edycji)
  String _imageUrl = '';

  /// Status ładowania (podczas zapisywania)
  bool _isLoading = false;

  /// Wybrane zdjęcie dla platform natywnych
  File? _selectedImage;

  /// Wybrane zdjęcie dla platformy web (jako bajty)
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    // Jeśli tryb edycji, załaduj istniejące dane
    if (widget.data != null) {
      _firstNameController.text = widget.data!['firstName'] ?? '';
      _lastNameController.text = widget.data!['lastName'] ?? '';
      _phoneController.text = widget.data!['phone'] ?? '';
      // Obsługa różnych nazw pól dla URL zdjęcia
      _imageUrl =
          (widget.data!['image'] ??
                  widget.data!['Image'] ??
                  widget.data!['imageUrl'] ??
                  '')
              .toString();
    }
  }

  @override
  void dispose() {
    // Zwolnij zasoby kontrolerów
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// \brief Otwiera selektor zdjęcia profilowego
  ///
  /// Proces różni się w zależności od platformy:
  /// - Web: Zapisuje bajty w _selectedImageBytes
  /// - Mobile/Desktop: Zapisuje ścieżkę do pliku w _selectedImage
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Otwórz galerię zdjęć urządzenia
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Platforma WEB - odczytaj jako bajty
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null; // Wyczyść plik
        });
      } else {
        // Platforma mobile/desktop - użyj ścieżki do pliku
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = null; // Wyczyść bajty
        });
      }
    }
  }

  /// \brief Przesyła zdjęcie profilowe do Firebase Storage
  ///
  /// Proces:
  /// 1. Jeśli nie wybrano nowego zdjęcia, zwróć istniejący URL
  /// 2. Wygeneruj unikalną nazwę: groomers/timestamp.jpg
  /// 3. Prześlij dane (bajty dla web, plik dla native)
  /// 4. Pobierz i zwróć URL pobierania
  ///
  /// \return URL przesłanego zdjęcia lub istniejący URL lub null przy błędzie
  Future<String?> _uploadImage() async {
    // Jeśli nie wybrano nowego zdjęcia, zwróć istniejący URL
    if (_selectedImage == null && _selectedImageBytes == null) return _imageUrl;

    try {
      // Generuj unikalną nazwę pliku
      final fileName = 'groomers/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb && _selectedImageBytes != null) {
        // Web - prześlij bajty z metadanymi MIME
        await ref.putData(
          _selectedImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (_selectedImage != null) {
        // Native - prześlij plik
        await ref.putFile(_selectedImage!);
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

  /// \brief Zapisuje dane pracownika do bazy danych
  ///
  /// Proces:
  /// 1. Walidacja formularza (pola wymagane)
  /// 2. Przesłanie zdjęcia (jeśli wybrane)
  /// 3. Przygotowanie danych:
  ///    - firstName, lastName, phone
  ///    - image i imageUrl (dla kompatybilności)
  /// 4. Dodanie (addGroomer) lub aktualizacja (updateGroomer)
  /// 5. Zamknięcie dialogu i pokazanie komunikatu
  Future<void> _save() async {
    // Walidacja pól wymaganych
    if (!_formKey.currentState!.validate()) return;

    // Pokaż wskaźnik ładowania
    setState(() => _isLoading = true);

    try {
      // Prześlij zdjęcie (jeśli wybrane)
      final imageUrl = await _uploadImage();

      // Przygotuj dane do zapisu
      final groomerData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'image': imageUrl ?? '', // Oba pola dla kompatybilności
        'imageUrl': imageUrl ?? '',
      };

      final db = DatabaseMethods();
      if (widget.id == null) {
        // Tryb dodawania - utwórz nowy dokument
        await db.addGroomer(groomerData);
      } else {
        // Tryb edycji - zaktualizuj istniejący dokument
        await db.updateGroomer(widget.id!, groomerData);
      }

      // Sukces - zamknij dialog i pokaż komunikat
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.id == null
                  ? 'Pracownik dodany'
                  : 'Pracownik zaktualizowany',
            ),
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
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      title: Text(widget.id == null ? 'Dodaj Pracownika' : 'Edytuj Pracownika'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Klikalne zdjęcie profilowe
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    // Wybierz źródło zdjęcia w kolejności: nowe bajty -> nowy plik -> istniejący URL
                    backgroundImage:
                        _selectedImageBytes != null
                            ? MemoryImage(
                              _selectedImageBytes!,
                            ) // Nowe zdjęcie (web)
                            : (_selectedImage != null
                                    ? FileImage(
                                      _selectedImage!,
                                    ) // Nowe zdjęcie (native)
                                    : (_imageUrl.isNotEmpty
                                        ? NetworkImage(_imageUrl)
                                        : null))
                                as ImageProvider?, // Istniejące
                    // Ikona placeholder gdy brak zdjęcia
                    child:
                        _selectedImageBytes == null &&
                                _selectedImage == null &&
                                _imageUrl.isEmpty
                            ? Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[600],
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kliknij, aby zmienić zdjęcie',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // Pole imienia
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Imię',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                // Pole nazwiska
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                // Pole telefonu
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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
            backgroundColor: const Color(0xFF2196F3),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.id == null ? 'Dodaj' : 'Zapisz'),
        ),
      ],
    );
  }
}
