import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinix_frontend/constants/assets.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/login_repo.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isLoading = false;

  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();
  final TextEditingController _field4Controller = TextEditingController();

  final FocusNode _field1FocusNode = FocusNode();
  final FocusNode _field2FocusNode = FocusNode();
  final FocusNode _field3FocusNode = FocusNode();
  final FocusNode _field4FocusNode = FocusNode();

  int _remainingSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _field1FocusNode.requestFocus();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _remainingSeconds = 30;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds > 0) {
          _startResendTimer();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  // Get full OTP
  String get _otp =>
      '${_field1Controller.text}${_field2Controller.text}${_field3Controller.text}${_field4Controller.text}';

  Future<void> verifyOtp() async {
    String otp = _otp.trim();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 4-digit OTP")),
      );
      return;
    }

    try {
      final verifyResponse = await LoginRepo().verifyOtp(
        widget.phoneNumber,
        otp,
      );
      final verifyBody = verifyResponse["body"];

      if (verifyResponse["statusCode"] == 200 &&
          verifyBody != null &&
          verifyBody["message"] == "OTP verified successfully") {
        final loginResponse = await LoginRepo().loginPatient(
          widget.phoneNumber,
        );
        print("login response: $loginResponse");

        final loginStatusCode = loginResponse["statusCode"];
        final loginBody = loginResponse["body"];

        if (loginStatusCode == 200 &&
            loginBody != null &&
            loginBody["response"] == true) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.patientDashboard,
            (route) => false,
          );
        } else if (loginResponse["statusCode"] == 200 &&
            loginBody != null &&
            loginBody["response"] == false &&
            loginBody["message"].toString().contains("Patient not found")) {
          Navigator.pushReplacementNamed(
            context,
            Routes.patientDetailScreen,
            arguments: widget.phoneNumber,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loginBody?["message"] ??
                    "Failed to log in patient. Please try again.",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verifyBody?["message"] ??
                  verifyBody?["error"] ??
                  "OTP verification failed",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  void _resendOtp() {
    if (_canResend) {
      print('Resending OTP to: ${widget.phoneNumber}');

      _field1Controller.clear();
      _field2Controller.clear();
      _field3Controller.clear();
      _field4Controller.clear();

      _field1FocusNode.requestFocus();

      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();
    _field4Controller.dispose();

    _field1FocusNode.dispose();
    _field2FocusNode.dispose();
    _field3FocusNode.dispose();
    _field4FocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SVG Image
              Center(
                child: SvgPicture.asset(
                  SVGAssets
                      .otpVerificationSvg, // Replace with your actual SVG asset
                  height: 220,
                ),
              ),
              SizedBox(height: 30),

              // Header
              Text(
                "Verification Code",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),

              SizedBox(height: 10),

              // Phone info text
              Text(
                "We have sent the verification code to\n ${widget.phoneNumber}",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              SizedBox(height: 30),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOtpField(
                    controller: _field1Controller,
                    focusNode: _field1FocusNode,
                    nextFocusNode: _field2FocusNode,
                    previousFocusNode: null,
                  ),
                  _buildOtpField(
                    controller: _field2Controller,
                    focusNode: _field2FocusNode,
                    nextFocusNode: _field3FocusNode,
                    previousFocusNode: _field1FocusNode,
                  ),
                  _buildOtpField(
                    controller: _field3Controller,
                    focusNode: _field3FocusNode,
                    nextFocusNode: _field4FocusNode,
                    previousFocusNode: _field2FocusNode,
                  ),
                  _buildOtpField(
                    controller: _field4Controller,
                    focusNode: _field4FocusNode,
                    nextFocusNode: null,
                    previousFocusNode: _field3FocusNode,
                    isLastField: true,
                  ),
                ],
              ),

              SizedBox(height: 30),

              // Verify Button
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await verifyOtp();
                  setState(() {
                    _isLoading = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                          "Verify",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
              ),

              SizedBox(height: 20),

              // Resend OTP
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the OTP? ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendOtp : null,
                      child: Text(
                        _canResend
                            ? "Resend OTP"
                            : "Wait $_remainingSeconds seconds",
                        style: GoogleFonts.poppins(
                          color: _canResend ? Colors.teal : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocusNode,
    required FocusNode? previousFocusNode,
    bool isLastField = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      width: 65,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: (value) {
          if (value.length == 1) {
            // Auto advance to next field
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            } else if (isLastField) {
              // Hide keyboard if last field
              FocusManager.instance.primaryFocus?.unfocus();
            }
          } else if (value.isEmpty && previousFocusNode != null) {
            // Go back to previous field on delete
            previousFocusNode.requestFocus();
          }
        },
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
