import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/screens/features/doctor/appointments/appointments_screen.dart';
import 'package:medinix_frontend/screens/features/doctor/home/home_screen.dart';
import 'package:medinix_frontend/screens/features/doctor/patients/patients_screen.dart';
import 'package:medinix_frontend/screens/features/doctor/profile/profile_screen.dart';
import 'package:medinix_frontend/screens/features/doctor/scanner/qr_scanner_widget.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(
      key: HomeScreen.homeKey,
      openScanner: false,
      onNavigateToVisits: _navigateToVisits,
      onNavigateToPatients: _navigateToPatients,
    ),
    AppointmentsScreen(),
    PatientsScreen(),
    ProfileScreen(),
  ];

  void _navigateToVisits() {
    // print("Navigating to Visits tab");
    setState(() {
      _selectedIndex = 1; // Switch to Visits tab
    });
  }

  void _navigateToPatients() {
    // print("Navigating to Patients tab");
    setState(() {
      _selectedIndex = 2; // Switch to Patients tab
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Material(
        elevation: 100,
        shadowColor: Colors.teal,
        child: SizedBox(
          height: 70,
          child: BottomNavigationBar(
            selectedLabelStyle: GoogleFonts.poppins(),
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0
                      ? PhosphorIcons.house(PhosphorIconsStyle.fill)
                      : PhosphorIcons.house(),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1
                      ? PhosphorIcons.calendar(PhosphorIconsStyle.fill)
                      : PhosphorIcons.calendar(),
                ),
                label: 'Visits',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 2
                      ? PhosphorIcons.users(PhosphorIconsStyle.fill)
                      : PhosphorIcons.users(),
                ),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3
                      ? PhosphorIcons.userCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.userCircle(),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff009797), Color(0xff4cb6b6), Color(0xff99d5d5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(PhosphorIcons.qrCode(), color: Colors.white),
          onPressed: () {
            // Show QR scanner in bottom sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (context) {
                return QRScannerWidget(
                  onPatientFound: (patientData) {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      Routes.patientDetailsScreen,
                      arguments: patientData,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
