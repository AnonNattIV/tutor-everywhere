import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/admins/requiredverifications.dart';
import 'package:tutoreverywhere_frontend/pages/admin/id_verify_user.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';

class IdVerifyPage extends StatefulWidget {
  const IdVerifyPage({super.key});

  @override
  State<IdVerifyPage> createState() => _IdVerifyPageState();
}

class _IdVerifyPageState extends State<IdVerifyPage> {
  final _baseUrl = AppConstants.normalizedBaseUrl;
  late final Dio _dio;
  late final RestClient _client;

  List<RequiredVerificationsResponse> _verifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchRequiredVerifications();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: "application/json",
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, error: true));
    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  Future<void> _fetchRequiredVerifications() async {
    final token = context.read<AuthProvider>().token;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.getRequiredVerifications(token!);
      setState(() {
        _verifications = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load verifications: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Verifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequiredVerifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchRequiredVerifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_verifications.isEmpty) {
      return const Center(child: Text('No pending verifications.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchRequiredVerifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _verifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _verifications[index];
          return _VerificationCard(user: user, onRefresh: _fetchRequiredVerifications,);
        },
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final RequiredVerificationsResponse user;
  final VoidCallback onRefresh;

  const _VerificationCard({required this.user, required this.onRefresh});

  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return const Color(0xFF1565C0);
      case 'female':
        return const Color(0xFFAD1457);
      default:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genderColor = _genderColor(user.gender);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: genderColor.withValues(alpha: 0.15),
              child: Icon(_genderIcon(user.gender), color: genderColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Gender badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: genderColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: genderColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          user.gender.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: genderColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Full name
                      Expanded(
                        child: Text(
                          '${user.firstname} ${user.lastname}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UUID: ${user.userId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => IdVerifyUserPage(userId: user.userId)));
                onRefresh();
              }
            )
          ],
        ),
      ),
    );
  }
}
