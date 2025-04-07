import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //SVG
            Center(child: SvgPicture.asset(SVGAssets.loginSvg, height: 250)),

            SizedBox(height: 20),

            //Text constants
            Text(
              "Welcome 👋",
              style: GoogleFonts.poppins(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your trusted platform for seamless healthcare management.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 20),

            Spacer(),

            Text(
              "Continue as:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 15),

            //Login buttons
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(Routes.patientLoginScreen);
              },
              child: loginContainer(
                title: "Patient",
                description:
                    "View your appointments, prescriptions, and medical history with ease.",
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(Routes.doctorLoginScreen);
              },
              child: loginContainer(
                title: "Doctor",
                description:
                    "Access your dashboard to manage appointments, prescriptions, and patient records.",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loginContainer({required String title, required String description}) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(15),
      shadowColor: Colors.black26,

      child: Container(
        padding: const EdgeInsets.all(15),
        width: MediaQuery.sizeOf(context).width,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
                Spacer(),
                Icon(PhosphorIcons.arrowRight(), color: Colors.teal),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
