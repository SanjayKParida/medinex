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
  String doctorID = "";
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

class PatientAppointments {
  PatientAppointments._internal();
  static final PatientAppointments patientAppointments =
      PatientAppointments._internal();

  factory PatientAppointments() {
    return patientAppointments;
  }

  List<PatientAppointmentModel> patientAppointmentsList = [];

  bool patientAppointmentsLoaded = false;
}

class PatientAppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String time;
  final String reason;
  final String status;
  final DateTime createdAt;

  PatientAppointmentModel({
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
  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
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
