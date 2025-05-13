import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/utilities/doctor_data_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/repositories/patient_repository.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientFound;

  const QRScannerWidget({super.key, required this.onPatientFound});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isProcessing = false;
  late DoctorDataService doctorService;
  String? _pendingQrCode;
  bool _doctorDataInitialized = false;
  bool _isWebSocketConnected = false;
  bool _isWebSocketRegistered = false;
  int _retryCount = 0;
  String _connectionStatus = 'Connecting to server...';
  int _reconnectAttempt = 0;
  Timer? _pingTimer;
  Map<String, dynamic>? _scannedPatientData;
  bool _showConnectionDialog = false;

  // Add connection ID from server
  String? _connectionId;

  // Add detailed logging system
  List<String> _connectionLog = [];
  String _detailedStatus = '';

  // Track the last time a QR code was scanned to prevent duplicate scans
  DateTime? _lastScanTime;

  late SharedPreferencesService _prefsService;
  late PatientRepo _patientRepo;
  late DoctorRepo _doctorRepo;

  @override
  void initState() {
    super.initState();
    _addToLog('Initializing QR scanner');
    doctorService = DoctorDataService.getInstance();
    _prefsService = SharedPreferencesService.getInstance();
    _patientRepo = PatientRepo();
    _doctorRepo = DoctorRepo();

    // Initialize scanner controller immediately
    _scannerController = MobileScannerController();
    _addToLog('Mobile scanner controller initialized');

    _initDoctorData().then((_) {
      _requestCameraPermission().then((hasPermission) {
        if (hasPermission) {
          _addToLog('Camera permission granted');
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
          // Start WebSocket connection
          _connectWebSocket();
        } else {
          _addToLog('Camera permission denied');
          _showPermissionDeniedMessage();
        }
      });
    });
  }

  @override
  void dispose() {
    _addToLog('Disposing QR scanner');
    _scannerController?.dispose();
    _closeWebSocket();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  /// Adds a message to the connection log
  void _addToLog(String message) {
    debugPrint('QR SCANNER: $message');
    setState(() {
      _connectionLog.add(
        '${DateTime.now().toString().split('.')[0]}: $message',
      );
      // Keep log to a reasonable size
      if (_connectionLog.length > 20) {
        _connectionLog.removeAt(0);
      }
      _detailedStatus = message;
    });
  }

  Future<void> _initDoctorData() async {
    try {
      _addToLog('Initializing doctor data');
      await doctorService.init();
      setState(() {
        _doctorDataInitialized = true;
      });
      if (doctorService.doctorId.isEmpty) {
        _addToLog('Error: Doctor ID is empty after initialization');
        _showError('Doctor ID not found. Please log in again.');
      } else {
        _addToLog('Doctor data initialized, ID: ${doctorService.doctorId}');

        // Log the WebSocket URL to help with debugging
        final websocketUrl = dotenv.env['WEBSOCKET_API_ENDPOINT'];
        _addToLog('WebSocket URL from env: $websocketUrl');
        if (websocketUrl == null || websocketUrl.isEmpty) {
          _addToLog('WARNING: WebSocket URL is not configured in .env file');
        } else if (!websocketUrl.startsWith('ws://') &&
            !websocketUrl.startsWith('wss://')) {
          _addToLog(
            'WARNING: WebSocket URL does not start with ws:// or wss://',
          );
        }
      }
    } catch (e) {
      _addToLog('Error initializing doctor data: $e');
      _showError('Failed to load doctor profile');
    }
  }

  Future<bool> _requestCameraPermission() async {
    _addToLog('Requesting camera permission');
    var status = await Permission.camera.status;
    if (status.isGranted) {
      _addToLog('Camera permission already granted');
      return true;
    } else {
      _addToLog('Requesting camera permission from user');
      final result = await Permission.camera.request();
      _addToLog('Camera permission request result: ${result.isGranted}');
      return result.isGranted;
    }
  }

  void _showPermissionDeniedMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission is required to scan QR codes'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  void _connectWebSocket() {
    try {
      if (!_doctorDataInitialized) {
        _addToLog('Doctor data not initialized, delaying WebSocket connection');
        Future.delayed(Duration(seconds: 2), () {
          _connectWebSocket();
        });
        return;
      }

      final doctorId = doctorService.doctorId;
      if (doctorId.isEmpty) {
        _addToLog('Error: Doctor ID is empty, cannot connect to WebSocket');
        _showError('Doctor ID not available. Please log in again.');
        return;
      }

      final websocketUrl = dotenv.env['WEBSOCKET_API_ENDPOINT'];
      if (websocketUrl == null || websocketUrl.isEmpty) {
        _addToLog('Error: WebSocket URL is not configured');
        _showError('WebSocket service not configured');
        return;
      }

      // Close any existing connection first
      _closeWebSocket();

      setState(() {
        _isWebSocketConnected = false;
        _isWebSocketRegistered = false;
        _connectionStatus = 'Connecting to server...';
      });

      // Create WebSocket connection with proper formatting
      String connectionUrl = websocketUrl;

      // If URL starts with https://, convert to wss://
      if (connectionUrl.startsWith('https://')) {
        final uri = Uri.parse(connectionUrl);
        connectionUrl = 'wss://${uri.host}${uri.path}';
      }
      // Ensure URL starts with wss:// or ws://
      else if (!connectionUrl.startsWith('wss://') &&
          !connectionUrl.startsWith('ws://')) {
        final uri = Uri.parse(connectionUrl);
        connectionUrl = 'wss://${uri.host}${uri.path}';
      }

      // IMPORTANT: Ensure the path ends with a forward slash if using API Gateway
      if (connectionUrl.contains('execute-api') &&
          !connectionUrl.endsWith('/')) {
        connectionUrl = '$connectionUrl/';
      }

      _addToLog('Connecting to WebSocket URL: $connectionUrl');

      // Create WebSocket channel with proper headers
      _channel = IOWebSocketChannel.connect(
        connectionUrl,
        pingInterval: Duration(seconds: 20),
        headers: {
          'User-Agent': 'MedinexDoctorApp',
          'X-Client-Type': 'doctor',
          'X-Doctor-ID': doctorId,
          'Origin': 'https://medinex.app',
        },
      );

      // Mark as connected
      setState(() {
        _isWebSocketConnected = true;
        _connectionStatus = 'Connection established';
      });

      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          _addToLog('Received WebSocket message: $message');
          _onWebSocketMessage(message);
        },
        onError: (error) {
          _addToLog('WebSocket error: $error');
          setState(() {
            _isWebSocketConnected = false;
            _isWebSocketRegistered = false;
            _connectionStatus = 'Connection error';
          });
          _scheduleReconnect();
        },
        onDone: () {
          _addToLog('WebSocket connection closed');
          setState(() {
            _isWebSocketConnected = false;
            _isWebSocketRegistered = false;
            _connectionStatus = 'Connection closed';
          });
          _scheduleReconnect();
        },
      );

      // Register the doctor immediately after connection
      _registerDoctor();
    } catch (e) {
      _addToLog('Error connecting to WebSocket: $e');
      setState(() {
        _isWebSocketConnected = false;
        _isWebSocketRegistered = false;
        _connectionStatus = 'Connection error';
      });
      _scheduleReconnect();
    }
  }

  void _registerDoctor() {
    final doctorId = doctorService.doctorId;
    if (doctorId.isEmpty) {
      _addToLog('Cannot register: Doctor ID is empty');
      return;
    }

    _addToLog('Registering doctor ID with WebSocket: $doctorId');

    final Map<String, dynamic> registrationData = {
      'action': 'register',
      'data': {'userId': doctorId, 'userType': 'doctor'},
    };

    if (_connectionId != null) {
      registrationData['connectionId'] = _connectionId;
    }

    try {
      _channel!.sink.add(jsonEncode(registrationData));
      _addToLog('Registration message sent successfully');

      setState(() {
        _connectionStatus = 'Registering...';
      });
    } catch (e) {
      _addToLog('Error sending registration: $e');
      _showError('Failed to register with server');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Exponential backoff with maximum of 30 seconds
    final int delaySeconds = _retryCount < 5 ? (2 << _retryCount) : 30;
    _retryCount++;

    _addToLog(
      'Scheduling WebSocket reconnect in $delaySeconds seconds (attempt $_retryCount)',
    );

    setState(() {
      _connectionStatus = 'Reconnecting in ${delaySeconds}s...';
    });

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _addToLog('Attempting reconnection #$_retryCount');
        _connectWebSocket();
      } else {
        _addToLog('Widget no longer mounted, cancelling reconnection');
      }
    });
  }

  void _closeWebSocket() {
    _addToLog('Closing WebSocket connection');
    if (_channel != null) {
      try {
        // Send a disconnect message before closing
        if (_isWebSocketConnected) {
          try {
            final message = {
              'action': 'disconnect',
              'data': {'userId': doctorService.doctorId},
            };
            _channel!.sink.add(jsonEncode(message));
            _addToLog('Sent disconnect message to WebSocket server');

            // Small delay to allow the message to be sent
            Future.delayed(Duration(milliseconds: 100), () {
              _channel!.sink.close();
              _channel = null;
              _addToLog(
                'WebSocket connection closed gracefully after disconnect',
              );
            });
          } catch (e) {
            _addToLog('Error sending disconnect message: $e');
            _channel!.sink.close();
            _channel = null;
          }
        } else {
          _channel!.sink.close();
          _channel = null;
          _addToLog('WebSocket connection closed gracefully');
        }
      } catch (e) {
        _addToLog('Error closing WebSocket: $e');
        _channel = null;
      }
    }

    setState(() {
      _isWebSocketConnected = false;
      _isWebSocketRegistered = false;
    });
  }

  void _onQRDetected(BarcodeCapture barcode) {
    if (_isProcessing) {
      _addToLog('Already processing a QR code, ignoring new scan');
      return;
    }

    // Prevent multiple rapid scans of the same QR code
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inSeconds < 3) {
      _addToLog('Ignoring scan - too soon after previous scan');
      return;
    }
    _lastScanTime = now;

    HapticFeedback.mediumImpact();
    _addToLog('QR code detected');

    final List<Barcode> barcodes = barcode.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _addToLog('QR code data length: ${code.length} chars');

        if (_isWebSocketConnected && _isWebSocketRegistered) {
          _processPatientQR(code);
        } else {
          _addToLog(
            'WebSocket not ready. Storing QR code for later processing',
          );
          _pendingQrCode = code;

          if (!_isWebSocketConnected) {
            _addToLog('WebSocket not connected, reconnecting');
            _showError('Connecting to server...');
            _connectWebSocket();
          } else if (!_isWebSocketRegistered) {
            _addToLog('WebSocket not registered, registering doctor');
            _showError('Waiting for server registration...');
            _registerDoctor();
          }
        }
        break;
      }
    }
  }

  void _processQrCodeAfterDelay(String qrCode) {
    Future.delayed(Duration(milliseconds: 500), () {
      _processPatientQR(qrCode);
    });
  }

  void _processPatientQR(String qrCode) {
    _addToLog('Processing patient QR code');
    setState(() {
      _isProcessing = true;
      _connectionStatus = 'Processing QR code...';
    });

    try {
      if (_channel != null && _isWebSocketConnected) {
        _addToLog('WebSocket connected, sending QR data to server');

        // Get doctor information
        final doctorId = doctorService.doctorId;
        final doctorName = doctorService.name;
        final specialization = doctorService.specialization;

        if (doctorId.isEmpty) {
          _addToLog('Error: Doctor ID not available');
          _showError('Doctor ID not available. Please log in again.');
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        // IMPORTANT: Validate QR content format
        // The server expects qrCode to be a JSON string containing patientId field
        String validQrCode = qrCode;
        try {
          // First check if the QR is valid JSON already
          final decoded = jsonDecode(qrCode);

          // Make sure it contains patientId field as required by sendMessage.js
          if (!decoded.containsKey('patientId')) {
            _addToLog('QR code missing patientId field, adding dummy value');
            decoded['patientId'] =
                'QR_${DateTime.now().millisecondsSinceEpoch}';
            validQrCode = jsonEncode(decoded);
          } else {
            _addToLog(
              'QR code already contains patientId: ${decoded['patientId']}',
            );
            // Use original QR code as it's already properly formatted
          }
        } catch (jsonError) {
          // If it's not valid JSON, wrap it in a proper format
          _addToLog('QR code is not valid JSON, reformatting');
          final wrappedData = {
            'patientId': 'QR_${DateTime.now().millisecondsSinceEpoch}',
            'rawContent': qrCode,
          };
          validQrCode = jsonEncode(wrappedData);
          _addToLog('Reformatted QR data: $validQrCode');
        }

        // Format message exactly as expected by sendMessage.js
        final Map<String, dynamic> scanMessage = {
          'action': 'qr_scan',
          'data': {
            'qrCode': validQrCode, // Now properly formatted as JSON string
            'doctorId': doctorId,
            'doctorName': doctorName,
            'specialization': specialization,
          },
        };

        // Add connectionId if available
        if (_connectionId != null) {
          scanMessage['connectionId'] = _connectionId;
        }

        final scanMessageJson = jsonEncode(scanMessage);
        _addToLog('Sending QR scan message to server: $scanMessageJson');
        _addToLog(
          'AWS LOG - [DOCTOR:$doctorId] - Sending QR scan: ${validQrCode.length} chars',
        );
        _channel!.sink.add(scanMessageJson);
        _addToLog('QR scan message sent to WebSocket server');

        // Set a timeout to reset processing state if no response
        // Increase timeout and add retry logic
        int retryCount = 0;
        const maxRetries = 2;
        const int timeoutSeconds = 8; // Reduced timeout for faster retries

        void tryProcessQR() {
          Future.delayed(Duration(seconds: timeoutSeconds), () {
            if (_isProcessing && mounted) {
              if (retryCount < maxRetries) {
                retryCount++;
                _addToLog(
                  'No response, retrying (attempt $retryCount of $maxRetries)...',
                );

                // Try sending the message again
                _channel!.sink.add(scanMessageJson);
                _addToLog('Retry: QR scan message sent to WebSocket server');
                _addToLog(
                  'AWS LOG - [DOCTOR:$doctorId] - Retry #$retryCount sending QR scan',
                );

                // Set up another timeout for this retry
                tryProcessQR();
              } else {
                _addToLog(
                  'Timeout waiting for server response after $maxRetries retries',
                );

                // Show error message to user
                _showError(
                  'Patient not connected. Please ask the patient to open their app and try again.',
                );

                setState(() {
                  _isProcessing = false;
                  _connectionStatus = 'Connection active';
                });
              }
            }
          });
        }

        // Start the timeout/retry cycle
        tryProcessQR();
      } else {
        if (!_isWebSocketConnected) {
          _addToLog('WebSocket not connected, cannot process QR');
          _showError('WebSocket not connected. Reconnecting...');
          _pendingQrCode = qrCode;
          _connectWebSocket();
        } else {
          _addToLog('WebSocket connection issue');
          _showError('WebSocket connection issue. Please try again.');
        }

        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      _addToLog('Error processing QR code: $e');
      _showError('Failed to process QR code: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onWebSocketMessage(dynamic message) {
    _addToLog('Received WebSocket message: $message');

    // Any message confirms connection is working
    if (!_isWebSocketRegistered) {
      setState(() {
        _isWebSocketRegistered = true;
        _isWebSocketConnected = true;
        _connectionStatus = 'Connection active';
      });
      _addToLog('Connection confirmed active');
    }

    try {
      // Convert to string if not already
      String messageStr = message is String ? message : message.toString();
      messageStr = messageStr.trim();

      // Handle patient response message
      if (messageStr.startsWith('{') && messageStr.endsWith('}')) {
        final data = jsonDecode(messageStr);

        // Check for patient response
        if (data['type'] == 'patient_response') {
          _addToLog('Received patient response message');
          _handleConnectionResponse(data);
          return;
        }

        // Check for doctor request sent confirmation
        if (data['message'] == 'Doctor request sent') {
          _addToLog('Doctor request sent confirmation received');
          return;
        }
      }

      // Handle plain text messages
      if (messageStr == 'Doctor request sent') {
        _addToLog('Doctor request sent confirmation received (plain text)');
        return;
      }

      // SPECIAL CASE FOR "Registered" PLAIN TEXT MESSAGE
      // This handles legacy plain text responses from the server directly
      if (messageStr.toLowerCase() == 'registered') {
        _addToLog('Received legacy plain text registration confirmation');
        _addToLog(
          'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Registered (legacy format)',
        );

        setState(() {
          _isWebSocketRegistered = true;
          _retryCount = 0;
          _connectionStatus = 'Connected to server';
        });

        if (_pendingQrCode != null) {
          _addToLog('Processing pending QR code after registration');
          _processQrCodeAfterDelay(_pendingQrCode!);
          _pendingQrCode = null;
        }
        return;
      }

      // Check if the message is plain text error message
      if (messageStr.trim().startsWith('Internal Server Error') ||
          messageStr.toLowerCase().contains('error') &&
              !messageStr.startsWith('{')) {
        _addToLog('Received plain text error message: $messageStr');
        _addToLog(
          'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Server error: $messageStr',
        );

        // Stop processing state if we're in it
        if (_isProcessing) {
          setState(() {
            _isProcessing = false;
            _connectionStatus = 'Connection active';
          });

          // Show error to user
          _showError('Server error: $messageStr');
        }
        return;
      }

      // Try to parse as JSON - with special handling for potential invalid formats
      Map<String, dynamic> data;
      try {
        // Check if message is valid JSON by looking for opening brace
        if (messageStr.startsWith('{') && messageStr.endsWith('}')) {
          data = jsonDecode(messageStr);
          _addToLog('Successfully parsed WebSocket message as JSON');
        } else {
          // If it's not a standard JSON message, try to convert it to JSON
          _addToLog(
            'Message not in standard JSON format, attempting to wrap it',
          );
          throw FormatException('Not a standard JSON object');
        }
      } catch (e) {
        _addToLog('Error parsing WebSocket message as JSON: $e');
        _addToLog(
          'AWS LOG - [DOCTOR:${doctorService.doctorId}] - JSON parse error: $e',
        );

        // For common plain text messages, handle them directly
        if (messageStr.toLowerCase().contains('pong')) {
          _addToLog('Received pong response - connection confirmed');
          setState(() {
            _isWebSocketConnected = true;
            _isWebSocketRegistered = true;
            _connectionStatus = 'Connected to server';
          });
          return;
        } else if (messageStr.toLowerCase().contains('registered') ||
            messageStr.toLowerCase().contains('success')) {
          _addToLog(
            'WebSocket registration successful from plain text message',
          );
          _addToLog(
            'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Registered (text format)',
          );
          setState(() {
            _isWebSocketRegistered = true;
            _retryCount = 0;
            _connectionStatus = 'Connected to server';
          });

          if (_pendingQrCode != null) {
            _addToLog('Processing pending QR code after registration');
            _processQrCodeAfterDelay(_pendingQrCode!);
            _pendingQrCode = null;
          }
          return;
        }

        // Try to convert plain text to a JSON object
        try {
          data = {'message': messageStr, 'isPlainText': true};
          _addToLog('Converted plain text message to JSON object');
        } catch (e2) {
          _addToLog('Failed to process message in any format: $e2');
          return;
        }
      }

      // Log parsed message content for AWS
      _addToLog(
        'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Message type: ${data['type'] ?? 'unknown'}, action: ${data['action'] ?? 'none'}',
      );

      // Extract connectionId if present
      if (data.containsKey('connectionId')) {
        _connectionId = data['connectionId'];
        _addToLog('Received connectionId: $_connectionId');
        _addToLog(
          'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Got connectionId: $_connectionId',
        );

        // If we have a connectionId but aren't registered yet, try to register
        if (!_isWebSocketRegistered && _connectionId != null) {
          Future.delayed(Duration(milliseconds: 100), () {
            _registerDoctor();
          });
        }
      }

      // Handle the message based on its structure
      // First check if this is a registration response
      if (data.containsKey('type') && data['type'] == 'registration_response') {
        _addToLog('Received registration response: ${data['status']}');
        if (data['status'] == 'success') {
          setState(() {
            _isWebSocketRegistered = true;
            _retryCount = 0;
            _connectionStatus = 'Connected to server';
          });

          _addToLog('Registration successful with new JSON format');
          _addToLog(
            'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Registered with JSON format',
          );

          if (_pendingQrCode != null) {
            _addToLog('Processing pending QR code after registration');
            _processQrCodeAfterDelay(_pendingQrCode!);
            _pendingQrCode = null;
          }
          return;
        }
      }

      // Then check for success/error messages
      if (data.containsKey('status') && data['status'] == 'success') {
        _addToLog('Received success message: ${data['message'] ?? "Success"}');
        return;
      }

      // Check for error message from server
      if (data.containsKey('error') ||
          (data.containsKey('message') &&
              data['message'].toString().toLowerCase().contains('error'))) {
        _addToLog('Server reported error: ${data['error'] ?? data['message']}');
        _addToLog(
          'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Server error: ${data['error'] ?? data['message']}',
        );

        // Stop processing state if we're in it
        if (_isProcessing) {
          setState(() {
            _isProcessing = false;
            _connectionStatus = 'Connection active';
          });

          // Show error to user
          _showError(
            data['error'] ?? data['message'] ?? 'Server reported an error',
          );
        }

        // If we got an error but also received a connectionId, try registering again
        if (_connectionId != null && !_isWebSocketRegistered) {
          Future.delayed(Duration(seconds: 1), () {
            _addToLog(
              'Retrying registration with connectionId: $_connectionId',
            );
            _registerDoctor();
          });
        }

        return;
      }

      // Handle different response types from sendMessage.js
      if (data.containsKey('type')) {
        final messageType = data['type'];
        _addToLog('Message type: $messageType');

        if (messageType == 'doctor_request') {
          // This is what sendMessage.js sends to patients, not doctors
          _addToLog(
            'Received doctor_request message, ignoring as we are the doctor app',
          );
        } else if (messageType == 'patient_data' ||
            messageType == 'patient_info') {
          // This matches sendMessage.js's format for patient data
          _addToLog('Received patient data from server');
          if (data.containsKey('patient')) {
            _handlePatientData(data['patient']);
          }
        } else if (messageType == 'connection_response') {
          // Handle patient response to connection request
          _addToLog('Received connection response from patient');
          _handleConnectionResponse(data);
        } else if (messageType == 'error') {
          // Handle explicit error type
          _addToLog('Received error message from server: ${data['message']}');
          _addToLog(
            'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Server error: ${data['message']}',
          );
          _showError('Server error: ${data['message']}');

          // Reset processing state if we're in it
          if (_isProcessing) {
            setState(() {
              _isProcessing = false;
              _connectionStatus = 'Connection active';
            });
          }
        }
      } else if (data.containsKey('patient')) {
        // Direct patient data format
        _addToLog('Received direct patient data format');
        _handlePatientData(data['patient']);
      } else if (data.containsKey('message') && !data.containsKey('error')) {
        final msg = data['message'].toString().toLowerCase();
        _addToLog('Received message: $msg');

        if (msg.contains('registered') || msg.contains('success')) {
          _addToLog('WebSocket registration successful from JSON message');
          setState(() {
            _isWebSocketRegistered = true;
            _retryCount = 0;
            _connectionStatus = 'Connected to server';
          });

          if (_pendingQrCode != null) {
            _addToLog('Processing pending QR code after registration');
            _processQrCodeAfterDelay(_pendingQrCode!);
            _pendingQrCode = null;
          }
        } else if (msg.contains('pong')) {
          _addToLog('Received pong response - connection confirmed');
          setState(() {
            _isWebSocketConnected = true;
            _isWebSocketRegistered = true;
            _connectionStatus = 'Connected to server';
          });
        }
      } else {
        _addToLog('Received unrecognized message format: $data');
      }
    } catch (e) {
      _addToLog('Error processing WebSocket message: $e');
      _addToLog(
        'AWS LOG - [DOCTOR:${doctorService.doctorId}] - Message processing error: $e',
      );
      // Don't show this error to the user unless we're actively processing
      if (_isProcessing) {
        _showError('Error processing server response: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handlePatientData(Map<String, dynamic> patientData) {
    _addToLog('Processing patient data: ${patientData.toString()}');

    setState(() {
      _isProcessing = false;
      _connectionStatus = 'Connected to server';
      _scannedPatientData = patientData;
    });

    // Check for error flag or dummy data marker from sendMessage.js
    final bool hasError = patientData['error'] == true;
    final bool isDummyData =
        patientData.containsKey('note') &&
        patientData['note'].toString().contains('DUMMY');

    if (hasError || isDummyData) {
      _addToLog('Patient data error or dummy data detected');
      _showError(
        isDummyData
            ? 'Could not decode patient QR code. Verify the QR is valid.'
            : 'Error retrieving patient data: ${patientData['message'] ?? 'Unknown error'}',
      );
    }

    // Process the data from sendMessage.js format
    final Map<String, dynamic> data = Map<String, dynamic>.from(patientData);

    // Add doctor ID to the patient data if not already present
    if (!data.containsKey('doctorId')) {
      data['doctorId'] = doctorService.doctorId;
    }

    // Add scan metadata if not provided
    if (!data.containsKey('scannedBy')) {
      data['scannedBy'] = {
        'doctorId': doctorService.doctorId,
        'doctorName': doctorService.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    // Show connect patient dialog
    if (mounted) {
      setState(() {
        _showConnectionDialog = true;
      });
      _addToLog('Showing patient connection dialog');

      // Show a dialog to ask if the doctor wants to connect with this patient
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Patient Identified'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${data['name'] ?? 'Unknown'}'),
                SizedBox(height: 8),
                Text('ID: ${data['patientId'] ?? data['id'] ?? 'Unknown'}'),
                SizedBox(height: 16),
                Text('Would you like to connect with this patient?'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Skip'),
                onPressed: () {
                  _addToLog('Doctor skipped connection with patient');
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _showConnectionDialog = false;
                  });
                  // Continue with normal flow without connecting
                  widget.onPatientFound(data);
                  Navigator.pop(context); // Close the scanner
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text('Connect', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _addToLog('Doctor requested connection with patient');
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _showConnectionDialog = false;
                  });
                  // Send connection request
                  _requestPatientConnection(data['patientId'] ?? data['id']);
                  // Continue with normal flow
                  widget.onPatientFound(data);
                  Navigator.pop(context); // Close the scanner
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Handle response to doctor's connection request
  void _handleConnectionResponse(Map<String, dynamic> data) async {
    final patientId = data['patientId'] ?? 'Unknown';
    final bool accepted = data['accepted'] == true;

    _addToLog(
      'Received connection response from patient $patientId: ${accepted ? 'accepted' : 'declined'}',
    );

    if (accepted) {
      setState(() {
        _isProcessing = true;
        _connectionStatus = 'Updating connection...';
      });

      try {
        // Get doctor ID from shared preferences
        final userDetails = _prefsService.getUserDetails();
        final doctorId = userDetails?['doctorId'];

        if (doctorId == null) {
          throw Exception('Doctor ID not found');
        }

        // Update doctor's patients list
        final doctorUpdateResult = await _doctorRepo.updateDoctorDetails(
          doctorId: doctorId,
          patientId: patientId,
          action: 'add',
        );

        if (!doctorUpdateResult['success']) {
          throw Exception(
            doctorUpdateResult['body']['message'] ?? 'Failed to update doctor',
          );
        }

        // Add patient to DoctorPatients list
        if (!DoctorPatients().patientsList.any(
          (p) => p['patientId'] == patientId,
        )) {
          DoctorPatients().patientsList.add({
            'patientId': patientId,
            'name': data['name'] ?? 'Unknown Patient',
            'dob': data['dob'] ?? '',
            'gender': data['gender'] ?? '',
            'phoneNumber': data['phone'] ?? '',
            'address': data['address'] ?? '',
            'doctorID': doctorId,
          });
          DoctorPatients().patientsLoaded = true;
        }

        setState(() {
          _isProcessing = false;
          _connectionStatus = 'Connection active';
        });

        // Show success message and close scanner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Patient $patientId accepted your connection request',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );

        // Close the scanner and refresh patients screen
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isProcessing = false;
          _connectionStatus = 'Connection active';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to update connection: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    } else {
      // Show rejection message and close scanner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient $patientId declined your connection request',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );

      // Close the scanner
      Navigator.pop(context);
    }
  }

  // Request connection with a patient
  void _requestPatientConnection(String patientId) {
    if (!_isWebSocketConnected || !_isWebSocketRegistered) {
      _addToLog('Cannot request connection: WebSocket not ready');
      _showError('Not connected to server');
      return;
    }

    try {
      final doctorId = doctorService.doctorId;
      final doctorName = doctorService.name;
      final specialization = doctorService.specialization;

      final connectionRequest = {
        'action': 'connect_patient',
        'data': {
          'doctorId': doctorId,
          'patientId': patientId,
          'doctorName': doctorName,
          'specialization': specialization,
          'message': 'Dr. $doctorName would like to connect with you',
        },
      };

      _addToLog('Sending connection request to patient $patientId');
      _channel!.sink.add(jsonEncode(connectionRequest));
      _addToLog('Connection request sent successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection request sent to patient'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      _addToLog('Error sending connection request: $e');
      _showError('Failed to send connection request: $e');
    }
  }

  // Periodic ping to keep connection alive
  void _sendPing() {
    if (!_isWebSocketConnected || _channel == null) {
      return;
    }

    try {
      _addToLog('Sending ping to server');
      _channel!.sink.add(jsonEncode({'action': 'ping'}));
    } catch (e) {
      _addToLog('Error sending ping: $e');
    }
  }

  void _showError(String message) {
    _addToLog('ERROR: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  // Helper function to find minimum of two integers
  int min(int a, int b) {
    return a < b ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scan Patient QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade800,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Connection status indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _isWebSocketConnected
                      ? (_isWebSocketRegistered
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1))
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isWebSocketConnected
                        ? (_isWebSocketRegistered
                            ? Colors.green
                            : Colors.orange)
                        : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isWebSocketConnected
                          ? (_isWebSocketRegistered
                              ? Icons.check_circle
                              : Icons.pending)
                          : Icons.error,
                      size: 14,
                      color:
                          _isWebSocketConnected
                              ? (_isWebSocketRegistered
                                  ? Colors.green
                                  : Colors.orange)
                              : Colors.red,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isWebSocketConnected
                                ? (_isWebSocketRegistered
                                    ? Colors.green
                                    : Colors.orange)
                                : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        _connectWebSocket();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size(60, 24),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Reconnect",
                        style: TextStyle(fontSize: 11, color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Camera Scanner - Only show when connected and registered
          if (_isWebSocketConnected && _isWebSocketRegistered)
            Expanded(
              child:
                  _scannerController == null
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                      : _buildScannerView(),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CupertinoActivityIndicator(color: Colors.teal),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Connecting to server...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
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
            ),

          SizedBox(height: 16),

          Text(
            'Position the QR code within the frame to scan',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Manual patient entry would go here
              },
              icon: Icon(PhosphorIcons.notepad(), color: Colors.white),
              label: Text('Enter Patient ID Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Scanner
            if (_scannerController != null)
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onQRDetected,
              )
            else
              Center(
                child: Text(
                  'Camera initializing...',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // Overlay
            Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Scanner cutout (transparent)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Corner indicators
                      ...List.generate(4, (index) {
                        final bool isTop = index < 2;
                        final bool isLeft = index.isEven;
                        return Positioned(
                          top: isTop ? 0 : null,
                          bottom: !isTop ? 0 : null,
                          left: isLeft ? 0 : null,
                          right: !isLeft ? 0 : null,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                top:
                                    isTop
                                        ? BorderSide(
                                          color: Colors.teal,
                                          width: 4,
                                        )
                                        : BorderSide.none,
                                bottom:
                                    !isTop
                                        ? BorderSide(
                                          color: Colors.teal,
                                          width: 4,
                                        )
                                        : BorderSide.none,
                                left:
                                    isLeft
                                        ? BorderSide(
                                          color: Colors.teal,
                                          width: 4,
                                        )
                                        : BorderSide.none,
                                right:
                                    !isLeft
                                        ? BorderSide(
                                          color: Colors.teal,
                                          width: 4,
                                        )
                                        : BorderSide.none,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing QR Code...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
