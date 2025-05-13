import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:medinix_frontend/utilities/patient_data_service.dart';
import 'package:medinix_frontend/repositories/ai_repository.dart';
import 'package:medinix_frontend/repositories/patient_repository.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'dart:convert';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  bool _isLoading = false;
  bool _isNewUser = true; // Will be set correctly in initState
  bool _showSymptomLogger = false;
  final TextEditingController _symptomController = TextEditingController();
  final PatientDataService _patientDataService =
      PatientDataService.getInstance();
  final PatientRepo _patientRepo = PatientRepo();

  // List to store health logs
  List<dynamic> _healthLogs = [];
  bool _isLoadingHealthLogs = true;

  // List to store AI diagnosis results
  final List<Map<String, dynamic>> aiDiagnosisResults = [];

  @override
  void initState() {
    super.initState();
    _checkPatientStatus();
    _fetchHealthLogs();
  }

  void _checkPatientStatus() {
    setState(() {
      // Use the PatientDataService to determine if user is new
      _isNewUser = _patientDataService.isNewUser;
    });
  }

  Future<void> _fetchHealthLogs() async {
    setState(() {
      _isLoadingHealthLogs = true;
    });

    // Get details about the user first
    final userData = _patientDataService.patientData;
    print("Full patient data: $userData");

    try {
      // Get patient ID from patient data service
      final patientId = _patientDataService.patientId;
      print("Fetching health logs for patient ID: '$patientId'");

      if (patientId.isNotEmpty) {
        // Log all patient properties to help diagnose format issues
        print("Patient ID length: ${patientId.length}");
        print(
          "Patient ID chars: ${patientId.split('').map((c) => c.codeUnitAt(0)).join(', ')}",
        );

        final result = await _patientRepo.getHealthLogs(patientId);

        print("Health logs API response structure: ${result.keys}");
        print("Health logs API response: $result");
        print("Health logs data type: ${result['healthLogs'].runtimeType}");
        print("Health logs data length: ${result['healthLogs'].length}");

        if (result['healthLogs'].isNotEmpty) {
          print("First health log: ${result['healthLogs'].first}");
        }

        if (result['error'] == null && result['healthLogs'] != null) {
          setState(() {
            _healthLogs = result['healthLogs'];
            print("Found ${_healthLogs.length} health logs");
            // If there are health logs, the patient is not a new user
            if (_healthLogs.isNotEmpty) {
              _isNewUser = false;
            }
          });
        } else {
          print('Error fetching health logs: ${result['error']}');
          setState(() {
            // Ensure empty array is set
            _healthLogs = [];
          });
        }
      } else {
        print('Cannot fetch health logs: Patient ID is empty');
        setState(() {
          _healthLogs = [];
        });
      }
    } catch (e) {
      print('Exception fetching health logs: $e');
      setState(() {
        _healthLogs = [];
      });
    } finally {
      setState(() {
        _isLoadingHealthLogs = false;
      });
    }
  }

  Future<void> _logSymptoms() async {
    if (_symptomController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var aiResponse = await AiRepository().analyzeSymptoms(
        _symptomController.text,
      );

      print("AI response extracted: $aiResponse");

      setState(() {
        _isLoading = false;
        _showSymptomLogger = false; // Hide symptom logger after analysis
        aiDiagnosisResults.add(aiResponse);
      });

      // Clear the text controller
      _symptomController.clear();

      // Update patient data with the new symptoms
      await _updatePatientSymptoms();

      // Refresh health logs after logging symptoms
      await _fetchHealthLogs();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your symptoms have been logged successfully'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing symptoms: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



 

  Future<void> _updatePatientSymptoms() async {
    // In a real implementation, this would save to backend and local storage
    await _patientDataService.updatePatientData({
      "symptoms": {
        "description": _symptomController.text,
        "severity":
            "Moderate", // Could be user-selected in a real implementation
        "frequency": "First occurrence", // Could be user-selected
      },
    });

    // After updating, refresh patient status
    _checkPatientStatus();
  }

  void _bookAppointment() {
    // Navigate to appointment booking screen
    // In a real implementation, this would use Navigator
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              // Show different content based on user status
              _isNewUser
                  ? _buildNewUserContent()
                  : Column(
                    children: [
                      if (_showSymptomLogger) _buildSymptomLogger(),
                      _buildAIHealthInsights(),
                      _buildHealthLogs(),
                      _buildUploadedRecords(),
                    ],
                  ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton:
          !_isNewUser && !_showSymptomLogger
              ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showSymptomLogger = true;
                  });
                },
                child: Container(
                  width: 180,
                  height: 56,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff009797),

                        Color.fromARGB(255, 83, 162, 162),
                        Color(0xff4cb6b6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.stethoscope(), color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Log Symptoms",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildHeader() {
    // Use patient name from PatientDataService
    final patientName = _patientDataService.patientName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Health",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
              if (!_isNewUser)
                Text(
                  "Hello, $patientName",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              PhosphorIcons.pencilSimple(),
              color: Colors.grey.shade700,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewUserContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.robot(),
                    size: 48,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Welcome to your AI Health Insights!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  "Start by logging any symptoms you're currently experiencing or book your first check-up.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSymptomLogger = true;
                      _isNewUser = false; // For demo purposes
                    });
                  },
                  icon: Icon(PhosphorIcons.notepad(), color: Colors.white),
                  label: Text("Log Symptoms"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _bookAppointment,
                  icon: Icon(PhosphorIcons.calendarPlus(), color: Colors.teal),
                  label: Text("Book Appointment"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: BorderSide(color: Colors.teal),
                    minimumSize: Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Health Profile Setup",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                _buildProfileItem(
                  title: "Do you have any allergies?",
                  icon: PhosphorIcons.drop(),
                  color: Colors.red,
                ),
                _buildProfileItem(
                  title: "Any chronic conditions?",
                  icon: PhosphorIcons.heartbeat(),
                  color: Colors.purple,
                ),
                _buildProfileItem(
                  title: "Add your current medications",
                  icon: PhosphorIcons.pill(),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
        ),
        trailing: Icon(
          PhosphorIcons.caretRight(),
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: () {
          // Handle the tap to fill in this health profile item
        },
      ),
    );
  }

  Widget _buildSymptomLogger() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Log Your Symptoms",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showSymptomLogger = false;
                        });
                      },
                      icon: Icon(PhosphorIcons.x(), size: 20),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(24, 24),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Describe your symptoms in detail:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _symptomController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        "e.g. headache, nausea, fatigue for the past 2 days",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _logSymptoms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            "Analyze Symptoms",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ],
            ),
          ),

          // Show AI diagnosis results if available
          if (aiDiagnosisResults.isNotEmpty) ...[
            SizedBox(height: 24),
            Text(
              "AI Analysis Results",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            ...aiDiagnosisResults.last["possibleConditions"]
                .map<Widget>((condition) => _buildConditionCard(condition))
                .toList(),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.warning(), color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiDiagnosisResults.last["disclaimer"],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    final bool shouldSeeDoctor = condition["recommendDoctor"] == true;
    final Color severityColor =
        condition["severity"] == "Moderate"
            ? Colors.orange
            : condition["severity"] == "Severe"
            ? Colors.red
            : Colors.green;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.stethoscope(),
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  condition["name"],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: severityColor.withOpacity(0.3)),
                ),
                child: Text(
                  condition["severity"],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (shouldSeeDoctor) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIcons.firstAid(), color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "We recommend consulting a doctor for this condition",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _bookAppointment,
              icon: Icon(PhosphorIcons.calendarPlus(), size: 16),
              label: Text("Book Appointment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIHealthInsights() {
    // Use real data from aiDiagnosisResults if available
    if (aiDiagnosisResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.brain(), color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  "AI Health Insights",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEmptyState(
              icon: PhosphorIcons.robot(),
              title: "No insights yet",
              subtitle: "Log your symptoms to get AI-powered health insights",
            ),
          ],
        ),
      );
    }

    // Use the latest analysis result
    final latestResult = aiDiagnosisResults.last;
    final conditions = latestResult['possibleConditions'] as List<dynamic>;
    final riskLevel = latestResult['riskLevel'] as String;
    final suggestions = latestResult['suggestions'] as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.brain(), color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                "AI Health Insights",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Possible Conditions Card
          _buildInsightCard(
            title: "Possible Conditions",
            content:
                conditions.isNotEmpty
                    ? conditions.join("\n• ")
                    : "No conditions identified",
            icon: PhosphorIcons.stethoscope(),
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          // Risk Level Card
          _buildInsightCard(
            title: "Risk Level",
            content: riskLevel,
            icon: PhosphorIcons.heartbeat(),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          // Suggestions Card
          _buildInsightCard(
            title: "Suggestions",
            content:
                suggestions.isNotEmpty
                    ? suggestions.join("\n• ")
                    : "No suggestions available",
            icon: PhosphorIcons.lightbulb(),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.startsWith("• ") ? content : "• $content",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthLogs() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.heartbeat(), color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Health Logs",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              // View All button
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.healthLogsScreen);
                },
                icon: Icon(
                  PhosphorIcons.arrowRight(),
                  color: Colors.teal,
                  size: 16,
                ),
                label: Text(
                  "View All",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health logs list - only show one log
          if (_isLoadingHealthLogs)
            Center(child: CircularProgressIndicator(color: Colors.teal))
          else if (_healthLogs.isEmpty)
            _buildEmptyState(
              icon: PhosphorIcons.notepad(),
              title: "No health logs yet",
              subtitle: "Your symptom logs will appear here",
            )
          else
            _buildHealthLogCard(_healthLogs.first),
        ],
      ),
    );
  }

  Widget _buildHealthLogCard(Map<String, dynamic> log) {
    final String date =
        log['createdAt'] != null
            ? DateTime.parse(log['createdAt']).toString().substring(0, 10)
            : 'Unknown date';

    final String symptoms = log['currentSymptoms'] ?? 'No symptoms recorded';

    // Parse the generatedInsights field which contains the AI analysis
    Map<String, dynamic> insights = _parseGeneratedInsights(
      log['generatedInsights'],
    );

    // Extract and limit the data for display
    List<String> possibleConditions = insights['possible_conditions'] ?? [];
    String riskLevel = insights['risk_level'] ?? 'Not specified';
    List<String> suggestions = insights['suggestions'] ?? [];

    // Limit to showing only 2 items (or all if less than 2)
    possibleConditions = possibleConditions.take(2).toList();
    suggestions = suggestions.take(2).toList();

    // For risk level, just show the first sentence if it's long
    if (riskLevel.contains('.')) {
      riskLevel = riskLevel.split('.').first + '.';
    }

    // Determine severity based on risk level
    String severity = 'Not specified';
    Color severityColor = Colors.green;

    if (riskLevel.toLowerCase().contains('moderate')) {
      severity = 'Moderate';
      severityColor = Colors.orange;
    } else if (riskLevel.toLowerCase().contains('high') ||
        riskLevel.toLowerCase().contains('severe')) {
      severity = 'Severe';
      severityColor = Colors.red;
    } else if (riskLevel.toLowerCase().contains('low')) {
      severity = 'Mild';
      severityColor = Colors.green;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: severityColor.withOpacity(0.3)),
                ),
                child: Text(
                  severity,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Symptoms Section
          Text(
            "Symptoms:",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            symptoms,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Possible Conditions Section
          if (possibleConditions.isNotEmpty) ...[
            Text(
              "Possible Conditions:",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              possibleConditions.join(', ') +
                  (insights['possible_conditions']?.length > 2 ? '...' : ''),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Risk Level Section
          Text(
            "Risk Level:",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            riskLevel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Suggestions Section
          if (suggestions.isNotEmpty) ...[
            Text(
              "Suggestions:",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  suggestions
                      .map(
                        (suggestion) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "• ",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
            if (insights['suggestions']?.length > 2)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Show full details in a modal
                    _showFullInsightsModal(log);
                  },
                  child: Text(
                    "View All",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Helper method to parse the generatedInsights field
  Map<String, dynamic> _parseGeneratedInsights(String? insights) {
    if (insights == null || insights.isEmpty) {
      return {};
    }

    // Result map to store parsed data
    Map<String, dynamic> result = {
      'possible_conditions': <String>[],
      'risk_level': '',
      'suggestions': <String>[],
    };

    try {
      // Check if it's a JSON string wrapped in backticks
      if (insights.contains('```json')) {
        // Extract the JSON string between backticks
        final jsonStart = insights.indexOf('{', insights.indexOf('```json'));
        final jsonEnd = insights.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonStr = insights.substring(jsonStart, jsonEnd);
          final parsed = jsonDecode(jsonStr);

          if (parsed['possible_conditions'] is List) {
            result['possible_conditions'] = List<String>.from(
              parsed['possible_conditions'],
            );
          }

          if (parsed['risk_level'] is String) {
            result['risk_level'] = parsed['risk_level'];
          }

          if (parsed['suggestions'] is List) {
            result['suggestions'] = List<String>.from(parsed['suggestions']);
          }
        }
      } else {
        // Parse the plain text format (key : value)
        final lines = insights.split(',');

        for (var line in lines) {
          line = line.trim();

          if (line.contains(':')) {
            final parts = line.split(':');
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();

            if (key == 'possible_conditions') {
              result['possible_conditions'] =
                  value.split(',').map((e) => e.trim()).toList();
            } else if (key == 'risk_level') {
              result['risk_level'] = value;
            } else if (key == 'suggestions') {
              result['suggestions'] =
                  value.split(',').map((e) => e.trim()).toList();
            }
          }
        }
      }

      return result;
    } catch (e) {
      print('Error parsing insights: $e');
      return result;
    }
  }

  void _showFullInsightsModal(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Detailed Health Insights",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(PhosphorIcons.x(), size: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: BouncingScrollPhysics(),
                          children: [
                            // Symptoms Section
                            _buildDetailSection(
                              title: "Symptoms",
                              content:
                                  log['currentSymptoms'] ??
                                  'No symptoms recorded',
                            ),

                            // Medical History
                            if (log['medicalHistory'] != null &&
                                log['medicalHistory'].isNotEmpty)
                              _buildDetailSection(
                                title: "Medical History",
                                content: log['medicalHistory'],
                              ),

                            // Parse insights for full display
                            _buildFullInsightsSection(log['generatedInsights']),

                            // Date
                            _buildDetailSection(
                              title: "Recorded On",
                              content:
                                  log['createdAt'] != null
                                      ? DateTime.parse(log['createdAt'])
                                          .toString()
                                          .substring(0, 16)
                                          .replaceAll('T', ' at ')
                                      : 'Unknown date',
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

  Widget _buildDetailSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullInsightsSection(String? insights) {
    if (insights == null || insights.isEmpty) {
      return SizedBox.shrink();
    }

    final parsedInsights = _parseGeneratedInsights(insights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Possible Conditions
        if (parsedInsights['possible_conditions']?.isNotEmpty ?? false)
          _buildListSection(
            title: "Possible Conditions",
            items: parsedInsights['possible_conditions'],
          ),

        // Risk Level
        if (parsedInsights['risk_level']?.isNotEmpty ?? false)
          _buildDetailSection(
            title: "Risk Level",
            content: parsedInsights['risk_level'],
          ),

        // Suggestions
        if (parsedInsights['suggestions']?.isNotEmpty ?? false)
          _buildListSection(
            title: "Suggestions",
            items: parsedInsights['suggestions'],
          ),
      ],
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "• ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedRecords() {
    // Mock data - in a real app, you could get this from a repository
    final records = [
      {
        'name': 'Blood Test - March 2024',
        'type': 'PDF',
        'date': 'Mar 20, 2024',
        'tag': 'Blood',
      },
      {
        'name': 'Chest X-Ray',
        'type': 'Image',
        'date': 'Jan 15, 2024',
        'tag': 'X-Ray',
      },
      {
        'name': 'Prescription - Dr. Johnson',
        'type': 'PDF',
        'date': 'Mar 15, 2024',
        'tag': 'Prescription',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.folderSimple(),
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Uploaded Records",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(PhosphorIcons.plus(), size: 16),
                label: Text("Add Record"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          records.isEmpty
              ? _buildEmptyState(
                icon: PhosphorIcons.folderSimple(),
                title: "No records",
                subtitle: "Upload your medical records to keep them organized",
              )
              : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _buildRecordCard(records[index]);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, String> record) {
    final IconData fileIcon =
        record['type'] == 'PDF'
            ? PhosphorIcons.filePdf()
            : record['type'] == 'Image'
            ? PhosphorIcons.fileImage()
            : PhosphorIcons.fileText();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File icon and type
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  fileIcon,
                  size: 50,
                  color:
                      record['type'] == 'PDF'
                          ? Colors.red
                          : record['type'] == 'Image'
                          ? Colors.blue
                          : Colors.orange,
                ),
              ),
            ),
          ),
          // Record details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['name']!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record['type']!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record['tag']!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  record['date']!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
