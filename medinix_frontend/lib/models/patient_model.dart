class PatientModel {
  final String id;
  final String patientId;
  final String name;
  final String dob;
  final String phoneNumber;
  final String gender;
  final Map<String, dynamic> symptoms;
  final Map<String, dynamic> emergencyDetails;
  final String? doctorId;
  final Map<String, dynamic> _originalData;

  PatientModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dob,
    required this.phoneNumber,
    required this.gender,
    required this.symptoms,
    required this.emergencyDetails,
    this.doctorId,
    required Map<String, dynamic> originalData,
  }) : _originalData = originalData;

  // Factory constructor to create a PatientModel from JSON data
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? '',
      symptoms:
          json['symptoms'] is Map
              ? Map<String, dynamic>.from(json['symptoms'])
              : {},
      emergencyDetails:
          json['emergencyDetails'] is Map
              ? Map<String, dynamic>.from(json['emergencyDetails'])
              : {},
      doctorId: json['doctorId'],
      originalData: json,
    );
  }

  // Access to original data for fields not explicitly modeled
  dynamic get(String key) => _originalData[key];

  // Check if the patient has any medical history
  bool get hasSymptoms =>
      symptoms.isNotEmpty &&
      symptoms['description'] != null &&
      symptoms['description'].toString().isNotEmpty;

  // Check if the patient has emergency details
  bool get hasEmergencyContact =>
      emergencyDetails.isNotEmpty &&
      emergencyDetails['name'] != null &&
      emergencyDetails['name'].toString().isNotEmpty &&
      emergencyDetails['phoneNumber'] != null &&
      emergencyDetails['phoneNumber'].toString().isNotEmpty;

  // Calculate age from date of birth
  int? get age {
    if (dob.isEmpty) return null;

    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // Convert back to JSON
  Map<String, dynamic> toJson() => _originalData;
}
