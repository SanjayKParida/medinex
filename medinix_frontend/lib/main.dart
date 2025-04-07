import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Load dot env
  await dotenv.load();

  // Initialize shared preferences
  final sharedPrefs = SharedPreferencesService.getInstance();
  await sharedPrefs.init();

  await logSharedPreferences();

  runApp(const MyApp());
}

Future<void> logSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();

  if (keys.isEmpty) {
    print("🔍 SharedPreferences is empty.");
  } else {
    print("📦 Stored SharedPreferences:");
    for (var key in keys) {
      final value = prefs.get(key); // Dynamically gets any type
      print("➡️ $key: $value");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medinix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: Routes.splashScreen,
      routes: Routes.routesMap,
    );
  }
}
