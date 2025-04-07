import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medinix_frontend/constants/routes.dart';
import 'package:medinix_frontend/repositories/login_repo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalConditionsController =
      TextEditingController();
  final TextEditingController _pastSurgeriesController =
      TextEditingController();
  final TextEditingController _currentMedicationsController =
      TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _emergencyRelationController =
      TextEditingController();
  final TextEditingController _symptomFrequencyController =
      TextEditingController();
  final TextEditingController _symptomDescriptionController =
      TextEditingController();
  final TextEditingController _symptomSeverityController =
      TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedGender;
  String? _selectedSeverity;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _severity = ['Mild', 'Moderate', 'Severe'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phone = ModalRoute.of(context)?.settings.arguments as String?;
    if (phone != null) {
      _phoneController.text = phone;
    }
  }

  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final emergencyDetails = {
          'name': _emergencyNameController.text,
          'phoneNumber': _emergencyPhoneController.text,
          'relation': _emergencyRelationController.text,
        };

        final symptomsDetails = {
          'description': _symptomDescriptionController.text,
          'severity': _symptomSeverityController.text,
          'frequency': _symptomFrequencyController.text,
        };

        final patientData = {
          'name': _nameController.text,
          'dob': _dobController.text,
          'weight': _weightController.text,
          'height': _heightController.text,
          'bloodGroup': _selectedBloodGroup,
          'gender': _selectedGender,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'symptoms': symptomsDetails,
          'medicalConditions': _medicalConditionsController.text,
          'pastSurgeries': _pastSurgeriesController.text,
          'currentMedications': _currentMedicationsController.text,
          'emergencyDetails': emergencyDetails,
        };

        print("Patient data : $patientData");

        await LoginRepo().handleRegisterPatient(
          patientData,
        ); // ✅ Main integration point

        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.patientDashboard,
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient registered successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering patient: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Patient Registration',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.user()),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter patient name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.calendar()),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.genderIntersex()),
                  ),
                  value: _selectedGender,
                  items:
                      _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.phone()),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.house()),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                Text(
                  'Physical Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Weight and Height in a row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(PhosphorIcons.barbell()),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          prefixIcon: Icon(Icons.height),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Blood Group
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  value: _selectedBloodGroup,
                  items:
                      _bloodGroups.map((bloodGroup) {
                        return DropdownMenuItem(
                          value: bloodGroup,
                          child: Text(bloodGroup),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodGroup = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Medical Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Symptom Description
                TextFormField(
                  controller: _symptomDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Current Symptom (if any)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.paragraph()),
                  ),
                ),
                const SizedBox(height: 16),

                //Symptom Severity
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Severity (ignore if no symptoms)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.firstAidKit()),
                  ),
                  value: _selectedSeverity,
                  items:
                      _severity.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSeverity = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Symptom Frequency
                TextFormField(
                  controller: _symptomFrequencyController,
                  decoration: InputDecoration(
                    labelText: 'Frequency (if any)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.faceMask()),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical Conditions
                TextFormField(
                  controller: _medicalConditionsController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Conditions/Allergies',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.health_and_safety),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Past Surgeries
                TextFormField(
                  controller: _pastSurgeriesController,
                  decoration: InputDecoration(
                    labelText: 'Past Surgeries/Procedures',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.asclepius()),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Current Medications
                TextFormField(
                  controller: _currentMedicationsController,
                  decoration: InputDecoration(
                    labelText: 'Current Medications',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.pill()),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                Text(
                  'Emergency Contact',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Contact Name
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.addressBook()),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Contact Phone
                TextFormField(
                  controller: _emergencyPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.phoneCall()),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Emergency Contact Relation
                TextFormField(
                  controller: _emergencyRelationController,
                  decoration: InputDecoration(
                    labelText: 'Relation to Patient',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: Icon(PhosphorIcons.treeStructure()),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal,
                    ),
                    child:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Register Patient',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _symptomFrequencyController.dispose();
    _symptomDescriptionController.dispose();
    _symptomSeverityController.dispose();
    _medicalConditionsController.dispose();
    _pastSurgeriesController.dispose();
    _currentMedicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }
}
