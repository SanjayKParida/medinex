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

  //Get health logs
  Future<Map<String, dynamic>> getHealthLogs(String patientId) async {
    try {
      final url = Uri.parse('$baseUrl/get-health-logs');
      print("Requesting health logs from: $url");
      print("Request body: ${jsonEncode({'patientId': patientId})}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patientId': patientId}),
      );

      print(
        "Health logs API raw response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Health logs response parsed data: $responseData");

        // Check if the response has a body field that is a JSON string
        if (responseData.containsKey('body') &&
            responseData['body'] is String) {
          try {
            // Parse the inner JSON string in the body field
            final bodyData = jsonDecode(responseData['body']);
            print("Parsed body data: $bodyData");

            if (bodyData.containsKey('healthLogs')) {
              return {
                'statusCode': response.statusCode,
                'error': null,
                'healthLogs': bodyData['healthLogs'] ?? [],
              };
            }
          } catch (e) {
            print("Error parsing body JSON: $e");
          }
        }

        // Fallback to existing logic if the above path fails
        final dynamic dataToUse =
            responseData.containsKey('body')
                ? (responseData['body'] is String
                    ? jsonDecode(responseData['body'])
                    : responseData['body'])
                : responseData;

        print("Data after extracting body if needed: $dataToUse");

        // Handle various potential response formats
        final List<dynamic> healthLogs = [];

        if (dataToUse is Map) {
          if (dataToUse.containsKey('healthLogs')) {
            healthLogs.addAll(dataToUse['healthLogs'] ?? []);
          } else if (dataToUse.containsKey('data')) {
            healthLogs.addAll(dataToUse['data'] ?? []);
          }
        }

        print("Extracted health logs: $healthLogs");

        return {
          'statusCode': response.statusCode,
          'error': null,
          'healthLogs': healthLogs,
        };
      } else {
        String errorMessage = "Unknown error";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ??
              (errorData['body'] != null
                  ? (errorData['body']['message'] ?? "Unknown error")
                  : "Unknown error");
        } catch (e) {
          errorMessage = "Could not parse error response: ${response.body}";
        }

        print("Error getting health logs: $errorMessage");
        return {
          'statusCode': response.statusCode,
          'error': errorMessage,
          'healthLogs': [],
        };
      }
    } catch (e) {
      print("Exception getting health logs: $e");
      return {
        'statusCode': 500,
        'error': "Failed to get health logs: $e",
        'healthLogs': [],
      };
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

  Future<Map<String, dynamic>> updatePatientDetails({
    required String patientId,
    required String doctorId,
    required String action,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-patient-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'action': action,
        }),
      );
      print("doctorID: $doctorId");
      final responseData = jsonDecode(response.body);
      print("responseData: $responseData");
      if (response.statusCode == 200) {
        // Fetch latest patient data and update SharedPreferences
        final detailsResult = await getPatientDetails(
          responseData['body']?['patientData']?['phoneNumber'] ?? '',
        );
        if (detailsResult['statusCode'] == 200 &&
            detailsResult['body']['response'] == true &&
            detailsResult['body']['patientData'] != null) {
          final latestPatientData = detailsResult['body']['patientData'];
          await _prefsService.saveUserData("patient", latestPatientData);
        }
        return {
          'statusCode': response.statusCode,
          'success': true,
          'body': responseData,
          'message': 'Doctor assigned to patient successfully',
        };
      } else {
        return {
          'statusCode': response.statusCode,
          'success': false,
          'body': {
            'message':
                responseData['message'] ?? 'Failed to update patient details',
          },
        };
      }
    } catch (e) {
      return {
        'statusCode': 500,
        'success': false,
        'body': {'message': 'Error updating patient details: $e'},
      };
    }
  }
}
