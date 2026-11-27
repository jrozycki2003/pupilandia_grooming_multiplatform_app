# Raport: komunikacja sieciowa — Pupilandia

**Przedmiot:** Bezpieczeństwo Aplikacji i Systemów Mobilnych — zajęcia 7\
**Autorzy:** Michał Dyrka, Jakub Różycki, Mateusz Sarwa\
**Data audytu:** 27.11.2026\
**Zakres:** aplikacja Flutter na Androidzie, wariant `release` zbudowany na potrzeby ćwiczeń i podpisany **kluczem debug**; emulator Android 15 (API 35), `targetSdkVersion=36`.\
**Status:** dokument roboczy — przegląd kodu i konfiguracji, test online/offline oraz **wykonane testy MITM/TLS dla Firestore**; pozostałe scenariusze wymagają dalszej weryfikacji.

> **Metodyka:** przegląd kodu Flutter i manifestów; `flutter build apk --release` (APK 71,3 MB, tymczasowo podpisane kluczem debug), `flutter install --release -d emulator-5554`; test online/offline; mitmproxy 12.3.1 na Windows 10, port `127.0.0.1:18080`, emulator ustawiony na `10.0.2.2:18080`; porównanie ruchu Firestore przed i po instalacji CA mitmproxy w magazynie certyfikatów użytkownika Androida. Po testach wyłączono proxy (`http_proxy=:0`), usunięto CA i przywrócono podpis `release` w `build.gradle.kts`. Numery linii odnoszą się do lokalnego stanu projektu i mogą wymagać aktualizacji.

## 1.1 Mapa połączeń

