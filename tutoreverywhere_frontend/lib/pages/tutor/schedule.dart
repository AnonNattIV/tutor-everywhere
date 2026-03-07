import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutoreverywhere_frontend/models/tutors/appointment.dart';

// Example appointment list for testing
final List<Appointment> sampleAppointments = [
  Appointment(
    appointmentId: 'apt_001',
    tutorId: 'tutor_123',
    tutorFirstname: 'John',
    tutorLastname: 'Smith',
    tutorVerified: true,
    studentId: 'student_456',
    studentFirstname: 'Emma',
    studentLastname: 'Watson',
    studentVerified: true,
    startDate: DateTime(2024, 12, 25, 14, 30), // Dec 25, 2024 at 2:30 PM
    endDate: DateTime(2024, 12, 25, 16, 30),   // Dec 25, 2024 at 4:30 PM
    placeName: 'Central Library, Study Room 3',
    description: 'Need help with calculus derivatives and integration',
    subject: 'Mathematics - Calculus',
  ),
  
  Appointment(
    appointmentId: 'apt_002',
    tutorId: 'tutor_124',
    tutorFirstname: 'Sarah',
    tutorLastname: 'Johnson',
    tutorVerified: true,
    studentId: 'student_457',
    studentFirstname: 'Michael',
    studentLastname: 'Chen',
    studentVerified: false,
    startDate: DateTime(2024, 12, 26, 10, 0),  // Dec 26, 2024 at 10:00 AM
    endDate: DateTime(2024, 12, 26, 11, 30),   // Dec 26, 2024 at 11:30 AM
    placeName: 'Online (Zoom)',
    description: 'Conversation practice for IELTS speaking test',
    subject: 'English - IELTS Preparation',
  ),
  
  Appointment(
    appointmentId: 'apt_003',
    tutorId: 'tutor_125',
    tutorFirstname: 'David',
    tutorLastname: 'Park',
    tutorVerified: true,
    studentId: 'student_458',
    studentFirstname: 'Sophia',
    studentLastname: 'Rodriguez',
    studentVerified: true,
    startDate: DateTime(2024, 12, 27, 15, 45), // Dec 27, 2024 at 3:45 PM
    endDate: DateTime(2024, 12, 27, 17, 15),   // Dec 27, 2024 at 5:15 PM
    placeName: 'Starbucks on Main Street',
    description: null,  // No description
    subject: 'Physics - Mechanics',
  ),
  
  Appointment(
    appointmentId: 'apt_004',
    tutorId: 'tutor_126',
    tutorFirstname: 'Maria',
    tutorLastname: 'Garcia',
    tutorVerified: false,
    studentId: 'student_459',
    studentFirstname: 'James',
    studentLastname: 'Wilson',
    studentVerified: false,
    startDate: DateTime(2024, 12, 28, 9, 0),   // Dec 28, 2024 at 9:00 AM
    endDate: DateTime(2024, 12, 28, 10, 30),    // Dec 28, 2024 at 10:30 AM
    placeName: null,  // No place name
    description: 'Basic programming concepts and Python syntax',
    subject: 'Computer Science - Python',
  ),
  
  // Appointment happening now
  Appointment(
    appointmentId: 'apt_005',
    tutorId: 'tutor_127',
    tutorFirstname: 'Robert',
    tutorLastname: 'Brown',
    tutorVerified: true,
    studentId: 'student_460',
    studentFirstname: 'Olivia',
    studentLastname: 'Martinez',
    studentVerified: true,
    startDate: DateTime.now().subtract(const Duration(minutes: 30)),  // Started 30 mins ago
    endDate: DateTime.now().add(const Duration(hours: 1)),            // Ends in 1 hour
    placeName: 'University Library, Room 201',
    description: 'Reviewing organic chemistry reactions for midterm exam',
    subject: 'Chemistry - Organic Chemistry',
  ),
  
  // Tomorrow's appointment
  Appointment(
    appointmentId: 'apt_006',
    tutorId: 'tutor_128',
    tutorFirstname: 'Jennifer',
    tutorLastname: 'Lee',
    tutorVerified: true,
    studentId: 'student_461',
    studentFirstname: 'William',
    studentLastname: 'Taylor',
    studentVerified: false,
    startDate: DateTime.now().add(const Duration(days: 1, hours: 14)),  // Tomorrow at 2:00 PM
    endDate: DateTime.now().add(const Duration(days: 1, hours: 16)),    // Tomorrow at 4:00 PM
    placeName: 'Online (Google Meet)',
    description: 'Essay editing and feedback for college application',
    subject: 'Writing - College Essays',
  ),
];

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name and verified badge
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: '${appointment.studentFirstname} ${appointment.studentLastname}',
                        ),
                        if (appointment.studentVerified)
                          const WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Date and time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(appointment.startDate)} - ${DateFormat('HH:mm').format(appointment.endDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Subject
            Row(
              children: [
                const Icon(Icons.book, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.subject,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            // Place name (if available)
            if (appointment.placeName != null && appointment.placeName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.placeName!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            
            // Description (if available)
            if (appointment.description != null && appointment.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.utc(2030, 1, 1),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
        
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
        
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
        
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),

        if (_selectedDay != null)
        Text("Appointment for ${DateFormat('d MMMM yyyy').format(_selectedDay!)}"),
        _buildAppointmentCard(sampleAppointments[0])
      ],
    );
  }
}