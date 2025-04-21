import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void showQRCodeBottomSheet(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final String secureKey = dotenv.env['SECURE_KEY']!;
  final String? websocketUrl = dotenv.env['WEBSOCKET_API_ENDPOINT'];
  print("websocketUrl: $websocketUrl");

  // Retrieve and decode userData Map from SharedPreferences
  final userDataString = prefs.getString('userData');
  if (userDataString == null) return;

  //Payload encryption function
  String encryptPayload(String data, String key) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.cbc),
    );
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  //Encrypted data
  final encryptedData = encryptPayload(userDataString, secureKey);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return websocketUrl != null
          ? WebSocketQRSheet(
            encryptedData: encryptedData,
            websocketUrl: websocketUrl,
          )
          : QRSheetContent(encryptedData: encryptedData);
    },
  );
}

class WebSocketQRSheet extends StatefulWidget {
  final String encryptedData;
  final String websocketUrl;

  const WebSocketQRSheet({
    super.key,
    required this.encryptedData,
    required this.websocketUrl,
  });

  @override
  State<WebSocketQRSheet> createState() => _WebSocketQRSheetState();
}

class _WebSocketQRSheetState extends State<WebSocketQRSheet> {
  WebSocketChannel? _channel;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    // Connect to websocket
    _connectWebSocket();
  }

  @override
  void dispose() {
    // Close websocket connection
    _closeWebSocket();
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      final userDetails =
          SharedPreferencesService.getInstance().getUserDetails();
      _patientId = userDetails?['patientId'];

      if (_patientId == null) return;

      _channel = WebSocketChannel.connect(Uri.parse(widget.websocketUrl));

      // Register connection with user ID
      _channel!.sink.add(
        jsonEncode({
          'action': 'register',
          'data': {'userId': _patientId},
        }),
      );

      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);

          // Handle doctor appointment request
          if (data['type'] == 'doctor_request') {
            final doctorId = data['doctorId'];

            // Show a dialog to accept or reject appointment
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: Text('Doctor Appointment Request'),
                    content: Text(
                      'A doctor is requesting to see you. Do you accept?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Send rejection response
                          _channel!.sink.add(
                            jsonEncode({
                              'action': 'respond_appointment',
                              'data': {
                                'response': 'rejected',
                                'doctorId': doctorId,
                                'patientId': _patientId,
                              },
                            }),
                          );
                          Navigator.pop(context);
                        },
                        child: Text('Reject'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Send acceptance response
                          _channel!.sink.add(
                            jsonEncode({
                              'action': 'respond_appointment',
                              'data': {
                                'response': 'accepted',
                                'doctorId': doctorId,
                                'patientId': _patientId,
                              },
                            }),
                          );

                          // Update patient details with the doctorId
                          _updatePatientDoctorId(doctorId);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You have accepted the doctor\'s request',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text('Accept'),
                      ),
                    ],
                  ),
            );
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  void _updatePatientDoctorId(String doctorId) async {
    try {
      // Update in memory
      PatientDetails.patientDetails.doctorID = doctorId;

      final userData = await SharedPreferences.getInstance();

      // Get current user data JSON
      final userDataString = userData.getString('userData');
      if (userDataString != null) {
        final userDetails = jsonDecode(userDataString);
        userDetails['doctorId'] = doctorId;

        // Save updated data
        await userData.setString('userData', jsonEncode(userDetails));
      }

      print('Patient doctorId updated to: $doctorId');
    } catch (e) {
      print('Error updating patient doctorId: $e');
    }
  }

  void _closeWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
      print('WebSocket connection closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return QRSheetContent(encryptedData: widget.encryptedData);
  }
}

class QRSheetContent extends StatelessWidget {
  final String encryptedData;

  const QRSheetContent({super.key, required this.encryptedData});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.65,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: SizedBox(
            width: screenWidth,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),  
                  const SizedBox(height: 20),
                  Text(
                    "🧾 Patient QR Code",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  //Secure QR generation
                  QrImageView(
                    data: encryptedData,
                    version: QrVersions.auto,
                    size: MediaQuery.of(context).size.width * 0.8,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Patient ID : ${SharedPreferencesService.getInstance().getUserDetails()!['patientId']}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
