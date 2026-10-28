# Karta projektu — BAiSM

Szablon z zajęć 1. Finalna wersja ma być też w [README](../README.md). Karta jest punktem odniesienia przez semestr; zmiany zgłaszacie prowadzącemu.

## Informacje o sekcji

| Pole | Wartość |
| --- | --- |
| Nazwa sekcji / aplikacji | Pupilandia — aplikacja do rezerwacji wizyt w salonie groomerskim |
| Technologia | Flutter (Dart) |
| Skład sekcji | Jakub Różycki, Mateusz Sarwa, Michał Dyrka |
| Link do repozytorium | https://github.com/jrozycki2003/pupilandia_grooming_multiplatform_app |
| Backend | Firebase (Authentication, Cloud Firestore, Cloud Storage), logika po stronie aplikacji + Firebase Security Rules |

## 1. Koncepcja aplikacji

Pupilandia to aplikacja mobilna do rezerwacji wizyt w salonie groomerskim: klient wybiera usługi, groomera i termin, a salon zarządza harmonogramem, ofertą i historią wizyt przez panele pracownika i administratora. Rozwiązuje problem telefonicznych i papierowych rezerwacji oraz braku jednego miejsca z historią usług i przypomnieniami. Dane klientów i rezerwacji trzymamy w Firebase, dlatego głównym tematem bezpieczeństwa jest kontrola dostępu między rolami.

**Grupa docelowa:** właściciele psów i kotów korzystający z salonu (klienci), groomerzy (pracownicy) oraz właściciel/administrator salonu.

**Temat startowy:** brak — własny projekt (wcześniej praca inżynierska), rozszerzany o założenia przedmiotu.

## 2. Role użytkowników

| Rola | Co może | Czego NIE może |
| --- | --- | --- |
| Klient (domyślny) | Rejestracja i logowanie (e-mail + hasło), reset hasła; przegląd usług, cennika, porad, galerii, mapy; rezerwacja, edycja i anulowanie **własnych** wizyt; historia; opinie; profil ze zdjęciem; przypomnienia | Widzieć/edytować/usuwać rezerwacje i dane innych klientów; wchodzić do paneli pracownika i administratora; zarządzać usługami, cennikiem, groomerami, poradami, galerią i ogłoszeniami; nadawać role |
| Pracownik (groomer) | Wszystko co klient + panel: harmonogram i kalendarz **własnych** rezerwacji, status/szczegóły wizyt | Usuwać dane (rezerwacje, klientów); zarządzać ofertą; widzieć rezerwacje innych groomerów; panel administratora; nadawać role |
| Administrator | Pełne zarządzanie salonem: usługi, cennik, groomerzy, porady, galeria, ogłoszenia, wszystkie rezerwacje, lista klientów | Odczytać hasła (Firebase Auth); nadawać role z poziomu aplikacji (konsola Firebase — kolekcje `Admin`/`Employee`); obchodzić reguły backendu |

## 3. Dane i klasyfikacja

| Dane | Skąd | Gdzie | Klasyfikacja | Uzasadnienie |
| --- | --- | --- | --- | --- |
| E-mail i imię | Rejestracja | Oba: Firestore `users` + SharedPreferences | Poufne | Dane osobowe; e-mail łączy użytkownika z `Booking` |
| Hasło, token sesji, UID | Firebase Auth | Backend (hash hasła); urządzenie (SDK); UID też w SharedPreferences | Poufne | Przejęcie konta |
| Rezerwacje (usługi, termin, cena, groomer, notatki) | Formularz | Backend `Booking` | Poufne | Historia usług; notatki = dowolny tekst |
| Zdjęcie profilowe | Aparat / galeria | Storage + URL w Firestore i SharedPreferences | Poufne | Wizerunek / dana osobowa |
| Role (`Admin` / `Employee`) | Konsola Firebase | Backend | Poufne | Eskalacja uprawnień |
| Opinie | Użytkownik | Firestore `feedback` / `reviews` | Wewnętrzne | Imię, e-mail, treść |
| Harmonogram powiadomień | Aplikacja | Urządzenie (lokalne, bez FCM) | Wewnętrzne | Termin wizyty |
| Usługi, cennik, groomerzy, porady, ogłoszenia, galeria | Administrator | Firestore + Storage | Publiczne | Oferta salonu |
| Lokalizacja | Stały punkt salonu | W aplikacji; GPS użytkownika **nie** jest zbierany | Publiczne | Adres salonu; dokładny GPS użytkownika byłby szczególnie wrażliwy |

