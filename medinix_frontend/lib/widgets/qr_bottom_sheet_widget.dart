import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medinix_frontend/utilities/patient_data_service.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:medinix_frontend/repositories/patient_repository.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';

/// Shows a WebSocket connection bottom sheet
Future<void> showQRCodeBottomSheet(
  BuildContext context, {
  String? patientId,
}) async {
  // Get patient ID from service if not provided
  String pid = patientId ?? '';
  debugPrint(
    'QR SHEET: Initial patientId parameter: ${pid.isEmpty ? "EMPTY" : pid}',
  );

  if (pid.isEmpty) {
    try {
      final patientDataService = PatientDataService.getInstance();

      // Initialize the service - this is safe to call even if already initialized
      debugPrint('QR SHEET: Ensuring PatientDataService is initialized');
      await patientDataService.init();

      // Try to refresh patient data
      await patientDataService.refreshPatientData();

      // Get the patient ID
      pid = patientDataService.patientId;
      debugPrint(
        'QR SHEET: Got patient ID from service: ${pid.isEmpty ? "EMPTY" : pid}',
      );

      // If still empty, let's see if we can find it elsewhere
      if (pid.isEmpty) {
        debugPrint(
          'QR SHEET: PatientDataService not providing ID, checking for alternatives',
        );
        // Add any alternative ways to get the patient ID

        // For testing, we could use a placeholder ID
        pid = 'TEST-PATIENT-ID';
        debugPrint('QR SHEET: Using test patient ID for debugging: $pid');
      }
    } catch (e) {
      debugPrint('QR SHEET: Error getting patient ID from service: $e');
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WebSocketConnectionSheet(patientId: pid),
  );
}

class WebSocketConnectionSheet extends StatefulWidget {
  final String patientId;

  const WebSocketConnectionSheet({super.key, required this.patientId});

  @override
  State<WebSocketConnectionSheet> createState() =>
      _WebSocketConnectionSheetState();
}

class _WebSocketConnectionSheetState extends State<WebSocketConnectionSheet> {
  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  Timer? _pingTimer;

  // Connection state
  bool _isConnected = false;
  bool _isRegistered = false;
  String? _connectionId;
  String _connectionStatus = 'Initializing...';
  bool _patientIdMissing = false;

  // QR Code state
  String _qrData = '';
  bool _showQrCode = false;
  Timer? _qrRefreshTimer;
  bool _qrCodeScanned = false;
  PatientDataService? _patientDataService;
  SharedPreferencesService? _prefsService;

  // Connection attempt tracking
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 3;
  bool _isDisposed = false;

  // Logs for debugging
  final List<String> _logs = [];

  final PatientRepo _patientRepo = PatientRepo();
  final DoctorRepo _doctorRepo = DoctorRepo();
  late String? currentDoctorId;

  bool _hasDoctorLinked = false;

  @override
  void initState() {
    currentDoctorId = _patientDataService?.doctorId;
    super.initState();
    debugPrint('WS: Initializing WebSocket sheet');
    _isDisposed = false;
    _patientDataService = PatientDataService.getInstance();
    _prefsService = SharedPreferencesService.getInstance();
    // Check if patient ID is available
    if (widget.patientId.isEmpty) {
      debugPrint('WS: WARNING: Patient ID is empty!');
      setState(() {
        _patientIdMissing = true;
        _connectionStatus = 'Cannot connect: Patient ID is missing';
      });
    } else {
      debugPrint('WS: Patient ID available: ${widget.patientId}');
      // Check if patient already has a doctor linked

      debugPrint(
        'WS: Doctor linked to patient? ${currentDoctorId != null && currentDoctorId!.isNotEmpty ? "YES ($currentDoctorId)" : "NO"}',
      );
      if (currentDoctorId != null && currentDoctorId!.isNotEmpty) {
        setState(() {
          _hasDoctorLinked = true;
          _connectionStatus = 'Doctor already linked';
        });
        // Do not connect to WebSocket or show QR
        return;
      }
      // Only generate QR and connect if no doctor is linked
      _generateQrData();
      Future.microtask(() {
        if (!_isDisposed) {
          _connectWebSocket();
          _qrRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
            if (!_qrCodeScanned) {
              _generateQrData();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Use direct console output instead of _log to prevent setState during disposal
    debugPrint('WS: Disposing WebSocket sheet');

    // Cancel timers and subscriptions
    _pingTimer?.cancel();
    _qrRefreshTimer?.cancel();
    _streamSubscription?.cancel();

    // Close WebSocket channel
    if (_channel != null) {
      try {
        _channel!.sink.close();
        debugPrint('WS: WebSocket channel closed during disposal');
      } catch (e) {
        debugPrint('WS: Error closing WebSocket during disposal: $e');
      }
      _channel = null;
    }

    super.dispose();
  }

  // Generate QR code data in the format expected by the doctor's scanner
  void _generateQrData() {
    try {
      // Get additional patient information if available
      String name = _patientDataService?.patientName ?? 'Unknown';
      String phoneNumber = _patientDataService?.phoneNumber ?? '';
      String dateOfBirth = '';
      List<String> symptoms = [];

      // Create a JSON object with patient data for QR code
      // This format must match what's expected by the QR scanner in doctor's app
      final patientData = {
        'patientId': widget.patientId,
        'name': name,
        'phone': phoneNumber,
        'dob': dateOfBirth,
        'symptoms': symptoms,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      // Convert to JSON string
      _qrData = jsonEncode(patientData);
      _log('Generated QR data: $_qrData');

      if (mounted && !_isDisposed) {
        setState(() {
          _showQrCode = true;
        });
      }
    } catch (e) {
      _log('Error generating QR data: $e');
      // Fallback to a simpler format if there's an error
      final fallbackData = {'patientId': widget.patientId};
      _qrData = jsonEncode(fallbackData);
    }
  }

  // Add a log entry
  void _log(String message) {
    // Always print to console regardless of widget state
    debugPrint('WS: $message');

    // Only update UI state if widget is still mounted
    if (mounted && !_isDisposed) {
      setState(() {
        _logs.add('${DateTime.now().toString().split('.')[0]}: $message');
        if (_logs.length > 30) _logs.removeAt(0);
      });
    }
  }

  // Clean up all connection resources
  void _cleanupConnection() {
    // Just print to console here, don't use _log to avoid setState during disposal
    debugPrint('WS: Cleaning up WebSocket resources');

    // Cancel ping timer
    _pingTimer?.cancel();
    _pingTimer = null;

    // Cancel stream subscription
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Close channel if open
    if (_channel != null) {
      try {
        _channel!.sink.close();
        debugPrint('WS: WebSocket channel closed');
      } catch (e) {
        debugPrint('WS: Error closing WebSocket: $e');
      }
      _channel = null;
    }

    // Reset state if component is still mounted
    if (mounted && !_isDisposed) {
      setState(() {
        _isConnected = false;
        _isRegistered = false;
        _connectionStatus = 'Disconnected';
      });
    }

    // Reset connection attempts counter
    _connectionAttempts = 0;
  }

  // Connect to WebSocket
  Future<void> _connectWebSocket() async {
    // Prevent connection if disposed
    if (_isDisposed) return;

    // Check max connection attempts
    if (_connectionAttempts >= _maxConnectionAttempts) {
      _log('Maximum connection attempts reached. Please try again later.');
      _updateStatus('Connection failed - too many attempts');
      return;
    }

    _connectionAttempts++;

    // Clean up any existing connection first
    _cleanupConnection();

    if (mounted && !_isDisposed) {
      setState(() {
        _connectionStatus = 'Connecting...';
      });
    }

    // Get WebSocket URL from env
    final wsUrl = dotenv.env['WEBSOCKET_API_ENDPOINT'];
    if (wsUrl == null || wsUrl.isEmpty) {
      _log('WebSocket URL not configured in .env file');
      _updateStatus('Missing WebSocket URL configuration');
      return;
    }

    _log('WebSocket URL from env: $wsUrl');

    try {
      // Convert URL to proper WebSocket format
      final uri = Uri.parse(wsUrl);

      // Ensure we're using the correct scheme
      // AWS API Gateway uses wss:// for secure WebSockets
      String scheme;
      if (uri.scheme == 'wss' || uri.scheme == 'ws') {
        // Already using WebSocket scheme, maintain it
        scheme = uri.scheme;
      } else if (uri.scheme == 'https') {
        scheme = 'wss';
      } else if (uri.scheme == 'http') {
        scheme = 'ws';
      } else {
        // Default to secure WebSocket if scheme is unknown
        scheme = 'wss';
      }

      final connectionUrl =
          Uri(
            scheme: scheme,
            host: uri.host,
            path: uri.path,
            queryParameters:
                uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
          ).toString();

      _log('Connecting to: $connectionUrl');

      // Create fresh WebSocket connection - use IOWebSocketChannel for better platform compatibility
      try {
        if (scheme == 'wss') {
          // For secure connections
          _channel = IOWebSocketChannel.connect(
            connectionUrl,
            pingInterval: const Duration(seconds: 20),
          );
        } else {
          // For non-secure connections
          _channel = WebSocketChannel.connect(Uri.parse(connectionUrl));
        }
      } catch (e) {
        _log('Error creating WebSocket channel: $e');
        _updateStatus('Failed to create connection');
        return;
      }

      if (_channel == null) {
        _log('Failed to create WebSocket channel');
        _updateStatus('Connection failed');
        return;
      }

      // Listen for messages with error handling
      _streamSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Set up ping to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendPing();
      });

      // Update state to connected if still mounted
      if (mounted && !_isDisposed) {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected, waiting for registration';
        });
      }

      // Send registration after a short delay to ensure connection is stable
      await Future.delayed(const Duration(milliseconds: 500));

      // Check again if still mounted before sending registration
      if (!_isDisposed && _channel != null) {
        _sendRegistration();
      }
    } catch (e) {
      _log('Error connecting to WebSocket: $e');
      _updateStatus('Connection failed');
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    // Skip processing if disposed
    if (_isDisposed) return;

    _log('Received: $message');

    try {
      // Check if the message is valid JSON
      // First, try to determine if it's a string or already parsed data
      String messageStr = message.toString();

      // Some messages might be plain text instead of JSON
      // Check if the message starts with { or [ which indicates JSON
      if (messageStr.trim().startsWith('{') ||
          messageStr.trim().startsWith('[')) {
        // Try to parse JSON
        final data = jsonDecode(messageStr);

        // Extract connectionId if available
        if (data is Map && data.containsKey('connectionId')) {
          _connectionId = data['connectionId'].toString();
          _log('Connection ID: $_connectionId');
        }

        // Check for doctor_request message - a doctor has scanned the QR code
        if (data is Map &&
            data.containsKey('type') &&
            data['type'] == 'doctor_request') {
          _handleDoctorRequest(Map<String, dynamic>.from(data));
          return;
        }

        // Check for registration confirmation
        if (data is Map && data.containsKey('message')) {
          final msg = data['message'].toString().toLowerCase();

          if (msg.contains('registered') || msg.contains('success')) {
            if (mounted && !_isDisposed) {
              setState(() {
                _isRegistered = true;
                _connectionStatus = 'Connected and registered';
              });
            }
            _log('Registration successful');
          } else if (msg.contains('error')) {
            _log('Server reported error: ${data['message']}');
            _updateStatus('Server error: ${data['message']}');
          }
        }
      } else {
        // Handle plain text messages
        final textMessage = messageStr.toLowerCase();

        // Check if it's a registration confirmation
        if (textMessage.contains('registered') ||
            textMessage.contains('success')) {
          if (mounted && !_isDisposed) {
            setState(() {
              _isRegistered = true;
              _connectionStatus = 'Connected and registered';
            });
          }
          _log('Registration confirmation received (text format)');
        } else if (textMessage.contains('error')) {
          _log('Server reported error (text format): $messageStr');
          _updateStatus('Server error: $messageStr');
        } else {
          // Handle other text messages (ping responses, etc.)
          _log('Received text message: $messageStr');
        }
      }
    } catch (e) {
      _log('Error processing message: $e');
    }
  }

  // Handle doctor scan request
  void _handleDoctorRequest(Map<String, dynamic> data) async {
    _log('Doctor has scanned your QR code');
    setState(() {
      _qrCodeScanned = true;
    });
    final doctorId = data['doctorId'] ?? 'Unknown';
    final doctorName = data['doctorName'] ?? 'Doctor';
    final specialization = data['specialization'] ?? '';
    _log(
      'Doctor: $doctorName ($specialization), ID: $doctorId wants to connect',
    );

    // Check if patient already has a doctor linked
    String? currentDoctorId = _patientDataService?.doctorId;
    print("currentDoctorId: $currentDoctorId");
    if (currentDoctorId != null && currentDoctorId.isNotEmpty) {
      // Show dialog to remove current doctor
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Doctor Already Linked'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You already have a doctor linked to your account.'),
                  SizedBox(height: 8),
                  Text('Doctor ID: $currentDoctorId'),
                  SizedBox(height: 16),
                  Text(
                    'To link a new doctor, please remove the current doctor.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    'Remove Doctor',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    try {
                      // Remove doctorId from patient
                      final patientResult = await _patientRepo
                          .updatePatientDetails(
                            action: 'remove',
                            patientId: widget.patientId,
                            doctorId: '',
                          );
                      print("patient result :: $patientResult");

                      if (patientResult['success'] == true) {
                        // Only try to update doctor if patient update was successful
                        final doctorResult = await _doctorRepo
                            .updateDoctorDetails(
                              action: 'remove',
                              doctorId: currentDoctorId,
                              patientId: '',
                            );
                        print("doctor result :: $doctorResult");

                        // Always close the confirmation dialog first
                        Navigator.of(dialogContext).pop();

                        if (doctorResult['success'] == true) {
                          // Get latest patient data to update SharedPreferences
                          final phoneNumber = _patientDataService?.phoneNumber;
                          print("phone number for refresh :: $phoneNumber");
                          if (phoneNumber != null && phoneNumber.isNotEmpty) {
                            final result = await _patientRepo.getPatientDetails(
                              phoneNumber,
                            );
                            print("get patient details result :: $result");
                            if (result['statusCode'] == 200 &&
                                result['body']['body']['response'] == true &&
                                result['body']['body']['patientData'] != null) {
                              final latestPatientData =
                                  result['body']['body']['patientData'];
                              await _prefsService?.saveUserData(
                                "patient",
                                latestPatientData,
                              );
                              await _patientDataService?.refreshPatientData();

                              setState(() {
                                _hasDoctorLinked = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Doctor removed successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } else {
                          String errorMessage =
                              doctorResult['body']?['message'] ??
                              'Failed to update doctor details';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        // Close dialog and show patient update error
                        Navigator.of(dialogContext).pop();
                        String errorMessage =
                            patientResult['body']?['message'] ??
                            'Failed to update patient details';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Close dialog if still open
                      Navigator.of(dialogContext).pop();
                      print("Error removing doctor: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error removing doctor: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // If no doctor linked, proceed as before
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Doctor Connection Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $doctorName ($specialization) would like to connect with you.',
                ),
                SizedBox(height: 16),
                Text('Do you want to accept this connection request?'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Decline'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _sendConnectionResponse(doctorId, false);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text('Accept', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  _sendConnectionResponse(doctorId, true);
                  // Update patient document with doctorId
                  final result = await _patientRepo.updatePatientDetails(
                    patientId: widget.patientId,
                    doctorId: doctorId,
                    action: 'add',
                  );
                  if (result['success'] == true) {
                    await _patientDataService?.refreshPatientData();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Doctor assigned successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to assign doctor: '
                          '${result['body']?['message'] ?? 'Unknown error'}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Send connection response to doctor
  void _sendConnectionResponse(String doctorId, bool accepted) {
    if (!_isConnected || !_isRegistered || _channel == null) {
      _log('Cannot respond: WebSocket not ready');
      return;
    }

    try {
      final responseMessage = {
        'action': 'connection_response',
        'data': {
          'doctorId': doctorId,
          'patientId': widget.patientId,
          'response': accepted ? 'accepted' : 'declined',
        },
      };

      if (_connectionId != null) {
        responseMessage['connectionId'] = _connectionId as Object;
      }

      final jsonMessage = jsonEncode(responseMessage);
      _log('Sending connection response: $jsonMessage');
      _channel!.sink.add(jsonMessage);

      _log('Connection response sent: ${accepted ? "Accepted" : "Declined"}');

      _updateStatus(accepted ? 'Connected to doctor' : 'Connection declined');

      // Show appropriate message and close the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                accepted ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  accepted
                      ? 'You have accepted the doctor\'s request'
                      : 'You have declined the doctor\'s request',
                ),
              ),
            ],
          ),
          backgroundColor: accepted ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );

      // Close the bottom sheet
      Navigator.of(context).pop();
    } catch (e) {
      _log('Error sending connection response: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    // Skip processing if disposed
    if (_isDisposed) return;

    _log('WebSocket error: $error');

    if (error is WebSocketChannelException) {
      _log('Channel error details: ${error.inner}');
    }

    _updateStatus('Connection error');
    _handleDisconnect();
  }

  // Handle WebSocket disconnection
  void _handleDisconnect() {
    // Skip processing if disposed
    if (_isDisposed) return;

    _log('WebSocket disconnected');

    // Cancel subscriptions but don't close the channel as it's already closed
    _streamSubscription?.cancel();
    _streamSubscription = null;

    _pingTimer?.cancel();
    _pingTimer = null;

    // Update state if mounted
    if (mounted && !_isDisposed) {
      setState(() {
        _isConnected = false;
        _isRegistered = false;
        _connectionStatus = 'Disconnected';
        _channel = null;
      });
    }
  }

  // Update status with setState check
  void _updateStatus(String status) {
    if (mounted && !_isDisposed) {
      setState(() {
        _connectionStatus = status;
      });
    }
  }

  // Send a ping to keep the connection alive
  void _sendPing() {
    // Skip if disposed or not connected
    if (_isDisposed || _channel == null || !_isConnected) return;

    try {
      final pingMessage = {
        'action': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (_connectionId != null) {
        pingMessage['connectionId'] = _connectionId as Object;
      }

      _channel!.sink.add(jsonEncode(pingMessage));
      _log('Ping sent');
    } catch (e) {
      _log('Error sending ping: $e');
    }
  }

  // Send registration message per sendMessage.js format
  void _sendRegistration() {
    // Skip if disposed or not connected
    if (_isDisposed || !_isConnected || _channel == null) {
      _log('Cannot register: not connected');
      return;
    }

    if (widget.patientId.isEmpty) {
      _log('Cannot register: patient ID is empty');
      return;
    }

    try {
      // Create registration message exactly as expected by sendMessage.js
      final registrationMessage = {
        'action': 'register',
        'data': {
          'userId': widget.patientId,
          'timestamp': DateTime.now().toIso8601String(),
          'device': Platform.isAndroid ? 'android' : 'ios',
        },
      };

      // Add connectionId if we have it
      if (_connectionId != null) {
        registrationMessage['connectionId'] = _connectionId as Object;
      }

      final jsonMessage = jsonEncode(registrationMessage);
      _log('Sending registration: $jsonMessage');
      _channel!.sink.add(jsonMessage);

      _updateStatus('Registration sent');
    } catch (e) {
      _log('Error sending registration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If patient has a doctor linked, show message and remove button
    String? currentDoctorId = _patientDataService?.doctorId;
    if (_hasDoctorLinked &&
        currentDoctorId != null &&
        currentDoctorId.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.teal, size: 48),
            SizedBox(height: 16),
            Text(
              'You are already linked to a doctor.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Doctor ID: $currentDoctorId',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'To link a new doctor, please remove the current doctor.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.remove_circle, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              label: Text(
                'Remove Doctor',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                try {
                  // Remove doctorId from patient
                  final patientResult = await _patientRepo.updatePatientDetails(
                    patientId: widget.patientId,
                    doctorId: '',
                    action: 'remove',
                  );
                  print("patient result :: $patientResult");

                  if (patientResult['success'] == true) {
                    // Only try to update doctor if patient update was successful
                    final doctorResult = await _doctorRepo.updateDoctorDetails(
                      doctorId: currentDoctorId,
                      patientId: '',
                      action: 'remove',
                    );
                    print("doctor result :: $doctorResult");

                    // Always close the confirmation dialog first
                    Navigator.of(context).pop();

                    if (doctorResult['success'] == true) {
                      // Get latest patient data to update SharedPreferences
                      final phoneNumber = _patientDataService?.phoneNumber;
                      print("phone number for refresh :: $phoneNumber");
                      if (phoneNumber != null && phoneNumber.isNotEmpty) {
                        final result = await _patientRepo.getPatientDetails(
                          phoneNumber,
                        );
                        print("get patient details result :: $result");
                        if (result['statusCode'] == 200 &&
                            result['body']['body']['response'] == true &&
                            result['body']['body']['patientData'] != null) {
                          final latestPatientData =
                              result['body']['body']['patientData'];
                          await _prefsService?.saveUserData(
                            "patient",
                            latestPatientData,
                          );
                          await _patientDataService?.refreshPatientData();

                          setState(() {
                            _hasDoctorLinked = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Doctor removed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } else {
                      String errorMessage =
                          doctorResult['body']?['message'] ??
                          'Failed to update doctor details';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    // Close dialog and show patient update error
                    Navigator.of(context).pop();
                    String errorMessage =
                        patientResult['body']?['message'] ??
                        'Failed to update patient details';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Close dialog if still open
                  Navigator.of(context).pop();
                  print("Error removing doctor: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing doctor: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Patient QR Code',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Connection status
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusBorderColor()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusBorderColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectionStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusBorderColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // QR Code Section - Only show when connected and registered
            if (_isConnected && _isRegistered && !_patientIdMissing) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Have Your Doctor Scan This Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (context, error) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.red.shade50,
                            child: Center(
                              child: Text(
                                'Error generating QR',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Patient ID: ${widget.patientId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: _qrCodeScanned ? null : _generateQrData,
                          tooltip: 'Refresh QR code',
                          color: _qrCodeScanned ? Colors.grey : Colors.teal,
                        ),
                      ],
                    ),
                    if (_qrCodeScanned)
                      Chip(
                        label: Text('Scanned by Doctor'),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: TextStyle(color: Colors.green.shade800),
                        avatar: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade800,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (!_isConnected || !_isRegistered) ...[
              // Show connection status message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CupertinoActivityIndicator(color: Colors.teal),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connecting to server...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we establish a secure connection',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Patient ID (shown if missing)
            if (_patientIdMissing)
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Missing - patient not logged in?',
                      style: TextStyle(color: Colors.red),
                    ),
                    const Text(
                      'Patient ID is required to generate QR code',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _connectWebSocket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reconnect'),
                ),
                ElevatedButton(
                  onPressed: _isConnected ? _sendRegistration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for status display
  Color _getStatusColor() {
    if (_isConnected) {
      return _isRegistered
          ? Colors.green.withOpacity(0.1)
          : Colors.blue.withOpacity(0.1);
    }
    return Colors.red.withOpacity(0.1);
  }

  Color _getStatusBorderColor() {
    if (_isConnected) {
      return _isRegistered ? Colors.green : Colors.blue;
    }
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (_isConnected) {
      return _isRegistered ? Icons.check_circle : Icons.info;
    }
    return Icons.error_outline;
  }
}
