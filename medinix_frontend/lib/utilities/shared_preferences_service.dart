import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferencesService? _instance;
  SharedPreferences? _prefs;

  SharedPreferencesService._internal();

  static SharedPreferencesService getInstance() {
    _instance ??= SharedPreferencesService._internal();
    return _instance!;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception("SharedPreferences not initialized. Call init() first.");
    }
    return _prefs!;
  }

  // Save userType and full user data as JSON
  Future<void> saveUserData(
    String userType,
    Map<String, dynamic> userDetails,
  ) async {
    await prefs.setString("userData", jsonEncode(userDetails));
    await prefs.setString("userType", userType);
  }

  String? get userType => prefs.getString('userType');

  Map<String, dynamic>? getUserDetails() {
    final userData = prefs.getString('userData');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  bool isLoggedIn() {
    return userType != null && prefs.getString('userData') != null;
  }

  Future<void> logout() async {
    await prefs.clear();
  }

}
