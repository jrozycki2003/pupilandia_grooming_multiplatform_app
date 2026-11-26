# Raport: logowanie i sesje — Pupilandia
**Autorzy:** Jakub Różycki, Mateusz Sarwa, Michał Dyrka

Aplikacja do rezerwacji wizyt w salonie groomerskim. Flutter (Android i web), Firebase Auth (e-mail i hasło), Firestore. Własnego backendu nie ma, sesją zajmuje się SDK Firebase. Zakres: przegląd kodu, dowody w formacie plik:linia.

## 1.1 Elementy sesji

### Diagram sekwencji logowania i sesji

```mermaid
sequenceDiagram
    participant U as Użytkownik
    participant A as Aplikacja Flutter
    participant M as Magazyn SharedPreferences
    participant F as Firebase Auth
    participant D as Firestore

    U->>A: E-mail i hasło
    A->>F: signInWithEmailAndPassword()
    F-->>A: Zalogowany użytkownik, sesją zarządza SDK
    A->>D: Odczyt danych profilu użytkownika
    D-->>A: Imię, e-mail, zdjęcie
    A->>M: Zapis ID, imienia, e-maila, URL zdjęcia
    A->>D: Sprawdzenie Admin/{email}, Employee/{email}
    D-->>A: Wynik sprawdzenia roli
    Note over A,F: Zwykłe żądania i odświeżanie tokenów obsługuje SDK Firebase; brak własnej implementacji w kodzie aplikacji

    U->>A: Wyloguj
    A->>F: signOut()
    opt Wylogowanie przez menu boczne home.dart
        A->>M: Nadpisanie danych profilu pustymi ciągami
    end

    U->>A: Zapomniałem hasła
    A->>F: sendPasswordResetEmail()
    F-->>U: E-mail z linkiem resetu hasła
```

### Tabela elementów sesji

| Element | Gdzie powstaje | Gdzie leży | Ważny przez | Jak unieważnić | Problem | Decyzja |
| --- | --- | --- | --- | --- | --- | --- |
| Hasło | wpisuje użytkownik (login.dart) | Firebase Auth | bez limitu w kodzie | reset linkiem (forgot_password.dart), zmiany hasła w aplikacji brak | minimum 6 znaków (signup.dart), brak weryfikacji e-maila | D4, D5 |
| Sesja Firebase (tokeny) | Firebase Auth po zalogowaniu (login.dart) | pamięć zarządzana przez SDK | czasu nie ustawiamy w kodzie | signOut() lokalnie (home.dart), po stronie serwera brak w kodzie | nie ma funkcji zakończenia sesji na innych urządzeniach | D7 |
| Dane profilu | login.dart, signup.dart | SharedPreferences, jawny tekst (shared_pref.dart) | do wylogowania z menu bocznego | nadpisanie pustym tekstem (home.dart) | web_navbar.dart nie czyści tych danych, a e-mail i id z nich idą do rezerwacji i historii (book_appointment.dart, history.dart) | D1, D2 |
| Rola admin i pracownik | dokument Admin/{email} lub Employee/{email} (home.dart) | Firestore | bez limitu | usunięcie dokumentu | aplikacja tylko ukrywa przyciski, w repo nie ma reguł Firestore | D6 |
| Link resetu hasła | Firebase, wysyłany e-mailem | skrzynka użytkownika | ustala Firebase, w kodzie brak ustawienia | użycie linku | komunikat zdradza, czy konto istnieje (forgot_password.dart) | D3 |

Zewnętrznego dostawcy logowania i biometrii w aplikacji nie ma (brak google_sign_in, flutter_appauth i local_auth w pubspec.yaml).

## 1.2 Scenariusze

