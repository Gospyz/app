import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local app settings using SharedPreferences.
class SettingsService {
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String locationNameKey = 'location_name';
  static const String locationAddressKey = 'location_address';
  static const String locationAdminKey = 'location_admin';
  static const String notifEmailKey = 'notif_email';
  static const String notifPushKey = 'notif_push';
  static const String notifSmsKey = 'notif_sms';

  Future<void> saveLocationInfo(String name, String address, String admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(locationNameKey, name);
    await prefs.setString(locationAddressKey, address);
    await prefs.setString(locationAdminKey, admin);
  }

  Future<Map<String, String?>> getLocationInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(locationNameKey),
      'address': prefs.getString(locationAddressKey),
      'admin': prefs.getString(locationAdminKey),
    };
  }

  Future<void> saveNotifPrefs(bool email, bool push, bool sms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notifEmailKey, email);
    await prefs.setBool(notifPushKey, push);
    await prefs.setBool(notifSmsKey, sms);
  }

  Future<Map<String, bool?>> getNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getBool(notifEmailKey),
      'push': prefs.getBool(notifPushKey),
      'sms': prefs.getBool(notifSmsKey),
    };
  }

  Future<void> saveThemeMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, darkMode);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? false;
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, languageCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(languageKey) ?? 'RO';
  }
}
