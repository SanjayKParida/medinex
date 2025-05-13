import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/repositories/patient_home_screen_repo.dart';
import 'package:medinix_frontend/screens/features/patient/appointments/appointments_screen.dart';

import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/widgets/appointment_card_widget.dart';
import 'package:medinix_frontend/widgets/health_tips_card_widget.dart';
import 'package:medinix_frontend/widgets/top_pick_card_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static GlobalKey<_HomeScreenState> homeKey = GlobalKey<_HomeScreenState>();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDoctorsLoading = false;
  bool isAppointmentLoading = false;
  late List<VerifiedDoctor> verifiedDoctors;

  final PageController _pageController = PageController();
  int currentPage = 0;
  String? patientName;

  @override
  void initState() {
    _getPatientInfo();
    if (!Appointments().appointmentsLoaded) {
      loadPatientAppointments();
    }
    if (!ApprovedDoctors().verifiedDoctorsListLoaded) {
      loadVerifiedDoctors();
    }
    super.initState();
  }

  void _getPatientInfo() {
    final userDetails = SharedPreferencesService.getInstance().getUserDetails();
    patientName = userDetails?['name'] ?? 'Patient';
  }

  void loadPatientAppointments() async {
    if (Appointments().appointmentsLoaded && !isAppointmentLoading) {
      setState(() {
        isAppointmentLoading = false;
      });
      return;
    }

    setState(() {
      isAppointmentLoading = true;
    });

    SharedPreferencesService prefs = SharedPreferencesService.getInstance();
    final userData = prefs.getUserDetails();
    try {
      final response = await PatientHomeScreenRepo().getPatientAppointments(
        userData?['patientId'],
      );
      if (response['success'] == true) {
        setState(() {
          isAppointmentLoading = false;
          Appointments().appointmentsLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        isAppointmentLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load appointments :(")));
    }
  }

  void loadVerifiedDoctors() async {
    setState(() {
      isDoctorsLoading = true;
    });

    try {
      await PatientHomeScreenRepo().getVerifiedDoctors();
      verifiedDoctors = ApprovedDoctors().verifiedDoctorsList;
      setState(() {
        isDoctorsLoading = false;
        ApprovedDoctors().verifiedDoctorsListLoaded = true;
      });
    } catch (error) {
      setState(() {
        isDoctorsLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load doctors :(")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add status bar configuration
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        color: Colors.teal,
        onRefresh: () async {
          loadPatientAppointments();
          loadVerifiedDoctors();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(),
                      const SizedBox(height: 10),
                      Text(
                        "Hope you're feeling healthy today!",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildAppointmentsSection(),
              _buildTopDoctorsSection(),
              _buildHealthTipsSection(),
              // Footer
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "by  ",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "PRTCL",
                      style: GoogleFonts.limelight(
                        fontSize: 24,
                        color: Colors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return Row(
        children: [
          Text(
            "Good Morning",
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10),
          Image.asset(PNGAssets.morningPng, height: 30),
        ],
      );
    } else if (hour < 17) {
      return Row(
        children: [
          Text(
            "Good Afternoon",
            style: GoogleFonts.poppins(
              color: Colors.teal,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10),
          Image.asset(PNGAssets.afternoonPng, height: 30),
        ],
      );
    }
    return Row(
      children: [
        Text(
          "Good Evening",
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 10),
        Image.asset(PNGAssets.nightPng, height: 30),
      ],
    );
  }

  Widget _buildAppointmentsSection() {
    return isAppointmentLoading
        ? _buildLoadingAppointments()
        : Appointments().patientAppointmentsList.isNotEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Appointments",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Simple navigation to appointments screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.25,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 10),
                itemCount:
                    Appointments().patientAppointmentsList.length > 3
                        ? 3
                        : Appointments().patientAppointmentsList.length,
                itemBuilder: (context, index) {
                  // Sort appointments by date to show latest first
                  final sortedAppointments = [
                    ...Appointments().patientAppointmentsList,
                  ];
                  sortedAppointments.sort(
                    (a, b) => DateTime.parse(
                      b.date,
                    ).compareTo(DateTime.parse(a.date)),
                  );

                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: AppointmentCard(
                      appointment: sortedAppointments[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.appointmentDetailsScreen,
                          arguments: sortedAppointments[index],
                        );
                      },
                      onCancelTap: (appointmentId) {
                        _showCancellationDialog(appointmentId);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        )
        : _buildEmptyAppointments();
  }

  Widget _buildTopDoctorsSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Top Doctors",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to see all doctors
                },
                child: Text(
                  'Browse All',
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 195,
            child:
                isDoctorsLoading
                    ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.teal),
                    )
                    : ApprovedDoctors().verifiedDoctorsList.isEmpty
                    ? _buildEmptyState(
                      'No doctors available',
                      'Check back later for available doctors',
                      PhosphorIcons.stethoscope(),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: ApprovedDoctors().verifiedDoctorsList.length,
                      itemBuilder: (context, index) {
                        VerifiedDoctor pickedDoctor =
                            ApprovedDoctors().verifiedDoctorsList[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: TopPickCard(
                            doctor: pickedDoctor,
                            onTap: () {
                              // Just navigate to the appointment booking screen
                              Navigator.pushNamed(
                                context,
                                Routes.appointmentBookingScreen,
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Health Tips",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.25,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: healthTips.length,
              itemBuilder: (context, index) {
                return HealthTipCard(
                  healthTip: healthTips[index],
                  primaryColor: Colors.teal,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Add cancellation dialog
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
                                      final result =
                                          await AppointmentRepository()
                                              .cancelAppointment(
                                                appointmentId: appointmentId,
                                                reason:
                                                    reasonController.text
                                                        .trim(),
                                                cancelledBy: 'patient',
                                              );

                                      if (result['success']) {
                                        Navigator.of(context).pop(result);
                                      } else {
                                        print("result: $result");
                                        setState(() {
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

  // Helper method to update appointment status locally
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

  // Add missing loading appointments method
  Widget _buildLoadingAppointments() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              "Loading your appointments...",
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

  // Add missing empty appointments method
  Widget _buildEmptyAppointments() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.calendar(), size: 60, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            "No appointments scheduled",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Book an appointment with a doctor to get started",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, Routes.appointmentBookingScreen);
            },
            icon: Icon(PhosphorIcons.plus(), color: Colors.white),
            label: Text("Book Appointment"),
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
    );
  }
}
