import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final SharedPreferencesService _prefsService =
      SharedPreferencesService.getInstance();

  bool _isLoadingAppointments = true;
  List<dynamic> _appointments = [];
  String? _errorMessage;

  // Flag to determine if this patient is linked to current doctor
  bool _isPatientLinkedToDoctor = false;
  String? _currentDoctorId;

  @override
  void initState() {
    super.initState();
    _checkDoctorPatientRelationship();
  }

  void _checkDoctorPatientRelationship() async {
    // Get current doctor ID from shared preferences
    final userDetails = _prefsService.getUserDetails();
    _currentDoctorId = userDetails?['doctorId'];

    // Check if this patient has a doctorId that matches the current doctor
    final patientDoctorId = widget.patient['doctorId'];

    // Set flag based on whether IDs match
    setState(() {
      _isPatientLinkedToDoctor =
          patientDoctorId != null &&
          _currentDoctorId != null &&
          patientDoctorId == _currentDoctorId;

      // Initialize tab controller based on relationship
      _tabController = TabController(
        length: _isPatientLinkedToDoctor ? 3 : 2,
        vsync: this,
      );
    });

    // Only fetch appointments if patient is linked to doctor
    if (_isPatientLinkedToDoctor) {
      _fetchPatientAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _errorMessage = null;
    });

    try {
      final result = await _appointmentRepo.getAppointments(
        patientId: widget.patient['patientId'],
      );

      setState(() {
        _isLoadingAppointments = false;
        if (result['success']) {
          _appointments = result['appointments'] ?? [];
        } else {
          _errorMessage = result['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingAppointments = false;
        _errorMessage = 'Error loading appointments: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build correct tabs and content based on relationship flag
    final List<Widget> tabs = [
      const Tab(text: 'Overview'),
      const Tab(text: 'Medical'),
    ];

    final List<Widget> tabViews = [_buildOverviewTab(), _buildMedicalTab()];

    // Add appointments tab only if patient is linked to doctor
    if (_isPatientLinkedToDoctor) {
      tabs.add(const Tab(text: 'Appointments'));
      tabViews.add(_buildAppointmentsTab());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: tabs,
        ),
      ),
      body: TabBarView(controller: _tabController, children: tabViews),
      floatingActionButton:
          _isPatientLinkedToDoctor && _tabController.index == 2
              ? FloatingActionButton(
                onPressed: () {
                  // Navigate to create appointment screen
                  final args = {"pickedPatient": widget.patient};
                  Navigator.pushNamed(
                    context,
                    Routes.createAppointmentScreen,
                    arguments: args,
                  );
                },
                backgroundColor: Colors.teal,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          _buildPatientProfileCard(),
          SizedBox(height: 20),

          // Contact Info
          _buildSectionTitle('Contact Information'),
          _buildInfoCard(
            children: [
              _buildInfoItem(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: widget.patient['phoneNumber'] ?? 'Not provided',
              ),
              _buildInfoItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: widget.patient['email'] ?? 'Not provided',
              ),
              _buildInfoItem(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: widget.patient['address'] ?? 'Not provided',
              ),
              _buildInfoItem(
                icon: Icons.contacts_outlined,
                title: 'Emergency Contact',
                value: widget.patient['emergencyContact'] ?? 'Not provided',
              ),
            ],
          ),
          SizedBox(height: 20),

          // Registration Details
          _buildSectionTitle('Registration Details'),
          _buildInfoCard(
            children: [
              _buildInfoItem(
                icon: Icons.numbers_outlined,
                title: 'Patient ID',
                value: widget.patient['patientId'] ?? 'N/A',
              ),
              _buildInfoItem(
                icon: Icons.calendar_today_outlined,
                title: 'Registration Date',
                value:
                    widget.patient['registrationDate'] != null
                        ? DateFormat('MMM d, yyyy').format(
                          DateTime.parse(widget.patient['registrationDate']),
                        )
                        : 'Not available',
              ),
              _buildInfoItem(
                icon: Icons.event_available_outlined,
                title: 'Last Visit',
                value:
                    widget.patient['lastVisit'] != null
                        ? DateFormat(
                          'MMM d, yyyy',
                        ).format(DateTime.parse(widget.patient['lastVisit']))
                        : 'No visits recorded',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vital Information
          _buildSectionTitle('Basic Health Information'),
          _buildInfoCard(
            children: [
              _buildInfoItem(
                icon: Icons.cake_outlined,
                title: 'Date of Birth',
                value: widget.patient['dob'] ?? 'Not provided',
              ),
              _buildInfoItem(
                icon: Icons.monitor_weight_outlined,
                title: 'Weight',
                value:
                    widget.patient['weight'] != null
                        ? '${widget.patient['weight']} kg'
                        : 'Not recorded',
              ),
              _buildInfoItem(
                icon: Icons.height_outlined,
                title: 'Height',
                value:
                    widget.patient['height'] != null
                        ? '${widget.patient['height']} cm'
                        : 'Not recorded',
              ),
              _buildInfoItem(
                icon: Icons.bloodtype_outlined,
                title: 'Blood Group',
                value: widget.patient['bloodGroup'] ?? 'Not recorded',
              ),
            ],
          ),
          SizedBox(height: 20),

          // Medical Conditions
          _buildSectionTitle('Medical History'),
          _buildInfoCard(
            children: [
              _buildInfoItem(
                icon: Icons.medical_information_outlined,
                title: 'Medical Conditions',
                value: widget.patient['medicalCondition'] ?? 'None recorded',
                valueTextStyle: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
              _buildInfoItem(
                icon: Icons.medication_outlined,
                title: 'Current Medications',
                value: widget.patient['currentMedications'] ?? 'None recorded',
                valueTextStyle: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
              _buildInfoItem(
                icon: Icons.dangerous_outlined,
                title: 'Allergies',
                value: widget.patient['allergies'] ?? 'None recorded',
                valueTextStyle: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Surgical History
          _buildSectionTitle('Surgical History'),
          _buildInfoCard(
            children: [
              _buildInfoItem(
                icon: Icons.medical_services_outlined,
                title: 'Past Surgeries',
                value:
                    widget.patient['pastSurgeries'] ?? 'No surgeries recorded',
                valueTextStyle: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_isLoadingAppointments) {
      return Center(
        child: SizedBox(
          width: 40,
          height: 30,
          child: LoadingIndicator(
            indicatorType: Indicator.lineScalePulseOut,
            colors: const [Colors.teal],
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red.shade800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPatientAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No appointments found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Schedule a new appointment using the + button',
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

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildPatientProfileCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  (widget.patient['name'] != null &&
                          widget.patient['name'].toString().isNotEmpty)
                      ? widget.patient['name'].toString()[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient['name'] ?? 'Unknown Patient',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          widget.patient['gender'] ?? 'Not specified',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          widget.patient['dob'] ?? 'Not specified',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          widget.patient['phoneNumber'] ?? 'Not specified',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    TextStyle? valueTextStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.teal),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style:
                      valueTextStyle ??
                      GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;

    switch (appointment['status']?.toLowerCase() ?? 'scheduled') {
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

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // View appointment details
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['reason'] ?? 'General Checkup',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          appointment['status'] ?? 'Scheduled',
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8),
                        Text(
                          appointment['date'] ?? 'No date',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8),
                        Text(
                          appointment['time'] ?? 'No time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
