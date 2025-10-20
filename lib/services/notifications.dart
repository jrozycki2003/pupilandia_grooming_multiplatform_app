/// \file notifications.dart
/// \brief Serwis do obsługi powiadomień lokalnych
/// 
/// Zarządza powiadomieniami przypominającymi o wizytach.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// \class NotificationsService
/// \brief Serwis zarządzający powiadomieniami lokalnymi
class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin(); ///< Plugin do powiadomień

  static bool _initialized = false; ///< Status inicjalizacji

  /// \brief Inicjalizuje serwis powiadomień
  /// 
  /// Konfiguruje plugin i ustawia strefę czasową.
  static Future<void> initialize() async {
    if (_initialized) return;

    // Timezone init
    tz.initializeTimeZones();
    final String localName = tz.local.name; // ensure local initialized
    tz.setLocalLocation(tz.getLocation(localName));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: null,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// \brief Sprawdza czy aplikacja ma uprawnienia do powiadomień
  /// \return true jeśli uprawnienia są przyznane
  static Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      // On Android < 13 it's granted by default. On 13+ needs POST_NOTIFICATIONS
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    } else {
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    }
  }

  /// \brief Prośi użytkownika o uprawnienia do powiadomień
  /// \return true jeśli użytkownik przyznał uprawnienia
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  /// \brief Planuje powiadomienie przypominające
  /// \param id Unikalny identyfikator powiadomienia
  /// \param dateTime Data i czas powiadomienia
  /// \param title Tytuł powiadomienia
  /// \param body Treść powiadomienia
  static Future<void> scheduleReminder({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    // Only schedule if permission is granted and time is in the future
    final allowed = await isPermissionGranted();
    final when = dateTime.toLocal();
    if (!allowed || when.isBefore(DateTime.now().toLocal())) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminders_channel',
          'Przypomnienia o wizytach',
          channelDescription:
              'Powiadomienia przypominające o zbliżających się wizytach',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }
}
