import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AppointmentRepository {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/add-appointment');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(appointmentData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['body'] ?? data,
          'message':
              data['body']?['message'] ?? 'Appointment created successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['body']?['message'] ?? 'Failed to create appointment',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> getAppointments({
    String? doctorId,
    String? patientId,
    String? status,
  }) async {
    try {
      Map<String, dynamic> requestBody = {};

      if (doctorId != null) requestBody['doctorId'] = doctorId;
      if (patientId != null) requestBody['patientId'] = patientId;

      final url =
          doctorId != null
              ? Uri.parse('$baseUrl/get-appointment-by-doctor-id')
              : Uri.parse('$baseUrl/get-appointments-by-patient-id');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'appointments': data['body']?['appointments'] ?? [],
          'message':
              data['body']?['message'] ?? 'Appointments fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['body']?['message'] ?? 'Failed to fetch appointments',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/update-appointment-status');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'appointmentId': appointmentId, 'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['body'] ?? data,
          'message':
              data['body']?['message'] ??
              'Appointment status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              data['body']?['message'] ?? 'Failed to update appointment status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
