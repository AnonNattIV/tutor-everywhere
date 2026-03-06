import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/students/data.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    required this.userId,
    this.embedded = false,
    this.showEmbeddedAppBar = true,
  });

  final String userId;
  final bool embedded;
  final bool showEmbeddedAppBar;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image; // Locally picked image (overrides fetched URL temporarily)
  String _bio = '';
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  bool _isUploadingImage = false; // Add loading state for image upload

  // Student data state
  StudentData? _student;
  bool _isLoading = true;
  String? _errorMessage;

  // Dio client setup
  late final Dio _dio;
  late final RestClient _client;
  static const String _baseUrl = AppConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchStudentData();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        contentType: "application/json",
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  Future<void> _fetchStudentData() async {
    try {
      final student = await _client.getStudentsDataById(widget.userId);

      if (!mounted) return;

      setState(() {
        _student = student;
        _bio = student.bio ?? 'Lorem Ipsum';
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

  /// Builds the profile picture URL with special handling for default_pfp.png
  String? _getProfilePictureUrl() {
    final picture = _student?.profilePicture;
    if (picture == null || picture.isEmpty) return null;

    // Special case: default profile picture needs assets path prefix
    if (picture.contains('default_pfp.png')) {
      return '${_baseUrl}assets/pfp/default_pfp.png';
    }

    // Return absolute URL if already full, otherwise prepend base URL
    return picture.startsWith('http') ? picture : _baseUrl + picture;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isUploadingImage = true; // Show loading indicator
    });

    // Upload image to server using Retrofit
    await _uploadProfilePicture(File(pickedFile.path));
  }

  // New method to upload profile picture using Retrofit
  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      final token = context.read<AuthProvider>().token;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Call the Retrofit API endpoint
      await _client.uploadStudentProfilePicture(
        token,
        imageFile,
      );

      // Refresh student data to get updated profile picture URL
      await _fetchStudentData();

      if (!mounted) return;
      
      setState(() {
        _isUploadingImage = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );

    } on DioException catch (e) {
      setState(() {
        _isUploadingImage = false;
        // Revert to previous image if upload failed
        _image = null;
      });

      String errorMessage = 'Failed to upload image';
      if (e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      
      debugPrint('Upload error: ${e.message}');
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _image = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
      
      debugPrint('Unexpected error: $e');
    }
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
    try {
      final token = context.read<AuthProvider>().token;
      _client.setStudentBio(token!, value);
      setState(() {
        _bio = value;
        _isEditingBio = false;
      });
    } on DioException catch (e) {
      print(e.response?.data['message']);
    } catch (e) {
      print(e);
    }

    // temporary message at the bottom to confirm the local save succeeded.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bio updated')));
  }

  String _formatDateOfBirth(Object? dateValue) {
    // 1. Handle null or empty
    if (dateValue == null) return 'Not specified';

    DateTime? date;

    // 2. If it's already a DateTime object
    if (dateValue is DateTime) {
      date = dateValue;
    }
    // 3. If it's a String (most common from API)
    else if (dateValue is String) {
      if (dateValue.isEmpty) return 'Not specified';
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('Failed to parse date string: $dateValue');
        return 'Invalid date';
      }
    }
    // 4. Fallback for other types
    else {
      debugPrint('Unknown date type: ${dateValue.runtimeType}');
      return 'Invalid date format';
    }

    // 5. Format the valid DateTime
    return DateFormat('d MMMM yyyy').format(date);
  }

  // Returns gender icon widget or null if gender is not specified
  Widget? _buildGenderIcon(String? gender) {
    if (gender == null || gender.isEmpty) return null;

    final isMale = gender.toLowerCase() == 'male';
    return Icon(
      isMale ? Icons.male : Icons.female,
      size: 24,
      color: isMale ? Colors.blue : Colors.pink,
    );
  }

  // Returns verified badge widget or null if not verified
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
    // Loading state
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

    // Error state
    if (_errorMessage != null) {
      return widget.embedded
          ? Center(child: Text('Error: $_errorMessage'))
          : Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                title: const Text('My Profile'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $_errorMessage'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchStudentData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
    }

    // Extract display values with fallbacks
    final firstName = _student?.firstname ?? 'John';
    final lastName = _student?.lastname ?? 'Doe';
    final fullName = '$firstName $lastName';
    final dateOfBirth = _student?.dateofbirth ?? '1 January 1970';
    final profileImageUrl = _getProfilePictureUrl();
    final gender = _student?.gender;
    final verified = _student?.verified;

    // Determine image provider: local pick > fetched URL > default icon
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
                  onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
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
                    onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isUploadingImage ? Colors.grey : Colors.deepPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
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
              // Gender icon before name
              if (_buildGenderIcon(gender) != null) ...[
                _buildGenderIcon(gender)!,
                const SizedBox(width: 6),
              ],
              // Full name
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Verified badge after name
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
                          // text: dateOfBirth.toString(),
                          text: _formatDateOfBirth(dateOfBirth),
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
                _buildMenuItem(Icons.history, 'Lesson History'),
                // _buildMenuItem(Icons.settings, 'Settings'),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );

    if (widget.embedded) {
      if (widget.showEmbeddedAppBar) {
        // Case 1: Navigated from reviews tab → show back button AppBar
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '$firstName $lastName',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: profileContent,
        );
      } else {
        // Case 2: Embedded in parent with its own AppBar (e.g., StudentHomePage tab)
        // → Just return content wrapped in Material (no duplicate AppBar)
        return Material(
          color: Colors.grey.shade50,
          child: profileContent,
        );
      }
    }

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
        // 👇 Removed PopupMenuButton since StudentHomePage already has it
      ),
      body: profileContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (_) {},
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Find Tutors',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.deepPurple),
            ),
            label: 'Profile',
          ),
        ],
      ),
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
    _dio.close(force: true); // Prevent memory leaks
    super.dispose();
  }
}