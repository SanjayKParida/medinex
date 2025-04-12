import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/patient_home_screen_repo.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/widgets/appointment_card_widget.dart';
import 'package:medinix_frontend/widgets/top_pick_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDoctorsLoading = false;
  bool isAppointmentLoading = false;
  late List<VerifiedDoctor> verifiedDoctors;

  @override
  void initState() {
    if (!PatientAppointments().patientAppointmentsLoaded) {
      loadPatientAppointments();
    }
    if (!ApprovedDoctors().verifiedDoctorsListLoaded) {
      loadVerifiedDoctors();
    }
    super.initState();
  }

  void loadPatientAppointments() async {
    setState(() {
      isAppointmentLoading = true;
    });
    SharedPreferencesService prefs = SharedPreferencesService.getInstance();
    final userData = prefs.getUserDetails();
    setState(() {
      isAppointmentLoading = true;
    });
    try {
      final response = await PatientHomeScreenRepo().getPatientAppointments(
        userData?['patientId'],
      );
      if (response['success'] == true) {
        print(
          "patient appointments :: ${PatientAppointments().patientAppointmentsList}",
        );
        setState(() {
          isAppointmentLoading = false;
          PatientAppointments().patientAppointmentsLoaded = true;
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
    print("loadVerifiedDoctors called");
    setState(() {
      isDoctorsLoading = true;
    });

    try {
      await PatientHomeScreenRepo().getVerifiedDoctors();
      verifiedDoctors = ApprovedDoctors().verifiedDoctorsList;
      print("doctors list ::: $verifiedDoctors}");
      // if (value['verifiedDoctors'].isEmpty) {}
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Greeting Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getGreeting(),
                    const SizedBox(height: 10),
                    Text(
                      "Hope you're feeeling healthy today!",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                buildAppointmentsSection(),
                // Top picks
                buildTopDoctorsSection(),

                const SizedBox(height: 20), // Add space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "See all",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.225,
          width: MediaQuery.sizeOf(context).width,
          child:
              isAppointmentLoading
                  ? const Center(
                    child: CupertinoActivityIndicator(color: Colors.teal),
                  )
                  : PatientAppointments().patientAppointmentsList.isEmpty
                  ? Center(
                    child: Text(
                      "You are all caught up ✅",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,

                    physics: const BouncingScrollPhysics(),

                    itemCount:
                        PatientAppointments().patientAppointmentsList.length,
                    itemBuilder: (context, index) {
                      PatientAppointmentModel pickedAppointment =
                          PatientAppointments().patientAppointmentsList[index];
                      return AppointmentCard(appointment: pickedAppointment);
                    },
                  ),
        ),
      ],
    );
  }

  Widget buildTopDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Top Picks",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to see all doctors
              },
              child: Text(
                "Browse",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 195,
          child:
              isDoctorsLoading
                  ? const Center(
                    child: CupertinoActivityIndicator(color: Colors.teal),
                  )
                  : ApprovedDoctors().verifiedDoctorsList.isEmpty
                  ? Center(
                    child: Text(
                      "No doctors available at the moment",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: ApprovedDoctors().verifiedDoctorsList.length,
                    itemBuilder: (context, index) {
                      VerifiedDoctor pickedDoctor =
                          ApprovedDoctors().verifiedDoctorsList[index];
                      return TopPickCard(
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
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget getGreeting() {
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
      Row(
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
}
