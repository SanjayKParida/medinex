import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/screens/features/patient/appointments/appointments_screen.dart';
import 'package:medinix_frontend/screens/features/patient/home/home_screen.dart';
import 'package:medinix_frontend/screens/features/patient/profile/profile_screen.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/patient_data_service.dart';
import 'package:medinix_frontend/widgets/qr_bottom_sheet_widget.dart';
import 'package:medinix_frontend/screens/features/patient/insights/health_insights_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

// Export the state class for use in other files
class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(key: HomeScreen.homeKey),
    AppointmentsScreen(),
    HealthInsightsScreen(),
    ProfileScreen(),
  ];

  // Method to navigate to a specific tab
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
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
                      ? PhosphorIcons.hospital(PhosphorIconsStyle.fill)
                      : PhosphorIcons.hospital(),
                ),
                label: 'Visits',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 2
                      ? PhosphorIcons.tooth(PhosphorIconsStyle.fill)
                      : PhosphorIcons.tooth(),
                ),
                label: 'Health',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3
                      ? PhosphorIcons.user(PhosphorIconsStyle.fill)
                      : PhosphorIcons.user(),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          (_selectedIndex != 1 && _selectedIndex != 2)
              ? Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff009797),
                      Color(0xff4cb6b6),
                      Color(0xff99d5d5),
                    ],
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
                  icon: Icon(
                    PhosphorIcons.identificationBadge(),
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Navigate to QR screen or perform action
                    showQRCodeBottomSheet(
                      context,
                    );
                  },
                ),
              )
              : SizedBox(),
    );
  }
}
