import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/utilities/doctor_data_service.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _doctorService = DoctorDataService.getInstance();
  final _prefsService = SharedPreferencesService.getInstance();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      debugPrint('PROFILE: Initializing DoctorDataService');
      await _doctorService.init();

      // Attempt to refresh doctor data for the latest information
      debugPrint('PROFILE: Refreshing doctor data');
      // Add a refreshDoctorData method call here if available

      debugPrint('PROFILE: Doctor data loaded successfully');
    } catch (e) {
      debugPrint('PROFILE: Error loading doctor data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Logout', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _prefsService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.loginScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use DoctorDataService getters
    final doctorName = _doctorService.name;
    final email = _doctorService.email;
    final phoneNumber = _doctorService.mobileNumber;
    final specialization = _doctorService.specialization;
    final doctorId = _doctorService.doctorId;

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
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with profile image and basic info
                      _buildProfileHeader(doctorName, specialization),

                      SizedBox(height: 20),

                      // Information sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Personal Information'),
                            _buildInfoCard([
                              _buildInfoItem(
                                PhosphorIcons.identificationCard(),
                                'Doctor ID',
                                doctorId,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.envelope(),
                                'Email',
                                email,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.phone(),
                                'Phone',
                                phoneNumber,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.stethoscope(),
                                'Specialization',
                                specialization,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.buildings(),
                                'Clinic Name',
                                _doctorService.clinicName,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.mapPin(),
                                'Work Address',
                                _doctorService.workAddress,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.certificate(),
                                'Medical Registration',
                                _doctorService.medicalRegistrationNumber,
                              ),
                              _buildInfoItem(
                                PhosphorIcons.clockCounterClockwise(),
                                'Years of Experience',
                                _doctorService.yearsOfExperience,
                              ),
                            ]),

                            SizedBox(height: 20),

                            _buildSectionTitle('Account'),
                            _buildActionCard([
                              _buildActionItem(
                                PhosphorIcons.gear(),
                                'Settings',
                                'App preferences and notifications',
                                () {
                                  // Navigate to settings
                                },
                              ),
                              _buildActionItem(
                                PhosphorIcons.shieldStar(),
                                'Privacy',
                                'Manage your data and privacy',
                                () {
                                  // Navigate to privacy settings
                                },
                              ),
                              _buildActionItem(
                                PhosphorIcons.signOut(),
                                'Logout',
                                'Sign out from your account',
                                () => _logout(context),
                                isDestructive: true,
                              ),
                            ]),

                            SizedBox(height: 32),

                            Center(
                              child: Text(
                                'Medinix v1.0.0',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String specialization) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Row(
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  specialization,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.teal, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
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

  Widget _buildActionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.teal,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(),
              color: isDestructive ? Colors.red.shade300 : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
