import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BookingRepo {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  //Create appointment
  Future<Map<String, dynamic>> createAppointment(
    String patientId,
    String doctorId,
    String date,
    String time,
  ) async {
    final url = Uri.parse('$baseUrl/add-appointment');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "doctorId": doctorId,
          "patientId": patientId,
          "date": date,
          "time": time,
          "reason": "General Checkup",
        }),
      );

      final data = jsonDecode(response.body);
      print("appointment booked :: ${data['body']['message']}");

      if (response.statusCode == 200) {
        print("appointment data :: ${data['body']}");

        return {"success": true, "appointmentMessage": data['body']['message']};
      } else {
        return {
          "success": false,
          "message": data['body']['message'] ?? "Unknown error",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Failed to book appointment: ${e.toString()}",
      };
    }
  }

  //Get available slots
  Future<Map<String, dynamic>> getAvailableSlots(
    String doctorId,
    String date,
  ) async {
    final url = Uri.parse('$baseUrl/get-available-slots');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({"doctorId": doctorId, "date": date}),
        headers: {"Content-Type": "application/json"},
      );

      final data = jsonDecode(response.body);
      print("Available slots :: $data");

      if (response.statusCode == 200) {
        print("response data :: ${data['body']}");

        return {
          "success": true,
          "availableSlots": data['body']['availableSlots'],
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
}
