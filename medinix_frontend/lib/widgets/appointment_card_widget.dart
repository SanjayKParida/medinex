import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medinix_frontend/utilities/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppointmentCard extends StatelessWidget {
  final PatientAppointmentModel appointment;
  final VoidCallback? onTap;

  const AppointmentCard({super.key, required this.appointment, this.onTap});

  // Get status-specific icons
  IconData _getStatusIcon() {
    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor() {
    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get gradient based on appointment status
  List<Color> _getGradientColors() {
    switch (appointment.status.toLowerCase()) {
      case 'confirmed':
        return [
          const Color(0xff009797),
          const Color(0xff4cb6b6),
          const Color(0xff99d5d5),
        ];
      case 'pending':
        return [
          const Color(0xffe8963a),
          const Color(0xfff0b978),
          const Color(0xfff7d9b3),
        ];
      case 'cancelled':
        return [
          const Color(0xffd64545),
          const Color(0xffe37777),
          const Color(0xffefadad),
        ];
      case 'completed':
        return [
          const Color(0xff3a7bd5),
          const Color(0xff6fa0e3),
          const Color(0xffa3c6f0),
        ];
      default:
        return [
          const Color(0xff009797),
          const Color(0xff4cb6b6),
          const Color(0xff99d5d5),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the date
    final DateFormat dateFormatter = DateFormat('EEE, MMM d');
    final DateTime parsedDate = DateTime.parse(appointment.date);
    final String formattedDate = dateFormatter.format(parsedDate);

    // Get the gradient colors based on status
    final gradientColors = _getGradientColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.2, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with appointment info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Doctor info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment with',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment.doctorId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status chip
                      appointment.status != "confirmed"
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(),
                                  color: _getStatusColor(),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.status,
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : _buildActionButton(
                            icon: PhosphorIcons.xCircle(),
                            label: "Cancel",
                            onTap: () {},
                          ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Appointment details card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and time column
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDetailRow(
                                  icon: PhosphorIcons.calendar(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  text: formattedDate,
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  icon: PhosphorIcons.clock(),
                                  text: appointment.time,
                                ),
                              ],
                            ),
                          ),

                          // Vertical divider
                          Container(
                            height: 50,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),

                          // Reason column
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Reason',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    appointment.reason,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
