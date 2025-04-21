import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _requestCameraPermission().then((hasPermission) {
      if (hasPermission) {
        setState(() {
          _isScanning = true;
          _scannerController = MobileScannerController();
        });
        _connectWebSocket();
      } else {
        _showPermissionDeniedMessage();
      }
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _closeWebSocket();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else {
      final result = await Permission.camera.request();
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
      _channel = WebSocketChannel.connect(
        Uri.parse(dotenv.env['WEBSOCKET_API_ENDPOINT']!),
      );

      _channel!.stream.listen(
        (message) {
          final Map<String, dynamic> response = jsonDecode(message);

          if (response.containsKey('patient')) {
            _handlePatientData(response['patient']);
          } else if (response.containsKey('error')) {
            _showError(response['error']);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 3), _connectWebSocket);
  }

  void _closeWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  void _onQRDetected(BarcodeCapture barcode) {
    if (_isProcessing) return;

    HapticFeedback.mediumImpact();

    final List<Barcode> barcodes = barcode.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _processPatientQR(code);
        break;
      }
    }
  }

  void _processPatientQR(String qrCode) {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Send QR code to WebSocket server
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'qr_scan', 'data': qrCode}));
      } else {
        _showError('WebSocket not connected. Please try again.');
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showError('Failed to process QR code: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handlePatientData(Map<String, dynamic> patientData) {
    setState(() {
      _isProcessing = false;
    });

    // Call the callback with patient data
    widget.onPatientFound(patientData);

    // Close the scanner
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isProcessing = false;
    });
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
          SizedBox(height: 20),
          Expanded(
            child:
                _isScanning && _scannerController != null
                    ? _buildScannerView()
                    : Center(
                      child: CircularProgressIndicator(color: Colors.teal),
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
                // TODO: Navigate to patient search or manual entry
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
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onQRDetected,
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
