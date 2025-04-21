import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/screens/features/doctor/appointments/appointment_details_screen.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/utilities/models.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final _sharedPrefs = SharedPreferencesService.getInstance();
  final Appointments _appointmentsData = Appointments();

  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _filteredAppointments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _filterAppointments(_tabController.index);
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if appointments are already loaded in the singleton
    if (_appointmentsData.appointmentsLoaded) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filterAppointments(_tabController.index);
        });
      }
      return;
    }

    // If not loaded, fetch from API
    await _fetchDoctorAppointments();
  }

  Future<void> _fetchDoctorAppointments() async {
    try {
      // Get doctor ID from shared preferences
      final userDetails = _sharedPrefs.getUserDetails();
      final doctorId = userDetails?['doctorId'];

      if (doctorId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Doctor ID not found. Please log in again.';
          });
        }
        return;
      }

      final result = await _appointmentRepo.getAppointments(doctorId: doctorId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          try {
            // Get the appointments array safely
            final appointmentsData =
                result['appointments'] as List<dynamic>? ?? [];

            // Convert to AppointmentModel safely
            _appointmentsData.doctorAppointmentsList =
                appointmentsData.map((appointment) {
                  try {
                    return AppointmentModel.fromJson(
                      appointment is Map
                          ? Map<String, dynamic>.from(appointment)
                          : <String, dynamic>{},
                    );
                  } catch (e) {
                    print('Error converting appointment: $e');
                    // Return a placeholder model if conversion fails
                    return AppointmentModel(
                      id: 'error',
                      patientId: '',
                      doctorId: '',
                      date: '',
                      time: '',
                      reason: '',
                      status: 'error',
                      createdAt: DateTime.now(),
                    );
                  }
                }).toList();

            _appointmentsData.appointmentsLoaded = true;
            _filterAppointments(_tabController.index);
          } catch (e) {
            print('Error processing appointments: $e');
            _errorMessage = 'Error processing appointments data';
          }
        } else {
          _errorMessage = result['message'] ?? 'Failed to load appointments';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading appointments: $e';
        });
      }
    }
  }

  void _filterAppointments(int tabIndex) {
    setState(() {
      List<dynamic> rawAppointments =
          _appointmentsData.doctorAppointmentsList
              .map(
                (appointment) =>
                    appointment is AppointmentModel
                        ? {
                          '_id': appointment.id,
                          'patientId': appointment.patientId,
                          'doctorId': appointment.doctorId,
                          'date': appointment.date,
                          'time': appointment.time,
                          'reason': appointment.reason,
                          'status': appointment.status,
                          'createdAt': appointment.createdAt.toIso8601String(),
                        }
                        : appointment,
              )
              .toList();

      switch (tabIndex) {
        case 0: // All
          _filteredAppointments = List.from(rawAppointments);
          break;
        case 1: // Upcoming
          _filteredAppointments =
              rawAppointments.where((appointment) {
                final status = appointment['status']?.toLowerCase() ?? '';
                return status == 'confirmed' || status == 'scheduled';
              }).toList();
          break;
        case 2: // Completed
          _filteredAppointments =
              rawAppointments.where((appointment) {
                final status = appointment['status']?.toLowerCase() ?? '';
                return status == 'completed';
              }).toList();
          break;
        case 3: // Cancelled
          _filteredAppointments =
              rawAppointments.where((appointment) {
                final status = appointment['status']?.toLowerCase() ?? '';
                return status == 'cancelled';
              }).toList();
          break;
      }
    });
  }

  void _refreshAppointments() {
    // Force a refresh from API
    _appointmentsData.appointmentsLoaded = false;
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false, // Allow content to extend behind status bar
        child: Column(
          children: [
            // Custom gradient header with tabs
            _buildHeader(),

            // Main content
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingView()
                      : _errorMessage != null
                      ? _buildErrorView()
                      : _filteredAppointments.isEmpty
                      ? _buildEmptyView()
                      : _buildAppointmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade700, Colors.teal.shade500],
        ),
      ),
      child: Column(
        children: [
          // Add extra padding at the top to account for status bar
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Header content with title and refresh button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                Text(
                  'My Visits',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshAppointments,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            padding: EdgeInsets.only(left: 16),
            labelPadding: EdgeInsets.symmetric(horizontal: 16),
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),

          // Add some bottom padding to the header
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 30,
            child: LoadingIndicator(
              indicatorType: Indicator.lineScalePulseOut,
              colors: const [Colors.teal],
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Failed to load appointments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              style: GoogleFonts.poppins(color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshAppointments,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message;

    switch (_tabController.index) {
      case 1:
        message = 'No upcoming appointments';
        break;
      case 2:
        message = 'No completed appointments';
        break;
      case 3:
        message = 'No cancelled appointments';
        break;
      default:
        message = 'No appointments found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new appointment by tapping the + button',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _filteredAppointments[index];
        return AppointmentCard(
          appointment: appointment,
          onTap: () async {
            // Navigate to appointment details screen
            final refreshRequired = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AppointmentDetailsScreen(appointment: appointment),
              ),
            );

            // Refresh the list if appointment was updated
            if (refreshRequired == true) {
              _refreshAppointments();
            }
          },
        );
      },
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onTap;

  const AppointmentCard({Key? key, required this.appointment, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText = appointment['status'] ?? 'Scheduled';

    switch (statusText.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    // Try to format date if it's ISO format
    String displayDate = appointment['date'] ?? 'No date';
    String displayTime = appointment['time'] ?? 'No time';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top part with status indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    "$displayDate · $displayTime",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      (appointment['patientName'] != null &&
                              appointment['patientName'].toString().isNotEmpty)
                          ? appointment['patientName']
                              .toString()[0]
                              .toUpperCase()
                          : 'P',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Patient details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['patientName'] ?? 'Unknown Patient',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          appointment['reason'] ?? 'General Checkup',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Patient ID: ${appointment['patientId'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (statusText.toLowerCase() == 'confirmed' ||
                      statusText.toLowerCase() == 'scheduled')
                    OutlinedButton.icon(
                      onPressed: () {
                        // Cancel appointment logic
                      },
                      icon: Icon(Icons.close, size: 16),
                      label: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  if (statusText.toLowerCase() == 'confirmed' ||
                      statusText.toLowerCase() == 'scheduled')
                    FilledButton.icon(
                      onPressed: () {
                        // Complete appointment logic
                      },
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Complete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (statusText.toLowerCase() != 'confirmed' &&
                      statusText.toLowerCase() != 'scheduled')
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('View Details'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
