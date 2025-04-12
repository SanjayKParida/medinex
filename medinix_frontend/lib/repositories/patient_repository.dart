import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class PatientRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final SharedPreferencesService _prefsService =
      SharedPreferencesService.getInstance();

    //Patient login function
  Future<Map<String, dynamic>> loginPatient(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/login-patient');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({"phoneNumber": phoneNumber}),
        headers: {"Content-Type": "application/json"},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userData = responseBody['body']?['userData'];

        if (userData != null) {
          await _prefsService.saveUserData("patient", userData);
        }

        return {"statusCode": 200, "body": responseBody['body'] ?? {}};
      } else {
        return {
          "statusCode": response.statusCode,
          "body":
              responseBody['body'] ??
              {"message": responseBody['message'] ?? "Unexpected error"},
        };
      }
    } catch (e) {
      return {
        "statusCode": 500,
        "body": {"message": "Something went wrong", "error": e.toString()},
      };
    }
  }

  //Register patient
  Future<Map<String, dynamic>> registerPatient(
    Map<String, dynamic> patientData,
  ) async {
    final url = Uri.parse('$baseUrl/register-patient');

    try {
      final response = await http.post(
        url,
        body: jsonEncode(patientData),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": jsonDecode(response.body)['message'] ?? "Unknown error",
        };
      }
    } catch (e) {
      return {"error": "Failed to register patient"};
    }
  }

  // Get Patient Details by Phone Number
  Future<Map<String, dynamic>> getPatientDetails(String phoneNumber) async {
    try {
      final url = Uri.parse('$baseUrl/get-patient-details');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': e.toString()},
      };
    }
  }
}
