import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class LoginRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  final SharedPreferencesService _prefsService =
      SharedPreferencesService.getInstance();

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

  //Doctor login function
  Future<Map<String, dynamic>> loginDoctor(
    String doctorLoginId,
    String password,
  ) async {
    final url = Uri.parse('${baseUrl}login-doctor');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "doctorLoginId": doctorLoginId,
          "password": password,
        }),
        headers: {"Content-Type": "application/json"},
      );

      final responseBody = jsonDecode(response.body);
      print("doctor response body: $responseBody");

      final logicalStatusCode = responseBody['statusCode'];
      final httpStatusCode = response.statusCode;

      print("HTTP status code: $httpStatusCode");
      print("Logical status code: $logicalStatusCode");

      final body = responseBody['body'] ?? {};

      if (logicalStatusCode == 200 && body['doctorData'] != null) {
        final doctorData = body['doctorData'];
        await _prefsService.saveUserData("doctor", doctorData);

        return {
          "statusCode": logicalStatusCode,
          "isApproved": doctorData["isApproved"],
          "body": body,
        };
      } else if (logicalStatusCode == 404) {
        return {
          "statusCode": 404,
          "doctorFound": false,
          "body": {"message": body['message'] ?? "Doctor not found"},
        };
      } else {
        return {
          "statusCode": logicalStatusCode,
          "body": {
            "message":
                body['message'] ?? responseBody['message'] ?? "Unknown error",
          },
        };
      }
    } catch (e) {
      print("Error in loginDoctor: $e");
      return {
        "statusCode": 500,
        "body": {"message": "Something went wrong", "error": e.toString()},
      };
    }
  }

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

  // ✅ Get Doctor Details by doctorLoginId
  Future<Map<String, dynamic>> getDoctorDetails(String doctorLoginId) async {
    try {
      final url = Uri.parse('$baseUrl/get-doctor-details');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorLoginId': doctorLoginId}),
      );

      final responseData = jsonDecode(response.body);

      return {'statusCode': response.statusCode, 'body': responseData};
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': e.toString()},
      };
    }
  }

  Future<Map<String, dynamic>> registerDoctor(
    Map<String, dynamic> doctorData,
  ) async {
    final url = Uri.parse('$baseUrl/register-doctor');

    try {
      final response = await http.post(
        url,
        body: jsonEncode(doctorData),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": jsonDecode(response.body)['message'] ?? "Unknown error",
        };
      }
    } catch (e) {
      return {"error": "Failed to register doctor: ${e.toString()}"};
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

  Future<void> handleRegisterDoctor(Map<String, dynamic> doctorData) async {
    final result = await registerDoctor(doctorData);

    if (result.containsKey("body") &&
        result["body"]["response"] == true &&
        result["body"].containsKey("doctorData")) {
      final userData = result["body"]["doctorData"];
      final sharedPrefService = SharedPreferencesService.getInstance();
      await sharedPrefService.init();

      // Save the doctor data and type
      await sharedPrefService.saveUserData("doctor", userData);
    } else {
      final error =
          result["body"]?["message"] ?? result["error"] ?? "Unknown error";
      throw Exception(error);
    }
  }

  Future<void> handleRegisterPatient(Map<String, dynamic> patientData) async {
    final result = await LoginRepo().registerPatient(patientData);

    if (result.containsKey("body") &&
        result["body"]["response"] == true &&
        result["body"].containsKey("userData")) {
      final userData = result["body"]["userData"];
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
