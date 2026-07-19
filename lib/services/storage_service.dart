import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/debug_screen.dart';

class StorageService {
  static const String _serverUrlKey = 'server_url';
  static const String _activeRideIdKey = 'active_ride_id';
  static const String _activeRideStatusKey = 'active_ride_status';

  // FlutterSecureStorage keys for sensitive data
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _genderKey = 'gender';
  
  static const String _defaultServerUrl = 'https://catalog-staring-hamstring.ngrok-free.dev';

  static late SharedPreferences _prefs;
  static bool _initialized = false;
  static bool _warnedNotInitialized = false;

  // In-memory cache for sensitive values loaded from FlutterSecureStorage
  static String? _cachedToken;
  static int? _cachedUserId;
  static String? _cachedUsername;
  static String? _cachedRole;
  static String? _cachedGender;

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> init() async {
    try {
      addDebugMessage('📦 Initializing StorageService...');
      
      _prefs = await SharedPreferences.getInstance();
      
      // Load sensitive data from secure storage
      _cachedToken = await _secure.read(key: _tokenKey);
      _cachedUserId = _parseInt(await _secure.read(key: _userIdKey));
      _cachedUsername = await _secure.read(key: _usernameKey);
      _cachedRole = await _secure.read(key: _roleKey);
      _cachedGender = await _secure.read(key: _genderKey);
      
      // Migration: if secure storage is empty but SharedPreferences has legacy data, copy it over
      if (_cachedToken == null) {
        final legacyToken = _prefs.getString(_tokenKey);
        if (legacyToken != null) {
          addDebugMessage('📦 Migrating token from SharedPreferences to secure storage');
          await _secure.write(key: _tokenKey, value: legacyToken);
          _cachedToken = legacyToken;
          await _prefs.remove(_tokenKey);
        }
      }
      if (_cachedUserId == null) {
        final legacyUserId = _prefs.getInt(_userIdKey);
        if (legacyUserId != null) {
          addDebugMessage('📦 Migrating userId from SharedPreferences to secure storage');
          await _secure.write(key: _userIdKey, value: legacyUserId.toString());
          _cachedUserId = legacyUserId;
          await _prefs.remove(_userIdKey);
        }
      }
      if (_cachedUsername == null) {
        final legacyUsername = _prefs.getString(_usernameKey);
        if (legacyUsername != null) {
          addDebugMessage('📦 Migrating username from SharedPreferences to secure storage');
          await _secure.write(key: _usernameKey, value: legacyUsername);
          _cachedUsername = legacyUsername;
          await _prefs.remove(_usernameKey);
        }
      }
      if (_cachedRole == null) {
        final legacyRole = _prefs.getString(_roleKey);
        if (legacyRole != null) {
          addDebugMessage('📦 Migrating role from SharedPreferences to secure storage');
          await _secure.write(key: _roleKey, value: legacyRole);
          _cachedRole = legacyRole;
          await _prefs.remove(_roleKey);
        }
      }
      
      _initialized = true;
      
      addDebugMessage('✅ StorageService initialized');
      addDebugMessage('Current server URL: ${getServerUrl()}');
    } catch (e) {
      addDebugMessage('❌ Error initializing StorageService: $e');
      _initialized = false;
      rethrow;
    }
  }

  static int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  static bool isInitialized() => _initialized;

  static void _warnOnce() {
    if (!_warnedNotInitialized) {
      _warnedNotInitialized = true;
      addDebugMessage('⚠️ StorageService not initialized — further warnings suppressed');
    }
  }

  static String getServerUrl() {
    try {
      if (!_initialized) {
        _warnOnce();
        return _defaultServerUrl;
      }
      return _prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
    } catch (e) {
      addDebugMessage('❌ Error getting server URL: $e');
      return _defaultServerUrl;
    }
  }

