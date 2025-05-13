import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class DoctorDataService {
  static DoctorDataService? _instance;
  Map<String, dynamic>? _doctorData;
  final SharedPreferencesService _prefsService =
      SharedPreferencesService.getInstance();

  DoctorDataService._internal();

  static DoctorDataService getInstance() {
    _instance ??= DoctorDataService._internal();
    return _instance!;
  }

  /// Initialize the doctor data service by loading data from SharedPreferences
  Future<void> init() async {
    await _prefsService.init();
    _loadDoctorData();
  }

  /// Load doctor data from SharedPreferences
  void _loadDoctorData() {
    final userData = _prefsService.getUserDetails();
    if (userData != null && _prefsService.userType == "doctor") {
      _doctorData = userData;
    }
  }

  /// Refresh doctor data from SharedPreferences
  void refreshDoctorData() {
    _loadDoctorData();
  }

  /// Check if doctor data is loaded
  bool get isDoctorDataLoaded => _doctorData != null;

  /// Get the complete doctor data
  Map<String, dynamic>? get doctorData => _doctorData;

  /// Get doctor ID with fallback
  String get doctorId => _doctorData?['doctorId'] ?? '';

  /// Get doctor name with fallback
  String get name => _doctorData?['name'] ?? 'Doctor';

  /// Get doctor phone number with fallback
  String get mobileNumber => _doctorData?['mobileNumber'] ?? '';

  /// Get doctor gender with fallback
  String get gender => _doctorData?['gender'] ?? '';

  /// Get doctor email with fallback
  String get email => _doctorData?['email'] ?? '';

  /// Get doctor date of birth with fallback
  String get dob => _doctorData?['dob'] ?? '';

  /// Get doctor specialization with fallback
  String get specialization => _doctorData?['specialization'] ?? '';

  /// Get doctor clinic name with fallback
  String get clinicName => _doctorData?['clinicName'] ?? '';

  /// Get doctor work address with fallback
  String get workAddress => _doctorData?['workAddress'] ?? '';

  /// Get doctor medical registration number with fallback
  String get medicalRegistrationNumber =>
      _doctorData?['medicalRegistrationNumber'] ?? '';

  /// Get doctor years of experience with fallback
  String get yearsOfExperience =>
      _doctorData?['yearsOfExperience']?.toString() ?? '0';

  /// Get doctor degree institution with fallback
  String get degreeInstitution => _doctorData?['degreeInstitution'] ?? '';

  /// Get doctor approval status
  bool get isApproved => _doctorData?['isApproved'] ?? false;

  /// Get list of linked patient IDs
  List<String> get patients {
    final patientsList = _doctorData?['patients'];
    if (patientsList is List) {
      return patientsList.map((id) => id.toString()).toList();
    }
    return [];
  }

  /// Get a nested value from the doctor data safely
  dynamic getNestedValue(String path) {
    if (_doctorData == null) return null;

    final keys = path.split('.');
    dynamic current = _doctorData;

    for (final key in keys) {
      if (current is! Map || !current.containsKey(key)) {
        return null;
      }
      current = current[key];
    }

    return current;
  }

  /// Save updated doctor data back to SharedPreferences
  Future<void> updateDoctorData(Map<String, dynamic> updatedData) async {
    // Get current data
    final currentData = _doctorData ?? {};

    // Merge with updated data
    final mergedData = {...currentData, ...updatedData};

    // Save back to SharedPreferences
    await _prefsService.saveUserData("doctor", mergedData);

    // Reload the doctor data
    _loadDoctorData();
  }
}
