/// \file admin_services.dart
/// \brief Moduł zarządzania usługami oferowanymi w salonie
///
/// Umożliwia dodawanie, edycję i usuwanie usług wraz z kategoriami, cenami i czasem trwania.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kubaproject/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

/// \class AdminServicesPage
/// \brief Widget strony zarządzania usługami
///
/// Wyświetla usługi w siatce kart (GridView) z możliwością:
/// - Filtrowania po kategoriach
/// - Dodawania nowych usług z parametrami
/// - Edycji istniejących usług
/// - Usuwania usług
class AdminServicesPage extends StatefulWidget {
  final bool isEmployee;
  const AdminServicesPage({super.key, this.isEmployee = false});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

/// \class _AdminServicesPageState
/// \brief Stan dla strony zarządzania usługami
class _AdminServicesPageState extends State<AdminServicesPage> {
  /// Instancja do obsługi operacji na bazie danych
  final DatabaseMethods _db = DatabaseMethods();

  /// Dostępne kategorie usług
  /// Kategorie pomagają klientom znaleźć usługi odpowiednie dla rozmiaru/typu zwierzęcia
  final List<String> _categoryOptions = const [
    'Mały pies (do 3 kg)',
    'Średni pies (3–10 kg)',
    'Duży pies (powyżej 10 kg)',
    'Koty',
    'Psy rasowe',
    'Inne',
  ];

  /// Aktualnie wybrany filtr kategorii
  /// "Wszystkie" pokazuje usługi ze wszystkich kategorii
  String _selectedCategoryFilter = 'Wszystkie';

  @override
  Widget build(BuildContext context) {
    // Wykryj czy to mobile (< 700px) dla układu responsive
    final isMobile = MediaQuery.of(context).size.width < 700;

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
            // Układ różny dla mobile i desktop
            child:
                isMobile
                    ? _buildMobileHeader() // Pionowy układ dla małych ekranów
                    : _buildDesktopHeader(), // Poziomy układ dla dużych ekranów
          ),
          // Siatka usług
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Nasłuchuj zmian w kolekcji usług w czasie rzeczywistym
              stream: _db.getServices(),
              builder: (context, snapshot) {
                // Pokaż wskaźnik ładowania podczas pobierania
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Jeśli brak usług, pokaż pusty stan
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Brak usług',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kliknij "Dodaj Usługę", aby utworzyć pierwszą usługę',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtruj dokumenty według wybranej kategorii
                final allDocs = snapshot.data!.docs;
                final docs =
                    allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final cat = (data['category'] ?? 'Inne').toString();
                      // Pokaż wszystkie lub tylko z wybranej kategorii
                      return _selectedCategoryFilter == 'Wszystkie' ||
                          cat == _selectedCategoryFilter;
                    }).toList();