| Połączenie | Domena / host | Co jest wysyłane lub pobierane | Protokół i uwierzytelnienie | Problem / ograniczenie dowodu | Decyzja i źródło |
|---|---|---|---|---|---|
| Logowanie, rejestracja i reset hasła — Firebase Authentication | Dokładne hosty SDK **nieustalone w ruchu** | W operacji logowania: e-mail i hasło; odpowiedź i stan sesji obsługiwane przez Firebase Auth | Komunikacja zarządzana przez SDK Firebase; dokładny przebieg HTTPS/TLS nieprzechwycony | Nie przeprowadzono testu proxy z własnym CA | Sprawdzić rzeczywiste hosty oraz odrzucanie niezaufanych certyfikatów. Dowody: `lib/pages/login.dart:42`, `lib/pages/signup.dart:53`, `lib/pages/forgot_password.dart:33` |
| Dane aplikacji — Cloud Firestore | **`firestore.googleapis.com:443` — potwierdzone w mitmproxy** | Dokumenty i zapytania związane m.in. z użytkownikami, rezerwacjami, ocenami, rolami; zakres zależy od operacji | HTTPS/TLS; uwierzytelnianie zarządzane przez SDK Firestore, szczegóły nagłówków niewidoczne | Próby TLS z CA proxy odrzucone zarówno przed, jak i po zainstalowaniu CA użytkownika; treści żądań nie odszyfrowano | Zachować weryfikację certyfikatu, zbadać reguły i zakres danych. Dowody: `lib/services/database.dart`, `lib/pages/history.dart:260,620`; log mitmproxy 08:38 oraz 08:41–08:42, 27.11.2026 |
| Zdjęcia — Firebase Storage | Dokładny host zasobów **nieustalony w ruchu** | Bajty zdjęć JPEG, ścieżka obiektu (np. `avatars/$uid/$ts.jpg`), otrzymany URL do pobrania | SDK Firebase Storage, dalsze pobieranie przez URL | URL pobierania może działać jako adres udostępnienia; nie sprawdzono, czy zawiera token w parametrach | Nie logować ani nie ujawniać URL-i z tokenami; kontrolować reguły Storage. Dowody: `lib/pages/profile.dart:121-124`, `lib/pages/admin/admin_gallery.dart:514-527` |
| Grafiki pobierane dynamicznie | Host zależy od `widget.url`, `image`, `imageUrl`; **nieustalony** | Żądania pobrania obrazów z dynamicznych adresów | `Image.network()` / `NetworkImage()`; schemat URL i przekierowania wymagają kontroli | W pokazanych miejscach nie widać sprawdzenia `https` ani listy dozwolonych domen | Walidować schemat HTTPS i źródła URL; zbadać przekierowania. Dowody: `lib/pages/home.dart:280-282,1283-1285,4139,4795,5057`, `lib/widgets/user_avatar.dart:27` |
| Google Maps SDK | **`mapsmobilesdks-pa.googleapis.com:443` — zaobserwowany CONNECT**, przypisanie do SDK Google Maps prawdopodobne, ale niewykazane jednoznacznie | Żądania danych mapowych i pomocnicze metadane SDK; dokładne pola nieustalone | Komunikacja obsługiwana przez SDK | Połączenie zakończyło się `502 Bad Gateway` po rozłączeniu klienta; nie jest to dowód akceptacji/odrzucenia certyfikatu; wcześniej mapa nie wyświetlała kafelków | Powtórzyć test Maps i ustalić przyczynę niepowodzenia. Dowód: `lib/pages/home.dart:4322`; log mitmproxy 08:42:35 |
| Linki do serwisów społecznościowych | `www.facebook.com`, `www.instagram.com`, `www.tiktok.com` | Otwarcie adresu strony po kliknięciu; dalszy ruch realizuje zewnętrzna aplikacja/przeglądarka | Jawnie podane adresy `https://`, `LaunchMode.externalApplication` | Nie stanowi to bezpośredniego klienta HTTP Pupilandii; dalsze przekierowania niebadane | Pozostawić HTTPS i nie dopinać danych konta do URL. Dowód: `lib/pages/home.dart:3650-3664,3694` |
| Google Play Services / usługi pomiarowe i pozostałe SDK | Niepełna identyfikacja; w proxy widziano również `accounts.google.com`, `update.googleapis.com`, `www.google.com` oraz `edgedl.me.gvt1.com`, **bez dowodu, że ruch pochodził z Pupilandii** | Biblioteki mogą wysyłać identyfikatory techniczne i dane diagnostyczne; nie potwierdzono rzeczywistych pól ani domen | Do sprawdzenia analizą ruchu | Chrome i usługi systemowe również generowały ruch w czasie testu (np. `POST .../domainreliability/upload`, `GET http://edgedl.me.gvt1.com/...`); nie przypisujemy go aplikacji. Wcześniejsza inspekcja emulatora wykazała pliki analityki, lecz nie dowodzi transferu danych | Odseparować ruch aplikacji od ruchu systemowego, sprawdzić niezbędność SDK; dowody: log 08:41 i inspekcja emulatora z wcześniejszych zajęć |

**Dane niepotwierdzone:** Przechwycono metadane połączeń (hosty i wyniki uzgadniania TLS), **nie** odszyfrowano połączeń Firestore ani nie potwierdzono pełnej listy domen kontaktowanych przez SDK. Brak wyniku wyszukiwania tekstowego `http://` w Dart nie obejmuje konfiguracji natywnych bibliotek ani adresów otrzymywanych z Firestore. Nie znaleziono bezpośredniej implementacji WebView w przeszukanym kodzie Dart; nie sprawdzono wszystkich zależności natywnych.

## 1.2 Scenariusze

