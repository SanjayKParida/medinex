import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/repositories/doctor_repository.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/screens/features/doctor/patients/patient_details_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool _isUpdating = false;
  String? _errorMessage;
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  @override
  Widget build(BuildContext context) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText = widget.appointment['status'] ?? 'Scheduled';

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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          'Appointment Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body:
          _isUpdating
              ? Center(
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
                      'Updating appointment status...',
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    _buildStatusCard(statusText, statusColor, statusIcon),
                    SizedBox(height: 24),

                    // Patient Information
                    _buildSectionTitle('Patient Information'),
                    _buildInfoCard([
                      _buildInfoItem(
                        icon: Icons.person_outline,
                        title: 'Name',
                        value: widget.appointment['patientName'] ?? 'Unknown',
                      ),
                      _buildInfoItem(
                        icon: Icons.badge_outlined,
                        title: 'Patient ID',
                        value: widget.appointment['patientId'] ?? 'N/A',
                      ),
                      _buildInfoItem(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value:
                            widget.appointment['patientPhone'] ??
                            'Not provided',
                      ),
                    ]),
                    SizedBox(height: 24),

                    // Appointment Details
                    _buildSectionTitle('Appointment Details'),
                    _buildInfoCard([
                      _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date',
                        value: widget.appointment['date'] ?? 'Not set',
                      ),
                      _buildInfoItem(
                        icon: Icons.access_time_outlined,
                        title: 'Time',
                        value: widget.appointment['time'] ?? 'Not set',
                      ),
                      _buildInfoItem(
                        icon: Icons.medical_information_outlined,
                        title: 'Reason',
                        value:
                            widget.appointment['reason'] ?? 'General checkup',
                      ),
                    ]),
                    SizedBox(height: 24),

                    // Notes Section
                    _buildSectionTitle('Notes'),
                    Container(
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
                        children: [
                          Text(
                            widget.appointment['notes'] ??
                                'No notes available for this appointment.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          if (statusText.toLowerCase() == 'confirmed' ||
                              statusText.toLowerCase() == 'scheduled')
                            TextButton.icon(
                              onPressed: () {
                                // Add/edit notes logic
                              },
                              icon: Icon(Icons.edit_note, size: 16),
                              label: Text('Add Notes'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.teal,
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Error message if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    // Buttons
                    if (statusText.toLowerCase() == 'confirmed' ||
                        statusText.toLowerCase() == 'scheduled')
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => _updateAppointmentStatus('cancelled'),
                                icon: Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red,
                                ),
                                label: Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    () => _updateAppointmentStatus('completed'),
                                icon: Icon(Icons.check_circle_outline),
                                label: Text('Complete'),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // View Patient Button
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Navigate to patient details using the patient ID
                            if (widget.appointment['patientId'] != null) {
                              final patientId = widget.appointment['patientId'];

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Center(
                                    child: SizedBox(
                                      width: 40,
                                      height: 30,
                                      child: LoadingIndicator(
                                        indicatorType:
                                            Indicator.lineScalePulseOut,
                                        colors: const [Colors.teal],
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              );

                              try {
                                // Try to find patient in existing data first
                                Map<String, dynamic>? patientData;

                                // Check if we already have the patient data in our singleton
                                if (DoctorPatients().patientsLoaded) {
                                  patientData = DoctorPatients().patientsList
                                      .firstWhere(
                                        (patient) =>
                                            patient['patientId'] == patientId,
                                        orElse: () => <String, dynamic>{},
                                      );
                                }

                                // If patient not found in the list, fetch all patients
                                if (patientData == null ||
                                    patientData.isEmpty) {
                                  final doctorRepo = DoctorRepo();
                                  await doctorRepo.getDoctorPatients();

                                  patientData = DoctorPatients().patientsList
                                      .firstWhere(
                                        (patient) =>
                                            patient['patientId'] == patientId,
                                        orElse: () => <String, dynamic>{},
                                      );
                                }

                                // Close loading dialog
                                Navigator.pop(context);

                                if (patientData.isNotEmpty) {
                                  // Navigate to patient details screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PatientDetailsScreen(
                                            patient: patientData!,
                                          ),
                                    ),
                                  );
                                } else {
                                  // Patient not found
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Patient details not found',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Close loading dialog
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading patient: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Patient ID not available'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.person_search),
                          label: Text('View Patient Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.teal,
                            side: BorderSide(color: Colors.teal),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusCard(String status, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Spacer(),
          if (widget.appointment['createdAt'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Created',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat(
                    'MMM d, yyyy',
                  ).format(DateTime.parse(widget.appointment['createdAt'])),
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
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

  Widget _buildInfoCard(List<Widget> children) {
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
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
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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

  Future<void> _updateAppointmentStatus(String newStatus) async {
    if (widget.appointment['id'] == null) {
      setState(() {
        _errorMessage = 'Cannot update: Appointment ID is missing';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      // Example implementation - you would need to create this method in your repository
      final Map<String, dynamic> result = await _appointmentRepo
          .updateAppointmentStatus(
            appointmentId: widget.appointment['id'],
            status: newStatus,
          );

      setState(() {
        _isUpdating = false;
      });

      if (result['success']) {
        // Show success message and pop back to appointments list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to appointments list with refresh flag
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to update appointment status';
        });
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
}
