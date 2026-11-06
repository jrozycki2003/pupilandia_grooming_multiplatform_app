# D3 — Decyzje dotyczące bezpiecznego przechowywania danych

**Projekt:** Pupilandia (Flutter — Android; zalecenia dla iOS wymagają odrębnej weryfikacji)  
**Zespół:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa  
**Data:** 6 listopada 2026 r.  
**Stan:** projekt decyzji do realizacji na zajęciach 5; poniższe zabezpieczenia **nie są jeszcze deklarowane jako wdrożone**.

## 1. Założenia

Dokument rozwija inwentaryzację D1 i raport stanu obecnego D2 na podstawie zasad ze slajdów „BAiSM — Zajęcia 4: Bezpieczne przechowywanie danych”. Przyjęto zasadę minimalizacji: jeśli danej nie trzeba utrwalać na urządzeniu, lepiej jej nie zapisywać niż szyfrować zbędną kopię. Tokenów i kluczy nie wolno zapisywać samodzielnie w `SharedPreferences`. Gdy aplikacja musi przechowywać **własny sekret**, właściwym rozwiązaniem dla Fluttera jest magazyn oparty na Android Keystore / iOS Keychain (np. `flutter_secure_storage`), z ustaloną dostępnością i wykluczeniem z niepożądanych kopii zapasowych.

Dla Firebase Auth, Firestore i pozostałych bibliotek należy uwzględnić, że ich lokalnymi danymi zarządza **SDK**. Nie można zakładać, że zastąpienie jednego wywołania aplikacji `flutter_secure_storage` przeniesie wewnętrzne pliki Firebase do Keystore/Keychain. Dla tych bibliotek potrzebna jest konfiguracja SDK, polityka retencji, zabezpieczenia systemowe i testy.

## 2. Decyzje dla poszczególnych kategorii danych

| Dane / klasyfikacja | Czy muszą być przechowywane lokalnie? | Docelowy magazyn i dostępność | Uzasadnienie i działania |
|---|---|---|---|
| ID użytkownika (`USERKEY`) — **poufne** | **Nie** jako osobna trwała kopia | Bieżący użytkownik `FirebaseAuth` / pamięć procesu; dostęp po zalogowaniu | Zastąpić nadmiarowy zapis `SharedPreferences` odczytem stanu uwierzytelnienia. Nie logować identyfikatora. |
| Nazwa użytkownika (`USERNAMEKEY`) — **poufne** | **Nie**, jeśli dostępna z profilu/serwera | Pamięć procesu lub pobranie na żądanie; dostęp tylko w aktywnej sesji | Usunąć trwałą kopię z preferencji po migracji. |
| E-mail (`USEREMAILKEY`) — **poufne** | **Nie** jako dodatkowa kopia | `FirebaseAuth.currentUser` lub odczyt na żądanie; tylko podczas sesji | Ograniczyć duplikowanie danych osobowych na dysku. |
| URL zdjęcia (`USERIMAGEKEY`) — **poufne**, szczególnie przy podpisanych adresach | **Nie** jako trwała kopia | Odczyt na żądanie; krótki cache tylko jeśli wymagany | Adres może identyfikować użytkownika lub zawierać parametry dostępu. Nie logować pełnego URL. |
| Stan sesji i poświadczenia Firebase Auth — **szczególnie wrażliwe**, jeśli obejmują aktywne tokeny | **Tak**, jeśli aplikacja ma utrzymywać logowanie po zamknięciu | Magazyn **zarządzany przez Firebase Auth SDK**; dostęp wyłącznie dla aplikacji, z kontrolą po wylogowaniu. Docelowo wymagany brak odtworzenia sesji na innym urządzeniu przez backup | Nie kopiować tokenów do własnych preferencji, nie wypisywać ich w logach. Zweryfikować ochronę i cykl życia stanu przez SDK; wylogowanie musi usuwać aktywną sesję. |
| Pomocnicze dane kryptograficzne Firebase Auth — **wewnętrzne/potencjalnie poufne** | Według potrzeb SDK | Magazyn SDK, ograniczony do kontenera aplikacji; dostęp według mechanizmu SDK | Nie modyfikować ręcznie wewnętrznych plików. Zweryfikować backup i odtwarzanie. |
| Dokumenty i cache Firestore — **potencjalnie poufne** (klienci, wizyty) | **Do ograniczenia**; trwały cache tylko jeśli wymagane offline | Preferować dane pobierane z serwera na żądanie; jeśli offline nie jest wymagany, wyłączyć trwałą persystencję Firestore dla właściwej konfiguracji. Jeśli offline konieczny, określić retencję, ograniczenia danych i zasady usuwania | Na emulatorze stwierdzono bazę Firestore 217 088 B, ale bez inspekcji rekordów. Nie zakładać, że `signOut()` automatycznie czyści cache; przetestować wymianę kont. |
| Własne tokeny API, refresh tokeny lub inne sekrety **jeżeli pojawią się w przyszłości** — **szczególnie wrażliwe** | Tylko jeśli bez nich nie można bezpiecznie obsłużyć sesji | `flutter_secure_storage` oparte na Keystore/Keychain; na iOS rozważyć `WhenUnlockedThisDeviceOnly`, a jeśli konieczny dostęp w tle — `AfterFirstUnlockThisDeviceOnly`. Android: odpowiednia polityka dostępności klucza | **W aktualnym audycie nie wykryto własnego zapisu takich tokenów.** To warunkowa zasada projektowa, a nie opis istniejącej danej. |
| Identyfikator instalacji Firebase (`PersistedInstallation...json`) — **poufne** | Zależnie od usług Firebase | Magazyn zarządzany przez Firebase SDK; nieeksportowany poza potrzebne usługi | Nie kopiować do logów ani dokumentacji; wykluczyć niepożądane odtwarzanie między urządzeniami zgodnie z możliwościami SDK. |
| Firebase Heartbeat i metadane usług — **wewnętrzne** | Według potrzeb bibliotek | Dane techniczne SDK w prywatnym katalogu aplikacji; dostęp dla aplikacji | Minimalizacja zbędnych integracji i retencji; nie utrwalać własnych kopii. |
| Google Measurement (preferencje i lokalna baza) — **wewnętrzne/potencjalnie poufne** | **Do weryfikacji** | Konfiguracja bibliotek lub rezygnacja ze zbędnego zbierania danych; magazyn SDK | Sam plik nie dowodzi profilowania; ocenić faktyczne użycie komponentu, identyfikatory i możliwości opt-out. W poprzednim laboratorium usunięto deklaracje uprawnień reklamowych, lecz pozostały pliki SDK. |
| Tymczasowe zdjęcia / Image Picker — **poufne**, gdy zawierają zdjęcia osób | **Tylko na czas operacji** | Katalog `cache/` aplikacji; usuwanie po udanym lub anulowanym przesłaniu | Nie utrwalać w galerii ani w kopii zapasowej bez zgody i potrzeby. Zaobserwowany JPG miał 0 B — nie potwierdza zapisania obrazu. |
| Zaplanowane powiadomienia i dane wtyczki — **wewnętrzne/potencjalnie poufne** | **Tak**, tylko dla aktywnych przypomnień | Magazyn wtyczki / systemowy harmonogram, z możliwie krótką, neutralną treścią; dostęp systemowy wymagany dla działania przypomnień | Nie umieszczać nazwisk ani szczegółów wizyt na ekranie blokady. Anulować przypomnienia po wylogowaniu lub usunięciu wizyty. |
| Cache Google Maps i dane techniczne — **wewnętrzne/publiczne** | Tylko jako cache SDK | Katalog cache zarządzany przez SDK; bez dokładnej lokalizacji użytkownika | Minimalizować retencję. Sama mapa salonu nie wymaga GPS. |
| Zasoby Fluttera i cache kodu — **wewnętrzne/techniczne** | **Tak**, dla działania aplikacji | Prywatne katalogi aplikacji, zarządzane przez system/Flutter | Bez sekretów aplikacji; nie są magazynem danych użytkownika. |