| Scenariusz | Oczekiwane zachowanie | Co dzieje się u nas / status | Jak sprawdziliśmy lub jak sprawdzimy |
|---|---|---|---|
| Publiczne Wi-Fi z podsłuchem | Hasła, tokeny i dane osobowe nie są ujawniane podsłuchującemu | **Nieprzetestowane**; połączenia z Firebase działają online | Test ruchu na kontrolowanej sieci z analizą metadanych i TLS, bez ujawniania danych konta |
| Proxy z własnym certyfikatem CA | Release odrzuca nieufny certyfikat podstawiony przez proxy | **WYKONANO — PASS dla Firestore**: połączenia `firestore.googleapis.com:443` kończyły się `Client TLS handshake failed` / `certificate unknown` | mitmproxy 12.3.1, port `18080`, emulator `10.0.2.2:18080`, brak zainstalowanego CA; logi 08:38:10–08:38:34 (27.11.2026). Nie badano tak wszystkich klientów |
| Certyfikat CA dodany przez użytkownika | Release nie akceptuje podstawionego certyfikatu jedynie na podstawie zaufania CA użytkownika | **WYKONANO — PASS dla Firestore**: po instalacji CA mitmproxy w Androidzie klient nadal zgłaszał `tls alert certificate unknown` | Ponowne uruchomienie Pupilandii i logi 08:41:18–08:42:34; do Chrome/Google Update widoczne były także *inne*, odszyfrowane połączenia, bez związku dowodowego z Firestore |
| Żądanie przez `http://` | Połączenia z danymi wrażliwymi blokowane; HTTPS wymagane | W skanowanym `lib/**/*.dart` (z wyjątkiem `api_keys.dart`) nie znaleziono `http://` ani `Uri.http()`; **test rzeczywistego żądania niewykonany** | Test konkretnego adresu HTTP na kontrolowanym serwerze lub test jednostkowy; sprawdzić manifest release |
| Wymiana certyfikatu serwera | Połączenia działają po legalnej wymianie certyfikatu wystawionego przez zaufane CA | **Nieprzetestowane** | Test serwera kontrolowanego, bez modyfikowania produkcyjnej konfiguracji Firebase |
| Token lub dane w URL | Tokeny i dane poufne nie trafiają do adresów, logów i historii | Nie znaleziono ręcznego `Authorization` ani stałych URL z tokenem w przeszukanym Dart; **dynamiczne URL obrazów niesprawdzone** | Sprawdzić schemat i nazwy parametrów URL obrazów **bez ujawniania ich wartości** |
| Przekierowanie na obcą domenę | Brak przekazania tokenów/sekretów do obcego hosta | **Nieprzetestowane** | Test przekierowania przez kontrolowany serwer; osobno dla obrazów i zewnętrznej przeglądarki |
| Ruch SDK i WebView | Wszystkie biblioteki respektują bezpieczną konfigurację; brak niepotrzebnej telemetrii | **CZĘŚCIOWO:** zaobserwowano `firestore.googleapis.com:443` i `CONNECT mapsmobilesdks-pa.googleapis.com:443` (zakończone `502` po rozłączeniu klienta). Brak potwierdzonego własnego WebView | Logi mitmproxy 08:38–08:42 + przegląd kodu. Inne żądania w tym czasie mogą pochodzić z Chrome/systemu i nie są dowodem ruchu Pupilandii |
| **Dodatkowo: utrata internetu (test wykonany)** | Aplikacja nie ulega awarii; informuje o braku danych lub pokazuje bezpieczne zastępniki | **Pozytywny test podstawowy:** interfejs działa, część obrazów zostaje zastąpiona grafikami lokalnymi | Emulator Android 15, wariant release, tryb samolotowy i wyłączone Wi-Fi; obserwacja interfejsu |

## 1.3 Konfiguracja sieci

