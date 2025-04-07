import 'package:flutter/material.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/login_repo.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _syncAndNavigate();
    });
  }

  Future<void> _syncAndNavigate() async {
    final prefs = SharedPreferencesService.getInstance();
    await prefs.init();

    final userType = prefs.userType;

    if (userType == "doctor") {
      final doctorLoginId = prefs.getUserDetails()?["doctorLoginId"];
      print("doctorLogin id : $doctorLoginId");

      if (doctorLoginId != null) {
        final result = await LoginRepo().getDoctorDetails(doctorLoginId);

        print("Doctor details API response: $result");

        final statusCode = result['statusCode'];
        final body = result['body']['body'];
        print("Body: $body");

        if (statusCode == 200 &&
            body['response'] == true &&
            body['doctorData'] != null) {
          final latestDoctorData = body['doctorData'];
          print("Latest doctor Data: $latestDoctorData");

          await prefs.saveUserData("doctor", latestDoctorData);

          final isApproved = latestDoctorData["isApproved"] ?? false;
          if (isApproved) {
            Navigator.pushReplacementNamed(context, Routes.doctorDashboard);
          } else {
            Navigator.pushReplacementNamed(
              context,
              Routes.doctorPendingApprovalScreen,
            );
          }
          return;
        }
      }

      // If login failed or doctor not found
      Navigator.pushReplacementNamed(context, Routes.loginScreen);
    } else if (userType == "patient") {
      final phoneNumber = prefs.getUserDetails()?["mobileNumber"];

      if (phoneNumber != null) {
        final result = await LoginRepo().getPatientDetails(phoneNumber);

        final statusCode = result['statusCode'];
        final body = result['body'];

        if (statusCode == 200 &&
            body['response'] == true &&
            body['patientData'] != null) {
          final latestPatientData = body['patientData'];
          print("latest patient data : $latestPatientData");
          await prefs.saveUserData("patient", latestPatientData);
        }
      }

      Navigator.pushReplacementNamed(context, Routes.patientDashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.loginScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Medinix',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