| Scenariusz | Co powinno się stać | Co dzieje się u nas | Jak sprawdziliśmy |
| --- | --- | --- | --- |
| Wylogowanie | sesja kończy się w aplikacji i na serwerze, dane lokalne znikają | signOut() i czyszczenie danych w menu bocznym, w web_navbar.dart tylko signOut(), unieważnienia na serwerze brak | home.dart:916-921, web_navbar.dart:332 |
| Zgubiony telefon | dostęp da się odciąć, aplikacja jest zablokowana | brak blokady aplikacji i brak wylogowania zdalnego, dane profilu jawnie w SharedPreferences | pubspec.yaml (brak local_auth), shared_pref.dart |
| Zmiana hasła | inne sesje się kończą | w aplikacji nie ma zmiany hasła, jest tylko reset linkiem | brak updatePassword w lib/, forgot_password.dart |
| Token wygasa w trakcie pracy | kontrolowane odświeżenie albo wylogowanie z komunikatem | aplikacja nie ma własnej obsługi, reaguje tylko na zmianę stanu logowania | main.dart |
| Reinstalacja aplikacji | sesja znika, dane nie wracają z kopii | manifest nie ustawia allowBackup | AndroidManifest.xml, tag application |
| Przechwycony token | działa krótko, da się go odwołać | w aplikacji nie ma mechanizmu odwołania tokenów | brak takiego kodu w lib/ |
| Logowanie u zewnętrznego dostawcy | hasło trafia tylko do dostawcy | nie dotyczy, aplikacja nie ma takiego logowania | pubspec.yaml |
| Logowanie biometrią | odblokowanie kluczem w sprzęcie | nie dotyczy, aplikacja nie ma biometrii | pubspec.yaml |
| Sprawdzanie, czy konto istnieje | ten sam komunikat dla każdego e-maila | różne komunikaty przy logowaniu i resecie, a rejestracja sprawdza e-mail wprost | login.dart, forgot_password.dart, signup.dart |
| Uprawnienia admina | sprawdzane na serwerze | sprawdzane w aplikacji po dokumencie w Firestore, reguł w repo brak | home.dart |

## 1.3 Polityka sesji

Kolumna "Docelowo" to wartości, które proponujemy wprowadzić.

| Parametr | U nas teraz | Docelowo | Źródło |
| --- | --- | --- | --- |
| Ważność tokenu dostępu | ustala Firebase, w kodzie brak ustawienia | bez zmian | RFC 9700 |
| Ważność tokenu odświeżania | ustala Firebase, w kodzie brak ustawienia | ponowne logowanie po 30 dniach bez aktywności | OWASP MASVS-AUTH |
| Wylogowanie po bezczynności | brak | panel admina i pracownika: 15 minut | OWASP MASVS-AUTH |
| Limit nieudanych logowań | brak w aplikacji, kod too-many-requests nie jest obsłużony (login.dart) | obsługa tego kodu z komunikatem i blokadą przycisku | OWASP Authentication Cheat Sheet |
| Operacje z ponownym potwierdzeniem | brak, reauthenticate nie występuje w lib/ | zmiana hasła, usunięcie konta, usuwanie danych przez admina | OWASP MASVS-AUTH, MASTG |
| Link resetu hasła | link Firebase, czas ustala Firebase | bez zmian, jeden komunikat dla każdego e-maila | OWASP Forgot Password Cheat Sheet |
| Liczba sesji i urządzeń | bez limitu i bez podglądu | przycisk "Wyloguj wszędzie" | OWASP MASVS-AUTH |
| Długość hasła | minimum 6 znaków (signup.dart) | minimum 8 znaków | OWASP Authentication Cheat Sheet |
| Weryfikacja e-maila | brak | wymagana przed rezerwacją | OWASP Authentication Cheat Sheet |

## 1.4 Decyzje

1. Jedna funkcja logout() używana w home.dart i web_navbar.dart, czyści też SharedPreferences.
2. E-mail i id do rezerwacji i historii brać z FirebaseAuth.currentUser, a nie z SharedPreferences (book_appointment.dart:358, history.dart:47).
3. Jeden komunikat przy logowaniu i resecie hasła, usunąć fetchSignInMethodsForEmail z rejestracji, dodać obsługę too-many-requests.
4. Hasło minimum 8 znaków, wysyłka sendEmailVerification po rejestracji.
5. Ekran zmiany hasła z reauthenticateWithCredential przed updatePassword, to samo przed usunięciem konta.
6. Dodać do repo firestore.rules i storage.rules, rolę admina i pracownika sprawdzać po stronie serwera.
7. Przycisk "Wyloguj wszędzie" po stronie serwera, wywoływany też po resecie hasła.
8. W AndroidManifest.xml ustawić android:allowBackup="false".
9. deleteUser (database.dart) usuwa tylko dokument w Firestore, dodać usuwanie konta w Firebase Auth.
10. Wymuszone logowanie po 30 dniach bez aktywności (klient) i po 15 minutach (panele).

## Źródła

OWASP MASVS-AUTH, OWASP MASTG, RFC 9700, OWASP Authentication Cheat Sheet, OWASP Forgot Password Cheat Sheet.

**Podstawa weryfikacji:** Przegląd kodu aplikacji Pupilandia; wskazania `plik:linia` w powyższych tabelach odnoszą się do stanu projektu analizowanego przy przygotowaniu raportu. Przed oddaniem warto sprawdzić ich aktualność na branchu `cybersecurity`.