| Ustawienie | U nas teraz (dowód) | Docelowo | Uzasadnienie / źródło |
|---|---|---|---|
| Ruch nieszyfrowany (`http`) | `targetSdkVersion=36` w `build/app/intermediates/merged_manifest/release/.../AndroidManifest.xml`; nie znaleziono `usesCleartextTraffic` ani `networkSecurityConfig` w przeszukanych manifestach. Brak własnych URL `http://` w skanowanym Dart | Wymagać HTTPS; potwierdzić zachowanie wszystkich używanych stosów HTTP | Domyślna polityka Androida dla target SDK ≥ 28 ogranicza cleartext w komponentach ją respektujących; nie dowodzi to zachowania wszystkich bibliotek |
| Zaufane urzędy certyfikacji | Nie znaleziono niestandardowych `trust-anchors` w XML projektu. W teście MITM klient Firestore odrzucił certyfikat proxy (log 08:38) | Zaufane CA systemowe odpowiednie dla klienta; brak wyłączania kontroli certyfikatów | Nie znaleziono `badCertificateCallback`, `HttpOverrides`, `SecurityContext` w sprawdzonym kodzie Dart |
| Certyfikaty użytkownika | Nie znaleziono jawnej konfiguracji `debug-overrides`/`networkSecurityConfig`; **przeprowadzono test z CA użytkownika**: Firestore odrzucił certyfikat podstawiony przez mitmproxy (08:41–08:42) | Rozdzielić politykę debug i release; bez przypadkowego zaufania CA użytkownika w release | Wymagania MASVS-NETWORK, Android Network Security Configuration |
| Pinning | W skanowanym Dart nie znaleziono własnego pinningu. Odrzucenie CA użytkownika przez Firestore **nie dowodzi pinningu**; możliwe działanie domyślnej polityki zaufania | Ocenić potrzebę pinningu per domena; nie deklarować go, jeśli nie jest wdrożony | MASVS-NETWORK; ryzyko awarii po zmianie certyfikatu |
| Zapasowy pin i plan rotacji | Nie dotyczy obecnie własnego pinningu | Jeśli wprowadzimy pinning — zapasowy pin i procedura wymiany | MASVS-NETWORK |
| Różnice debug/release | Sprawdzono manifesty `android/app/src/debug`, `profile` i `main`; w przeszukanym XML nie wykryto odrębnej polityki sieci. `flutter build apk --release` i instalacja na emulatorze udane, ale APK **podpisane kluczem debug** na potrzeby testu | Oddzielić ustawienia testowe od produkcyjnych; przywrócić podpis release | Wynik kompilacji: `app-release.apk` 71,3 MB; instalacja `flutter install --release -d emulator-5554` |
| Logowanie ruchu i błędów | `debugPrint("... $e")` w `lib/main.dart:30,36,43` i `lib/services/notifications.dart:47`. W przeszukanym Dart nie znaleziono ręcznego logowania nagłówków `Authorization` | Nie ujawniać szczegółów błędów z danymi osobowymi w release; logi testować osobno | Przegląd kodu; wynik wyszukiwania `log\(` dawał fałszywe trafienia `Dialog(` |

## 1.4 Decyzje

