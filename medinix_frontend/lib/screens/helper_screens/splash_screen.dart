import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';
import 'package:medinix_frontend/repositories/patient_repository.dart';
import 'package:medinix_frontend/utilities/patient_data_service.dart';
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

    Future.delayed(Duration(milliseconds: 400), () => _syncAndNavigate());
  }

  Future<void> _syncAndNavigate() async {
    print("called");
    final prefs = SharedPreferencesService.getInstance();
    await prefs.init();

    final userType = prefs.userType;

    if (userType == "doctor") {
      final doctorLoginId = prefs.getUserDetails()?["doctorId"];
      print("doctorLogin id : $doctorLoginId");

      if (doctorLoginId != null) {
        final result = await DoctorRepo().getDoctorDetails(doctorLoginId);

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
      final phoneNumber = prefs.getUserDetails()?["phoneNumber"];

      if (phoneNumber != null) {
        final result = await PatientRepo().getPatientDetails(phoneNumber);
        print("result:::: $result");

        final statusCode = result['statusCode'];
        final body = result['body']['body'];

        if (statusCode == 200 &&
            body['response'] == true &&
            body['patientData'] != null) {
          final latestPatientData = body['patientData'];
          print("latest patient data : $latestPatientData");
          await prefs.saveUserData("patient", latestPatientData);

          // PatientDataService is already initialized in main.dart
          final patientDataService = PatientDataService.getInstance();
          patientDataService.refreshPatientData();
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
          children: [
            Text(
              'Medinix',
              style: GoogleFonts.poppins(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            CupertinoActivityIndicator(color: Colors.teal, radius: 15),
          ],
        ),
      ),
    );
  }
}
