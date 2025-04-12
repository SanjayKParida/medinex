import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class DoctorRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final SharedPreferencesService _prefsService =
      SharedPreferencesService.getInstance();





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

      print("called");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['body']['response'] == true) {
        print("response data :: ${data['body']}");

        return {
          "success": true,
          "message": data['body']['message'],
          "doctorData": data['body']['doctorData'],
        };
      } else {
        return {
          "success": false,
          "message": data['body']['message'] ?? "Unknown error",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Failed to register doctor: ${e.toString()}",
      };
    }
  }

  //Get Doctor Details by doctorLoginId
  Future<Map<String, dynamic>> getDoctorDetails(String doctorId) async {
    try {
      final url = Uri.parse('$baseUrl/get-doctor-details');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorId': doctorId}),
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
}
