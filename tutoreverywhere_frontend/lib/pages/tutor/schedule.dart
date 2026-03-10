import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/appointment.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/pages/student/profile.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.userId, this.embedded = true});
  final String userId;
  final bool embedded;
  
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay = DateTime.now();

  // API client
  late final Dio _dio;
  late final RestClient _client;
  static const String _baseUrl = AppConstants.baseUrl;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGoogleMapsNavigation(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnack('Could not open Google Maps');
    }
  }

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchAppointments();
  }

   Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _client.getAppointmentByTutorId(widget.userId, year: _selectedDay?.year, month: _selectedDay?.month, day: _selectedDay?.day);
      
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data['message'] ?? e.message ?? 'Failed to load appointments';
        _isLoading = false;
      });
      debugPrint('Dio Error fetching appointments: ${e.type} - ${e.message}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching appointments: $e\nStack: $stackTrace');
    }
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: "application/json",
      validateStatus: (status) => status != null,
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, error: true));
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

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
                          recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute<void>(builder: (context) => StudentProfilePage(userId: appointment.studentId, embedded: true)))
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
            if (appointment.subject != null) ... [
              Row(
                children: [
                  const Icon(Icons.book, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.subject!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            
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
            if (appointment.latitude != null && appointment.longitude != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        children: [
                          TextSpan(
                            text: 'View coordinate in map',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _openGoogleMapsNavigation(
                                    appointment.latitude!,
                                    appointment.longitude!
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthProvider>().userId == widget.userId;

    final bodyContent = CustomScrollView(
      slivers:
        [
          SliverToBoxAdapter(
            child: TableCalendar(
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
                _fetchAppointments();
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
          ),

          if (_selectedDay != null)
            SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                DateFormat('d MMMM yyyy').format(_selectedDay!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(child: Text(_errorMessage!)),
            )
          else if (_appointments.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No appointments for this day')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildAppointmentCard(_appointments[index]),
                childCount: _appointments.length,
              ),
            ),
        ],
    );

    if (widget.embedded) {
      return bodyContent;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          centerTitle: true,
        ),
        body: bodyContent
      );
    }
  }
}