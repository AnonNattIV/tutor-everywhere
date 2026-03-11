import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';

class IdVerifyUserPage extends StatefulWidget {
  const IdVerifyUserPage({super.key, required this.userId});
  final String userId;

  @override
  State<IdVerifyUserPage> createState() => _IdVerifyUserPageState();
}

class _IdVerifyUserPageState extends State<IdVerifyUserPage> {
  final _baseUrl = AppConstants.normalizedBaseUrl;
  late final Dio _dio;
  late final RestClient _client;

  TutorData? _tutor;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Build API client and load current tutor verification profile.
    _setupDio();
    _fetchTutorData();
  }

  // Creates a scoped Dio/Retrofit client for admin verification APIs.
  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: "application/json",
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  // API call: fetch tutor profile and verification photo for review.
  Future<void> _fetchTutorData() async {
    try {
      final tutor = await _client.getTutorDataById(widget.userId);
      if (!mounted) return;
      setState(() {
        _tutor = tutor;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Failed to load profile';
        _isLoading = false;
      });
      debugPrint('Dio Error: ${e.type} - ${e.message}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Error: $e\nStack: $stackTrace');
    }
  }

  String _formatDateOfBirth(Object? dateValue) {
    if (dateValue == null) return 'Not specified';
    DateTime? date;
    if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      if (dateValue.isEmpty) return 'Not specified';
      date = DateTime.tryParse(dateValue);
      if (date == null) return 'Invalid date';
    } else {
      return 'Not specified';
    }
    return DateFormat('d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    Future<void> acceptVerification() async {
      try {
        // API call: mark tutor verification as accepted.
        await _client.acceptVerification(token!, widget.userId);
        if (!mounted) return;
        setState(() {
          _isLoading = true;
        });
        Navigator.pop(context);
      } on DioException catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.message ?? 'Failed to accept verification';
          _isLoading = false;
        });
        debugPrint('Dio Error: ${e.type} - ${e.message}');
      } catch (e, stackTrace) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unexpected error: $e';
          _isLoading = false;
        });
        debugPrint('Error: $e\nStack: $stackTrace');
      }
    }

    Future<void> denyVerification() async {
      try {
        // API call: mark tutor verification as denied.
        await _client.denyVerification(token!, widget.userId);
        if (!mounted) return;
        setState(() {
          _isLoading = true;
        });
        Navigator.pop(context);
      } on DioException catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.message ?? 'Failed to deny verification';
          _isLoading = false;
        });
        debugPrint('Dio Error: ${e.type} - ${e.message}');
      } catch (e, stackTrace) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unexpected error: $e';
          _isLoading = false;
        });
        debugPrint('Error: $e\nStack: $stackTrace');
      }
    }

    const loadingBody = Center(child: CircularProgressIndicator());
    final appBar = AppBar(title: Text("User ID Verification"));
    if (_isLoading) return Scaffold(appBar: appBar, body: loadingBody);
    if (_errorMessage != null && _tutor == null) {
      return Scaffold(
        appBar: appBar,
        body: Center(child: Text(_errorMessage!)),
      );
    }
    final firstName = _tutor?.firstname.trim() ?? 'Teacher';
    final lastName = _tutor?.lastname.trim() ?? 'Name';
    final fullName = '$firstName $lastName'.trim();
    final dateOfBirth = _formatDateOfBirth(_tutor?.dateofbirth);
    final gender = _tutor?.gender;
    final verificationPicture = _tutor?.verificationPicture;
    final verificationImageUrl = AppConstants.resolveApiUrl(
      verificationPicture,
      fallbackRelativePath: 'assets/pfp/default_pfp.png',
    );

    IconData genderIcon;
    Color genderColor;
    if (gender?.toLowerCase() == 'female') {
      genderIcon = Icons.female;
      genderColor = Colors.pinkAccent;
    } else if (gender?.toLowerCase() == 'male') {
      genderIcon = Icons.male;
      genderColor = Colors.blueAccent;
    } else {
      genderIcon = Icons.transgender;
      genderColor = Colors.purpleAccent;
    }

    return Scaffold(
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // Full name with gender icon
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(genderIcon, color: genderColor, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Date of birth
            Center(
              child: Text(
                'Date of Birth: $dateOfBirth',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // ID image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                verificationImageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Accept & Deny buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: acceptVerification,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: denyVerification,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Deny'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
