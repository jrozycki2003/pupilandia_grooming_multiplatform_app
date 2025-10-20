/// \file database.dart
/// \brief Serwis do obsługi operacji na bazie danych Firestore
/// 
/// Zawiera metody CRUD dla wszystkich kolekcji w Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

/// \class DatabaseMethods
/// \brief Klasa zawierająca metody dostępu do bazy danych
class DatabaseMethods {
  /// \brief Dodaje lub aktualizuje dane użytkownika
  /// \param userInfoMap Mapa z danymi użytkownika
  /// \param id Identyfikator użytkownika
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  /// \brief Dodaje nową rezerwację
  /// \param userInfoMap Dane rezerwacji
  Future addUserBooking(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Booking")
        .add(userInfoMap);
  }

  /// \brief Pobiera stream wszystkich rezerwacji
  /// \return Stream z rezerwacjami
  Future<Stream<QuerySnapshot>> getBookings() async {
    return FirebaseFirestore.instance.collection("Booking").snapshots();
  }

  /// \brief Usuwa rezerwację
  /// \param id Identyfikator rezerwacji
  Future deleteBooking(String id) async {
    return await FirebaseFirestore.instance
        .collection("Booking")
        .doc(id)
        .delete();
  }

  /// \brief Wyszukuje użytkownika po emailu
  /// \param email Adres email użytkownika
  /// \return QuerySnapshot z danymi użytkownika
  Future<QuerySnapshot> getUserByEmail(String email) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: email)
        .limit(1)
        .get();
  }

  /// \brief Aktualizuje zdjęcie profilowe użytkownika
  /// \param userId Identyfikator użytkownika
  /// \param imageUrl URL zdjęcia
  Future<void> updateUserImage(String userId, String imageUrl) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set({
          "image": imageUrl,
        }, SetOptions(merge: true));
  }

  /// \brief Pobiera stream rezerwacji dla konkretnego użytkownika
  /// \param email Email użytkownika
  /// \return Stream z rezerwacjami
  Stream<QuerySnapshot> getUpcomingBookings(String email) {
    return FirebaseFirestore.instance
        .collection('Booking')
        .where('Email', isEqualTo: email)
        .snapshots();
  }

  /// \brief Aktualizuje dane rezerwacji
  /// \param bookingId Identyfikator rezerwacji
  /// \param updates Mapa z danymi do aktualizacji
  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    await FirebaseFirestore.instance
        .collection('Booking')
        .doc(bookingId)
        .update(updates);
  }

  /// \brief Pobiera rezerwacje dla konkretnego dnia
  /// \param date Data
  /// \return Lista rezerwacji
  Future<List<Map<String, dynamic>>> getBookingsForDate(DateTime date) async {
    final dateString = '${date.day}/${date.month}/${date.year}';
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Booking')
            .where('date', isEqualTo: dateString)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// \brief Pobiera stream porad
  /// \return Stream z poradami
  Stream<QuerySnapshot> getTips() {
    return FirebaseFirestore.instance.collection('tips').snapshots();
  }

  /// \brief Pobiera stream opinii klientów
  /// \return Stream z opiniami
  Stream<QuerySnapshot> getReviews() {
    return FirebaseFirestore.instance.collection('reviews').snapshots();
  }

  Future<DocumentReference> addReview(Map<String, dynamic> reviewData) {
    return FirebaseFirestore.instance.collection('reviews').add(reviewData);
  }

  // Services (Usługi) — reset do schematu: { name, duration, price, image }
  Stream<QuerySnapshot> getServices() {
    return FirebaseFirestore.instance
        .collection('services')
        .orderBy('name')
        .snapshots();
  }

  Future<DocumentReference> addService(Map<String, dynamic> serviceData) {
    serviceData['name'] = (serviceData['name'] ?? '').toString();
    serviceData['duration'] = (serviceData['duration'] ?? 60);
    serviceData['price'] = (serviceData['price'] ?? 0);
    serviceData['image'] = (serviceData['image'] ?? '').toString();
    return FirebaseFirestore.instance.collection('services').add(serviceData);
  }

  // Groomers (Personel) — { firstName, lastName, phone, image }
  Stream<QuerySnapshot> getGroomers() {
    return FirebaseFirestore.instance
        .collection('groomers')
        .orderBy('firstName')
        .snapshots();
  }

  // Umów się na wizytę u konkretnego groomera w wybranym terminie
  Future<List<Map<String, dynamic>>> getGroomerBookingsForDate(
    String groomerId,
    DateTime date,
  ) async {
    final dateString = '${date.day}/${date.month}/${date.year}';
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Booking')
            .where('groomerId', isEqualTo: groomerId)
            .where('date', isEqualTo: dateString)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> updateUserName(String userId, String name) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': name,
    });
  }

  // Galeria (Before/After) — { imageBefore, imageAfter }
  Stream<QuerySnapshot> getGalleryBeforeAfter() {
    return FirebaseFirestore.instance
        .collection('galleryBeforeAfter')
        .snapshots();
  }

  Future<DocumentReference> addGalleryItem(Map<String, dynamic> galleryData) {
    return FirebaseFirestore.instance
        .collection('galleryBeforeAfter')
        .add(galleryData);
  }

  Future<void> deleteGalleryItem(String id) {
    return FirebaseFirestore.instance
        .collection('galleryBeforeAfter')
        .doc(id)
        .delete();
  }

  // Operacja CRUD dla porad
  Future<DocumentReference> addTip(Map<String, dynamic> tipData) {
    return FirebaseFirestore.instance.collection('tips').add(tipData);
  }

  Future<void> updateTip(String id, Map<String, dynamic> tipData) {
    return FirebaseFirestore.instance.collection('tips').doc(id).update(tipData);
  }

  Future<void> deleteTip(String id) {
    return FirebaseFirestore.instance.collection('tips').doc(id).delete();
  }

  // Announcements (Ogłoszenia) — pokazane na stronie głównej
  Stream<QuerySnapshot> getAnnouncements() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('startAt', descending: false)
        .snapshots();
  }

  Future<DocumentReference> addAnnouncement(Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('announcements').add(data);
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('announcements').doc(id).update(data);
  }

  Future<void> deleteAnnouncement(String id) {
    return FirebaseFirestore.instance.collection('announcements').doc(id).delete();
  }

  // Operacja CRUD dla usług
  Future<void> updateService(String id, Map<String, dynamic> serviceData) {
    return FirebaseFirestore.instance
        .collection('services')
        .doc(id)
        .update(serviceData);
  }

  Future<void> deleteService(String id) {
    return FirebaseFirestore.instance.collection('services').doc(id).delete();
  }

  // Operacja CRUD dla pracowników
  Future<DocumentReference> addGroomer(Map<String, dynamic> groomerData) {
    return FirebaseFirestore.instance.collection('groomers').add(groomerData);
  }

  Future<void> updateGroomer(String id, Map<String, dynamic> groomerData) {
    return FirebaseFirestore.instance
        .collection('groomers')
        .doc(id)
        .update(groomerData);
  }

  Future<void> deleteGroomer(String id) {
    return FirebaseFirestore.instance.collection('groomers').doc(id).delete();
  }

  /// \brief Pobiera stream wszystkich użytkowników
  /// \return Stream z użytkownikami
  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots();
  }

  /// \brief Usuwa użytkownika z bazy danych
  /// \param userId Identyfikator użytkownika
  Future<void> deleteUser(String userId) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete();
  }
}