## 4. Umowa o powierzchni ataku

| Wymagana funkcja | Jak u nas | Zajęcia |
| --- | --- | --- |
| Logowanie z tokenami, ≥2 role | Firebase Auth; 3 role z kolekcji `Admin`/`Employee` | Z2 audyt klienta; Z3 Rules + testy |
| Backend z regułami | Firebase Auth + Firestore + Storage; **brak pliku Rules w repo** | Z2 pliki Rules; Z3 emulator |
| Lokalne dane wrażliwe | SharedPreferences jawnym tekstem → plan: `flutter_secure_storage` | Z3 |
| ≥3 uprawnienia | Aparat, galeria, powiadomienia (w manifeście jest też lokalizacja do przeglądu) | Z2 przegląd; Z4 odmowa zgody |
| Deep link | Brak; plan App Links do wizyty / resetu hasła | Z4 |
| WebView / treść zewnętrzna | Teraz `url_launcher`; plan WebView z whitelistą | Z4 |
| Biometria | Brak; plan `local_auth` | Z4 |

## 5. Architektura

| Komponent | Technologia | Komunikuje się z |
| --- | --- | --- |
| Aplikacja mobilna | Flutter / Dart (Android; web do testów) | Firebase Auth, Firestore, Storage, Maps, aparat/galeria, powiadomienia lokalne |
| Backend | Firebase BaaS + Security Rules | Aplikacja (SDK, HTTPS) |
| Baza | Firestore + Storage | Aplikacja; Rules decydują o dostępie |
| Usługi zewnętrzne | Auth, Google Maps, `flutter_local_notifications` (bez FCM) | Aplikacja |

DFD: [threat-model/dfd.md](threat-model/dfd.md).

## 6. Podział ról w zespole

| Osoba | Główna odpowiedzialność | MASVS |
| --- | --- | --- |
| Jakub Różycki | Aplikacja Flutter, logowanie i panele ról, migracja na `flutter_secure_storage`, biometria (`local_auth`) | AUTH, STORAGE, RESILIENCE |
| Mateusz Sarwa | Firebase Security Rules (Firestore/Storage), emulator, testy autoryzacji, konfiguracja Firebase | AUTH (backend), NETWORK |
| Michał Dyrka | Model zagrożeń i DFD, arkusze zajęć, checklista MASVS, audyt uprawnień, deep link i WebView | PLATFORM, PRIVACY, CODE |

## 7. Plan do MVP (zajęcia 5)

| Zajęcia | Co będzie gotowe |
| --- | --- |
| Z2 | Szkielet (istniejąca aplikacja), szkic architektury / DFD |
| Z3 | Rules w repo + testy emulatora; role na backendzie; secure storage; czyszczenie uprawnień |
| Z4 | App Links, WebView z whitelistą, biometria |
| Z5 — MVP | Wszystkie funkcje z umowy (mogą być uproszczone) |

## 8. Największe ryzyko według sekcji

1. **Autoryzacja po stronie backendu** — role w kliencie; pobieranie całej kolekcji `Booking` i filtr po e-mailu. Bez Rules każdy zalogowany czyta/zmienia cudze wizyty albo nadaje sobie rolę.
2. **Niezaszyfrowane dane lokalne** — SharedPreferences + backup Androida.
3. **Klucze i konfiguracja w APK** — Maps i Firebase są wyciągalne; muszą być ograniczone w konsoli, nie „ukryte w kodzie”.
