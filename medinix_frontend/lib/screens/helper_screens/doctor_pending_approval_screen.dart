import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class DoctorPendingApprovalScreen extends StatefulWidget {
  const DoctorPendingApprovalScreen({super.key});

  @override
  State<DoctorPendingApprovalScreen> createState() =>
      _DoctorPendingApprovalScreenState();
}

class _DoctorPendingApprovalScreenState
    extends State<DoctorPendingApprovalScreen> {
  Future<void> _logout() async {
    final prefsService = SharedPreferencesService.getInstance();
    await prefsService.logout();

    Navigator.pushReplacementNamed(context, Routes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              SVGAssets.pendingApprovalSvg,
              height: MediaQuery.sizeOf(context).height * 0.5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Text(
                "Your account is pending approval. You'll be notified soon. Thanks for your patience! 🙏",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _logout();
              },
              child: Text(
                "Login using different account",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
