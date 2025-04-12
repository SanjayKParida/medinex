import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/repositories/doctor_repository.dart';
import 'package:medinix_frontend/repositories/patient_repository.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class AuthRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  /// Send OTP to the patient's phone number
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    print("baseUrl : $baseUrl");
    final url = Uri.parse('$baseUrl/send-otp');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({"phoneNumber": phoneNumber}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": jsonDecode(response.body)['error']};
      }
    } catch (e) {
      return {"error": "Failed to send OTP"};
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({"phoneNumber": phoneNumber, "otp": otp}),
        headers: {"Content-Type": "application/json"},
      );
      print('response : ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": jsonDecode(response.body)['error']};
      }
    } catch (e) {
      return {"error": "Failed to verify OTP"};
    }
  }

  Future<void> handleRegisterDoctor(Map<String, dynamic> doctorData) async {
    final result = await DoctorRepo().registerDoctor(doctorData);
    print("registered user data ::: ${result['doctorData']}");

    if (result['success'] == true && result.containsKey("doctorData")) {
      final userData = result["doctorData"];
      print("USER DATA ::: $userData");

      final sharedPrefService = SharedPreferencesService.getInstance();
      await sharedPrefService.init();

      // Save the doctor data and type
      await sharedPrefService.saveUserData("doctor", userData);
    } else {
      final error = result["message"] ?? "Unknown error";
      throw Exception(error);
    }
  }

  Future<void> handleRegisterPatient(Map<String, dynamic> patientData) async {
    final result = await PatientRepo().registerPatient(patientData);

    print("result ::: $result");

    if (result.containsKey("body") &&
        result["body"]["response"] == true &&
        result["body"].containsKey("userData")) {
      final userData = result["body"]["userData"];
      // print("user data ::: $userData");

      final sharedPrefService = SharedPreferencesService.getInstance();
      await sharedPrefService.init();

      // Save the full user object and type
      await sharedPrefService.saveUserData("patient", userData);
    } else {
      final error =
          result["body"]?["message"] ?? result["error"] ?? "Unknown error";
      print('error: $error');
    }
  }
}
