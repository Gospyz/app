import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing app settings in Firestore (cloud sync).
class FirestoreSettingsService {
  // Location Info
  Future<void> saveLocationInfo(String name, String address, String admin) async {
    final userId = await _getCurrentUserId();
    await setSetting(userId, 'location_name', name);
    await setSetting(userId, 'location_address', address);
    await setSetting(userId, 'location_admin', admin);
  }

  Future<Map<String, String?>> getLocationInfo() async {
    final userId = await _getCurrentUserId();
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    return {
      'name': doc.data()?['location_name'],
      'address': doc.data()?['location_address'],
      'admin': doc.data()?['location_admin'],
    };
  }

  // Notification Preferences
  Future<void> saveNotifPrefs(bool email, bool push, bool sms) async {
    final userId = await _getCurrentUserId();
    await setSetting(userId, 'notif_email', email);
    await setSetting(userId, 'notif_push', push);
    await setSetting(userId, 'notif_sms', sms);
  }

  Future<Map<String, bool?>> getNotifPrefs() async {
    final userId = await _getCurrentUserId();
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    return {
      'email': doc.data()?['notif_email'],
      'push': doc.data()?['notif_push'],
      'sms': doc.data()?['notif_sms'],
    };
  }

  // Theme Mode
  Future<void> saveThemeMode(bool darkMode) async {
    final userId = await _getCurrentUserId();
    await setSetting(userId, 'theme_mode', darkMode);
  }

  Future<bool> getThemeMode() async {
    final userId = await _getCurrentUserId();
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    return doc.data()?['theme_mode'] ?? false;
  }

  // Language
  Future<void> saveLanguage(String languageCode) async {
    final userId = await _getCurrentUserId();
    await setSetting(userId, 'language_code', languageCode);
  }

  Future<String> getLanguage() async {
    final userId = await _getCurrentUserId();
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    return doc.data()?['language_code'] ?? 'RO';
  }

  Future<String> _getCurrentUserId() async {
    // You may want to use FirebaseAuth here for real user id
    // For now, fallback to a static id for demo
    // Replace with: FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
    return 'default_user';
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _settingsCollection = 'app_settings';

  /// Save a setting to Firestore (document per setting type, e.g. theme, language, etc.)
  Future<void> setSetting(String userId, String key, dynamic value) async {
    await _firestore.collection(_settingsCollection).doc(userId).set({
      key: value,
    }, SetOptions(merge: true));
  }

  /// Get a setting from Firestore for a user.
  Future<dynamic> getSetting(String userId, String key) async {
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    if (doc.exists) {
      return doc.data()?[key];
    }
    return null;
  }

  /// Get all settings for a user.
  Future<Map<String, dynamic>?> getAllSettings(String userId) async {
    final doc = await _firestore.collection(_settingsCollection).doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
