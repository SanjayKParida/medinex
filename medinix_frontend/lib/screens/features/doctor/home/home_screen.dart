import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:medinix_frontend/screens/features/doctor/scanner/qr_scanner_widget.dart';
import 'package:medinix_frontend/screens/features/doctor/patients/patient_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';
import 'package:loading_indicator/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey homeKey = GlobalKey();
  final bool openScanner;
  final VoidCallback? onNavigateToVisits;
  final VoidCallback? onNavigateToPatients;
  const HomeScreen({
    super.key,
    this.openScanner = false,
    this.onNavigateToVisits,
    this.onNavigateToPatients,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MobileScannerController? _scannerController;
  bool isScanning = false;
  String? doctorId;
  String? doctorName;
  final String? websocketUrl = dotenv.env['WEBSOCKET_API_ENDPOINT'];
  WebSocketChannel? _channel;
  final Appointments _appointmentsData = Appointments();
  final DoctorPatients _patientsData = DoctorPatients();
  final DoctorRepo _doctorRepo = DoctorRepo();

  bool _isLoadingPatients = false;
  String? _patientErrorMessage;

  @override
  void initState() {
    super.initState();
    _getDoctorInfo();
    _fetchPatients();

    // If openScanner is true, open the scanner automatically
    if (widget.openScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQRScanner();
      });
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _closeWebSocket();
    super.dispose();
  }

  void _getDoctorInfo() {
    final userDetails = SharedPreferencesService.getInstance().getUserDetails();
    doctorId = userDetails?['doctorId'];
    doctorName = userDetails?['name'] ?? 'Doctor';
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPatients = true;
      _patientErrorMessage = null;
    });

    try {
      // Only fetch if data isn't already loaded
      if (!_patientsData.patientsLoaded) {
        final result = await _doctorRepo.getDoctorPatients();

        if (!mounted) return;

        setState(() {
          _isLoadingPatients = false;
          if (result['success'] != true) {
            _patientErrorMessage = result['message'];
          }
        });
      } else {
        setState(() {
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _patientErrorMessage = 'Error fetching patients: $e';
        });
      }
    }
  }

  void _refreshPatients() {
    _patientsData.patientsLoaded = false;
    _fetchPatients();
  }

  void _closeWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshPatients();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTodaysAppointments(),
            _buildRecentPatients(),
            // Add padding at bottom for better scrolling experience
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Get current time to determine greeting
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade700, Colors.teal.shade500],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dr. ${doctorName ?? ""}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    PhosphorIcons.userCircle(),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    _buildStatCard(
                      '${_getTodaysAppointments().length}',
                      'Today',
                      PhosphorIcons.calendar(),
                      Colors.orange.shade300,
                      constraints.maxWidth / 3 - 10,
                    ),
                    SizedBox(width: 10),
                    _buildStatCard(
                      '${_patientsData.patientsList.length}',
                      'Patients',
                      PhosphorIcons.users(),
                      Colors.blue.shade300,
                      constraints.maxWidth / 3 - 10,
                    ),
                    SizedBox(width: 10),
                    _buildStatCard(
                      '${_getCompletedAppointments().length}',
                      'Completed',
                      PhosphorIcons.check(),
                      Colors.green.shade300,
                      constraints.maxWidth / 3 - 10,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysAppointments() {
    final todaysAppointments = _getTodaysAppointments();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Visits',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () {
                  print("Today's Visits See All Pressed");
                  if (widget.onNavigateToVisits != null) {
                    widget.onNavigateToVisits!();
                  } else {
                    print("onNavigateToVisits callback is null");
                  }
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          todaysAppointments.isEmpty
              ? _buildEmptyState(
                'No visits scheduled for today',
                'Your scheduled visits will appear here',
                PhosphorIcons.calendar(),
              )
              : Column(
                children:
                    todaysAppointments
                        .take(3)
                        .map(
                          (appointment) => _buildAppointmentCard(appointment),
                        )
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentPatients() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Patients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () {
                  print("Recent Patients See All Pressed");
                  if (widget.onNavigateToPatients != null) {
                    widget.onNavigateToPatients!();
                  } else {
                    print("onNavigateToPatients callback is null");
                  }
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _isLoadingPatients
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 40,
                    height: 30,
                    child: LoadingIndicator(
                      indicatorType: Indicator.lineScalePulseOut,
                      colors: const [Colors.teal],
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
              : _patientErrorMessage != null
              ? _buildErrorState(_patientErrorMessage!)
              : _patientsData.patientsList.isEmpty
              ? _buildEmptyState(
                'No patients found',
                'Scan a patient QR code to add patients',
                PhosphorIcons.users(),
              )
              : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      _patientsData.patientsList.length > 5
                          ? 5
                          : _patientsData.patientsList.length,
                  itemBuilder:
                      (context, index) =>
                          _buildPatientCard(_patientsData.patientsList[index]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Unable to load patients',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _refreshPatients,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    final time = appointment['time'] ?? '00:00';
    final patientName = appointment['patientName'] ?? 'Unknown Patient';
    final reason = appointment['reason'] ?? 'General Checkup';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  reason,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(PhosphorIcons.caretRight(), color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final patientName = patient['name'] ?? 'Unknown';
    final initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsScreen(patient: patient),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.teal.withOpacity(0.1),
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              patientName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to get data
  List<dynamic> _getTodaysAppointments() {
    final today = DateTime.now();
    final formattedToday = DateFormat('yyyy-MM-dd').format(today);

    try {
      return _appointmentsData.doctorAppointmentsList
          .where((appointment) {
            if (appointment is AppointmentModel) {
              return appointment.date == formattedToday &&
                  (appointment.status.toLowerCase() == 'confirmed' ||
                      appointment.status.toLowerCase() == 'scheduled');
            }
            return false;
          })
          .map(
            (appointment) => {
              'patientName':
                  'Patient', // This would need to be fetched from patients data
              'time': appointment.time,
              'reason': appointment.reason,
              'id': appointment.id,
            },
          )
          .toList();
    } catch (e) {
      print('Error getting today\'s appointments: $e');
      return [];
    }
  }

  List<dynamic> _getCompletedAppointments() {
    try {
      return _appointmentsData.doctorAppointmentsList.where((appointment) {
        if (appointment is AppointmentModel) {
          return appointment.status.toLowerCase() == 'completed';
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error getting completed appointments: $e');
      return [];
    }
  }

  void _showQRScanner() async {
    bool hasPermission = await _requestCameraPermission();

    if (hasPermission) {
      final result = await showModalBottomSheet<Map<String, dynamic>?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => QRScannerWidget(
              onPatientFound: (patient) {
                Navigator.pop(context, patient);
              },
            ),
      );

      if (result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsScreen(patient: result),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission is required to scan QR codes'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildHomeContent());
  }
}
