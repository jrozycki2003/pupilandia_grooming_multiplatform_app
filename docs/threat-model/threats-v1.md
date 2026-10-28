# Model zagrożeń v1 — Pupilandia

Stan na zajęcia 2. Minimum 10 zagrożeń, każde przy elemencie DFD. Aktualizacja: półmetek (Z8) i po każdej nowej funkcji (deep link, WebView, biometria).

Skala ryzyka: macierz z zajęć 2 (wpływ × prawdopodobieństwo).  
Decyzje: **zredukować** / **wyeliminować** / **przenieść** / **zaakceptować**.

| ID | Element DFD | Zagrożenie (kto, którędy, po co) | STRIDE | Dane | P | W | Ryzyko | Decyzja | Wymaganie | Kiedy |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T01 | Proces: logowanie → Firebase Auth | Atakujący z hasłem lub skradzionym tokenem loguje się jako klient i czyta/zmienia wizyty | S | hasło, token, rezerwacje | śr | wys | **wysokie** | Przenieść część na Firebase Auth (hash haseł, limity); zredukować: lockout UX, później biometria na odblokowanie | MASVS-AUTH | Z3–Z6 |
| T02 | Magazyn: SharedPreferences | E-mail, UID i URL zdjęcia w XML jawnym tekstem; kopia zapasowa Androida (`allowBackup` domyślnie włączone) albo root | I | e-mail, UID, imię | wys | wys | **wysokie** | Zredukować: `flutter_secure_storage` + przegląd backup | MASVS-STORAGE-1 | Z3 |
| T03 | Magazyn: Firestore `Booking` | Klient w aplikacji filtruje po e-mailu, ale `getBookings()` i słabe Rules pozwalają odczytać **wszystkie** wizyty | I / E | rezerwacje, notatki, e-mail | wys | wys | **wysokie** | Zredukować: Rules `request.auth.token.email == resource.data.Email` (klient); admin/employee osobno | MASVS-AUTH | Z3 |
| T04 | Magazyn: Firestore `Admin` / `Employee` | Zalogowany użytkownik dopisuje dokument `Admin/{swój_email}` — panel i (przy słabych Rules) pełny CRUD | E | role | wys | wys | **wysokie** | Zredukować: `allow write: if false` na role z klienta; nadawanie tylko z konsoli / Admin SDK; rozważyć custom claims | MASVS-AUTH | Z3 |
| T05 | Proces: aplikacja Flutter | Zmodyfikowany APK albo proxy pomija `_verifyAdminAccess()` — UI nie jest granicą zaufania | T / E | wszystkie kolekcje | śr | wys | **wysokie** | Zredukować: **jedyna** autoryzacja w Rules; UI tylko wygoda | MASVS-AUTH, MASVS-CODE | Z3, Z8 |
| T06 | Przepływ: HTTPS do Firebase | Podsłuch w sieci otwartej; na urządzeniu deweloperskim user CA + proxy podmienia żądania | I / T | token, Booking | niska* | wys | **średnie** | Zaakceptować TLS SDK na MVP; świadomie bez pinningu do Z7 (koszt vs zysk na Firebase) | MASVS-NETWORK | Z7 |
| T07 | Magazyn: tokeny SDK Auth | Token sesji w katalogu aplikacji — na zrootowanym telefonie przejęcie konta bez hasła | S / I | token | śr | wys | **wysokie** | Zredukować: krótka sesja, wylogowanie, później biometria przed pokazaniem panelu; nie duplikować tokenu w SharedPreferences | MASVS-AUTH, MASVS-STORAGE | Z4, Z6 |
| T08 | Proces: zmiana rezerwacji | Brak dziennika „kto anulował / zmienił termin” — klient i salon mogą się wyprzeć | R | Booking | śr | śr | **średnie** | Zredukować: pole `updatedBy` + `updatedAt` (UID) i ewentualnie log w kolekcji `audit` tylko dla admina | MASVS-AUTH (niezaprzeczalność) | Z8 |
| T09 | Encja: Google Maps / config w APK | Klucz Maps i `firebase_options` wyciągalne z APK (jadx) — nadużycie billed API albo skan projektu | I | klucz API | wys | śr | **średnie** | Zredukować: restriction klucza (pakiet + SHA-1, HTTP referrer na web); zaakceptować że config Firebase jest publiczny z natury klienta | MASVS-RESILIENCE, MASVS-CODE | Z11 + już `SECURITY_SETUP.md` |
| T10 | Encja: system uprawnień | Manifest ma `ACCESS_FINE_LOCATION` / `COARSE`, choć karta mówi że GPS użytkownika nie zbieramy — sklep, malware, zła zgoda | I | lokalizacja (szczególnie wrażliwa **gdyby** włączona) | śr | śr | **średnie** | Wyeliminować zbędne uprawnienia, jeśli Maps działa na stałym markerze | MASVS-PRIVACY, MASVS-PLATFORM | Z3 |
| T11 | Proces: Firebase Auth (logowanie) | Brak własnego limitu prób w aplikacji; atak słownikowy na e-mail klienta | D / S | hasło | śr | śr | **średnie** | Przenieść na Firebase (throttling); zredukować: nie zdradzać „user-not-found” vs złe hasło jednakowym komunikatem tam gdzie się da | MASVS-AUTH | Z6 |
| T12 | Magazyn: Cloud Storage | URL zdjęcia profilowego lub obiekt w buckecie publiczny / czytelny dla każdego zalogowanego | I | wizerunek | śr | śr | **średnie** | Zredukować: Storage Rules po `request.auth.uid`; unikać publicznego `getDownloadURL` bez auth | MASVS-STORAGE, MASVS-AUTH | Z3 |
| T13 | Przepływ: kod ↔ biblioteki | Zależności Flutter (`image_picker`, Maps, Firebase) — podatność łańcucha dostaw | T | pośrednio wszystkie | niska | wys | **średnie** | Zredukować: `flutter pub outdated`, pinowanie wersji w `pubspec.lock` (już w repo), przegląd na Z10 | MASVS-CODE | Z10 |
| T14 | Encja: inna aplikacja (plan) | Deep link otwiera szczegóły wizyty po `bookingId` bez sprawdzenia właściciela | S / E | Booking | — | wys | **wysokie** *gdy powstanie* | Zredukować przy implementacji: walidacja parametrów + ten sam test co Rules | MASVS-PLATFORM | Z4 / Z9 |

\*Prawdopodobieństwo T06 na produkcji z TLS jest niższe niż na emulatorze z user CA — stąd „średnie”, nie „wszystko wysokie”.

## Priorytet do kodu (kolejność)

1. T03 + T04 + T05 — Rules i testy emulatora (inaczej reszta zabezpieczeń w UI nic nie daje).  
2. T02 + T10 — magazyn lokalny i manifest.  
3. T12 — Storage.  
4. T01 / T07 / T11 — sesja i logowanie (Z6).  
5. T14, WebView, biometria — dopiero gdy funkcje wejdą do DFD.

## Świadomie zaakceptowane na v1

- Brak certificate pinningu do Firebase (T06) — do przeglądu na zajęciach o sieci.  
- Publiczny charakter `google-services` / `firebase_options` w kliencie mobilnym (T09) — kompensata: ograniczenia klucza w konsoli, nie „sekret w kodzie”.
