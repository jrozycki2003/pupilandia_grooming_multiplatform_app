# D4 — Mapa kanałów potencjalnego wycieku danych

**Projekt:** Pupilandia (Flutter — Android)  
**Zespół:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa  
**Data:** 6 listopada 2026 r.  
**Środowisko audytu:** emulator Android 15 (API 35), wariant debug aplikacji `com.kuba.kubaproject`.  
**Status:** ocena stanu obecnego i **plan zabezpieczeń na zajęcia 5**; zaproponowane środki nie są jeszcze potwierdzone jako wdrożone.

## 1. Zakres i metodyka

Zgodnie z prezentacją „BAiSM — Zajęcia 4: Bezpieczne przechowywanie danych” sprawdzono osiem kanałów: **logi, kopie zapasowe, zrzuty ekranu/przełącznik aplikacji, schowek, klawiaturę, cache HTTP i WebView, pliki tymczasowe oraz powiadomienia**.

Podstawą są: przegląd plików Dart (`shared_pref.dart`, `main.dart`, `notifications.dart`, fragmenty `home.dart` i `web_navbar.dart`), sprawdzenie głównego i wynikowego manifestu, a także lista **nazw i rozmiarów** plików w prywatnym kontenerze aplikacji na emulatorze (`adb shell run-as`). **Nie odczytywano zawartości plików Firebase Auth ani prywatnych danych użytkowników.** Nie przeprowadzono jeszcze inspekcji logcat, zrzutów ekranu, schowka, kopii zapasowych ani faktycznie dostarczonych powiadomień.

**Rozróżnienie:** „Potwierdzono” odnosi się wyłącznie do tego, co zaobserwowano w kodzie lub na emulatorze. „Może” / „do sprawdzenia” oznacza ryzyko, a nie potwierdzony wyciek.

## 2. Mapa ośmiu kanałów (wymaganie D4)

| Kanał | Czy dotyczy Pupilandii? | Co trafia tam teraz / dowody | Jak zamkniemy kanał (plan) | Jak sprawdzimy skuteczność |
|---|---|---|---|---|
| **1. Logi** | **Tak** — aplikacja loguje błędy inicjalizacji | Potwierdzone `debugPrint("Firebase init error: $e")`, `debugPrint("Notifications init error: $e")`, `debugPrint("Locale init error: $e")` i wyjątek inicjalizacji usługi powiadomień. **Nie potwierdzono** występowania tokenów, e-maili ani haseł w logach. | Logować tylko niezbędne komunikaty diagnostyczne; maskować identyfikatory, dane osobowe i treść wyjątków mogących je zawierać; wyłączyć szczegółowe logi w release. | Przejrzeć lokalnie zanonimizowany `logcat` w scenariuszach logowania, błędów i wylogowania; sprawdzić również wydanie release. Nie kopiować tokenów do raportu. |
| **2. Kopie zapasowe** | **Tak** — aplikacja przechowuje lokalnie stan sesji i cache | W **głównym i wynikowym** manifeście debug nie znaleziono jawnych `allowBackup`, `dataExtractionRules`, `fullBackupContent`. Brak tych wpisów **nie dowodzi**, że backup jest wyłączony. Potwierdzono pliki Firebase Auth i bazę Firestore. | Określić politykę backupu; wykluczyć poświadczenia/sesję, identyfikatory instalacji, poufny cache i pliki tymczasowe z kopii i transferu na nowe urządzenie. Skonfigurować reguły dla odpowiednich wersji Androida, uwzględnić też iOS. | Sprawdzić wynikowy manifest i reguły ekstrakcji; test przywrócenia na osobnym koncie/emulatorze, bez danych rzeczywistych klientów; zweryfikować brak automatycznego odtworzenia sesji. |
| **3. Zrzuty ekranu / podgląd w przełączniku aplikacji** | **Tak** — aplikacja ma ekrany profilu, logowania i rezerwacji | Wyświetlane są potencjalne dane osobowe i szczegóły wizyt. **Nie sprawdzono** jeszcze ochrony `FLAG_SECURE` ani wyglądu podglądu aplikacji po przejściu w tło. | Na wrażliwych ekranach Androida zastosować `FLAG_SECURE` lub ochronę podglądu; dla iOS przygotować zasłonę przy przejściu w tło. Nie blokować zrzutów wszędzie bez uzasadnienia funkcjonalnego. | Otworzyć profil/rezerwację, spróbować zrzutu oraz przejść do widoku ostatnich aplikacji; sprawdzić, czy wrażliwe dane nie są widoczne. |
| **4. Schowek** | **Potencjalnie** — użytkownik może kopiować dane z interfejsu | Nie przeprowadzono audytu wywołań `Clipboard` ani testu ręcznego. **Nie potwierdzono** kopiowania tokenów lub haseł. | Nie kopiować sekretów do schowka. Jeśli kopiowanie danych osobowych jest konieczne, ograniczać zakres danych i oznaczać treść jako wrażliwą tam, gdzie wspiera to Android; nie implementować automatycznego kopiowania haseł. | Przeszukać kod pod kątem `Clipboard`, przetestować dostępne akcje „Kopiuj” i sprawdzić podgląd schowka Androida. |
| **5. Klawiatura** | **Tak / do sprawdzenia** — formularze logowania i danych użytkownika wymagają wpisywania informacji | Ryzyko dotyczy m.in. autokorekty i podpowiedzi zewnętrznej klawiatury. **Nie sprawdzono** konfiguracji pól hasła i sugestii. | Pola haseł: `obscureText`, właściwy typ/autouzupełnianie i wyłączenie zbędnych sugestii; nie wyłączać menedżera haseł bez analizy. Dla danych szczególnie wrażliwych ograniczyć przewidywanie tekstu. | Skontrolować widgety `TextField`/`TextFormField` i ustawienia pól; sprawdzić zachowanie klawiatury emulatora przy wpisywaniu testowych danych. |
| **6. Cache HTTP i WebView** | **Do weryfikacji** — aplikacja korzysta z usług sieciowych; obecność WebView i cache HTTP nie została ustalona | Potwierdzono **lokalny cache Firestore** (`databases/firestore...`, 217 088 B) oraz cache/metadane Google Maps, ale **nie jest to dowód** na cache HTTP lub WebView zawierający dane osobowe. | Nie utrwalać odpowiedzi zawierających dane osobowe, jeśli tryb offline nie jest wymagany; ograniczyć/wyłączyć persystencję Firestore według D3; dla ewentualnego WebView z danymi sesji ustalić czyszczenie ciasteczek i cache. | Przeszukać zależności i kod pod kątem WebView/HTTP; sprawdzić lokalne katalogi cache po użyciu aplikacji; powtórzyć po wylogowaniu i zmianie konta. |
| **7. Pliki tymczasowe** | **Tak** — funkcje galerii i aparatu korzystają z Image Picker | Potwierdzono `flutter_image_picker_shared_preference.xml` i plik `cache/*.jpg` o rozmiarze **0 B**. W obserwowanym pliku nie było zdjęcia. Inne pliki tymczasowe mogą powstawać podczas rzeczywistego wyboru/wykonania zdjęcia. | Usuwać pliki tymczasowe po zakończeniu/anulowaniu wysyłania, nie kopiować zdjęć do pamięci współdzielonej bez potrzeby; nie obejmować cache backupem. | Wykonać zdjęcie testowe, sprawdzić listę plików przed i po akcji, anulowaniu, wylogowaniu i restarcie; nie ujawniać samego zdjęcia. |
| **8. Powiadomienia** | **Tak** — Pupilandia planuje przypomnienia wizyt | W kodzie jest lokalna obsługa przypomnień, a na emulatorze istnieje `notification_plugin_cache.xml`. Nie sprawdzono **treści dostarczonego powiadomienia** ani widoku na ekranie blokady. Odmowa `POST_NOTIFICATIONS` nie powodowała awarii aplikacji. | Stosować neutralne treści bez danych osobowych i szczegółów wizyt, ograniczyć podgląd na ekranie blokady; anulować nieaktualne i przypisane do wylogowanego użytkownika przypomnienia. | Na koncie testowym zaplanować powiadomienie; zobaczyć ekran blokady i historię powiadomień, następnie sprawdzić zachowanie po wylogowaniu oraz anulowaniu rezerwacji. |