                // Wyświetl usługi w siatce
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400, // Maksymalna szerokość karty
                    childAspectRatio:
                        1.2, // Proporcje karty (szerokość/wysokość)
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildServiceCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Buduje nagłówek dla układu mobilnego
  ///
  /// Układ pionowy z elementami pod sobą:
  /// - Ikona i tytuł/opis w pierwszym rzędzie
  /// - Dropdown filtru i przycisk w drugim rzędzie (Wrap)
  ///
  /// \return Widget nagłówka dla mobile
  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rząd z ikoną i tytułem
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.spa, color: Color(0xFF4CAF50), size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zarządzanie Usługami',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dodawaj, edytuj i usuwaj usługi oferowane w salonie',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Wrap pozwala na zawijanie elementów do nowej linii
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Dropdown filtru kategorii
            DropdownButtonHideUnderline(
              child: Container(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategoryFilter,
                  items:
                      <String>['Wszystkie', ..._categoryOptions]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged:
                      (v) => setState(
                        () => _selectedCategoryFilter = v ?? 'Wszystkie',
                      ),
                ),
              ),
            ),
            // Przycisk dodawania usługi
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj Usługę'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// \brief Buduje nagłówek dla układu desktop
  ///
  /// Układ poziomy z wszystkimi elementami w jednym rzędzie:
  /// - Ikona, tytuł, filtr i przycisk obok siebie
  ///
  /// \return Widget nagłówka dla desktop
  Widget _buildDesktopHeader() {
    return Row(
      children: [
        // Ikona sekcji
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.spa, color: Color(0xFF4CAF50), size: 28),
        ),
        const SizedBox(width: 16),
        // Tytuł i opis
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zarządzanie Usługami',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Dodawaj, edytuj i usuwaj usługi oferowane w salonie',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Dropdown filtru
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String>(
              value: _selectedCategoryFilter,
              items:
                  <String>['Wszystkie', ..._categoryOptions]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged:
                  (v) => setState(
                    () => _selectedCategoryFilter = v ?? 'Wszystkie',
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Przycisk dodawania
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj Usługę'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// \brief Buduje kartę pojedynczej usługi
  ///
  /// Struktura karty:
  /// - Górna część: Zdjęcie usługi (AspectRatio 1:1) z przyciskami akcji w overlay
  /// - Dolna część: Chip kategorii, nazwa, czas trwania i cena
  ///
  /// \param id Identyfikator usługi w bazie danych
  /// \param data Dane usługi (nazwa, czas, cena, zdjęcie, kategoria)
  /// \return Widget reprezentujący usługę
  Widget _buildServiceCard(String id, Map<String, dynamic> data) {
    // Bezpiecznie pobierz dane
    final name = data['name'] ?? 'Bez nazwy';
    final duration = data['duration'] ?? 0;
    final price = data['price'] ?? 0;
    final imageUrl = data['image'] ?? '';
    final category = (data['category'] ?? 'Inne').toString();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== SEKCJA ZDJĘCIA Z PRZYCISKAMI =====
          Expanded(
            child: Stack(
              children: [
                // Zdjęcie usługi (pełna szerokość)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            // Obsługa błędu ładowania
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.spa,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                ),
                // Przyciski akcji w overlay (prawy górny róg)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Przycisk edycji (zielony)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        onPressed:
                            () =>
                                _showAddEditDialog(context, id: id, data: data),
                      ),
                      const SizedBox(width: 8),
                      // Przycisk usuwania (czerwony) - tylko dla admina
                      if (!widget.isEmployee)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => _confirmDelete(context, id, name),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sekcja informacji
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chip z kategorią
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Nazwa usługi
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Czas trwania i cena
                Row(
                  children: [
                    // Czas trwania (z ikoną zegara)
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$duration min',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    // Cena (zielony, pogrubiony)
                    Text(
                      '$price zł',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// \brief Wyświetla dialog dodawania/edycji usługi
  ///
  /// Otwiera _ServiceDialog z opcjonalnymi danymi do edycji.
  ///
  /// \param context Kontekst buildera
  /// \param id Opcjonalny identyfikator usługi (dla edycji)
  /// \param data Opcjonalne dane usługi (dla edycji)
  void _showAddEditDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ServiceDialog(id: id, data: data),
    );
  }

  /// \brief Wyświetla dialog potwierdzenia usunięcia
  ///
  /// Po potwierdzeniu wywołuje DatabaseMethods.deleteService()
  ///
  /// \param context Kontekst buildera
  /// \param id Identyfikator usługi do usunięcia
  /// \param name Nazwa usługi (do wyświetlenia w dialogu)
  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Usuń Usługę'),
            content: Text('Czy na pewno chcesz usunąć usługę "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Usuń usługę z bazy danych
                  await _db.deleteService(id);
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

/// \class _ServiceDialog
/// \brief Dialog do dodawania i edycji usługi
///
/// Formularz zawiera:
/// - Zdjęcie usługi (klikalne, opcjonalne)
/// - Przełącznik "Usługa dla rasy premium"
/// - Dropdown kategorii
/// - Pole nazwy (wymagane)
/// - Pole czasu trwania w minutach (wymagane, liczba)
/// - Pole ceny w złotych (wymagane, liczba)
class _ServiceDialog extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? data;

  const _ServiceDialog({this.id, this.data});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

/// \class _ServiceDialogState
/// \brief Stan dialogu usługi
class _ServiceDialogState extends State<_ServiceDialog> {
  /// Klucz formularza do walidacji
  final _formKey = GlobalKey<FormState>();

  /// Kontrolery dla pól tekstowych
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  /// URL istniejącego zdjęcia (dla trybu edycji)
  String _imageUrl = '';

  /// Status ładowania
  bool _isLoading = false;

  /// Wybrane zdjęcie dla platform natywnych
  File? _selectedImage;

  /// Flaga oznaczająca usługę dla ras premium
  /// Rasy premium wymagają specjalnej obsługi i mają wyższą cenę
  bool _isPremiumBreed = false;

  /// Wybrane zdjęcie dla platformy web
  Uint8List? _selectedImageBytes;

  /// Lista dostępnych kategorii (identyczna jak w parent widget)
  final List<String> _categoryOptions = const [
    'Mały pies (do 3 kg)',
    'Średni pies (3–10 kg)',
    'Duży pies (powyżej 10 kg)',
    'Koty',
    'Psy rasowe',
    'Inne',
  ];

  /// Aktualnie wybrana kategoria
  String _selectedCategory = 'Inne';

  @override
  void initState() {
    super.initState();
    // Jeśli tryb edycji, załaduj istniejące dane
    if (widget.data != null) {
      _nameController.text = widget.data!['name'] ?? '';
      _durationController.text = (widget.data!['duration'] ?? 60).toString();
      _priceController.text = (widget.data!['price'] ?? 0).toString();
      _imageUrl = widget.data!['image'] ?? '';
      _isPremiumBreed = (widget.data!['isPremiumBreed'] ?? false) as bool;
      _selectedCategory = (widget.data!['category'] ?? 'Inne').toString();
    }
  }

  @override
  void dispose() {
    // Zwolnij zasoby kontrolerów
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// \brief Otwiera selektor zdjęcia usługi
  ///
  /// Identyczny proces jak w innych modułach:
  /// - Web: Zapisuje bajty
  /// - Native: Zapisuje ścieżkę do pliku
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  /// \brief Przesyła zdjęcie usługi do Firebase Storage
  ///
  /// Struktura: services/timestamp.jpg
  ///
  /// \return URL przesłanego zdjęcia lub istniejący URL lub null
  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) return _imageUrl;

    try {
      final fileName = 'services/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb && _selectedImageBytes != null) {
        await ref.putData(
          _selectedImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (_selectedImage != null) {
        await ref.putFile(_selectedImage!);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd przesyłania zdjęcia: $e')));
      }
      return null;
    }
  }

  /// \brief Zapisuje dane usługi do bazy danych
  ///
  /// Struktura danych usługi:
  /// {
  ///   'name': string,
  ///   'duration': int (minuty),
  ///   'price': int (złotówki),
  ///   'image': string (URL),
  ///   'isPremiumBreed': bool,
  ///   'category': string
  /// }
  Future<void> _save() async {
    // Walidacja formularza
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prześlij zdjęcie jeśli wybrane
      final imageUrl = await _uploadImage();

      // Przygotuj dane do zapisu
      final serviceData = {
        'name': _nameController.text.trim(),
        'duration': int.parse(_durationController.text),
        'price': int.parse(_priceController.text),
        'image': imageUrl ?? '',
        'isPremiumBreed': _isPremiumBreed,
        'category': _selectedCategory,
      };

      final db = DatabaseMethods();
      if (widget.id == null) {
        // Dodaj nową usługę
        await db.addService(serviceData);
      } else {
        // Zaktualizuj istniejącą
        await db.updateService(widget.id!, serviceData);
      }

      // Sukces
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.id == null ? 'Usługa dodana' : 'Usługa zaktualizowana',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      title: Text(widget.id == null ? 'Dodaj Usługę' : 'Edytuj Usługę'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Klikalne zdjęcie usługi
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child:
                        _selectedImageBytes != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : _selectedImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : _imageUrl.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kliknij, aby dodać zdjęcie',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                // Przełącznik rasy
                SwitchListTile.adaptive(
                  value: _isPremiumBreed,
                  onChanged: (v) => setState(() => _isPremiumBreed = v),
                  title: const Text('Usługa dla rasy'),
                  subtitle: const Text(
                    'Zaznacz, jeśli dotyczy ras wymagających specjalnej obsługi',
                  ),
                  activeColor: Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                // Dropdown kategorii
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _categoryOptions
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged:
                      (v) => setState(() => _selectedCategory = v ?? 'Inne'),
                ),
                const SizedBox(height: 16),
                // Pole nazwy
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nazwa usługi'),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                // Pole czasu trwania
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Czas trwania (minuty)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wymagane';
                    if (int.tryParse(value!) == null) return 'Podaj liczbę';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Pole ceny
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cena (zł)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wymagane';
                    if (int.tryParse(value!) == null) return 'Podaj liczbę';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
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
