/// \file shared_pref.dart
/// \brief Serwis do zarządzania lokalnymi preferencjami użytkownika
/// 
/// Przechowuje dane użytkownika lokalnie używając SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';

/// \class SharedPreferenceHelper
/// \brief Klasa pomocnicza do zarządzania lokalnymi preferencjami
class SharedPreferenceHelper {
  static String userIdKey = "USERKEY"; ///< Klucz dla ID użytkownika
  static String userNameKey = "USERNAMEKEY"; ///< Klucz dla imienia użytkownika
  static String userEmailKey = "USEREMAILKEY"; ///< Klucz dla emaila użytkownika
  static String userImageKey = "USERIMAGEKEY"; ///< Klucz dla zdjęcia użytkownika

  /// \brief Zapisuje ID użytkownika
  /// \param getUserId ID użytkownika
  /// \return true jeśli zapis się powiódł
  Future<bool> saveUserId(String getUserId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }

  /// \brief Zapisuje imię użytkownika
  /// \param getUserName Imię użytkownika
  /// \return true jeśli zapis się powiódł
  Future<bool> saveUserName(String getUserName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, getUserName);
  }

  /// \brief Zapisuje email użytkownika
  /// \param getUserEmail Email użytkownika
  /// \return true jeśli zapis się powiódł
  Future<bool> saveUserEmail(String getUserEmail) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, getUserEmail);
  }

  /// \brief Zapisuje URL zdjęcia użytkownika
  /// \param getUserImage URL zdjęcia
  /// \return true jeśli zapis się powiódł
  Future<bool> saveUserImage(String getUserImage) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageKey, getUserImage);
  }

  /// \brief Pobiera zapisane ID użytkownika
  /// \return ID użytkownika lub null
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  /// \brief Pobiera zapisane imię użytkownika
  /// \return Imię użytkownika lub null
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  /// \brief Pobiera zapisany email użytkownika
  /// \return Email użytkownika lub null
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  /// \brief Pobiera zapisany URL zdjęcia użytkownika
  /// \return URL zdjęcia lub null
  Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageKey);
  }
}
