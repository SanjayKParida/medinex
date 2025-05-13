import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/repositories/patient_home_screen_repo.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final PatientHomeScreenRepo _repo = PatientHomeScreenRepo();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  bool _isLoading = false;
  String? _errorMessage;
  List<String> filters = ['All', 'Upcoming', 'Completed', 'Cancelled'];
  String selectedFilter = 'All';
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final userData = SharedPreferencesService.getInstance().getUserDetails();
      final patientId = userData?['patientId'];
      _patientId = patientId;

      if (patientId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Patient ID not found. Please login again.';
        });
        return;
      }

      // Reset the singleton data
      Appointments().patientAppointmentsList.clear();
      Appointments().appointmentsLoaded = false;

      final response = await _repo.getPatientAppointments(patientId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success'] == true) {
            Appointments().appointmentsLoaded = true;
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load appointments';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _showCancellationDialog(String appointmentId) async {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.cancel_outlined, color: Colors.red),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Cancel Appointment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Please provide a reason for cancellation:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        errorText: errorMessage,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () {
                                    Navigator.of(context).pop();
                                  },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () async {
                                    if (reasonController.text.trim().isEmpty) {
                                      setState(() {
                                        errorMessage =
                                            'Please enter a valid reason';
                                      });
                                      return;
                                    }

                                    setState(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final result = await _appointmentRepo
                                          .cancelAppointment(
                                            appointmentId: appointmentId,
                                            reason:
                                                reasonController.text.trim(),
                                            cancelledBy: 'patient',
                                          );

                                      if (result['success']) {
                                        // Update the appointment status in the local list immediately
                                        Navigator.of(context).pop(result);
                                      } else {
                                        setState(() {
                                          print("result: $result");
                                          isSubmitting = false;
                                          errorMessage =
                                              result['message'] ??
                                              'Failed to cancel appointment';
                                        });
                                      }
                                    } catch (er, st) {
                                      print("error: $er");
                                      print("stack trace: $st");
                                      setState(() {
                                        isSubmitting = false;
                                        errorMessage =
                                            'Failed to cancel appointment: $er';
                                      });
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isSubmitting
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Submit',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result['success'] == true) {
        // Update the local list immediately after dialog closes
        _updateLocalAppointmentStatus(appointmentId, 'cancelled');

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Appointment cancelled successfully',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _updateLocalAppointmentStatus(String appointmentId, String newStatus) {
    if (mounted) {
      setState(() {
        // Find the appointment in the singleton and update its status
        final index = Appointments().patientAppointmentsList.indexWhere(
          (appointment) => appointment.id == appointmentId,
        );

        if (index != -1) {
          // Create a new appointment with updated status
          final oldAppointment = Appointments().patientAppointmentsList[index];

          // Make sure all values are properly handled as non-null strings
          final updatedAppointment = AppointmentModel(
            id: oldAppointment.id,
            patientId: oldAppointment.patientId,
            doctorId: oldAppointment.doctorId,
            date: oldAppointment.date,
            time: oldAppointment.time,
            reason: oldAppointment.reason,
            status: newStatus,
            createdAt: oldAppointment.createdAt,
          );

          // Replace the old appointment with the updated one
          Appointments().patientAppointmentsList[index] = updatedAppointment;
        }
      });
    }
  }

  List<AppointmentModel> _getFilteredAppointments() {
    final appointments = Appointments().patientAppointmentsList;

    if (selectedFilter == 'All') {
      return appointments;
    }

    return appointments.where((appointment) {
      final status = appointment.status.toLowerCase();

      if (selectedFilter == 'Upcoming') {
        return status == 'scheduled' || status == 'confirmed';
      } else if (selectedFilter == 'Completed') {
        return status == 'completed';
      } else if (selectedFilter == 'Cancelled') {
        return status == 'cancelled' || status == 'rejected';
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        color: Colors.teal,
        onRefresh: _fetchAppointments,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFilterChips(),
              Expanded(
                child:
                    _isLoading
                        ? _buildLoadingState()
                        : _errorMessage != null
                        ? _buildErrorState()
                        : _buildAppointmentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Appointments',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                onPressed: _fetchAppointments,
                icon: Icon(
                  PhosphorIcons.arrowClockwise(),
                  color: Colors.teal,
                  size: 24,
                ),
                tooltip: 'Refresh appointments',
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Manage your scheduled appointments',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter),
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
              backgroundColor: Colors.white,
              selectedColor: Colors.teal,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.teal : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: CupertinoActivityIndicator(color: Colors.teal),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your appointments...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.warning(), size: 48, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load appointments',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAppointments,
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final appointments = _getFilteredAppointments();

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No appointments found';
    String subMessage = 'You don\'t have any appointments yet';

    if (selectedFilter != 'All') {
      message = 'No ${selectedFilter.toLowerCase()} appointments';
      subMessage =
          'You don\'t have any ${selectedFilter.toLowerCase()} appointments';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.calendar(),
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Parse date and time
    DateTime? appointmentDate;
    try {
      if (appointment.date != null) {
        appointmentDate = DateTime.parse(appointment.date!);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Determine status color
    Color statusColor;
    IconData statusIcon;

    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = PhosphorIcons.check();
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = PhosphorIcons.clock();
        break;
      case 'completed':
        statusColor = Colors.teal;
        statusIcon = PhosphorIcons.checkCircle();
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = PhosphorIcons.x();
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = PhosphorIcons.question();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Appointment header with date and status
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date display
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIcons.calendar(),
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointmentDate != null
                              ? dateFormat.format(appointmentDate)
                              : 'Date not available',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          appointment.time ?? 'Time not specified',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 6),
                      Text(
                        appointment.status.capitalize(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // Appointment details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.teal.shade50,
                      child: Text(
                        'D',
                        style: GoogleFonts.poppins(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor (ID: ${appointment.doctorId})',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Appointment ID: ${appointment.id.substring(0, 8)}...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Reason
                if (appointment.reason != null &&
                    appointment.reason!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        appointment.reason!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                // Actions buttons if appointment is upcoming
                if (appointment.status.toLowerCase() == 'scheduled' ||
                    appointment.status.toLowerCase() == 'confirmed')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement reschedule
                          },
                          icon: Icon(PhosphorIcons.calendarX()),
                          label: Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.shade200),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showCancellationDialog(appointment.id);
                          },
                          icon: Icon(PhosphorIcons.x()),
                          label: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
