import 'package:medinix_frontend/constants/assets.dart';

class PatientDetails {
  //Private constructor
  PatientDetails._internal();

  //Single instance of the class
  static final PatientDetails patientDetails = PatientDetails._internal();

  //Returning an instance
  factory PatientDetails() {
    return patientDetails;
  }

  //Properties
  String name = "";
  String dob = "";
  int weight = 0;
  int height = 0;
  String bloodGroup = "";
  String gender = "";
  String doctorId = ""; // This will store the linked doctor's ID
  String medicalCondition = "";
  String phoneNumber = "";
  String symptoms = "";
  String address = "";
  String pastSurgeries = "";
  String currentMedications = "";
  String emergencyDetails = "";
}

class DoctorDetails {
  //Private constructor
  DoctorDetails._internal();

  //Single instance of the class
  static final DoctorDetails doctorDetails = DoctorDetails._internal();

  //Returning the instance
  factory DoctorDetails() {
    return doctorDetails;
  }

  //Properties
  String name = "";
  String dob = "";
  String gender = "";
  String mobileNumber = "";
  String email = "";
  String clinicName = "";
  String workAddress = "";
  String medicalRegistrationNumber = "";
  String specialization = "";
  int yearsOfExperience = 0;
  String degreeInstitution = "";
  String governmentID = "";
}

class Appointments {
  Appointments._internal();
  static final Appointments patientAppointments = Appointments._internal();

  factory Appointments() {
    return patientAppointments;
  }

  List<AppointmentModel> doctorAppointmentsList = [];
  List<AppointmentModel> patientAppointmentsList = [];

  bool appointmentsLoaded = false;
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String time;
  final String reason;
  final String status;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  // Convert JSON to Appointment
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class HealthTip {
  final String title;
  final String summary;
  final String? imagePath;

  const HealthTip({required this.title, required this.summary, this.imagePath});

  // Factory method to create from Map
  factory HealthTip.fromMap(Map<String, String> map) {
    return HealthTip(
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      imagePath: map['image'],
    );
  }
}

// Health Articles using the HealthTip class
final List<HealthTip> healthTips = [
  HealthTip(
    title: 'Stay Hydrated',
    summary:
        'Drinking 2-3 liters of water daily helps flush out toxins and boosts energy.',
    imagePath: SVGAssets.drinkingSvg,
  ),
  HealthTip(
    title: 'Get Enough Sleep',
    summary:
        'Aim for 7-9 hours of sleep to improve memory, immunity, and mood.',
    imagePath: SVGAssets.sleepingSvg,
  ),
  HealthTip(
    title: 'Eat More Greens',
    summary:
        'Leafy vegetables are rich in vitamins and fiber for a healthy gut.',
    imagePath: SVGAssets.greensSvg,
  ),
  HealthTip(
    title: 'Take Regular Walks',
    summary:
        'Just 30 minutes of walking a day can enhance heart health and reduce stress.',
    imagePath: SVGAssets.walkingSvg,
  ),
  HealthTip(
    title: 'Practice Deep Breathing',
    summary: 'Calm your mind and body with 5-minute breathing exercises daily.',
    imagePath: SVGAssets.breathingSvg,
  ),
];

class ApprovedDoctors {
  //Private Constructor
  ApprovedDoctors._internal();

  //static instance of the class
  static final ApprovedDoctors approvedDoctors = ApprovedDoctors._internal();

  //Factory constructor for the class
  factory ApprovedDoctors() {
    return approvedDoctors;
  }

  List<VerifiedDoctor> verifiedDoctorsList = [];

  bool verifiedDoctorsListLoaded = false;
}

class VerifiedDoctor {
  final String id;
  final String doctorId;
  final String name;
  final String dob;
  final String gender;
  final String mobileNumber;
  final String email;
  final String workAddress;
  final String medicalRegistrationNumber;
  final String specialization;
  final String yearsOfExperience;
  final String degreeInstitution;
  final bool isApproved;

  VerifiedDoctor({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.mobileNumber,
    required this.email,
    required this.workAddress,
    required this.medicalRegistrationNumber,
    required this.specialization,
    required this.yearsOfExperience,
    required this.degreeInstitution,
    required this.isApproved,
  });

  factory VerifiedDoctor.fromJson(Map<String, dynamic> json) {
    return VerifiedDoctor(
      id: json['_id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      workAddress: json['workAddress'] ?? '',
      medicalRegistrationNumber: json['medicalRegistrationNumber'] ?? '',
      specialization: json['specialization'] ?? '',
      yearsOfExperience: json['yearsOfExperience'].toString(),
      degreeInstitution: json['degreeInstitution'] ?? '',
      isApproved: json['isApproved'] ?? false,
    );
  }
}

class DoctorPatients {
  //Private constructor
  DoctorPatients._internal();

  //Single instance of the class
  static final DoctorPatients doctorPatients = DoctorPatients._internal();

  //Factory constructor for the class
  factory DoctorPatients() {
    return doctorPatients;
  }

  List<Map<String, dynamic>> patientsList = [];
  bool patientsLoaded = false;
  String? errorMessage;
}
