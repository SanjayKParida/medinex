import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medinix_frontend/utilities/patient_data_service.dart';

class AiRepository {
  static final PatientDataService _patientDataService =
      PatientDataService.getInstance();
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  // Replace with your actual API base URL

  Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    try {
      final url = Uri.parse('$baseUrl/log-symptoms');
      print("medical history: ${_patientDataService.medicalHistory}");
      print("patient id: ${_patientDataService.patientId}");
      print("symptoms: $symptoms");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentSymptoms': symptoms,
          'medicalHistory': _patientDataService.medicalHistory,
          'notes': '',
          'patientId': _patientDataService.patientId,
        }),
      );
      print("AI response: ${response.body}");

      if (response.statusCode == 200) {
        // Create a map to store the extracted data
        final Map<String, dynamic> extractedData = {
          'possibleConditions': <String>[],
          'riskLevel': 'Unknown',
          'suggestions': <String>[],
        };

        try {
          final responseData = json.decode(response.body);
          print("responseData in 200: $responseData");

          // The insights field is nested inside the body field
          String? insightsStr;

          // Handle different response structures
          if (responseData is Map<String, dynamic>) {
            // Check if this is the body-wrapped response
            if (responseData.containsKey('body') &&
                responseData['body'] is String) {
              // Parse the body string, which is a JSON string
              final bodyData = json.decode(responseData['body']);
              if (bodyData is Map<String, dynamic> &&
                  bodyData.containsKey('insights')) {
                insightsStr = bodyData['insights'];
              }
            }
            // Direct access if insights is at the top level
            else if (responseData.containsKey('insights')) {
              insightsStr = responseData['insights'];
            }
          }

          print("Insights string: $insightsStr");

          // Only proceed with extraction if insightsStr is not null
          if (insightsStr != null) {
            // Extract possible conditions
            final possibleConditionsMatch = RegExp(
              r'possible_conditions\s*:\s*(.*?)(?=,\s*risk_level|$)',
              dotAll: true,
            ).firstMatch(insightsStr);
            if (possibleConditionsMatch != null &&
                possibleConditionsMatch.group(1) != null) {
              final conditionsStr = possibleConditionsMatch.group(1)!.trim();
              extractedData['possibleConditions'] =
                  conditionsStr.split(',').map((c) => c.trim()).toList();
            }

            // Extract risk level
            final riskLevelMatch = RegExp(
              r'risk_level\s*:\s*(.*?)(?=,\s*suggestions|$)',
              dotAll: true,
            ).firstMatch(insightsStr);
            if (riskLevelMatch != null && riskLevelMatch.group(1) != null) {
              extractedData['riskLevel'] = riskLevelMatch.group(1)!.trim();
            }

            // Extract suggestions
            final suggestionsMatch = RegExp(
              r'suggestions\s*:\s*(.*?)$',
              dotAll: true,
            ).firstMatch(insightsStr);
            if (suggestionsMatch != null && suggestionsMatch.group(1) != null) {
              final suggestionsStr = suggestionsMatch.group(1)!.trim();
              extractedData['suggestions'] =
                  suggestionsStr.split(',').map((s) => s.trim()).toList();
            }
          } else {
            print("Warning: insights is null in the response");
          }
        } catch (e) {
          print("Error parsing response: $e");
          // We'll return the default extractedData with empty values
        }

        return extractedData;
      } else {
        throw Exception('Failed to analyze symptoms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing symptoms: $e');
      rethrow;
    }
  }
}
