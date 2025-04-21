import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medinix_frontend/repositories/booking_repo.dart';
import 'package:medinix_frontend/screens/features/patient/home/home_screen.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:medinix_frontend/utilities/shared_preferences_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({required this.pickedDoctor, super.key});

  final VerifiedDoctor pickedDoctor;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? selectedDate;
  List<String> availableSlots = [];
  String? selectedSlot;
  bool isBooking = false;
  bool isFetchingSlots = false;

  // Specialty descriptions map
  final Map<String, String> specialtyDescriptions = {
    'Cardiology':
        'Specializes in heart conditions, including diagnosis and treatment of coronary artery disease, heart failure, and arrhythmias.',
    'Dermatology':
        'Focuses on skin conditions, including acne, eczema, psoriasis, and skin cancer screening and treatment.',
    'Endocrinology':
        'Deals with hormone-related disorders, such as diabetes, thyroid diseases, and metabolic conditions.',
    'Gastroenterology':
        'Specializes in digestive system disorders, including acid reflux, IBS, liver disease, and colonoscopies.',
    'General Medicine':
        'Provides comprehensive care for adults, managing a wide range of acute and chronic illnesses.',
    'Neurology':
        'Treats disorders of the nervous system, including stroke, epilepsy, multiple sclerosis, and Parkinson\'s disease.',
    'Obstetrics & Gynecology':
        'Focuses on women\'s health, including pregnancy, childbirth, reproductive health, and gynecological conditions.',
    'Oncology':
        'Diagnoses and treats cancer, including chemotherapy, radiation therapy, and cancer screening.',
    'Ophthalmology':
        'Specializes in eye care, including vision correction, cataracts, glaucoma, and retinal diseases.',
    'Orthopedics':
        'Deals with musculoskeletal issues, including fractures, joint replacements, and sports injuries.',
    'Pediatrics':
        'Provides medical care for infants, children, and adolescents, including developmental assessments and vaccinations.',
    'Psychiatry':
        'Diagnoses and treats mental health conditions, such as depression, anxiety, bipolar disorder, and schizophrenia.',
    'Pulmonology':
        'Focuses on respiratory disorders, including asthma, COPD, pneumonia, and sleep apnea.',
    'Radiology':
        'Uses imaging techniques (X-rays, MRI, CT scans) to diagnose and guide treatment for various conditions.',
    'Urology':
        'Specializes in urinary tract and male reproductive health, including kidney stones, prostate issues, and incontinence.',
  };

  Future<void> fetchAvailableSlots(DateTime date) async {
    setState(() {
      isFetchingSlots = true;
    });
    try {
      print("date ::: $date");
      print("format date :: ${formatDate(date)}");
      final response = await BookingRepo().getAvailableSlots(
        widget.pickedDoctor.doctorId,
        formatDate(date),
      );

      print("response ::: $response");

      if (response['success'] == true) {
        final List<dynamic> slots = response['availableSlots'];

        setState(() {
          availableSlots = List<String>.from(slots);
          isFetchingSlots = false;
        });
      } else {
        setState(() {
          availableSlots = [];
          isFetchingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No slots available for the selected date.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching slots: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch available slots.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isFetchingSlots = false;
      });
    }
  }

  Future<void> bookAppointment() async {
    SharedPreferencesService prefs = SharedPreferencesService.getInstance();
    var userDetails = prefs.getUserDetails();

    setState(() => isBooking = true);

    try {
      final response = await BookingRepo().createAppointment(
        userDetails?['patientId'],
        widget.pickedDoctor.doctorId,
        formatDate(selectedDate!),
        selectedSlot!,
      );

      print("Success :: $response");

      if (response['success']) {
        setState(() => isBooking = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 2),
              content: Text('Appointment booked successfully!'),
              backgroundColor: Colors.teal,
            ),
          );
        }

        Appointments().patientAppointmentsList.add(
          AppointmentModel(
            id: widget.pickedDoctor.id,
            patientId: userDetails?['patientId'],
            doctorId: widget.pickedDoctor.doctorId,
            date: formatDate(selectedDate!),
            time: selectedSlot!,
            reason: "general checkup",
            status: "confirmed",
            createdAt: DateTime.now(),
          ),
        );

        HomeScreen.homeKey.currentState?.setState(() {});

        // print(
        //   "Appointment List :: ${PatientAppointments().patientAppointmentsList}",
        // );
        setState(() => isBooking = false);

        Navigator.pop(context);
      } else {
        setState(() => isBooking = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            content: Text(
              response['message'],
              style: TextStyle(color: Colors.teal),
            ),
            backgroundColor: Colors.white,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(
            "Error occurred : $e",
            style: TextStyle(color: Colors.teal),
          ),
          backgroundColor: Colors.white,
        ),
      );
    }
  }

  String formatDate(DateTime pickedDate) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    print("Formatted Date :: $formattedDate");
    return formattedDate;
  }

  void pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      initialDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        availableSlots = [];
        selectedSlot = null;
      });

      await fetchAvailableSlots(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Book Appointment",
          style: GoogleFonts.poppins(
            color: Colors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorInfoCard(),
              const SizedBox(height: 15),
              _buildDateSelector(),
              const SizedBox(height: 15),
              _buildTimeSlots(),
              const SizedBox(height: 15),
              Text(
                "Note: The doctor reserves the right to cancel the appointment if necessary.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
              // const SizedBox(height: 32),
              // _buildBookButton(),
              // const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (selectedDate != null && selectedSlot != null && !isBooking)
                      ? bookAppointment
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isBooking
                      ? CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                        "Book Appointment",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    final doctor = widget.pickedDoctor;
    final specialtyDescription =
        specialtyDescriptions[doctor.specialization] ??
        'Expert in providing specialized medical care and treatment.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal.shade700, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, size: 40, color: Colors.teal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Experience: ${doctor.yearsOfExperience} years",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  PhosphorIcons.briefcase(),
                  "Specialization",
                  doctor.specialization,
                ),
                const SizedBox(height: 12),
                Text(
                  specialtyDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 24, thickness: 1),
                _buildInfoRow(
                  PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                  "Verified",
                  "",
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  PhosphorIcons.mapPin(),
                  "Location",
                  widget.pickedDoctor.workAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: label == "Verified" ? Colors.amber : Colors.teal,
        ),
        const SizedBox(width: 8),
        Text(
          label == "Verified" ? "Verified" : "$label: ",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Expanded(child: Text(value, style: GoogleFonts.roboto(fontSize: 14))),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Appointment Date",
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!)
                      : "No date selected",
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        selectedDate != null
                            ? Colors.black
                            : Colors.grey.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: pickDate,
                  icon: Icon(
                    PhosphorIcons.calendar(),
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text("Select"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (selectedDate == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Please select a date to view available time slots",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Time Slots",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isFetchingSlots
                ? Center(child: CupertinoActivityIndicator(color: Colors.black))
                : availableSlots.isEmpty
                ? const Center(
                  child: Text(
                    "No slots available for this date",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      availableSlots.map((slot) {
                        return ChoiceChip(
                          label: Text(slot),
                          selected: selectedSlot == slot,
                          selectedColor: Colors.teal.shade100,
                          labelStyle: TextStyle(
                            color:
                                selectedSlot == slot
                                    ? Colors.teal.shade800
                                    : Colors.black,
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedSlot = slot;
                            });
                          },
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }
}