## 3. Najważniejsze ryzyka i priorytety

1. **Wysoki priorytet — sesja i cache przy backupie/wylogowaniu.** Na urządzeniu znajdują się pliki Firebase Auth i baza Firestore. Nie ustalono jeszcze, czy są przywracane z kopii ani co pozostaje po wylogowaniu.
2. **Wysoki priorytet — spójność dwóch ścieżek wylogowania.** W `home.dart` cztery wartości `SharedPreferences` są zastępowane pustymi łańcuchami po `signOut()`, natomiast w `web_navbar.dart` jest tylko `signOut()`. Nie stwierdzono tu anulowania przypomnień ani czyszczenia cache Firestore.
3. **Średni priorytet — logowanie wyjątków.** `debugPrint` wypisuje komunikaty błędów; faktycznej obecności sekretów w logach nie dowiedziono.
4. **Średni priorytet — podgląd ekranu, powiadomienia, pliki tymczasowe.** Możliwe ujawnienie szczegółów wizyty lub zdjęć wymaga testów funkcjonalnych.
5. **Do sprawdzenia — schowek, klawiatura, HTTP/WebView.** Nie przypisywać im potwierdzonego wycieku bez dowodu.

## 4. Kryteria akceptacji na zajęcia 5

- **Logi:** brak tokenów, haseł i danych osobowych w logach wydania produkcyjnego; komunikaty błędów są zanonimizowane.
- **Zrzuty/podgląd:** wrażliwe ekrany nie ujawniają danych podczas przełączania aplikacji; działanie sprawdzone na Androidzie.
- **Backup:** nie można odzyskać aktywnej sesji ani poufnego cache poprzedniego użytkownika przez przywrócenie kopii lub migrację na inne urządzenie.
- **Wylogowanie:** stan Firebase Auth, własne dane lokalne i przypomnienia są obsługiwane spójnie niezależnie od ścieżki wylogowania; cache Firestore nie ujawnia danych poprzedniego konta.
- **Pozostałe kanały:** istnieją wyniki testów dla schowka, klawiatury, cache, plików tymczasowych i powiadomień, również tam, gdzie okaże się, że ryzyko jest nieistotne.

**Powiązane dokumenty:** `inwentaryzacja.md` (D1), `raport-przed.md` (D2), `decyzje.md` (D3), `polityka-sesji.md` (D5).
