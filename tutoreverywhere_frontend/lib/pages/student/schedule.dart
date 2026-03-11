import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/appointment.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/profile.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentSchedulePage extends StatefulWidget {
  const StudentSchedulePage({
    super.key,
    required this.userId,
    this.embedded = true,
  });
  final String userId;
  final bool embedded;

  @override
  State<StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  Map<DateTime, List<Appointment>> _appointmentsByDay = {};
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay = DateTime.now();

  // API client
  late final Dio _dio;
  late final RestClient _client;
  static String get _baseUrl => AppConstants.normalizedBaseUrl;

  String _dioErrorMessage(
    DioException e, {
    String fallback = 'Failed to load appointments',
  }) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return e.message ?? fallback;
  }

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
    _fetchAppointmentsForMonth(targetMonth: _focusedDay);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Map<DateTime, List<Appointment>> _groupAppointmentsByDay(
    List<Appointment> appointments,
  ) {
    final grouped = <DateTime, List<Appointment>>{};
    for (final appointment in appointments) {
      final day = _normalizeDate(appointment.startDate);
      grouped.putIfAbsent(day, () => <Appointment>[]).add(appointment);
    }
    return grouped;
  }

  List<Appointment> _eventsForDay(DateTime day) {
    return _appointmentsByDay[_normalizeDate(day)] ?? const <Appointment>[];
  }

  Future<List<Appointment>?> _tryFetchLegacyAppointmentsForDay(
    DateTime dayToLoad,
  ) async {
    try {
      return await _client.getAppointmentByStudentId(
        widget.userId,
        year: dayToLoad.year,
        month: dayToLoad.month,
        day: dayToLoad.day,
      );
    } on DioException {
      return null;
    }
  }

  Future<void> _fetchAppointmentsForMonth({DateTime? targetMonth}) async {
    final monthToLoad = targetMonth ?? _focusedDay;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _client.getAppointmentByStudentId(
        widget.userId,
        year: monthToLoad.year,
        month: monthToLoad.month,
      );

      if (!mounted) return;
      final groupedAppointments = _groupAppointmentsByDay(appointments);
      setState(() {
        _appointmentsByDay = groupedAppointments;
        final selectedDay = _selectedDay;
        _appointments = selectedDay == null
            ? <Appointment>[]
            : _eventsForDay(selectedDay);
        _isLoading = false;
      });
    } on DioException catch (e) {
      final selectedDay = _selectedDay ?? monthToLoad;
      final fallbackAppointments = await _tryFetchLegacyAppointmentsForDay(
        selectedDay,
      );
      if (fallbackAppointments != null) {
        if (!mounted) return;
        final groupedAppointments = _groupAppointmentsByDay(
          fallbackAppointments,
        );
        setState(() {
          _appointmentsByDay = groupedAppointments;
          _appointments = _eventsForDay(selectedDay);
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _errorMessage = _dioErrorMessage(e);
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
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: "application/json",
        validateStatus: (status) => status != null,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

  Widget _buildHiddenAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          text:
                              '${appointment.tutorFirstname} ${appointment.tutorLastname}',
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => TutorProfilePage(
                                  userId: appointment.tutorId,
                                  embedded: true,
                                ),
                              ),
                            ),
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
            if (appointment.subject != null) ...[
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
            if (appointment.placeName != null &&
                appointment.placeName!.isNotEmpty) ...[
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
            if (appointment.description != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(children: [Text(appointment.description!)]),
              ),
            ],

            if (appointment.latitude != null &&
                appointment.longitude != null) ...[
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
                                appointment.longitude!,
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthProvider>().userId == widget.userId;

    final bodyContent = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 1, 1),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            daysOfWeekHeight: 28,
            rowHeight: 56,
            eventLoader: _eventsForDay,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 1,
              markerSize: 5,
              markerMargin: EdgeInsets.only(top: 2),
              markersAlignment: Alignment.bottomCenter,
              canMarkersOverflow: false,
              defaultTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              outsideTextStyle: TextStyle(fontSize: 16, color: Colors.black38),
              markerDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),

            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _appointments = _eventsForDay(selectedDay);
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
              setState(() => _focusedDay = focusedDay);
              _fetchAppointmentsForMonth(targetMonth: focusedDay);
            },
          ),
        ),

        if (_selectedDay != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                DateFormat('d MMMM yyyy').format(_selectedDay!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          SliverFillRemaining(child: Center(child: Text(_errorMessage!)))
        else if (_appointments.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No appointments for this day')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => (isOwner)
                  ? _buildAppointmentCard(_appointments[index])
                  : _buildHiddenAppointmentCard(_appointments[index]),
              childCount: _appointments.length,
            ),
          ),
      ],
    );

    if (widget.embedded) {
      return bodyContent;
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule'), centerTitle: true),
        body: bodyContent,
      );
    }
  }
}
