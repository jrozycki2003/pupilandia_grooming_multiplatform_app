# D2 — Raport „przed”: stan lokalnego przechowywania danych

**Projekt:** Pupilandia (Flutter / Android)  
**Zespół:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa  
**Środowisko:** emulator Android 15, API 35; oględziny z 5 listopada 2026 r. oraz przegląd kodu 6 listopada 2026 r.  
**Cel:** udokumentowanie aktualnego stanu **przed wdrożeniem poprawek bezpieczeństwa** na zajęcia 5.

## Metoda i ograniczenia

- Przejrzano kod `lib/services/shared_pref.dart`, miejsca wylogowania w `lib/pages/home.dart` i `lib/widgets/web_navbar.dart` oraz wyszukano `print`, `debugPrint`, `signOut` i `.clear` w `lib/`.
- Na emulatorze użyto `adb shell run-as com.kuba.kubaproject ls -la` w katalogach `shared_prefs/`, `databases/`, `files/`, `cache/`, `app_flutter/`. Odczytano **nazwy i rozmiary plików, nie ich zawartość**.
- **Nie odczytywano tokenów, danych sesyjnych ani danych osobowych.** Nie przeprowadzono jeszcze przeglądu logcat pod kątem wycieków. Nie badano iOS, kopii zapasowych, ani zachowania po wylogowaniu i reinstalacji.
- Oceny ryzyka to **wstępne oceny ekspozycji**, nie potwierdzenia naruszenia bezpieczeństwa.

## Wykryte miejsca zapisu i potencjalne ujawnienie danych

| Miejsce | Co potwierdzono | Czy dane jawne? | Wstępne ryzyko | Dowód / uwagi |
|---|---|---|---|---|
| `SharedPreferences` (cztery klucze aplikacji) | `USERKEY`, `USERNAMEKEY`, `USEREMAILKEY`, `USERIMAGEKEY` są zapisywane przez `setString` w `lib/services/shared_pref.dart` | **Potencjalnie tak** — standardowe SharedPreferences nie szyfruje tych wartości; bieżących wartości na emulatorze nie odczytano | **Średnie** (dane osobowe/identyfikatory) | Kod źródłowy; `FlutterSharedPreferences.xml` widoczny w jednym odczycie, niewidoczny w kolejnym |
| `shared_prefs/com.google.firebase.auth.api.Store...xml` | Istnieje lokalny plik stanu Firebase Auth (4360 B) | **Nieustalone** — nie otwierano pliku; nie wolno zakładać, że token jest jawny | **Potencjalnie wysokie** (sesja uwierzytelnienia) | Lista plików z emulatora; wymaga oceny mechanizmu ochrony SDK |
| `shared_prefs/com.google.firebase.auth.api.crypto...xml` | Istnieją metadane pomocnicze Firebase Auth (537 B) | Nieustalone | Do weryfikacji | Lista plików z emulatora |
| `databases/firestore...` | Istnieje lokalna baza Firestore (217 088 B) | **Nieustalone** — nie analizowano danych ani szyfrowania bazy | **Potencjalnie wysokie**, jeśli zawiera dokumenty klientów lub rezerwacji | Lista plików z emulatora; zawartość i retencja nieznane |
| `shared_prefs/com.google.android.gms.measurement.prefs.xml`, `databases/google_app_measurement_local.db` | Pliki komponentu pomiarowego (baza 16 384 B) | Nieustalone | Do weryfikacji | Lista plików z emulatora; nie dowodzi śledzenia użytkownika |
| `files/PersistedInstallation...json` | Lokalny stan/identyfikator instalacji Firebase (570 B) | Nieustalone | Średnie (identyfikator) | Lista plików z emulatora |
| `shared_prefs/FirebaseHeartBeat...xml` | Plik diagnostyczny Firebase (719 B) | Nieustalone | Niskie / do weryfikacji | Lista plików z emulatora |
| `shared_prefs/flutter_image_picker_shared_preference.xml` | Dane pomocnicze Image Picker (362 B) | Nieustalone | Średnie, jeśli przechowuje ścieżki do zdjęć | Lista plików z emulatora |
| `cache/*.jpg` | Pusty plik tymczasowy `.jpg` (0 B) | **Nie zawiera zdjęcia w badanej chwili** | Niskie dla tego konkretnego pliku; przyszłe zdjęcia wymagają kontroli | Lista plików z emulatora |
| `shared_prefs/notification_plugin_cache.xml` | Plik pomocniczy powiadomień (130 B) | Nieustalone | Do weryfikacji, jeśli zawiera szczegóły wizyt | Lista plików z emulatora |
| `cache/com.google.android.gms.maps.volley/` i `files/DATA_disk_creation_time...` | Cache/metadane Google Maps | Nieustalone | Niskie / do weryfikacji | Lista katalogów i plików |
| Logi aplikacji | Wykryto `debugPrint("Firebase init error: $e")`, `debugPrint("Notifications init error: $e")`, `debugPrint("Locale init error: $e")` oraz log błędu inicjalizacji powiadomień | **Nie potwierdzono wycieku**; treść wyjątków może zawierać dane diagnostyczne | Średnie, jeśli szczegóły trafiają do produkcyjnych logów | Przeszukanie `lib/`; brak jeszcze próby w logcat |

## Stan wylogowania — ustalony w przeglądzie kodu

| Ścieżka | Obecne zachowanie | Ryzyko / luka |
|---|---|---|
| `lib/pages/home.dart` (menu „Wyloguj”) | Wywołuje `FirebaseAuth.instance.signOut()`, **następnie zapisuje puste łańcuchy** do `USERKEY`, `USERNAMEKEY`, `USEREMAILKEY` i `USERIMAGEKEY`; przechodzi na ekran główny | Zastąpienie wartości `''` nie usuwa samych kluczy. Nie widać czyszczenia cache Firestore ani powiadomień powiązanych z kontem |
| `lib/widgets/web_navbar.dart` (menu `logout`) | Wywołuje tylko `FirebaseAuth.instance.signOut()` | **Brak jawnego czyszczenia czterech wartości SharedPreferences** w tej ścieżce; zachowanie pozostałych komponentów wymaga testu |

**Ważne:** wcześniejsze wyszukiwanie `.clear(` nie wykazało wywołań, ale nie było dowodem na brak czyszczenia wartości — `home.dart` używa `saveUser*('')`. Ta różnica została uwzględniona w raporcie.

## Potwierdzone i niepotwierdzone ustalenia

**Potwierdzone:** aplikacja deklaruje zapis danych osobowych w zwykłym `SharedPreferences`; lokalnie istnieje baza Firestore oraz pliki stanu Firebase Auth i innych SDK; kod zawiera logowanie wyjątków; obie ścieżki wylogowania różnią się zakresem czyszczenia danych aplikacji.

**Niepotwierdzone:** obecność konkretnych danych osobowych w aktualnych preferencjach, token przechowywany jawnym tekstem, plaintext w bazie Firestore, rzeczywisty wyciek do logcat, możliwość odtworzenia sesji z backupu, stan po reinstalacji i po zmianie hasła.


## Wstępny priorytet

1. Spójne czyszczenie danych osobowych we wszystkich ścieżkach wylogowania.
2. Kontrola trwałego cache Firestore i polityki sesji.
3. Audyt logów oraz kopii zapasowych.
4. Minimalizacja zbędnych kopii danych osobowych w `SharedPreferences`.
