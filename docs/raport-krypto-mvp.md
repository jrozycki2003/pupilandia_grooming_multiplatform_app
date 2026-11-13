# Raport bezpieczeństwa - Pupilandia

**Zajęcia 5:** Kryptografia i kamień milowy MVP
**Autor:** Mateusz Sarwa, Michał Dyrka, Jakub Różycki

---

## 1. Kryptografia w aplikacji

Aplikacja nie implementuje własnej kryptografii. Szyfrowanie transmisji, przechowywanie haseł i generowanie identyfikatorów dokumentów realizują SDK Firebase (Auth, Firestore, Storage). Poniższa tabela obejmuje wszystkie miejsca, w których aplikacja korzysta z kryptografii, kluczy lub losowości (bezpośrednio albo przez SDK).

### 1.1 Tabela

| Miejsce w aplikacji | Zadanie | Co jest teraz (plik:linia) | Klucz: skąd i gdzie | Problem | Decyzja i źródło |
|---|---|---|---|---|---|
| Konfiguracja Firebase (Web) | Identyfikacja projektu (nie sekret) | `lib/api_keys.dart:12` - `FIREBASE_WEB_API_KEY` jako stała Dart; używana w `lib/firebase_options.dart:60` | Stała w kodzie; plik w `.gitignore` (`.gitignore`, wpis `lib/api_keys.dart`), ale wartość trafia do zbudowanej aplikacji | Klucz w kodzie - da się go odczytać z paczki. Klucz Firebase nie jest sekretem, ale bez ograniczeń w konsoli i bez Security Rules pozwala każdemu wywołać API projektu | Klucza nie ukrywamy, tylko go ograniczamy: restrykcje klucza w Google Cloud Console (domeny / pakiet Android + SHA-1), Firebase App Check, dostęp kontrolowany przez Security Rules (dokumentacja Firebase „Learn about using and managing API keys for Firebase”; OWASP MASVS-CRYPTO-2) |
| Mapa salonu (Google Maps) | Identyfikacja klienta API | `android/app/src/main/AndroidManifest.xml:64-65` - `com.google.android.geo.API_KEY` = `${GOOGLE_MAPS_API_KEY}`; wstrzykiwany w `android/app/build.gradle.kts:49` | `secrets.properties` (poza repo), ale w gotowym APK jawny w manifeście | Klucz wyciągalny z APK (`aapt dump` / jadx) - możliwe nadużycie limitów płatnego API | Restrykcja klucza do aplikacji Android (nazwa pakietu + odcisk SHA-1 certyfikatu) i tylko Maps SDK for Android (dokumentacja Google Maps Platform „API security best practices”) |
| Logowanie i rejestracja | Ochrona haseł | `lib/pages/login.dart:42` - `signInWithEmailAndPassword`; `lib/pages/signup.dart:53-54` - `createUserWithEmailAndPassword` | Brak klucza po stronie aplikacji; hasło przekazywane do Firebase Auth przez TLS | Brak - aplikacja nie haszuje ani nie zapisuje hasła lokalnie; Firebase Auth przechowuje hasła z użyciem funkcji wolnej (zmodyfikowany scrypt) | Bez zmian - hasła po stronie serwera, specjalna funkcja do haseł (zasada 05 z zajęć; dokumentacja Firebase Auth „Password hashing”, OWASP MASVS-AUTH) |
| Komunikacja z Firebase (Auth, Firestore, Storage) | Poufność i integralność w tranzycie | Wywołania SDK, np. `lib/services/database.dart:14-26`; brak własnego klienta HTTP w `lib/` | Klucze sesyjne TLS negocjowane przez system/SDK; certyfikaty z magazynu systemowego | Brak `usesCleartextTraffic` w manifeście - sprawdzone; brak przypinania certyfikatów (świadomie - rotacja certyfikatów Google) | Bez zmian - TLS zapewniany przez SDK (OWASP MASVS-NETWORK-1). Przypinania nie wdrażamy (zalecenie Firebase / Google - certyfikaty rotowane) |
| Dane użytkownika na urządzeniu | Poufność | `lib/services/shared_pref.dart:21-45` - UID, imię, e-mail, URL zdjęcia zapisane jawnym tekstem w `SharedPreferences`; wywołania w `lib/pages/login.dart:66-69`, `lib/pages/signup.dart:61-64` | Brak klucza - dane niezaszyfrowane | Dane osobowe jawnie w `shared_prefs/` (zob. `docs/storage/raport-przed.md`) | Minimalizacja zamiast szyfrowania: usunąć trwałą kopię, czytać z `FirebaseAuth.currentUser` / Firestore (decyzja D3, `docs/storage/decyzje.md`). Jeśli pojawi się własny sekret - `flutter_secure_storage` (Android Keystore / iOS Keychain) (OWASP MASTG, MASVS-STORAGE-1) |
| Nazwy plików w Storage (awatar, galeria, usługi, groomerzy, porady) | Losowość / unikalność | `lib/pages/profile.dart:120-121` - `avatars/$uid/$ts.jpg`, gdzie `ts = millisecondsSinceEpoch`; analogicznie `lib/pages/admin/admin_gallery.dart:513`, `admin_groomers.dart:497`, `admin_services.dart:681`, `admin_tips.dart:390` | Brak klucza | Przewidywalna ścieżka pliku (znacznik czasu). Ryzyko niskie - dostęp chroni token w `getDownloadURL()` i Rules Storage, ale nazwy nie mogą być traktowane jako tajne | Nie opierać bezpieczeństwa na nazwie pliku; dostęp tylko przez Storage Rules. Jeśli potrzebny losowy identyfikator - auto-ID Firestore lub `Random.secure()` (dokumentacja Dart `dart:math`; OWASP MASVS-CRYPTO-1). Usunąć nieużywaną zależność `random_string` z `pubspec.yaml:22` |
| Identyfikatory dokumentów Firestore (rezerwacje, opinie, usługi) | Losowość | `lib/services/database.dart:26` - `.add()`; `:121`, `:137`, `:184`, `:196`, `:216`, `:241` | Brak klucza; ID generuje SDK (20 znaków, generator kryptograficzny) | Brak | Bez zmian (dokumentacja Firestore - auto-ID) |

