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
