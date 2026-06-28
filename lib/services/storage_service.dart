import 'package:shared_preferences/shared_preferences.dart';
import '../screens/debug_screen.dart';

class StorageService {
  static const String _serverUrlKey = 'server_url';
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _activeRideIdKey = 'active_ride_id';
  static const String _activeRideStatusKey = 'active_ride_status';
  
  static const String _defaultServerUrl = 'http://localhost:8080';

  static late SharedPreferences _prefs;
  static bool _initialized = false;

  // ✅ Better initialization
  static Future<void> init() async {
    try {
      addDebugMessage('📦 Initializing SharedPreferences...');
      
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      
      addDebugMessage('✅ SharedPreferences initialized');
      addDebugMessage('Current server URL: ${getServerUrl()}');
    } catch (e) {
      addDebugMessage('❌ Error initializing SharedPreferences: $e');
      _initialized = false;
      rethrow;
    }
  }

  // ✅ Check if initialized
  static bool isInitialized() => _initialized;



  static String getServerUrl() {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized, using default URL');
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
        addDebugMessage('⚠️ StorageService not initialized');
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
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.setString(_tokenKey, token);
      addDebugMessage('✅ Token saved');
    } catch (e) {
      addDebugMessage('❌ Error saving token: $e');
    }
  }

  static String? getToken() {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return null;
      }
      return _prefs.getString(_tokenKey);
    } catch (e) {
      addDebugMessage('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveUserId(int userId) async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.setInt(_userIdKey, userId);
      addDebugMessage('✅ User ID saved: $userId');
    } catch (e) {
      addDebugMessage('❌ Error saving user ID: $e');
    }
  }

  static int? getUserId() {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return null;
      }
      return _prefs.getInt(_userIdKey);
    } catch (e) {
      addDebugMessage('❌ Error getting user ID: $e');
      return null;
    }
  }

    static Future<void> clearToken() async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.remove(_tokenKey);
      addDebugMessage('✅ Token cleared');
    } catch (e) {
      addDebugMessage('❌ Error clearing token: $e');
    }
  }

  static Future<void> clearUserId() async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.remove(_userIdKey);
      addDebugMessage('✅ User ID cleared');
    } catch (e) {
      addDebugMessage('❌ Error clearing user ID: $e');
    }
  }

  static Future<void> saveUsername(String username) async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.setString(_usernameKey, username);
      addDebugMessage('✅ Username saved: $username');
    } catch (e) {
      addDebugMessage('❌ Error saving username: $e');
    }
  }

  static String? getUsername() {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return null;
      }
      return _prefs.getString(_usernameKey);
    } catch (e) {
      addDebugMessage('❌ Error getting username: $e');
      return null;
    }
  }

  static Future<void> saveRole(String role) async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.setString(_roleKey, role);
      addDebugMessage('✅ Role saved: $role');
    } catch (e) {
      addDebugMessage('❌ Error saving role: $e');
    }
  }

  static String? getRole() {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return null;
      }
      final role = _prefs.getString(_roleKey);
      addDebugMessage('📋 Retrieved role: $role');
      return role;
    } catch (e) {
      addDebugMessage('❌ Error getting role: $e');
      return null;
    }
  }

  static Future<void> clearAllData() async {
    try {
      if (!_initialized) {
        addDebugMessage('⚠️ StorageService not initialized');
        return;
      }
      await _prefs.clear();
      addDebugMessage('✅ All data cleared');
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
  static String getAuthDeviceTokenUrl() => '${getServerUrl()}/api/auth/device-token';
  static String getUsersUrl() => '${getServerUrl()}/api/users';
  static String getChatSendUrl() => '${getServerUrl()}/api/chat/send';
  static String getChatHistoryUrl() => '${getServerUrl()}/api/chat/history';
  static String getNotificationsUrl() => '${getServerUrl()}/api/notifications';
  static String getNotificationsUnreadCountUrl() => '${getServerUrl()}/api/notifications/unread-count';
  static String getWebSocketUrl() {
    final baseUrl = getServerUrl();
    return '${baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')}/ws-chat';
  }
}