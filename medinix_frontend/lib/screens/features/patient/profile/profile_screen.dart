import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:medinix_frontend/utilities/patient_data_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _patientDataService = PatientDataService.getInstance();
  final _prefsService = SharedPreferencesService.getInstance();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
  }

  Future<void> _loadPatientInfo() async {
    try {
      debugPrint('PROFILE: Ensuring PatientDataService is initialized');
      final initialized = await _patientDataService.init();

      if (!initialized) {
        setState(() {
          _errorMessage =
              'Failed to initialize patient data: ${_patientDataService.lastError}';
          _isLoading = false;
        });
        return;
      }

      // Refresh to get latest data
      debugPrint('PROFILE: Refreshing patient data');
      final refreshed = await _patientDataService.refreshPatientData();

      if (refreshed) {
        debugPrint('PROFILE: Patient data loaded successfully');
      } else {
        debugPrint('PROFILE: Failed to refresh patient data');
        // Continue anyway, we might have data from initialization
      }
    } catch (e) {
      debugPrint('PROFILE: Error loading patient data: $e');
      setState(() {
        _errorMessage = 'Error loading profile: $e';
      });
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.loginScreen,
          (route) => false,
        );
      }
    }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error Loading Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.red.shade700),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _loadPatientInfo();
                  },
                  child: Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Use PatientDataService to get patient information
    final patientName = _patientDataService.patientName;
    // Use patientData['email'] directly since there's no getter for it
    final email = _patientDataService.patientData['email'] ?? 'Not available';
    final phoneNumber = _patientDataService.phoneNumber;
    final bloodGroup = _patientDataService.bloodGroup;
    final patientId = _patientDataService.patientId;
    final age = _patientDataService.age;
    final gender = _patientDataService.gender;
    final address = _patientDataService.address;
    final medicalCondition = _patientDataService.medicalCondition;
    final weight = _patientDataService.weight;
    final height = _patientDataService.height;
    final pastSurgeries = _patientDataService.pastSurgeries;
    final currentMedications = _patientDataService.currentMedications;

    // Format emergency details
    String emergencyDetailsText = 'Not provided';
    if (_patientDataService.hasEmergencyContact) {
      final details = _patientDataService.emergencyDetails;
      final name = details['name'];
      final number = details['phoneNumber'];
      final relation = details['relation'] ?? '';

      emergencyDetailsText = name;
      if (relation.isNotEmpty) {
        emergencyDetailsText += ' ($relation)';
      }
      if (number != null && number.toString().isNotEmpty) {
        emergencyDetailsText += ' • $number';
      }
    }

    // Format height and weight for display if available
    String biometricsText = 'Not available';
    if (height.isNotEmpty || weight.isNotEmpty) {
      biometricsText = '';
      if (height.isNotEmpty) {
        biometricsText += '$height cm';
      }
      if (weight.isNotEmpty) {
        if (biometricsText.isNotEmpty) biometricsText += ' • ';
        biometricsText += '$weight kg';
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        top: false, // Allow content to extend behind status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile image and basic info
              _buildProfileHeader(patientName, bloodGroup),

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
                        'Patient ID',
                        patientId,
                      ),
                      _buildInfoItem(
                        PhosphorIcons.user(),
                        'Gender & Age',
                        '$gender ${age != null ? '• $age years' : ''}',
                      ),
                      _buildInfoItem(PhosphorIcons.envelope(), 'Email', email),
                      _buildInfoItem(
                        PhosphorIcons.phone(),
                        'Phone',
                        phoneNumber,
                      ),
                      if (address.isNotEmpty)
                        _buildInfoItem(
                          PhosphorIcons.mapPin(),
                          'Address',
                          address,
                        ),
                      if (biometricsText != 'Not available')
                        _buildInfoItem(
                          PhosphorIcons.ruler(),
                          'Height & Weight',
                          biometricsText,
                        ),
                    ]),

                    SizedBox(height: 20),

                    _buildSectionTitle('Health Information'),
                    _buildInfoCard([
                      _buildInfoItem(
                        PhosphorIcons.drop(),
                        'Blood Group',
                        bloodGroup.isNotEmpty ? bloodGroup : 'Not available',
                      ),
                      _buildInfoItem(
                        PhosphorIcons.heartbeat(),
                        'Medical Condition',
                        medicalCondition.isNotEmpty
                            ? medicalCondition
                            : 'None specified',
                      ),
                      if (currentMedications.isNotEmpty)
                        _buildInfoItem(
                          PhosphorIcons.pill(),
                          'Current Medications',
                          currentMedications,
                        ),
                      if (pastSurgeries.isNotEmpty)
                        _buildInfoItem(
                          PhosphorIcons.bandaids(),
                          'Past Surgeries',
                          pastSurgeries,
                        ),
                      _buildInfoItem(
                        PhosphorIcons.firstAid(),
                        'Emergency Contact',
                        emergencyDetailsText,
                      ),
                    ]),

                    SizedBox(height: 20),

                    _buildSectionTitle('Account'),
                    _buildActionCard([
                      _buildActionItem(
                        PhosphorIcons.pencilSimple(),
                        'Edit Profile',
                        'Update your personal information',
                        () {
                          // Navigate to edit profile
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

  Widget _buildProfileHeader(String name, String bloodGroup) {
    final nameToShow = name.isNotEmpty ? name : 'Patient';

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
                  'My Profile',
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
                // Profile picture with blood group badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        nameToShow.isNotEmpty
                            ? nameToShow[0].toUpperCase()
                            : 'P',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    if (bloodGroup != 'Not available')
                      Positioned(
                        right: 0,
                        bottom: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            bloodGroup,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  nameToShow,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.shieldCheck(),
                      size: 16,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Verified Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
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
