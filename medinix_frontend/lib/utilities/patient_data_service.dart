import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class PatientDataService {
  static PatientDataService? _instance;
  static const String _patientDataKey = 'patient_data';
  SharedPreferences? _prefs;
  SharedPreferencesService? _prefsService;

  bool _isInitialized = false;
  Map<String, dynamic> _patientData = {};

  // Error handling
  String _lastError = '';
  bool _hasError = false;

  /// Private constructor
  PatientDataService._();

  /// Returns the singleton instance of [PatientDataService]
  static PatientDataService getInstance() {
    _instance ??= PatientDataService._();
    return _instance!;
  }

  /// Initialize the service
  /// Loads patient data from shared preferences
  Future<bool> init() async {
    try {
      debugPrint('DATA_SERVICE: Initializing PatientDataService');
      if (_isInitialized) {
        debugPrint('DATA_SERVICE: Already initialized, skipping');
        return true;
      }

      // Initialize standard SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize SharedPreferencesService to access userData
      _prefsService = SharedPreferencesService.getInstance();
      await _prefsService!.init();

      // First try to load from userData in SharedPreferencesService (primary source)
      bool success = await _loadPatientDataFromUserData();

      // If no data from userData, try to load from patientData (legacy/backup)
      if (!success || _patientData.isEmpty) {
        success = await _loadPatientData();
      }

      if (_patientData.isNotEmpty) {
        _isInitialized = true;
        _hasError = false;
        _lastError = '';

        debugPrint(
          'DATA_SERVICE: Initialization complete. Patient ID: ${patientId.isEmpty ? "EMPTY" : patientId}',
        );
        _logCurrentPatientData();
        return true;
      } else {
        debugPrint(
          'DATA_SERVICE: Initialization failed - no patient data found',
        );
        return false;
      }
    } catch (e) {
      _setError('Initialization error: $e');
      return false;
    }
  }

  /// Load patient data from SharedPreferencesService userData
  Future<bool> _loadPatientDataFromUserData() async {
    try {
      debugPrint(
        'DATA_SERVICE: Loading patient data from SharedPreferencesService userData',
      );
      if (_prefsService == null) {
        _setError('SharedPreferencesService not initialized');
        return false;
      }

      // Check if user is logged in and is a patient
      if (!_prefsService!.isLoggedIn() ||
          _prefsService!.userType != 'patient') {
        debugPrint(
          'DATA_SERVICE: No patient login found in SharedPreferencesService',
        );
        return false;
      }

      // Get userData from SharedPreferencesService
      final userDetails = _prefsService!.getUserDetails();
      debugPrint(
        'DATA_SERVICE: Raw userData from SharedPreferencesService: '
        'userDetails = ${userDetails.toString()}',
      );
      if (userDetails == null || userDetails.isEmpty) {
        debugPrint(
          'DATA_SERVICE: No userData found in SharedPreferencesService',
        );
        return false;
      }

      debugPrint('DATA_SERVICE: Found userData in SharedPreferencesService');
      _patientData = Map<String, dynamic>.from(userDetails);
      debugPrint(
        'DATA_SERVICE: Successfully loaded patient data from userData',
      );
      debugPrint(
        'DATA_SERVICE: doctorId in loaded userData: '
        'doctorId = ${_patientData['doctorId']}',
      );
      return true;
    } catch (e) {
      _setError('Error loading patient data from userData: $e');
      return false;
    }
  }

  /// Load patient data from shared preferences (legacy/backup)
  Future<bool> _loadPatientData() async {
    try {
      debugPrint('DATA_SERVICE: Loading patient data from SharedPreferences');
      if (_prefs == null) {
        _setError('SharedPreferences not initialized');
        return false;
      }

      final String? patientDataString = _prefs!.getString(_patientDataKey);
      debugPrint(
        'DATA_SERVICE: Raw data from SharedPreferences: ${patientDataString ?? "NULL"}',
      );

      if (patientDataString != null && patientDataString.isNotEmpty) {
        try {
          final decoded = json.decode(patientDataString);
          if (decoded is Map<String, dynamic>) {
            _patientData = decoded;
          } else {
            _patientData = Map<String, dynamic>.from(decoded as Map);
          }
          debugPrint(
            'DATA_SERVICE: Successfully loaded patient data from SharedPreferences',
          );
          return true;
        } catch (e) {
          _setError('Error decoding patient data: $e');
          _patientData = {};
          return false;
        }
      } else {
        debugPrint('DATA_SERVICE: No patient data found in SharedPreferences');
        _patientData = {};
        // This is not an error, just empty data
        return true;
      }
    } catch (e) {
      _setError('Error loading patient data: $e');
      return false;
    } finally {
      _logCurrentPatientData();
    }
  }

  /// Update patient data
  Future<bool> updatePatientData(Map<String, dynamic> newData) async {
    try {
      debugPrint('DATA_SERVICE: Updating patient data with: $newData');

      if (!_isInitialized) {
        debugPrint('DATA_SERVICE: Not initialized, initializing now');
        final initialized = await init();
        if (!initialized) {
          _setError('Failed to initialize during update');
          return false;
        }
      }

      // Merge the new data with the existing data
      _patientData.addAll(newData);

      // Try to update in SharedPreferencesService first
      if (_prefsService != null &&
          _prefsService!.isLoggedIn() &&
          _prefsService!.userType == 'patient') {
        try {
          await _prefsService!.saveUserData('patient', _patientData);
          debugPrint(
            'DATA_SERVICE: Patient data saved successfully to userData',
          );
          _hasError = false;
          _lastError = '';
          return true;
        } catch (e) {
          debugPrint(
            'DATA_SERVICE: Error saving to userData, falling back to patientData: $e',
          );
          // Fall back to legacy storage
        }
      }

      // Legacy storage fallback
      _prefs ??= await SharedPreferences.getInstance();

      try {
        final String patientDataString = json.encode(_patientData);
        final success = await _prefs!.setString(
          _patientDataKey,
          patientDataString,
        );

        if (success) {
          debugPrint(
            'DATA_SERVICE: Patient data saved successfully to legacy storage',
          );
          _hasError = false;
          _lastError = '';
        } else {
          _setError('Failed to save patient data to SharedPreferences');
          return false;
        }
      } catch (e) {
        _setError('Error saving patient data: $e');
        return false;
      }

      _logCurrentPatientData();
      return true;
    } catch (e) {
      _setError('Error in updatePatientData: $e');
      return false;
    }
  }

  /// Set error state
  void _setError(String error) {
    debugPrint('DATA_SERVICE ERROR: $error');
    _lastError = error;
    _hasError = true;
  }

  /// Logs the current state of patient data
  void _logCurrentPatientData() {
    debugPrint('DATA_SERVICE: Current patient data: $_patientData');
    debugPrint(
      'DATA_SERVICE: Current patient ID: ${patientId.isEmpty ? "EMPTY" : patientId}',
    );
    debugPrint(
      'DATA_SERVICE: Current patient name: ${patientName.isEmpty ? "EMPTY" : patientName}',
    );
  }

  /// Refresh the patient data from shared preferences
  Future<bool> refreshPatientData() async {
    try {
      debugPrint('DATA_SERVICE: Refreshing patient data');
      if (!_isInitialized) {
        debugPrint('DATA_SERVICE: Not initialized, initializing now');
        return await init();
      } else {
        // First try to refresh from userData
        bool success = await _loadPatientDataFromUserData();

        // If no data from userData or it failed, try legacy storage
        if (!success || _patientData.isEmpty) {
          success = await _loadPatientData();
        }

        if (success) {
          debugPrint('DATA_SERVICE: Patient data refreshed');
        } else {
          _setError('Failed to refresh patient data');
        }
        return success;
      }
    } catch (e) {
      _setError('Error refreshing patient data: $e');
      return false;
    }
  }

  /// Clear all patient data
  Future<bool> clearData() async {
    try {
      debugPrint('DATA_SERVICE: Clearing all patient data');
      bool success = true;

      if (_prefsService != null) {
        await _prefsService!.logout();
        debugPrint(
          'DATA_SERVICE: Cleared userData via SharedPreferencesService',
        );
      }

      _prefs ??= await SharedPreferences.getInstance();

      final legacySuccess = await _prefs!.remove(_patientDataKey);
      if (legacySuccess) {
        debugPrint('DATA_SERVICE: Cleared legacy patient data');
      } else {
        debugPrint('DATA_SERVICE: Failed to clear legacy patient data');
        success = false;
      }

      _patientData = {};
      debugPrint('DATA_SERVICE: Patient data cleared');
      return success;
    } catch (e) {
      _setError('Error clearing patient data: $e');
      return false;
    }
  }

  /// Check if there was an error
  bool get hasError => _hasError;

  /// Get the last error message
  String get lastError => _lastError;

  /// Check if patient data is loaded
  bool get isPatientDataLoaded => _patientData.isNotEmpty;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the patient data model
  Map<String, dynamic> get patientData => _patientData;

  /// Get patient name with fallback
  String get patientName {
    final name = _patientData['name'];
    return name != null && name.toString().isNotEmpty
        ? name.toString()
        : 'Patient';
  }

  /// Get patient ID with fallback
  String get patientId {
    final id = _patientData['patientId'];
    return id != null && id.toString().isNotEmpty ? id.toString() : '';
  }

  /// Get patient phone number with fallback
  String get phoneNumber {
    final phone = _patientData['phoneNumber'];
    return phone != null && phone.toString().isNotEmpty ? phone.toString() : '';
  }

  /// Get patient gender with fallback
  String get gender {
    final gen = _patientData['gender'];
    return gen != null && gen.toString().isNotEmpty ? gen.toString() : '';
  }

  /// Get patient age calculated from DOB
  int? get age {
    // Try to get age directly if available
    final ageValue = _patientData['age'];
    if (ageValue != null) {
      if (ageValue is int) {
        return ageValue;
      } else if (ageValue is String) {
        return int.tryParse(ageValue);
      }
    }

    // Calculate age from DOB if available
    final dobValue = _patientData['dob'];
    if (dobValue != null && dobValue.toString().isNotEmpty) {
      try {
        final dob = DateTime.parse(dobValue.toString());
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age;
      } catch (e) {
        debugPrint('DATA_SERVICE: Error calculating age from DOB: $e');
      }
    }

    return null;
  }

  /// Get date of birth
  String get dob {
    final dobValue = _patientData['dob'];
    return dobValue != null && dobValue.toString().isNotEmpty
        ? dobValue.toString()
        : '';
  }

  /// Get patient weight in kg
  String get weight {
    final weightValue = _patientData['weight'];
    return weightValue != null && weightValue.toString().isNotEmpty
        ? weightValue.toString()
        : '';
  }

  /// Get patient height in cm
  String get height {
    final heightValue = _patientData['height'];
    return heightValue != null && heightValue.toString().isNotEmpty
        ? heightValue.toString()
        : '';
  }

  /// Get patient blood group
  String get bloodGroup {
    final bloodGroupValue = _patientData['bloodGroup'];
    return bloodGroupValue != null && bloodGroupValue.toString().isNotEmpty
        ? bloodGroupValue.toString()
        : '';
  }

  /// Get patient address
  String get address {
    final addressValue = _patientData['address'];
    return addressValue != null && addressValue.toString().isNotEmpty
        ? addressValue.toString()
        : '';
  }

  /// Get patient medical conditions
  String get medicalCondition {
    // Check both singular and plural forms
    final conditionSingular = _patientData['medicalCondition'];
    final conditionPlural = _patientData['medicalConditions'];

    if (conditionPlural != null && conditionPlural.toString().isNotEmpty) {
      return conditionPlural.toString();
    } else if (conditionSingular != null &&
        conditionSingular.toString().isNotEmpty) {
      return conditionSingular.toString();
    }

    return '';
  }

  /// Get patient medical history
  String get medicalHistory {
    // Combine medical conditions, past surgeries, and current medications
    final conditions = medicalCondition;
    final surgeries = pastSurgeries;
    final medications = currentMedications;

    final List<String> historyParts = [];
    if (conditions.isNotEmpty)
      historyParts.add('Medical Conditions: $conditions');
    if (surgeries.isNotEmpty) historyParts.add('Past Surgeries: $surgeries');
    if (medications.isNotEmpty)
      historyParts.add('Current Medications: $medications');

    return historyParts.join('\n');
  }

  /// Get patient past surgeries
  String get pastSurgeries {
    final surgeriesValue = _patientData['pastSurgeries'];
    return surgeriesValue != null && surgeriesValue.toString().isNotEmpty
        ? surgeriesValue.toString()
        : '';
  }

  /// Get patient current medications
  String get currentMedications {
    final medicationsValue = _patientData['currentMedications'];
    return medicationsValue != null && medicationsValue.toString().isNotEmpty
        ? medicationsValue.toString()
        : '';
  }

  /// Check if the patient has submitted any symptoms
  bool get hasSymptoms {
    // Check hasSymptoms boolean first
    final hasSymptomsBool = _patientData['hasSymptoms'];
    if (hasSymptomsBool != null) {
      if (hasSymptomsBool is bool) {
        return hasSymptomsBool;
      } else if (hasSymptomsBool is String) {
        return hasSymptomsBool.toLowerCase() == 'true';
      }
    }

    // Check if symptoms object exists and has data
    final symptomsData = _patientData['symptoms'];
    if (symptomsData != null &&
        symptomsData is Map &&
        symptomsData.isNotEmpty) {
      final description = symptomsData['description'];
      return description != null && description.toString().isNotEmpty;
    }

    return false;
  }

  /// Get patient symptoms
  Map<String, dynamic> get symptoms {
    final symptomsData = _patientData['symptoms'];
    if (symptomsData == null) return {};

    if (symptomsData is Map<String, dynamic>) {
      return symptomsData;
    } else if (symptomsData is Map) {
      return Map<String, dynamic>.from(symptomsData);
    }
    return {};
  }

  /// Check if emergency contact is provided
  bool get hasEmergencyContact {
    final emergencyData = _patientData['emergencyDetails'];
    if (emergencyData == null) return false;

    if (emergencyData is Map) {
      // Check if required fields are present and not empty
      final name = emergencyData['name'];
      return name != null && name.toString().isNotEmpty;
    }
    return false;
  }

  /// Get emergency contact details
  Map<String, dynamic> get emergencyDetails {
    final data = _patientData['emergencyDetails'];
    if (data == null) return {};

    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  /// Get MongoDB ID (if available)
  String get mongoId {
    final id = _patientData['_id'];
    return id != null && id.toString().isNotEmpty ? id.toString() : '';
  }

  /// Get the linked doctor's ID
  String get doctorId {
    final id = _patientData['doctorId'];
    return id != null && id.toString().isNotEmpty ? id.toString() : '';
  }

  /// Determine if user is a new patient (no symptoms or medical history)
  bool get isNewUser {
    if (_patientData.isEmpty) return true;

    // Consider user new if they have no symptoms recorded
    final hasSubmittedSymptoms = hasSymptoms;
    final hasMedicalConditions = medicalCondition.isNotEmpty;
    final hasPastSurgeries = pastSurgeries.isNotEmpty;

    return !hasSubmittedSymptoms && !hasMedicalConditions && !hasPastSurgeries;
  }
}