### 1.2 Kategorie błędów

| Kategoria | Wynik | Jak szukaliśmy |
|---|---|---|
| Klucz w kodzie | **Znaleziono** - wiersze „Konfiguracja Firebase” (`lib/api_keys.dart:12`) i „Mapa salonu” (`AndroidManifest.xml:64-65`). Oba to klucze identyfikujące, a nie sekrety kryptograficzne - wymagają ograniczeń w konsoli, nie ukrywania | `grep` po `apiKey`, `API_KEY`, `secret`, `AIza`, `key`; `git log --all -- lib/api_keys.dart` (plik nigdy nie był commitowany); `git ls-files` po `google-services.json`, `*.jks`, `key.properties` - brak w repo |
| Przestarzały algorytm lub tryb | **Sprawdzone, brak** - aplikacja nie używa własnych algorytmów | `grep` po `crypto`, `encrypt`, `AES`, `ECB`, `md5`, `sha`; przegląd zależności w `pubspec.yaml` (brak `crypto`, `encrypt`, `pointycastle`) |
| Przewidywalna losowość | **Znaleziono (niskie ryzyko)** - wiersz „Nazwy plików w Storage” (`lib/pages/profile.dart:120`) | `grep` po `Random`, `random`, `millisecondsSinceEpoch`, `uuid`; zależność `random_string` w `pubspec.yaml` nie jest nigdzie importowana |
| Powtarzane wartości jednorazowe | **Sprawdzone, brak** - aplikacja nie generuje IV ani nonce | `grep` po `iv`, `nonce`, `IV`, `Cipher`; brak bibliotek kryptograficznych |
| Hasło jako zwykły skrót | **Sprawdzone, brak** - hasła obsługuje wyłącznie Firebase Auth | `grep` po `password`, `hash`, `sha`; przegląd `login.dart`, `signup.dart`, `forgot_password.dart` - hasło nie jest zapisywane ani haszowane lokalnie |
| Szyfrowanie bez integralności | **Nie dotyczy** - nic nie jest szyfrowane po stronie aplikacji. Uwaga: dane w `SharedPreferences` są jawne (wiersz „Dane użytkownika na urządzeniu”) | Jak wyżej; przegląd `lib/services/shared_pref.dart` |

**Ograniczenie metody:** przeszukiwanie kodu źródłowego (`grep`) i historii git. Dekompilacja buildu release (jadx / `apktool`) nie została jeszcze wykonana - zadanie w planie do zajęć 6.

---

## 2. Stan aplikacji i plan

### Stan aplikacji

