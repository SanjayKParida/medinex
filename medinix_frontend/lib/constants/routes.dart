import 'package:flutter/widgets.dart';
import 'package:medinix_frontend/screens/auth_screens/doctor_login_screen.dart';
import 'package:medinix_frontend/screens/auth_screens/login_screen.dart';
import 'package:medinix_frontend/screens/auth_screens/otp_verification_screen.dart';
import 'package:medinix_frontend/screens/auth_screens/patient_login_screen.dart';
import 'package:medinix_frontend/screens/features/doctor/doctor_dashboard.dart';
import 'package:medinix_frontend/screens/features/patient/home/appointment_booking_screen.dart';
import 'package:medinix_frontend/screens/features/patient/patient_dashboard.dart';
import 'package:medinix_frontend/screens/helper_screens/doctor_detail_screen.dart';
import 'package:medinix_frontend/screens/helper_screens/doctor_pending_approval_screen.dart';
import 'package:medinix_frontend/screens/helper_screens/forgot_password_screen.dart';
import 'package:medinix_frontend/screens/helper_screens/patient_detail_screen.dart';
import 'package:medinix_frontend/screens/helper_screens/splash_screen.dart';

class Routes {
  static const String splashScreen = "/";
  static const String patientLoginScreen = "/patientLoginScreen";
  static const String doctorLoginScreen = "/doctorLoginScreen";
  static const String doctorDashboard = "/doctorDashboard";
  static const String patientDashboard = "/patientDashboard";
  static const String otpVerificationScreen = "/otpVerificationScreen";
  static const String patientDetailScreen = "/patientDetailScreen";
  static const String loginScreen = "/loginScreen";
  static const String forgotPasswordScreen = "/forgotPasswordScreen";
  static const String appointmentBookingScreen = "/appointmentBookingScreen";
  static const String doctorDetailScreen = "/doctorDetailScreen";
  static const String doctorPendingApprovalScreen =
      "/doctorPendingApprovalScreen";

  static Map<String, Widget Function(BuildContext)> routesMap = {
    splashScreen: (context) => SplashScreen(),
    patientLoginScreen: (context) => PatientLoginScreen(),
    doctorLoginScreen: (context) => DoctorLoginScreen(),
    doctorDashboard: (context) => DoctorDashboard(),
    patientDashboard: (context) => PatientDashboard(),
    doctorDetailScreen: (context) => DoctorDetailScreen(),
    loginScreen: (context) => LoginScreen(),
    patientDetailScreen: (context) => PatientDetailScreen(),
    forgotPasswordScreen: (context) => ForgotPasswordScreen(),
    appointmentBookingScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return AppointmentBookingScreen(pickedDoctor: args['pickedDoctor']);

    },
    doctorPendingApprovalScreen: (context) => DoctorPendingApprovalScreen(),
    otpVerificationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      return OtpVerificationScreen(phoneNumber: args['phoneNumber']);
    },
  };
}