1. **Zidentyfikować rzeczywiste domeny i payloady**, w tym ruch Firebase, Maps i Google Play Services. Dowód: mapa połączeń z przeglądu kodu nie daje pełnej listy hostów. **Kryterium:** lista zaobserwowanych domen podczas logowania, odczytu danych i otwierania obrazów; bez zapisywania sekretów.
2. **Walidować dynamiczne adresy obrazów i przekierowania.** Zezwalać tylko na HTTPS oraz uzasadnione hosty, o ile nie koliduje to z rzeczywistymi źródłami obrazów. Dowód: `lib/pages/home.dart:280,1283,4139`, `lib/widgets/user_avatar.dart:27`. **Kryterium:** adres HTTP lub obca domena jest odrzucany lub bezpiecznie obsługiwany.
3. **Zweryfikować ochronę URL pobierania zdjęć Firebase Storage.** Nie zapisywać ani nie logować wartości parametrów umożliwiających pobranie zasobu; sprawdzić reguły dostępu i ewentualne publiczne URL. Dowód: `lib/pages/profile.dart:121-124`, `lib/pages/admin/admin_gallery.dart:527`. **Kryterium:** kontrola dostępu i brak wrażliwych URL w logach.
4. **Wykluczyć niebezpieczne obejście certyfikatów w wariancie release**, również w zmianach przyszłych. Dowód: skan `lib/**/*.dart` nie znalazł `badCertificateCallback` ani `HttpOverrides`; przeprowadzono udane testy odrzucania CA proxy dla Firestore przed i po instalacji CA użytkownika (logi 08:38, 08:41–08:42). **Kryterium:** próba z niezaufanym certyfikatem kończy się błędem połączenia dla odpowiednich klientów.
5. **Ograniczyć szczegóły diagnostyczne w wersji release.** Nie umieszczać haseł, tokenów ani danych osobowych w logach wyjątków; rozważyć `kDebugMode` i redakcję komunikatów. Dowód: `lib/main.dart:30,36,43`, `lib/services/notifications.dart:47`. **Kryterium:** sprawdzenie logcat na release bez danych wrażliwych.
6. **Zachować rozdzielenie konfiguracji debug i release.** Testów proxy nie wdrażać na stałe w wersji produkcyjnej. Po laboratorium **przywrócono** `signingConfigs.getByName("release")` w `android/app/build.gradle.kts`; nie commitować testowego podpisu debug do release. **Kryterium:** `git diff` nie zawiera testowej zmiany podpisu.
7. **Dokończyć osiem scenariuszy z punktu 1.2** na buildzie release i dopisać wyniki rzeczywiste. Dwa scenariusze MITM przetestowano dla Firestore; pozostałe przypadki oraz inne biblioteki nadal wymagają kontroli. **Kryterium:** dla każdego scenariusza wynik, data, metoda, zakres i dowód.

**Źródła metodyki:** prezentacja *BAiSM, Zajęcia 7 — Komunikacja sieciowa*, slajdy 2–6 i 11; OWASP MASVS-NETWORK i MASTG; dokumentacja Android Network Security Configuration; dokumentacja Flutter dotycząca połączeń sieciowych.

### Dowody z testów ruchu — 27.11.2026

**Stanowisko:** Windows 10, mitmproxy/mitmdump 12.3.1, Android Emulator `emulator-5554` z Androidem 15 (API 35), aplikacja Flutter zbudowana jako `release` (APK podpisana tymczasowym kluczem debug), manifest release `targetSdkVersion=36`.

**Test A — CA proxy niezaufane (08:38):**

```text
[08:38:09.949] server connect firestore.googleapis.com:443
[08:38:10.059] Client TLS handshake failed. The client does not trust the proxy's certificate for firestore.googleapis.com
```

**Test B — CA proxy zainstalowane w magazynie certyfikatów użytkownika (08:41–08:42):**

```text
[08:41:18.292] server connect firestore.googleapis.com:443
[08:41:18.400] Client TLS handshake failed. The client does not trust the proxy's certificate for firestore.googleapis.com
[08:42:35.623] error establishing server connection: client disconnected
CONNECT mapsmobilesdks-pa.googleapis.com:443
<< 502 Bad Gateway
```

**Interpretacja:** testy A i B wykazują odrzucenie podstawionego certyfikatu **dla obserwowanego klienta Firestore**. Nie dowodzą pinningu ani poprawnej ochrony każdego SDK. Ruch Chrome i usług systemowych zaobserwowany równolegle (także HTTP do `edgedl.me.gvt1.com`) **nie został przypisany do Pupilandii**. Przejęte żądania należy analizować bez publikowania tokenów, cookies czy parametrów dostępowych.

**Przywrócenie stanu:** wyłączono proxy poleceniem `adb shell settings put global http_proxy :0` (odczyt `:0`), usunięto testowy CA z emulatora, przywrócono wpis `signingConfig = signingConfigs.getByName("release")`. Nie wykonano nowych testów po przywróceniu stanu.

**Zastrzeżenie:** obserwacje kodu i dwa testy TLS nie zastępują pełnego audytu kryptograficznego wszystkich połączeń. Scenariusze nieprzeprowadzone są jawnie oznaczone w 1.2 i nie powinny być przedstawiane jako zaliczone.
