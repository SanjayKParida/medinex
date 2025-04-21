import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    // Set status bar to light icons on transparent background
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // App logo or name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIcons.firstAid(),
                        color: Colors.teal.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Medinix",
                      style: GoogleFonts.poppins(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Illustration
                Center(
                  child: SvgPicture.asset(
                    SVGAssets.loginSvg,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Welcome text
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Welcome to Medinix",
                        style: GoogleFonts.poppins(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your trusted platform for seamless healthcare management",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),

                // Login options title
                Text(
                  "Continue as:",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                // Patient Login Button
                _buildLoginOption(
                  title: "Patient",
                  icon: PhosphorIcons.user(),
                  description:
                      "View your appointments, prescriptions, and medical history",
                  color: Colors.blue.shade700,
                  onTap: () {
                    Navigator.of(context).pushNamed(Routes.patientLoginScreen);
                  },
                ),

                const SizedBox(height: 12),

                // Doctor Login Button
                _buildLoginOption(
                  title: "Doctor",
                  icon: PhosphorIcons.stethoscope(),
                  description:
                      "Manage appointments, prescriptions, and patient records",
                  color: Colors.teal.shade700,
                  onTap: () {
                    Navigator.of(context).pushNamed(Routes.doctorLoginScreen);
                  },
                ),

                const SizedBox(height: 24),

                // Version info
                Center(
                  child: Text(
                    "v1.0.0",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOption({
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(PhosphorIcons.caretRight(), color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
