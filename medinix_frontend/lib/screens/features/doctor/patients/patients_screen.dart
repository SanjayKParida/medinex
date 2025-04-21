import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';
import 'package:medinix_frontend/screens/features/doctor/patients/patient_details_screen.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:loading_indicator/loading_indicator.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final DoctorRepo _doctorRepo = DoctorRepo();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
    });

    // Only fetch if data isn't already loaded
    if (!DoctorPatients().patientsLoaded) {
      await _doctorRepo.getDoctorPatients();
    }

    setState(() {
      _isLoading = false;
    });
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
            // Custom gradient header
            _buildHeader(),

            // Main content
            Expanded(child: _buildContent()),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
            child: Row(
              children: [
                Text(
                  'My Patients',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchPatients,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
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
    } else if (DoctorPatients().errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                DoctorPatients().errorMessage!,
                style: GoogleFonts.poppins(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPatients,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    } else if (DoctorPatients().patientsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No patients linked to your account yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Scan a patient QR code to add them',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: DoctorPatients().patientsList.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final patient = DoctorPatients().patientsList[index];
          return PatientCard(patient: patient);
        },
      );
    }
  }
}

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              _buildPatientHeader(),

              // Details section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient info (DOB, gender, phone, etc)
                    _buildPatientInfo(),

                    // Actions row (buttons)
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade700, Colors.teal.shade500],
        ),
      ),
      child: Row(
        children: [
          // Avatar with first letter of name
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              (patient['name'] != null && patient['name'].toString().isNotEmpty)
                  ? patient['name'].toString()[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ),
          SizedBox(width: 16),

          // Name and ID
          Expanded(
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['name'] ?? 'Unknown Patient',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ID: ${patient['patientId'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.cake_outlined,
          label: 'DOB',
          value: patient['dob'] ?? 'Not specified',
        ),
        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Gender',
          value: patient['gender'] ?? 'Not specified',
        ),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: patient['phoneNumber'] ?? 'Not specified',
        ),
        if (patient['address'] != null)
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: patient['address'],
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade300),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            final args = {"pickedPatient": patient};
            Navigator.pushNamed(
              context,
              Routes.createAppointmentScreen,
              arguments: args,
            );
          },
          icon: Icon(Icons.calendar_today_outlined, size: 18),
          label: Text('Schedule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal,
            side: BorderSide(color: Colors.teal.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () {
            // Navigate to patient details screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(patient: patient),
              ),
            );
          },
          icon: Icon(Icons.visibility_outlined, size: 18),
          label: Text('View'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
