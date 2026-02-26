import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId, this.embedded = true});

  final String? userId;
  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();

  File? _image;
  String _bio = '';
  bool _isEditingBio = false;

  TutorData? _tutor;
  bool _isLoading = true;
  String? _errorMessage;

  late final Dio _dio;
  late final RestClient _client;
  static const String _baseUrl = 'http://10.0.2.2:3000/';

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchTutorData();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: 'application/json',
        validateStatus: (status) => status != null,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  String? _resolvedUserId() =>
      widget.userId ?? context.read<AuthProvider>().userId;

  Future<void> _fetchTutorData() async {
    final userId = _resolvedUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Missing user ID';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _client.getTutorDataById(userId);
      final tutor = response.data;

      if (!mounted) return;

      setState(() {
        _tutor = tutor;
        _bio = (tutor.bio?.trim().isNotEmpty ?? false)
            ? tutor.bio!.trim()
            : 'Lorem Ipsum';
        _bioController.text = _bio;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Failed to load profile';
        _isLoading = false;
      });
      debugPrint('Dio Error: ${e.type} - ${e.message}');
      debugPrint('Response: ${e.response?.data}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Unexpected Error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  String? _getProfilePictureUrl() {
    final picture = _tutor?.profilePicture;
    if (picture.isEmptyOrNull) return null;

    if (picture!.contains('default_pfp.png')) {
      return '${_baseUrl}assets/pfp/default_pfp.png';
    }

    return picture.startsWith('http') ? picture : '$_baseUrl$picture';
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });

    // TODO: Upload image to server and persist profile picture.
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
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
        );
      },
    );
  }

  void _startBioEdit() {
    _bioController.text = _bio;
    setState(() {
      _isEditingBio = true;
    });
  }

  void _cancelBioEdit() {
    _bioController.text = _bio;
    setState(() {
      _isEditingBio = false;
    });
  }

  void _saveBioMock() {
    final value = _bioController.text.trim();
    if (value.isEmpty || value == _bio) {
      setState(() {
        _isEditingBio = false;
      });
      return;
    }

    setState(() {
      _bio = value;
      _isEditingBio = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bio updated')));
  }

  String _formatDateOfBirth(DateTime? dateValue) {
    if (dateValue == null) return 'Not specified';
    return DateFormat('d MMMM yyyy').format(dateValue);
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
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                title: const Text('My Profile'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
    }

    if (_errorMessage != null) {
      final errorBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTutorData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

      return widget.embedded
          ? errorBody
          : Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                title: const Text('My Profile'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              body: errorBody,
            );
    }

    final tutor = _tutor;
    final firstName = tutor?.firstname ?? 'John';
    final lastName = tutor?.lastname ?? 'Doe';
    final fullName = '$firstName $lastName';
    final profileImageUrl = _getProfilePictureUrl();
    final gender = tutor?.gender;
    final verified = tutor?.verified;

    ImageProvider? profileImage;
    if (_image != null) {
      profileImage = FileImage(_image!);
    } else if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(profileImageUrl);
    }

    final profileContent = SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.deepPurple,
                          )
                        : null,
                  ),
                ),
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
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_buildGenderIcon(gender) != null) ...[
                _buildGenderIcon(gender)!,
                const SizedBox(width: 6),
              ],
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_buildVerifiedBadge(verified) != null)
                _buildVerifiedBadge(verified)!,
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Date of birth ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: _formatDateOfBirth(tutor?.dateofbirth),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: _isEditingBio ? null : _startBioEdit,
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit bio',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_isEditingBio) ...[
                    TextField(
                      controller: _bioController,
                      maxLines: 4,
                      minLines: 2,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your bio',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cancelBioEdit,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveBioMock,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      _bio,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMenuItem(Icons.school, 'My Subjects'),
                _buildMenuItem(Icons.history, 'Lesson History'),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );

    if (widget.embedded) return profileContent;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: profileContent,
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade700, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _dio.close(force: true);
    super.dispose();
  }
}

extension on String? {
  bool get isEmptyOrNull => this == null || this!.isEmpty;
}
