// lib/pages/tutor/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';

// Import tab widgets
import 'profile_tab.dart';
import 'reviews_tab.dart';
import 'subjects_tab.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  final String userId;
  final bool embedded;

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // Bio state
  String _bio = '';
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  // Preferred place state
  String _preferredPlace = '';
  final TextEditingController _preferredPlaceController = TextEditingController();
  bool _isEditingPreferredPlace = false;

  // Data state
  TutorData? _tutor;
  bool _isLoading = true;
  String? _errorMessage;

  // API client
  late final Dio _dio;
  late final RestClient _client;
  static const String _baseUrl = AppConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchTutorData();
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

  Future<void> _fetchTutorData() async {
    try {
      final tutor = await _client.getTutorDataById(widget.userId);
      if (!mounted) return;
      setState(() {
        _tutor = tutor;
        _bio = tutor.bio?.trim() ?? 'No bio provided';
        _bioController.text = _bio;
        _preferredPlace = tutor.preferredPlace?.trim() ?? 'Not specified';
        _preferredPlaceController.text = _preferredPlace;
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

  String? _getProfilePictureUrl() {
    final picture = _tutor?.profilePicture;
    if (picture == null || picture.isEmpty) return null;
    if (picture.contains('default_pfp.png')) {
      return '${_baseUrl}assets/pfp/default_pfp.png';
    }
    return picture.startsWith('http') ? picture : '$_baseUrl$picture';
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (pickedFile == null) return;
    setState(() => _image = File(pickedFile.path));
    // TODO: Upload to server
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Bio editing
  void _startBioEdit() {
    _bioController.text = _bio;
    setState(() => _isEditingBio = true);
  }

  void _cancelBioEdit() {
    _bioController.text = _bio;
    setState(() => _isEditingBio = false);
  }

  void _saveBio() {
    final value = _bioController.text.trim();
    if (value.isEmpty) {
      _cancelBioEdit();
      return;
    }
    try {
      final token = context.read<AuthProvider>().token;
      _client.setTutorBio(token!, value);
      setState(() {
        _bio = value;
        _isEditingBio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bio updated')));
    } on DioException catch (e) {
      print('Bio save error: ${e.response?.data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.data['message'] ?? 'Update failed'}')),
      );
    }
  }

  // Preferred place editing
  void _startPreferredPlaceEdit() {
    _preferredPlaceController.text = _preferredPlace;
    setState(() => _isEditingPreferredPlace = true);
  }

  void _cancelPreferredPlaceEdit() {
    _preferredPlaceController.text = _preferredPlace;
    setState(() => _isEditingPreferredPlace = false);
  }

  void _savePreferredPlace() {
    final value = _preferredPlaceController.text.trim();
    if (value.isEmpty) {
      _cancelPreferredPlaceEdit();
      return;
    }
    try {
      final token = context.read<AuthProvider>().token;
      _client.setTutorPreferredPlace(token!, value);
      setState(() {
        _preferredPlace = value;
        _isEditingPreferredPlace = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred place updated')));
    } on DioException catch (e) {
      print('Preferred place save error: ${e.response?.data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.data['message'] ?? 'Update failed'}')),
      );
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

  Widget? _buildGenderIcon(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    final isMale = gender.toLowerCase() == 'male';
    return Icon(
      isMale ? Icons.male : Icons.female,
      size: 24,
      color: isMale ? Colors.blue : Colors.pink,
    );
  }

  Widget? _buildVerifiedBadge(bool? verified) {
    if (verified != true) return null;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label))),
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade600,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(title: const Text('Tutor Profile'), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
              body: const Center(child: CircularProgressIndicator()),
            );
    }

    // Error state
    if (_errorMessage != null) {
      return widget.embedded
          ? Center(child: Text('Error: $_errorMessage'))
          : Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(title: const Text('Tutor Profile'), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $_errorMessage'),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchTutorData, child: const Text('Retry')),
                  ],
                ),
              ),
            );
    }

    // Extract values
    final firstName = _tutor?.firstname?.trim() ?? 'Teacher';
    final lastName = _tutor?.lastname?.trim() ?? 'Name';
    final fullName = '$firstName $lastName'.trim();
    final dateOfBirth = _formatDateOfBirth(_tutor?.dateofbirth);
    final profileImageUrl = _getProfilePictureUrl();
    final gender = _tutor?.gender;
    final verified = _tutor?.verified;
    final isOwner = context.read<AuthProvider>().userId == widget.userId;

    ImageProvider? profileImage;
    if (_image != null) {
      profileImage = FileImage(_image!);
    } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(profileImageUrl);
    }

    final profileContent = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: isOwner ? _showImageSourceActionSheet : null,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: profileImage,
                    child: profileImage == null ? const Icon(Icons.person, size: 70, color: Colors.deepPurple) : null,
                  ),
                ),
                if (isOwner)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Name + Gender + Verified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_buildGenderIcon(gender) != null) ...[_buildGenderIcon(gender)!, const SizedBox(width: 6)],
              Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (_buildVerifiedBadge(verified) != null) ...[const SizedBox(width: 8), _buildVerifiedBadge(verified)!],
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          if (!isOwner)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(icon: Icons.chat_bubble, label: 'Tap to chat', onPressed: () {
                  // TODO: Navigate to chat
                }),
                const SizedBox(width: 12),
                _buildActionButton(icon: Icons.calendar_month, label: 'View calendar', onPressed: () {
                  // TODO: Navigate to calendar
                }),
              ],
            ),
          if (!isOwner) const SizedBox(height: 24),
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.black87,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              tabs: [Tab(text: 'Profile'), Tab(text: 'Reviews'), Tab(text: 'Subjects')],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              children: [
                // Profile Tab
                ProfileTab(
                  dateOfBirth: dateOfBirth,
                  preferredPlace: _preferredPlace,
                  bio: _bio,
                  isEditingBio: _isEditingBio,
                  isEditingPreferredPlace: _isEditingPreferredPlace,
                  bioController: _bioController,
                  preferredPlaceController: _preferredPlaceController,
                  onStartEditBio: _startBioEdit,
                  onCancelEditBio: _cancelBioEdit,
                  onSaveBio: _saveBio,
                  onStartEditPreferredPlace: _startPreferredPlaceEdit,
                  onCancelEditPreferredPlace: _cancelPreferredPlaceEdit,
                  onSavePreferredPlace: _savePreferredPlace,
                  canEdit: isOwner,
                ),
                // Reviews Tab
                ReviewsTab(tutorId: widget.userId, tutorName: fullName),
                // Subjects Tab
                SubjectsTab(tutorId: widget.userId, tutorName: fullName),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return profileContent;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tutor Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: profileContent,
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _preferredPlaceController.dispose();
    _dio.close(force: true);
    super.dispose();
  }
}