import 'package:flutter/material.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  Future<void> _logout() async {
    final prefsService = SharedPreferencesService.getInstance();
    await prefsService.logout();

    Navigator.pushReplacementNamed(context, Routes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(onPressed: _logout, child: Text("Logout")),
      ),
    );
  }
}
