# D5 — Polityka sesji i usuwania danych lokalnych

**Projekt:** Pupilandia (Flutter — Android; założenia dla iOS wymagają testów)  
**Zespół:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa  
**Data:** 6 listopada 2026 r.  
**Status:** docelowa polityka do wdrożenia i weryfikacji na zajęciach 5; **nie stanowi potwierdzenia obecnego działania aplikacji**.

## 1. Cel i zakres

Celem polityki jest zapobieganie sytuacji, w której po wylogowaniu, wygaśnięciu sesji, zmianie hasła, reinstalacji lub odtworzeniu backupu na urządzeniu pozostaje dostęp do danych poprzedniego użytkownika. Obejmuje stan Firebase Auth, cztery klucze aplikacji w `SharedPreferences`, lokalny cache Firestore, pliki tymczasowe zdjęć, przypomnienia oraz dane pomocnicze SDK.

**Ważna granica odpowiedzialności:** Firebase Auth, Firestore i inne SDK zarządzają częścią swoich plików. Samo wywołanie `FirebaseAuth.instance.signOut()` nie jest dowodem, że usunięto cały cache Firestore, powiadomienia i wszystkie własne dane w preferencjach.

## 2. Stan faktyczny „przed”

- `lib/pages/home.dart` przy wylogowaniu wykonuje `FirebaseAuth.instance.signOut()` i zapisuje puste ciągi `''` do `USERKEY`, `USERNAMEKEY`, `USEREMAILKEY`, `USERIMAGEKEY`. **Wartości są nadpisywane, a klucze nie są usuwane.**
- `lib/widgets/web_navbar.dart` wykonuje przy wylogowaniu tylko `FirebaseAuth.instance.signOut()`; nie widać w tej ścieżce jawnego czyszczenia czterech kluczy.
- Na emulatorze Android 15 wykryto pliki preferencji Firebase Auth, bazę Firestore (217 088 B), dane biblioteki powiadomień i Image Picker. **Nie sprawdzono**, które z nich pozostają po wylogowaniu lub reinstalacji.
- Główny i wynikowy manifest debug nie zawierają jawnych wpisów `allowBackup`, `dataExtractionRules` ani `fullBackupContent`. **Nie zweryfikowano** zachowania kopii zapasowej i przywracania.

## 3. Polityka — pięć wymaganych zdarzeń

| Zdarzenie | Co usuwamy / jaka reakcja powinna nastąpić | Gdzie (magazyn) | Co może pozostać | Jak sprawdzimy |
|---|---|---|---|---|
| **1. Wylogowanie** | Zakończyć sesję przez Firebase Auth; **usunąć** cztery własne klucze użytkownika (nie tylko zapisać `''`); anulować przypomnienia przypisane do konta; usunąć zbędne tymczasowe zdjęcia; wyczyścić lub odseparować cache dokumentów tak, aby dane poprzedniego konta nie były widoczne. Obie ścieżki UI muszą wywoływać jedną funkcję wylogowania. | Firebase Auth SDK; `SharedPreferences`; Flutter Local Notifications; `cache/`; Firestore SDK | Niesekretne ustawienia UI oraz niezbędne pliki techniczne SDK | Zalogować konto testowe A, przeglądać dane, wylogować z obu miejsc, zamknąć i uruchomić aplikację ponownie; sprawdzić brak sesji i danych A, także po zalogowaniu konta B. |
| **2. Reinstalacja** | Nie przywracać automatycznie starej sesji ani poufnego cache po usunięciu i ponownym zainstalowaniu aplikacji. Zapobiec odtworzeniu tych danych z kopii. Dla iOS osobno uwzględnić, że wpisy Keychain mogą przetrwać odinstalowanie, jeśli zostaną kiedyś wprowadzone. | Prywatny kontener aplikacji; zasady backupu; ewentualnie iOS Keychain | Publiczne zasoby instalacji i niesekretne ustawienia tylko na podstawie jawnej decyzji | Na emulatorze testowym: odinstalować, ponownie zainstalować, uruchomić; sprawdzić ekran logowania i brak danych poprzedniego konta. Oddzielnie przetestować odtwarzanie backupu. |
| **3. Wygaśnięcie sesji / nieprawidłowe poświadczenia** | Przerwać dostęp do ekranów i operacji wymagających logowania; po potwierdzonej utracie możliwości odnowienia sesji wykonać spójne czyszczenie danych jak przy wylogowaniu. Nie wyświetlać zapisanych danych poprzedniego konta. Błędy sieci **nie powinny** samodzielnie kasować poprawnej sesji. | Firebase Auth; stan nawigacji; własne preferencje; cache Firestore; przypomnienia | Niesekretne ustawienia UI | W środowisku testowym wymusić odmowę autoryzacji/utratę ważności sesji; zweryfikować przekierowanie do logowania i brak dostępu do danych bez nowego uwierzytelnienia. Osobno przetestować zwykły brak internetu. |
| **4. Kopia zapasowa / nowe urządzenie** | Nie przenosić aktywnej sesji, tokenów, identyfikatorów instalacji ani cache poufnych dokumentów na inne urządzenie. Przy pierwszym uruchomieniu po odtworzeniu wymagane ponowne uwierzytelnienie. | Reguły Android `dataExtractionRules` / reguły dla starszych wersji; mechanizmy kopii na iOS; magazyny SDK | Wyłącznie świadomie dopuszczone niesekretne ustawienia | Test kopii i przywrócenia na drugim emulatorze lub urządzeniu testowym; kontrola stanu logowania i plików prywatnych bez odczytywania/udostępniania wartości tokenów. |
| **5. Zmiana hasła na serwerze** | Po potwierdzonym unieważnieniu poświadczeń przez serwer wymusić ponowne uwierzytelnienie, zakończyć dostęp do chronionych danych i wykonać czyszczenie jak przy wylogowaniu. Nie zakładać, że sama zmiana hasła natychmiast kończy każdą istniejącą sesję — rzeczywiste zachowanie Firebase trzeba przetestować. | Firebase Auth; logika sesji aplikacji; preferencje; cache; przypomnienia | Ustawienia niezwiązane z kontem | Konto testowe zalogowane na dwóch urządzeniach; zmiana hasła lub testowe unieważnienie sesji; sprawdzenie ponownego uwierzytelnienia i braku dostępu do cache poprzedniej sesji. |


## 5. Kryteria akceptacji

- Po wylogowaniu z **obu** interfejsów nie istnieje aktywna sesja w aplikacji, a cztery własne pola użytkownika nie są zachowane jako wartości w preferencjach.
- Konto B nie widzi danych konta A ani z ekranu, ani z dostępnego offline cache.
- Powiadomienia poprzedniego użytkownika nie są wyświetlane po wylogowaniu; tymczasowe zdjęcia nie pozostają bez potrzeby.
- Reinstalacja i przywrócenie kopii na inne urządzenie nie odtwarzają uprawnień i sesji poprzedniego użytkownika.
- Wygaśnięcie/unieważnienie sesji blokuje dostęp do danych poufnych, ale zwykła przerwa w sieci nie jest traktowana automatycznie jako wylogowanie.

**Powiązane dokumenty:** `inwentaryzacja.md` (D1), `raport-przed.md` (D2), `decyzje.md` (D3), `kanaly-wyciekow.md` (D4).
