import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:medinix_frontend/repositories/appointment_repository.dart';
import 'package:medinix_frontend/repositories/booking_repo.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const CreateAppointmentScreen({super.key, required this.patient});

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appointmentRepo = AppointmentRepository();
  final _bookingRepo = BookingRepo();
  final _sharedPrefs = SharedPreferencesService.getInstance();

  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  String? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _errorMessage;
  List<String> _availableSlots = [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset selected time when date changes
      });

      // Fetch available slots for the selected date
      _fetchAvailableSlots();
    }
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
    });

    try {
      // Get doctor ID from shared preferences or use a placeholder if not available
      final userDetails = _sharedPrefs.getUserDetails();
      final doctorId = userDetails?['doctorId'];

      if (doctorId == null) {
        setState(() {
          _errorMessage = 'Doctor ID not found. Please log in again.';
          _isLoadingSlots = false;
        });
        return;
      }

      final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _bookingRepo.getAvailableSlots(
        doctorId,
        dateFormatted,
      );

      setState(() {
        _isLoadingSlots = false;
      });

      if (response['success'] == true) {
        setState(() {
          _availableSlots = List<String>.from(response['availableSlots'] ?? []);

          if (_availableSlots.isEmpty) {
            _errorMessage = 'No available slots for the selected date.';
          } else {
            _errorMessage = null;
          }
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Failed to fetch available slots';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
        _errorMessage = 'Error fetching slots: $e';
      });
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTime == null) {
      setState(() {
        _errorMessage = 'Please select an appointment time';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format date for API
      final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final userDetails = _sharedPrefs.getUserDetails();
      final doctorId = userDetails?['doctorId'];

      if (doctorId == null) {
        setState(() {
          _errorMessage = 'Doctor ID not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await _appointmentRepo.createAppointment({
        'patientId': widget.patient['patientId'],
        'doctorId': doctorId,
        'date': dateFormatted,
        'time': _selectedTime,
        'reason': _reasonController.text,
      });

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to create appointment';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'Appointment scheduled successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to patients screen
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule Appointment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient card
                _buildPatientCard(),

                SizedBox(height: 24),

                Text(
                  'Appointment Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),

                // Date picker
                _buildDateSelector(),
                SizedBox(height: 16),

                // Time slots
                if (_selectedDate != null) _buildTimeSlots(),
                SizedBox(height: 16),

                // Reason field
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for appointment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason for the appointment';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 8),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 25,
                              height: 25,
                              child: LoadingIndicator(
                                indicatorType: Indicator.lineScalePulseOut,
                                colors: const [Colors.white],
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Schedule Appointment',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildPatientCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.teal,
            child: Text(
              (widget.patient['name'] != null &&
                      widget.patient['name'].toString().isNotEmpty)
                  ? widget.patient['name'].toString()[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient['name'] ?? 'Unknown Patient',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'ID: ${widget.patient['patientId']}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.teal),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_isLoadingSlots) {
      return Center(
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 30,
              child: LoadingIndicator(
                indicatorType: Indicator.lineScalePulseOut,
                colors: const [Colors.teal],
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading available slots...',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No available slots for the selected date. Please choose another date.',
                style: GoogleFonts.poppins(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableSlots.map((slot) {
                final isSelected = slot == _selectedTime;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTime = slot;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
