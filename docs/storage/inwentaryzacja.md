# D1 — Inwentaryzacja danych przechowywanych na urządzeniu

**Projekt:** Pupilandia (Flutter, Android)  
**Zespół:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa  
**Podstawa audytu:** kod źródłowy `lib/services/shared_pref.dart`, analiza bibliotek oraz inspekcja katalogu aplikacji na emulatorze Android 15 (API 35), 5 listopada 2026 r.  
**Zakres:** dane aplikacji i bibliotek; bez odczytywania zawartości plików sesji, tokenów i danych osobowych.

## Inwentaryzacja

| Dane | Gdzie znajdują się obecnie | Klasyfikacja | Czy muszą być na urządzeniu? | Docelowe miejsce i opcja dostępności |
|---|---|---|---|---|
| Identyfikator użytkownika (`USERKEY`) | `SharedPreferences` — zapis przewidziany w kodzie | Poufne (identyfikator powiązany z kontem) | Nie musi być trwale kopiowany poza stanem sesji | Preferować bieżący stan `FirebaseAuth` / pamięć procesu; usunąć zbędną kopię przy wylogowaniu |
| Nazwa użytkownika (`USERNAMEKEY`) | `SharedPreferences` — zapis przewidziany w kodzie | Poufne (dane osobowe) | Nie, jeżeli można pobrać z serwera | Pamięć procesu lub odczyt na żądanie; bez trwałego zapisu, jeśli nie jest potrzebny |
| E-mail użytkownika (`USEREMAILKEY`) | `SharedPreferences` — zapis przewidziany w kodzie | Poufne (dane osobowe) | Nie, jeżeli można pobrać po uwierzytelnieniu | Pamięć procesu / Firebase Auth; usunąć zbędną kopię z preferencji |
| URL zdjęcia profilowego (`USERIMAGEKEY`) | `SharedPreferences` — zapis przewidziany w kodzie | Poufne, jeżeli URL identyfikuje osobę lub zawiera parametry dostępu | Nie musi być trwale przechowywany | Odczyt na żądanie; nie logować pełnych adresów z tokenami |
| Stan uwierzytelnienia Firebase Auth (potencjalnie dane sesji) | `shared_prefs/com.google.firebase.auth.api.Store...xml` | Poufne / szczególnie wrażliwe, jeżeli zawiera aktywne poświadczenia | Tak, jeśli wymagane jest utrzymanie logowania | Pozostawić zarządzanie SDK Firebase Auth; zweryfikować ochronę danych SDK, wylogowanie oraz wykluczenia z backupu. Nie kopiować tokenów do `SharedPreferences` |
| Metadane kryptograficzne Firebase Auth | `shared_prefs/com.google.firebase.auth.api.crypto...xml` | Wewnętrzne, potencjalnie poufne | Tak — jeśli wymaga ich SDK | Magazyn zarządzany przez SDK; sprawdzić sposób ochrony i odtwarzania |
| Cache dokumentów Firestore | `databases/firestore.[DEFAULT]...` (217 088 B) | Potencjalnie poufne — zawartości nie analizowano | Do decyzji; zależy od wymagań pracy offline | Jeśli offline nie jest wymagany, ograniczyć/wyłączyć trwały cache. W przeciwnym razie określić retencję i czyszczenie przy wylogowaniu |
| Dane pomiarowe usług Google | `shared_prefs/com.google.android.gms.measurement.prefs.xml`, `databases/google_app_measurement_local.db` | Wewnętrzne; potencjalnie poufne, gdy zawierają identyfikatory | Niekoniecznie dla podstawowych funkcji aplikacji | Zweryfikować konieczność zależności, zakres pomiarów, retencję i konfigurację SDK |
| Diagnostyka Firebase | `shared_prefs/FirebaseHeartBeat...xml` | Wewnętrzne | Zarządzane przez SDK; konieczność do weryfikacji | Pozostawić pod kontrolą SDK; nie kopiować do własnych logów |
| Identyfikator/stan instalacji Firebase | `files/PersistedInstallation...json` | Poufne (identyfikator instalacji) | Tak, jeśli jest wymagany przez Firebase | Magazyn SDK; nie eksportować ani nie logować identyfikatora |
| Stan pomocniczy Image Picker | `shared_prefs/flutter_image_picker_shared_preference.xml` | Wewnętrzne; potencjalnie poufne, gdy zapisuje ścieżki do zdjęć | Tylko tymczasowo | Czyścić niepotrzebne dane po zakończeniu operacji; przechowywać w pamięci tymczasowej |
| Plik tymczasowy zdjęcia | `cache/*.jpg` (zaobserwowany plik miał 0 B) | Potencjalnie poufne (zdjęcie osoby) | Tylko podczas wyboru / przesyłania zdjęcia | Cache tymczasowy; usuwać po wykorzystaniu i nie umieszczać w kopiach zapasowych |
| Dane pomocnicze powiadomień | `shared_prefs/notification_plugin_cache.xml` | Wewnętrzne; potencjalnie poufne, jeśli zawierają szczegóły wizyt | Tylko gdy służą do harmonogramu przypomnień | Minimalizować treść powiadomień i okres przechowywania; czyścić przy wylogowaniu, jeśli powiązane z użytkownikiem |
| Cache/metadane Google Maps | `cache/com.google.android.gms.maps.volley/`, `files/DATA_disk_creation_time...`, `files/com.google.android.gms.maps._m_u` | Zasadniczo wewnętrzne / techniczne | Nie są konieczne jako trwały zapis | Cache SDK; bez danych lokalizacji użytkownika, o ile aplikacja ich nie pobiera |
| Konfiguracja usług Google i zasoby aplikacji | `files/phenotype/`, `files/phenotype_storage_info/`, `app_flutter/flutter_assets/`, `code_cache/` | Wewnętrzne / techniczne | Tak, jeśli potrzebne bibliotekom i aplikacji | Magazyn techniczny SDK/Flutter; nie umieszczać tam sekretów aplikacji |

## Potwierdzone ustalenia i ograniczenia

1. Kod `lib/services/shared_pref.dart` posiada metody zapisu i odczytu czterech kluczy: `USERKEY`, `USERNAMEKEY`, `USEREMAILKEY`, `USERIMAGEKEY`. **Nie potwierdzono obecności ich wartości** w bieżącym stanie emulatora; plik `FlutterSharedPreferences.xml` wystąpił we wcześniejszym odczycie katalogu, lecz nie w późniejszym.
2. W katalogu `databases/` potwierdzono lokalną bazę Firestore o rozmiarze 217 088 B oraz bazę Google Measurement o rozmiarze 16 384 B. Nie badano zawartości rekordów.
3. W `shared_prefs/` występują pliki Firebase Auth, Image Picker, powiadomień i komponentów Google. Ich nazwy potwierdzają istnienie lokalnego stanu bibliotek, ale **nie dowodzą przechowywania konkretnych tokenów jawnym tekstem**.
4. W `cache/` wykryto pusty plik JPG (0 B) oraz katalog cache Google Maps. Pusty plik nie dowodzi obecności obrazu użytkownika.
5. Tabela obejmuje stwierdzony stan Androida. Dla iOS należy osobno sprawdzić Keychain, UserDefaults, katalogi aplikacji i reguły kopii zapasowych.
6. Kolumna „Docelowe miejsce” zawiera **propozycje do decyzji D3**, a nie deklaracje już wdrożonych zabezpieczeń.