| Obszar | Status | Największe ryzyko |
|---|---|---|
| Funkcje (MVP) | **Działają** - rezerwacje, kalendarz, historia, panel administratora i pracownika, powiadomienia, galeria, porady, mapa (`README.md`, sekcja „Najważniejsze funkcje”) | Role sprawdzane w kliencie - np. flaga `isAdmin` w `lib/pages/book_appointment.dart:23`; bez Security Rules zalogowany użytkownik może czytać i zmieniać cudze dane |
| Build z repozytorium | **Warunkowo** - wymaga ręcznych kroków: skopiowania `lib/api_keys.dart.template` → `lib/api_keys.dart`, `secrets.properties`, `google-services.json` (`README.md:83-94`) | Czysty klon nie buduje się bez ręcznej konfiguracji - niespełnione kryterium M2 |
| Model zagrożeń | **Gotowe** - `docs/threat-model/` (`threat-model.md`, `dfd.md`, `threats-v1.md`) | Model trzeba zaktualizować o wnioski z zajęć 4-5 (klucze API, dane lokalne) |
| Uprawnienia | **Gotowe** - „Harden Android permissions” | Do potwierdzenia na Merged Manifest - biblioteki mogą dodawać uprawnienia |
| Przechowywanie danych | **Częściowo** - dokumentacja D1-D5 w `docs/storage/`, raport „przed” gotowy; `docs/storage/dokumentacja-storage.md` niezacommitowany. Kod nadal zapisuje dane w `SharedPreferences` (`lib/services/shared_pref.dart:21-45`) | Brak raportu „po” i brak wdrożenia decyzji D3 - niespełnione kryterium M4 |
| Kryptografia | **Bez własnej kryptografii** - wszystko przez SDK Firebase (sekcja 1) | Klucze Firebase i Maps wyciągalne z APK; ograniczenia w konsoli niezweryfikowane |

**Werdykt MVP: warunkowo.** Funkcje działają, a dokumenty z zajęć 2-4 są w `docs/`. Największe ryzyko to brak Security Rules Firestore/Storage w repozytorium (brak plików `firestore.rules` i `storage.rules`) przy rolach sprawdzanych wyłącznie w kliencie. Do tego build wymaga ręcznych kroków, a migracja danych z `SharedPreferences` nie jest wdrożona.

### Plan do zajęć 6

| Zadanie | Kto | Termin | Sposób sprawdzenia |
|---|---|---|---|
| Dodać `firestore.rules` i `storage.rules` do repozytorium (role na backendzie, dostęp tylko do własnych rezerwacji) | Jakub Różycki | przed zajęciami 6 | Testy w Firebase Emulator: użytkownik A nie czyta/nie modyfikuje rezerwacji użytkownika B ani nie nadaje sobie roli |
| Usunąć ręczne kroki builda - konfiguracja przez `flutterfire configure` / `--dart-define` z wartościami domyślnymi, aktualizacja README | Jakub Różycki | przed zajęciami 6 | Czysty `git clone` + polecenia z README → `flutter build apk` kończy się sukcesem |
| Wdrożyć decyzję D3: usunąć trwałą kopię UID / imienia / e-maila / URL z `SharedPreferences`, czyścić dane przy wylogowaniu | Jakub Różycki | przed zajęciami 6 | `adb shell run-as com.kuba.kubaproject cat shared_prefs/FlutterSharedPreferences.xml` - brak danych osobowych |
| Napisać raport „po” dla przechowywania danych (`docs/storage/raport-po.md`) i zacommitować `dokumentacja-storage.md` | Jakub Różycki | przed zajęciami 6 | Plik w repo; porównanie z `raport-przed.md` |
| Ograniczyć klucze API w Google Cloud Console (Maps: pakiet + SHA-1; Firebase Web: domeny) i włączyć App Check | Jakub Różycki | przed zajęciami 6 | Zrzut ustawień restrykcji; wywołanie API kluczem z innej aplikacji / domeny zwraca błąd 403 |
| Usunąć nieużywaną zależność `random_string` z `pubspec.yaml` | Jakub Różycki | przed zajęciami 6 | `flutter pub get` + `flutter analyze` bez błędów; `grep random_string lib/` pusty |
| Dekompilacja buildu release (jadx) - weryfikacja kategorii z 1.2 na gotowym APK | Jakub Różycki | przed zajęciami 6 | Wyniki dopisane do sekcji 1.2 tego raportu |
