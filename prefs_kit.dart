import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences instance used for non-secure storage.
late SharedPreferences _preferences;

/// FlutterSecureStorage instance used for secure storage.
late FlutterSecureStorage _secureStorage;

/// Base class representing a preference of type [T].
/// Supports reading, writing, and listening to changes.
/// Can store data in secure or non-secure storage.
abstract class Preference<T> {
  /// Key for the preference.
  final String key;

  /// Default value returned if no value is stored.
  final T defaultValue;

  /// Whether to store in secure storage (FlutterSecureStorage) or not.
  final bool isSecure;

  StreamController<T>? _controller;

  /// Constructor
  Preference(this.key, this.defaultValue, {this.isSecure = false});

  /// Broadcast stream of value changes.
  Stream<T> get onChanged {
    _controller ??= StreamController<T>.broadcast(
      onCancel: () {
        _controller?.close();
        _controller = null;
      },
    );
    return _controller!.stream;
  }

  /// Reads the value from storage.
  /// Returns [defaultValue] if not found.
  Future<T> read() async {
    if (isSecure) {
      final raw = await _secureStorage.read(key: key);
      return _decode(raw);
    } else {
      if (_isPrimitive<T>()) {
        return _readPrimitive() ?? defaultValue;
      } else {
        final raw = _preferences.getString(key);
        return _decode(raw);
      }
    }
  }

  /// Writes the value to storage and notifies listeners.
  /// Passing `null` removes the value and emits [defaultValue].
  Future<void> updateValue(T val) async {
    if (val == null) {
      if (isSecure) {
        await _secureStorage.delete(key: key);
      } else {
        await _preferences.remove(key);
      }
      _controller?.add(defaultValue);
    } else {
      if (isSecure || !_isPrimitive<T>()) {
        final encoded = _encode(val);
        if (isSecure) {
          await _secureStorage.write(key: key, value: encoded);
        } else {
          await _preferences.setString(key, encoded);
        }
      } else {
        _writePrimitive(val);
      }
      _controller?.add(val);
    }
  }

  /// Dispose the stream controller.
  void dispose() {
    _controller?.close();
  }

  /// Encodes a value for storage.
  /// For primitive types, just converts to string.
  /// For complex types, encodes as JSON.
  String _encode(T val) {
    if (val is String || val is num || val is bool) return val.toString();
    return jsonEncode(val);
  }

  /// Decodes a stored string back into [T].
  T _decode(String? raw) {
    if (raw == null) return defaultValue;
    if (T == String) return raw as T;
    if (T == int) return int.tryParse(raw) as T? ?? defaultValue;
    if (T == double) return double.tryParse(raw) as T? ?? defaultValue;
    if (T == bool) return (raw.toLowerCase() == 'true') as T;
    return jsonDecode(raw) as T;
  }

  /// Checks if type [U] is a primitive type.
  bool _isPrimitive<U>() => U == String || U == int || U == double || U == bool;

  /// Reads primitive types from SharedPreferences.
  T? _readPrimitive() {
    if (T == String) return _preferences.getString(key) as T?;
    if (T == int) return _preferences.getInt(key) as T?;
    if (T == double) return _preferences.getDouble(key) as T?;
    if (T == bool) return _preferences.getBool(key) as T?;
    return null;
  }

  /// Writes primitive types to SharedPreferences.
  void _writePrimitive(T val) {
    if (T == String) _preferences.setString(key, val as String);
    if (T == int) _preferences.setInt(key, val as int);
    if (T == double) _preferences.setDouble(key, val as double);
    if (T == bool) _preferences.setBool(key, val as bool);
  }
}

/// Boolean preference.
class BoolPreference extends Preference<bool> {
  BoolPreference(super.key, super.defaultValue, {super.isSecure = false});
}

/// Integer preference.
class IntPreference extends Preference<int> {
  IntPreference(super.key, super.defaultValue, {super.isSecure = false});
}

/// Double preference.
class DoublePreference extends Preference<double> {
  DoublePreference(super.key, super.defaultValue, {super.isSecure = false});
}

/// String preference.
class StringPreference extends Preference<String> {
  StringPreference(super.key, super.defaultValue, {super.isSecure = false});
}

/// List<String> preference.
class StringListPreference extends Preference<List<String>> {
  StringListPreference(super.key, super.defaultValue, {super.isSecure = false});

  @override
  String _encode(List<String> val) => jsonEncode(val);

  @override
  List<String> _decode(String? raw) {
    if (raw == null) return defaultValue;
    final decoded = jsonDecode(raw);
    return List<String>.from(decoded);
  }
}

/// Map<String, dynamic> preference.
class MapPreference extends Preference<Map<String, dynamic>> {
  MapPreference(super.key, super.defaultValue, {super.isSecure = false});

  @override
  String _encode(Map<String, dynamic> val) => jsonEncode(val);

  @override
  Map<String, dynamic> _decode(String? raw) {
    if (raw == null) return defaultValue;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }
}

/// Configuration for initializing preferences.
class PrefsKitConfig {
  /// Initialize SharedPreferences and FlutterSecureStorage.
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
  }

  /// Clears all preferences (both secure and non-secure).
  static Future<void> clearAll() async {
    await _preferences.clear();
    await _secureStorage.deleteAll();
  }
}