## 3. Opcje dostępności i ochrona kluczy

- **Android:** jeśli w przyszłości pojawią się własne sekrety, stosować rozwiązanie oparte na **Android Keystore**. Wymóg odblokowanego urządzenia lub uwierzytelnienia użytkownika dobierać do funkcji; nie wymuszać biometrii na danych potrzebnych w tle bez analizy działania.
- **iOS:** dla własnych tokenów używanych wyłącznie po odblokowaniu preferować Keychain `WhenUnlockedThisDeviceOnly`; jeśli potrzebne działanie po pierwszym odblokowaniu w tle, rozważyć `AfterFirstUnlockThisDeviceOnly`. Dostępność musi wynikać z faktycznych wymagań.
- **Firebase Auth:** nie przypisywać wewnętrznemu magazynowi SDK powyższych opcji bez sprawdzenia jego implementacji i konfiguracji na danej platformie.

## 4. Decyzje o kopiach zapasowych

W aktualnym `android/app/src/main/AndroidManifest.xml` nie znaleziono jawnych atrybutów `allowBackup`, `dataExtractionRules` ani `fullBackupContent`. **Brak wpisów nie dowodzi, że kopie zapasowe są wyłączone.** Należy sprawdzić *Merged Manifest* i zachowanie systemu.

**Decyzja:** dane sesji, identyfikatory instalacji powiązane z kontem, cache Firestore z danymi osobowymi i pliki tymczasowe nie mogą być swobodnie przywracane na inne urządzenie. Przed wdrożeniem wybrać wykluczenia i reguły kopii odpowiednie dla wersji Androida (w tym `dataExtractionRules` dla nowszych wersji oraz zasady dla starszych), zweryfikować backup chmurowy i transfer urządzenie–urządzenie. Ustawienia niesekretne mogą być odtwarzane, jeśli jest to świadoma decyzja.

## 6. Kryteria akceptacji

- Po wylogowaniu obie ścieżki usuwają dane użytkownika z własnych preferencji i nie udostępniają danych poprzedniego konta.
- Po ponownym uruchomieniu, reinstalacji i odtworzeniu kopii nie pojawia się nieautoryzowana sesja ani cache poprzedniego użytkownika.
- Żaden własny token lub klucz nie jest zapisywany w `SharedPreferences` czy logach.
- Przypomnienia nie ujawniają poufnych szczegółów wizyt na ekranie blokady; nieaktualne przypomnienia są anulowane.
- Zasady dostępności, backupu oraz ewentualnego cache offline są potwierdzone testami Androida; test iOS pozostaje osobnym zadaniem.

**Powiązane dokumenty:** `inwentaryzacja.md` (D1), `raport-przed.md` (D2), `kanaly-wyciekow.md` (D4), `polityka-sesji.md` (D5).  
**Uwaga:** dokument jest **projektem decyzji**, a nie dowodem wdrożenia. Stan faktyczny znajduje się w D1 i D2.