  static Future<void> setServerUrl(String url) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _prefs.setString(_serverUrlKey, url);
      addDebugMessage('✅ Server URL saved: $url');
    } catch (e) {
      addDebugMessage('❌ Error saving server URL: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.write(key: _tokenKey, value: token);
      _cachedToken = token;
      addDebugMessage('✅ Token saved');
    } catch (e) {
      addDebugMessage('❌ Error saving token: $e');
    }
  }

  static String? getToken() {
    if (!_initialized) {
      _warnOnce();
      return null;
    }
    return _cachedToken;
  }

  static Future<void> saveUserId(int userId) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.write(key: _userIdKey, value: userId.toString());
      _cachedUserId = userId;
      addDebugMessage('✅ User ID saved: $userId');
    } catch (e) {
      addDebugMessage('❌ Error saving user ID: $e');
    }
  }

  static int? getUserId() {
    if (!_initialized) {
      _warnOnce();
      return null;
    }
    return _cachedUserId;
  }

  static Future<void> clearToken() async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.delete(key: _tokenKey);
      _cachedToken = null;
      addDebugMessage('✅ Token cleared');
    } catch (e) {
      addDebugMessage('❌ Error clearing token: $e');
    }
  }

  static Future<void> clearUserId() async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.delete(key: _userIdKey);
      _cachedUserId = null;
      addDebugMessage('✅ User ID cleared');
    } catch (e) {
      addDebugMessage('❌ Error clearing user ID: $e');
    }
  }

  static Future<void> saveUsername(String username) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.write(key: _usernameKey, value: username);
      _cachedUsername = username;
      addDebugMessage('✅ Username saved: $username');
    } catch (e) {
      addDebugMessage('❌ Error saving username: $e');
    }
  }

  static String? getUsername() {
    if (!_initialized) {
      _warnOnce();
      return null;
    }
    return _cachedUsername;
  }

  static Future<void> saveRole(String role) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.write(key: _roleKey, value: role);
      _cachedRole = role;
      addDebugMessage('✅ Role saved: $role');
    } catch (e) {
      addDebugMessage('❌ Error saving role: $e');
    }
  }

  static String? getRole() {
    try {
      if (!_initialized) {
        _warnOnce();
        return null;
      }
      addDebugMessage('📋 Retrieved role: $_cachedRole');
      return _cachedRole;
    } catch (e) {
      addDebugMessage('❌ Error getting role: $e');
      return null;
    }
  }

  static Future<void> saveGender(String gender) async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      await _secure.write(key: _genderKey, value: gender);
      _cachedGender = gender;
      addDebugMessage('✅ Gender saved: $gender');
    } catch (e) {
      addDebugMessage('❌ Error saving gender: $e');
    }
  }

  static String? getGender() {
    try {
      if (!_initialized) {
        _warnOnce();
        return null;
      }
      return _cachedGender;
    } catch (e) {
      addDebugMessage('❌ Error getting gender: $e');
      return null;
    }
  }

  static Future<void> clearAllData() async {
    try {
      if (!_initialized) {
        _warnOnce();
        return;
      }
      final savedUrl = getServerUrl();
      await _prefs.clear();
      await _secure.deleteAll();
      _cachedToken = null;
      _cachedUserId = null;
      _cachedUsername = null;
      _cachedRole = null;
      _cachedGender = null;
      await setServerUrl(savedUrl);
      addDebugMessage('✅ All data cleared (server URL preserved)');
    } catch (e) {
      addDebugMessage('❌ Error clearing data: $e');
    }
  }

  static Future<void> saveActiveRideId(int rideId) async {
    if (!_initialized) return;
    await _prefs.setInt(_activeRideIdKey, rideId);
  }

  static int? getActiveRideId() {
    if (!_initialized) return null;
    return _prefs.getInt(_activeRideIdKey);
  }

  static Future<void> clearActiveRideId() async {
    if (!_initialized) return;
    await _prefs.remove(_activeRideIdKey);
    await _prefs.remove(_activeRideStatusKey);
  }

  static Future<void> saveActiveRideStatus(String status) async {
    if (!_initialized) return;
    await _prefs.setString(_activeRideStatusKey, status);
  }

  static String? getActiveRideStatus() {
    if (!_initialized) return null;
    return _prefs.getString(_activeRideStatusKey);
  }

  // Stale ride skip tracking
  static Future<void> saveStaleRideSkipped(int rideId) async {
    if (!_initialized) return;
    await _prefs.setBool('skip_stale_ride_$rideId', true);
  }

  static bool isStaleRideSkipped(int rideId) {
    if (!_initialized) return false;
    return _prefs.getBool('skip_stale_ride_$rideId') ?? false;
  }

  // API Endpoints
  static String getAuthRegisterUrl() => '${getServerUrl()}/api/auth/register';
  static String getAuthLoginUrl() => '${getServerUrl()}/api/auth/login';
  static String getAuthVerifyOtpUrl() => '${getServerUrl()}/api/auth/verify-otp';
  static String getAuthForgotPasswordUrl() => '${getServerUrl()}/api/auth/forgot-password';
  static String getAuthVerifyResetOtpUrl() => '${getServerUrl()}/api/auth/verify-reset-otp';
  static String getAuthResetPasswordUrl() => '${getServerUrl()}/api/auth/reset-password';
  static String getAuthDeviceTokenUrl() => '${getServerUrl()}/api/auth/device-token';
  static String getUsersUrl() => '${getServerUrl()}/api/users';
  static String getChatSendUrl() => '${getServerUrl()}/api/chat/send';
  static String getChatHistoryUrl() => '${getServerUrl()}/api/chat/history';

  static String getWebSocketUrl() {
    final baseUrl = getServerUrl();
    return '${baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')}/ws-chat';
  }
}
