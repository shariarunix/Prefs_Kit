# PrefsKit – Reactive Preference & Secure Storage Service for Flutter

A unified and reactive wrapper around **SharedPreferences** and **FlutterSecureStorage**.  
`PrefsKit` makes it easy to store and retrieve **primitives, lists, and maps** while also providing:

- **Secure storage support** for sensitive data  
- **Streams** to listen to preference changes in real-time  
- **Centralized configuration** for all app preferences  
- **Simple API** for reading, writing, and clearing values  

---

## Features

- Store primitives: `String`, `int`, `double`, `bool`
- Store collections: `List<String>`, `Map<String, dynamic>`
- Secure or non-secure storage (`SharedPreferences` vs `FlutterSecureStorage`)
- Reactive updates with `Stream<T>`
- Centralized config (`PrefsKit`) for global app settings

---

## Getting Started

### 1. Install dependencies

Add the required packages in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^latest-version
  shared_preferences: ^latest-version
```

### 2. Run

```bash
flutter pub get
```
### 3. Initialize in ```main.dart```

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PrefsKit
  await PrefsKitConfig.init();

  runApp(MyApp());
}
```

### 4. Usage

```dart
// Define
StringPreference localeCode = StringPreference('localeCode', 'en');
BoolPreference darkMode = BoolPreference('darkMode', false);
StringListPreference favorites = StringListPreference('favorites', []);
MapPreference userSettings = MapPreference('userSettings', {});

// Read
String locale = await localeCode.read();
bool isDark = await darkMode.read();

// Update
await localeCode.updateValue('fr');
await darkMode.updateValue(true);

// Listen
darkMode.onChanged.listen((isDark) {
  print('Dark mode changed: $isDark');
});

// Secure
final secureToken = StringPreference('authToken', '', isSecure: true);

await secureToken.updateValue('my_secret_token');
String token = await secureToken.read();

// Clear
await PrefsKit.clearAll();
```
