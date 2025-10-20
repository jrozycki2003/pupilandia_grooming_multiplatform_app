# 🔐 Security Setup - API Keys Configuration

## Przegląd

Ten projekt używa wrażliwych kluczy API, które **nie powinny** być commitowane do repozytorium GitHub. Ten dokument wyjaśnia, jak poprawnie skonfigurować projekt.

## 🚨 Ważne pliki

Następujące pliki zawierają **placeholder'y** dla kluczy API w repozytorium:
- `lib/firebase_options.dart` - zawiera placeholder'y dla Firebase
- `web/index.html` - zawiera placeholder dla Google Maps API

Następujące pliki są **ignorowane przez Git** (nie commituj ich):
- `.env` - plik środowiskowy z kluczami
- `secrets.properties` - właściwości z sekretami

## 📋 Konfiguracja dla nowego użytkownika

### Krok 1: Sklonuj repozytorium
```bash
git clone <repository-url>
cd kubaproject
```

### Krok 2: Utwórz plik z kluczami API

**GŁÓWNY PLIK KONFIGURACYJNY**: `lib/api_keys.dart`

```bash
# Skopiuj szablon
cp lib/api_keys.dart.template lib/api_keys.dart
```

Następnie otwórz `lib/api_keys.dart` i zastąp wszystkie placeholder'y swoimi prawdziwymi kluczami:

```dart
// Google Maps
const String GOOGLE_MAPS_API_KEY = 'Twój-Klucz-Google-Maps';

// Firebase Web
const String FIREBASE_WEB_API_KEY = 'Twój-Firebase-Web-API-Key';
const String FIREBASE_WEB_APP_ID = 'Twój-App-ID';
// ... itd.
```

⚠️ **WAŻNE:** Plik `lib/api_keys.dart` jest w `.gitignore` i **NIGDY** nie zostanie commitowany!

### Krok 3: (Opcjonalnie) Zaktualizuj web/index.html

Jeśli używasz aplikacji webowej, otwórz `web/index.html` i zamień placeholder Google Maps:

```html
<!-- Znajdź i zamień: -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY_HERE"></script>

<!-- Na: -->
<script src="https://maps.googleapis.com/maps/api/js?key=Twój-Klucz-Google-Maps"></script>
```

### Krok 3: (Opcjonalnie) Utwórz plik .env
```bash
cp .env.example .env
```

Wypełnij plik `.env` swoimi kluczami API.

## 🔑 Gdzie znaleźć klucze API?

### Google Maps API Key
1. Przejdź do [Google Cloud Console](https://console.cloud.google.com/)
2. Wybierz swój projekt
3. Nawigacja: APIs & Services → Credentials
4. Utwórz lub skopiuj istniejący klucz API dla Maps JavaScript API

### Firebase Configuration
1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Wybierz swój projekt
3. Kliknij ikonę koła zębatego → Project settings
4. Przewiń do sekcji "Your apps"
5. Dla każdej platformy (Web/Android) znajdziesz wszystkie potrzebne klucze

## ⚠️ Bezpieczeństwo

**NIGDY NIE:**
- Nie commituj plików z prawdziwymi kluczami API
- Nie udostępniaj kluczy API publicznie
- Nie pushuj zmian w `index.html` lub `firebase_options.dart` z prawdziwymi kluczami

**ZAWSZE:**
- Trzymaj prawdziwe klucze tylko lokalnie
- Przed commitem sprawdź, czy nie dodajesz prawdziwych kluczy
- Regularnie rotuj klucze API
- Ogranicz klucze API do konkretnych domen/aplikacji w Google Cloud Console

## 🛠️ Dla deweloperów zespołu

Jeśli jesteś członkiem zespołu:
1. Poproś team leadera o klucze API (NIE przez Git!)
2. Skonfiguruj pliki lokalnie zgodnie z instrukcjami powyżej
3. Nigdy nie commituj swoich skonfigurowanych plików

## ✅ Weryfikacja

Przed uruchomieniem projektu, upewnij się że:
- [ ] Plik `web/index.html` zawiera prawdziwy klucz Google Maps (nie placeholder)
- [ ] Plik `lib/firebase_options.dart` zawiera prawdziwe klucze Firebase (nie placeholder'y)
- [ ] Prawdziwe klucze są TYLKO lokalnie, nigdy nie commitowane do Git

## 🚀 Uruchomienie projektu

Po skonfigurowaniu kluczy API:

```bash
# Pobierz zależności
flutter pub get

# Uruchom aplikację
flutter run -d chrome  # dla web
flutter run            # dla Android/iOS
```

## 📞 Kontakt

W razie problemów z konfiguracją, skontaktuj się z administratorem projektu.
