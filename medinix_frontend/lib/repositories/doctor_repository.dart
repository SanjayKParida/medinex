import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/models.dart';
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
        body: jsonEncode({"doctorId": doctorLoginId, "password": password}),
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

  //Get Doctor's Patients
  Future<Map<String, dynamic>> getDoctorPatients() async {
    try {
      // Reset the singleton data
      DoctorPatients().patientsLoaded = false;
      DoctorPatients().errorMessage = null;
      DoctorPatients().patientsList = [];

      // Get doctor ID from shared preferences
      final userDetails = _prefsService.getUserDetails();
      final doctorId = userDetails?['doctorId'];
      print("doctor id: $doctorId");

      if (doctorId == null) {
        DoctorPatients().errorMessage =
            "Doctor ID not found. Please log in again.";
        return {'success': false, 'message': DoctorPatients().errorMessage};
      }

      final url = Uri.parse('$baseUrl/get-doctor-patients');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorId': doctorId}),
      );

      final responseData = jsonDecode(response.body);
      print("Patient response: $responseData");

      // Access the body object from the response
      final body = responseData['body'] ?? responseData;
      final isSuccess = body['response'] == true;

      if (response.statusCode == 200 && isSuccess) {
        final List<dynamic> patientsData = body['data'] ?? [];

        // Convert dynamic list to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> patients =
            patientsData
                .map((patient) => Map<String, dynamic>.from(patient))
                .toList();

        // Store patients in the singleton
        DoctorPatients().patientsList = patients;
        DoctorPatients().patientsLoaded = true;

        return {'success': true, 'data': patients};
      } else {
        final errorMsg =
            body['message'] ?? "Failed to fetch patients. Please try again.";
        DoctorPatients().errorMessage = errorMsg;
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      final errorMsg = "An error occurred: $e";
      DoctorPatients().errorMessage = errorMsg;
      return {'success': false, 'message': errorMsg};
    }
  }

  // Get a specific patient by ID
  Future<Map<String, dynamic>> getPatientById(String patientId) async {
    try {
      // Check if patients are already loaded in the singleton
      if (DoctorPatients().patientsLoaded) {
        // Try to find patient in existing data first
        final patient = DoctorPatients().patientsList.firstWhere(
          (patient) => patient['patientId'] == patientId,
          orElse: () => <String, dynamic>{},
        );

        if (patient.isNotEmpty) {
          return {'success': true, 'data': patient};
        }
      }

      // If not found in cache or cache not loaded, fetch all patients
      final result = await getDoctorPatients();

      if (result['success'] == true) {
        // Try to find patient in newly fetched data
        final patient = DoctorPatients().patientsList.firstWhere(
          (patient) => patient['patientId'] == patientId,
          orElse: () => <String, dynamic>{},
        );

        if (patient.isNotEmpty) {
          return {'success': true, 'data': patient};
        } else {
          return {'success': false, 'message': 'Patient not found'};
        }
      } else {
        return result; // Pass through the error from getDoctorPatients
      }
    } catch (e) {
      final errorMsg = "Error fetching patient: $e";
      return {'success': false, 'message': errorMsg};
    }
  }

  Future<Map<String, dynamic>> updateDoctorDetails({
    required String doctorId,
    required String patientId,
    required String action,
  }) async {
    try {
      print("➡️ Updating doctor details - Action: $action");
      final response = await http.post(
        Uri.parse('$baseUrl/update-doctor-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': doctorId,
          'patientId': patientId,
          'action': action,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("➡️ Doctor update response: $responseData");

      if (response.statusCode == 200) {
        // Get latest doctor data to verify the update
        final doctorDetails = await getDoctorDetails(doctorId);
        print("➡️ Latest doctor data: ${doctorDetails['body']}");

        return {
          'statusCode': response.statusCode,
          'success': true,
          'body': responseData,
          'message':
              action == "remove"
                  ? 'Patient removed from doctor\'s patient list successfully'
                  : 'Patient added to doctor\'s patient list successfully',
        };
      } else {
        return {
          'statusCode': response.statusCode,
          'success': false,
          'body': {
            'message':
                responseData['message'] ?? 'Failed to update doctor details',
          },
        };
      }
    } catch (e) {
      print("➡️ Error updating doctor details: $e");
      return {
        'statusCode': 500,
        'success': false,
        'body': {'message': 'Error updating doctor details: $e'},
      };
    }
  }
}
