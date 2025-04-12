import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/auth_repo.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //SVG
                Center(
                  child: SvgPicture.asset(
                    SVGAssets.patientLoginSvg,
                    height: 250,
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  "Enter your phone number",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),

                SizedBox(height: 15),

                //Phone Text Field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      // Always visible prefix
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '+91',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                      // Vertical divider
                      Container(height: 30, width: 1, color: Colors.grey),
                      // Phone input field
                      Expanded(
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              setState(() {});
                            }
                          },
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              counterText: '',
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: (value) {
                              // Handle phone number changes if needed
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),

                Center(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      final phoneNumber = "+91${_phoneController.text}";
                      print("Phone for API: $phoneNumber");

                      await AuthRepo().sendOtp(phoneNumber);

                      setState(() {
                        _isLoading = false;
                      });

                      Map<String, dynamic> args = {"phoneNumber": phoneNumber};

                      Navigator.pushNamed(
                        context,
                        Routes.otpVerificationScreen,
                        arguments: args,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.teal,
                      ),
                      height: 50,
                      width: MediaQuery.sizeOf(context).width * 0.7,
                      child: Center(
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20.0,
                                  width: 20.0,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  "Continue",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
