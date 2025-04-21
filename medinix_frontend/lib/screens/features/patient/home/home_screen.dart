import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/patient_home_screen_repo.dart';
import 'package:medinix_frontend/screens/features/patient/patient_dashboard.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/widgets/appointment_card_widget.dart';
import 'package:medinix_frontend/widgets/health_tips_card_widget.dart';
import 'package:medinix_frontend/widgets/top_pick_card_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
    final appointments = Appointments().patientAppointmentsList;

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
                  "Upcoming Appointments",
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
                  // Find the ancestor of type PatientDashboard and navigate to appointments tab
                  final state =
                      context
                          .findAncestorStateOfType<State<PatientDashboard>>();
                  if (state != null) {
                    // Using dynamic invocation for navigateToTab method
                    try {
                      (state as dynamic).navigateToTab(
                        1,
                      ); // 1 is the index for Appointments tab
                    } catch (e) {
                      print('Error navigating to appointments: $e');
                    }
                  }
                },
                child: Text(
                  'View All',
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
            height: MediaQuery.sizeOf(context).height * 0.28,
            child:
                isAppointmentLoading
                    ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.teal),
                    )
                    : appointments.isNotEmpty
                    ? Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: appointments.length,
                            onPageChanged: (index) {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: AppointmentCard(
                                  appointment: appointments[index],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: appointments.length,
                          effect: JumpingDotEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            activeDotColor: Colors.teal,
                            dotColor: Colors.teal.shade100,
                          ),
                        ),
                      ],
                    )
                    : _buildEmptyState(
                      'No appointments scheduled',
                      'Book an appointment with a doctor to get started',
                      PhosphorIcons.calendar(),
                    ),
          ),
        ],
      ),
    );
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
                              final Map<String, dynamic> args = {
                                "pickedDoctor": pickedDoctor,
                              };
                              Navigator.pushNamed(
                                context,
                                Routes.appointmentBookingScreen,
                                arguments: args,
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
            height: 180,
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
}
