import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/models.dart';

class PatientHomeScreenRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, dynamic>> getPatientAppointments(String patientId) async {
    try {
      final url = Uri.parse('$baseUrl/get-appointments-by-patient-id');
      final response = await http.post(
        url,
        body: jsonEncode({"patientId": patientId}),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['body']['response'] == true) {
        print("patient appoinments :: ${data['body']['appointments']}");

        for (var json in data['body']['appointments']) {
          PatientAppointments().patientAppointmentsList.add(
            PatientAppointmentModel.fromJson(json),
          );
        }
        print(
          "Patient Appointments from the API ${PatientAppointments().patientAppointmentsList}",
        );

        return {
          "success": true,
          "message": data['body']['message'],
          "appointments": data['body']['appointments'],
        };
      } else {
        return {
          "success": false,
          "message": data['body']['message'] ?? "Unknown error",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Failed to fetch appointments : $e"};
    }
  }

  Future<Map<String, dynamic>> getVerifiedDoctors() async {
    final url = Uri.parse('$baseUrl/get-verified-doctors');

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("getVerifiedDoctors called");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['body']['response'] == true) {
        print("verified doctors data :: ${data['body']['doctors']}");

        for (var json in data['body']['doctors']) {
          ApprovedDoctors().verifiedDoctorsList.add(
            VerifiedDoctor.fromJson(json),
          );
        }
        print(
          "Approved Doctors from the API ${ApprovedDoctors().verifiedDoctorsList}",
        );

        return {
          "success": true,
          "message": data['body']['message'],
          "verifiedDoctors": data['body']['doctors'],
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
        "message": "Failed to get doctor List: ${e.toString()}",
      };
    }
  }
}
