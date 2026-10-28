# Arkusz sekcji – Z2

Arkusz z zajęć 2. Punkty 1–4 do rundy z prowadzącym. Punkt 5 to zadanie na zajęcia 3.

## Nagłówek

| Pole | Wartość |
| --- | --- |
| Sekcja / aplikacja | Pupilandia — rezerwacje wizyt w salonie groomerskim |
| Technologia | Flutter (Dart) + Firebase |
| Zajęcia nr | 2 |
| Temat zajęć | Modelowanie zagrożeń i architektura |
| Obszar MASVS | Fundament pod wszystkie obszary; na dziś głównie **MASVS-AUTH**, **MASVS-STORAGE**, **MASVS-NETWORK**, **MASVS-PLATFORM** |
| Osoby obecne | Jakub Różycki, Mateusz Sarwa, Michał Dyrka |

## 0. Status z poprzedniego tygodnia

Zadanie z zajęć 1: repozytorium, karta projektu w README, szkielet który się buduje, lektura MASVS, szkic architektury.

| Zadanie | Status | Dowód |
| --- | --- | --- |
| Repozytorium GitHub z dostępem dla prowadzącego | zrobione | [pupilandia_grooming_multiplatform_app](https://github.com/jrozycki2003/pupilandia_grooming_multiplatform_app) |
| README z finalną kartą projektu | częściowo | Aplikacja w README jest opisana, ale **pełna karta projektu z zajęć 1 jeszcze nie jest wklejona** — do uzupełnienia przed rundą / Z3 |
| Szkielet aplikacji, który się buduje i loguje do Firebase | zrobione | Istniejąca aplikacja inżynierska: `lib/main.dart` (Firebase + `AuthChecker`), `lib/pages/login.dart`, `flutter run` na Androidzie |
| Lektura wprowadzenia do OWASP MASVS | zrobione | Omówione przy karcie projektu (mapowanie ról zespołu na obszary MASVS) |
| Szkic architektury | częściowo | Opis komponentów jest w karcie projektu; diagram DFD z granicami zaufania powstaje na Z2 (`docs/threat-model/`) |

## 1. Gdzie to zagrożenie występuje u nas?

Temat zajęć: **przepływy przez granice zaufania** oraz dane **poufne** i **szczególnie wrażliwe** z karty projektu.

Danych szczególnie wrażliwych (zdrowie, biometria, finanse, dokładna lokalizacja użytkownika) **obecnie nie zbieramy**. Lokalizacja użytkownika nie jest używana — na mapie jest stały adres salonu. Biometria jest dopiero w planie (Z4).

| Miejsce w aplikacji | Jakie dane lub funkcja są zagrożone | Klasyfikacja danych |
| --- | --- | --- |
| `lib/pages/login.dart`, `signup.dart`, `forgot_password.dart` | E-mail, hasło, token sesji Firebase (ID/refresh token w SDK) | Poufne |
| `lib/services/shared_pref.dart` — UID, imię, e-mail, URL zdjęcia jawnym tekstem | Dane osobowe + powiązanie z rezerwacjami | Poufne |
| `lib/services/database.dart` + kolekcja `Booking` | Rezerwacje (usługi, termin, cena, groomer, notatki, e-mail klienta) | Poufne |
| `lib/pages/home.dart`, `admin_panel.dart`, `employee_panel.dart` | Role: dokument w `Admin` / `Employee`; UI ukrywa panele, ale to nie jest ochrona backendu | Poufne |
| Firestore `users` + Cloud Storage (zdjęcie profilowe) | Dane konta i wizerunek | Poufne |
| Firestore `feedback` / `reviews` | Imię, e-mail autora, treść opinii | Wewnętrzne |
| `flutter_local_notifications` | Termin wizyty na urządzeniu | Wewnętrzne |
| Usługi, cennik, groomerzy, porady, galeria, ogłoszenia | Oferta salonu | Publiczne |
| Mapa salonu (`google_maps_flutter`) | Adres salonu (publiczny). **Lokalizacja użytkownika: nie zbierana** — mimo to w manifeście są `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Publiczne (salon) / szczególnie wrażliwe **gdyby** zbierać GPS użytkownika |
| Plan Z4: `local_auth` | Szablon biometryczny zostaje w systemie; odblokowanie aplikacji | Szczególnie wrażliwe (nie przechowujemy lokalnie we własnym magazynie) |

### Trzy przepływy przez granice zaufania (start STRIDE)

1. **Aplikacja → Firebase Authentication** (granica aplikacja ↔ sieć): logowanie e-mail/hasło, tokeny sesji.
2. **Aplikacja → Cloud Firestore (`Booking`, `Admin`, `Employee`, `users`)** (granica aplikacja ↔ sieć): odczyt/zapis rezerwacji i ról. Klient w kodzie filtruje po e-mailu, ale `getBookings()` potrafi pobrać **całą** kolekcję.
3. **Aplikacja → SharedPreferences / kopia zapasowa Androida** (granica aplikacja ↔ system): UID, imię, e-mail, URL zdjęcia; `allowBackup` nie jest wyłączone.

Szkic DFD: [docs/threat-model/dfd.md](../threat-model/dfd.md).

## 2. Co już mamy?

- Firebase Authentication (e-mail + hasło), sesja w SDK, `authStateChanges()` w `AuthChecker`.
- Trzy role w UI: klient / pracownik / administrator — sprawdzenie dokumentu w `Admin` / `Employee` (`home.dart`, `admin_panel.dart`).
- Komunikacja z Firebase po HTTPS (SDK).
- Hasła nie leżą w Firestore — tylko u dostawcy Auth.
- Klucze: `lib/api_keys.dart` w `.gitignore`, szablon `api_keys.dart.template`, `SECURITY_SETUP.md`.
- Brak zbierania GPS użytkownika w logice aplikacji (mapa = stały punkt salonu).
- Reset hasła przez Firebase (`forgot_password.dart`).

## 3. Czego brakuje?

| Luka / zagrożenie | Gdzie | Ryzyko | Dlaczego takie ryzyko |
| --- | --- | --- | --- |
| Brak pliku Security Rules w repo; role sprawdzane w kliencie | Firestore `Booking`, `Admin`, `Employee`, `users` | **wysokie** | Przy otwartych/słabych regułach każdy zalogowany może czytać cudze rezerwacje albo wpisać się do `Admin` |
| Dane osobowe w SharedPreferences (jawny tekst) + domyślny backup | `shared_pref.dart`, manifest | **wysokie** | Root, backup, inne aplikacje na starym Androidzie — wyciek e-maila i UID |
| Filtrowanie rezerwacji po stronie klienta | `database.dart` → `getBookings()` vs `getUpcomingBookings(email)` | **wysokie** | To samo co brak reguł: UI nie jest granicą zaufania |
| Klucz Maps / config Firebase w APK | `AndroidManifest` meta-data, `firebase_options.dart` | **średnie** | Binarka jest publiczna (M7/M8); klucz musi być ograniczony w konsoli Google/Firebase, nie „ukryty w kodzie” |
| Nieużywane uprawnienia lokalizacji | `AndroidManifest.xml` | **średnie** | Sklep i audyt pytają po co GPS; zbędna powierzchnia + zła klasyfikacja prywatności |
| Brak audytu zmian rezerwacji | backend | **średnie** | Repudiation: kto zmienił/anulował wizytę |
| Brak deep link, WebView z whitelistą, biometrii | umowa o powierzchni ataku | **niskie na dziś** | Funkcje jeszcze nie istnieją — ryzyko pojawi się przy implementacji (Z4) |

## 4. Jak to rozwiązuje nasza platforma?

| Mechanizm / biblioteka | Do czego go użyjemy | Pułapki i ograniczenia |
| --- | --- | --- |
| Firebase Authentication + ID token (JWT) | Tożsamość użytkownika; później custom claims zamiast kolekcji `Admin`/`Employee` | Token w aplikacji da się wyciągnąć z pamięci/root; claims trzeba **weryfikować w Rules**, nie tylko w Flutterze |
| Cloud Firestore Security Rules + Storage Rules | Autoryzacja obiektów (własna rezerwacja vs wszystkie) | Domyślnie w konsoli bywa `allow read, write: if true` na czas rozwoju. Emulator Rules jest obowiązkowy — test bez niego kłamie |
| `flutter_secure_storage` → Android Keystore | Zastąpić SharedPreferences dla UID/e-mail/sesji | Na Androidzie EncryptedSharedPreferences/Keystore; backup i `allowBackup`; na web Keystore nie istnieje (inny fallback) |
| TLS w SDK Firebase | Poufność na granicy aplikacja ↔ sieć | Certificate pinning nie jest w SDK „z pudełka”; proxy (mitmproxy + user CA) nadal działa na urządzeniu deweloperskim |
| Uprawnienia runtime (`permission_handler`) | Kamera, galeria, powiadomienia | Manifest ma też lokalizację — Google Maps często ciągnie GPS nawet gdy znacznik jest stały; trzeba świadomie nie prosić i usunąć permission |
| Android App Links / `local_auth` (plan) | Deep link i biometria | Intenty z innych aplikacji; fallback PIN; biometria odblokowuje klucz, nie zastępuje logowania do Firebase |

Porównanie z innymi sekcjami: ten sam problem (magazyn lokalny, role, sieć) w RN to Keychain, w Kotlinie Keystore bezpośrednio, na iOS Keychain Services.

## 5. Plan na kolejny tydzień (na zajęcia 3)

Zgodnie z kartą projektu (Z3) i zadaniem z zajęć 2.

| Zadanie | Osoba | Jak udowodnimy, że działa | Pozycja w checkliście MASVS |
| --- | --- | --- | --- |
| DFD z granicami zaufania (Mermaid + eksport PNG) oraz utrzymanie `docs/threat-model/` | Michał Dyrka | Pliki w `docs/threat-model/` (źródło + PNG) | model zagrożeń v1 |
| Model zagrożeń v1: przegląd i uzupełnienie tabeli STRIDE (≥10) | Michał Dyrka | `docs/threat-model/threats-v1.md` | jak wyżej |
| Audyt uprawnień: lokalizacja w manifeście vs mapa bez GPS; notatka do karty | Michał Dyrka | Diff `AndroidManifest.xml` + krótki opis | MASVS-PLATFORM, MASVS-PRIVACY |
| `firestore.rules` + `storage.rules` w repo; testy na emulatorze (klient vs pracownik vs admin) | Mateusz Sarwa | Log testu: klient **nie** czyta cudzego `Booking`; klient **nie** zapisuje `Admin/{email}` | MASVS-AUTH, MASVS-NETWORK |
| Migracja danych lokalnych do `flutter_secure_storage`; przegląd `allowBackup` | Jakub Różycki | Po logowaniu brak e-maila w jawnym `shared_prefs/*.xml` | MASVS-STORAGE-1 |
| Karta projektu (skład 3 os.) w README i zgłoszenie zmiany prowadzącemu | Jakub Różycki | README + karta z Michałem Dyrką | wymóg Z1 |

## 6. Pytania do prowadzącego

1. Czy custom claims w Firebase Auth są wymagane, czy wystarczą Security Rules oparte na kolekcjach `Admin`/`Employee` (dokument ID = e-mail), pod warunkiem że klient **nie może** tych kolekcji zapisywać?
2. Aplikacja ma też target **web (localhost)** — czy MAGVS/MASVS stosujemy formalnie tylko do Androida, a web zostawiamy jako środowisko testów?
3. Uprawnienie lokalizacji: Google Maps na Androidzie często „chce” GPS. Czy usunięcie `ACCESS_*_LOCATION` i zostawienie tylko znacznika salonu jest OK na umowę (3 uprawnienia: kamera, pliki, powiadomienia)?

### Notatki prowadzącego

Uwagi z rundy:

Ocena aktywności (0–2):
