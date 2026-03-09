import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/models/tutors/data.dart';
import 'package:tutoreverywhere_frontend/pages/all/chat.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/schedule.dart';
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
  bool _isUploadingImage = false; // Add loading state for image upload

  // Bio state
  String _bio = '';
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  // Preferred place state
  String _preferredPlace = '';
  final TextEditingController _preferredPlaceController =
      TextEditingController();
  bool _isEditingPreferredPlace = false;

  // Data state
  TutorData? _tutor;
  bool _isLoading = true;
  String? _errorMessage;

  // Location state
  String _province = '';
  String _location = '';
  bool _isEditingLocation = false;

  // Location edit dialog state
  String _selectedRegion = 'Central';
  String _selectedProvince = '';
  String _selectedLocation = '';

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
        // Initialize location state
        _province = tutor.province?.trim() ?? '';
        _location = tutor.location?.trim() ?? '';
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

  // Location editing
  void _startLocationEdit() {
    // Initialize with current values
    _selectedProvince = _province;
    _selectedLocation = _location;
    _selectedRegion = _province.isNotEmpty
        ? AppConstants.findRegionForProvince(_province)
        : 'Central';

    _showLocationEditDialog();
  }

  void _showLocationEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Region dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: AppConstants.regionProvinces.keys.map((region) {
                    return DropdownMenuItem(value: region, child: Text(region));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        _selectedRegion = value;
                        _selectedProvince = '';
                        _selectedLocation = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Province dropdown
                DropdownButtonFormField<String>(
                  value: _selectedProvince.isEmpty ? null : _selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: AppConstants.getProvincesForRegion(_selectedRegion)
                      .map((province) {
                        return DropdownMenuItem(
                          value: province,
                          child: Text(province),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        _selectedProvince = value;
                        _selectedLocation = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Location dropdown (conditional - only if province has locations)
                if (AppConstants.getLocationsForProvince(
                  _selectedProvince,
                ).isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedLocation.isEmpty ? null : _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'District/Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        AppConstants.getLocationsForProvince(
                          _selectedProvince,
                        ).map((loc) {
                          return DropdownMenuItem(value: loc, child: Text(loc));
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedLocation = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveLocation(ctx),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLocation(BuildContext dialogContext) async {
    if (_selectedProvince.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a province')));
      return;
    }

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not authenticated');

      await _client.setTutorLocation(
        token,
        _selectedProvince,
        _selectedLocation,
      );

      if (!mounted) return;
      setState(() {
        _province = _selectedProvince;
        _location = _selectedLocation;
        _isEditingLocation = false;
      });

      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully')),
      );
    } on DioException catch (e) {
      print('Location save error: ${e.response?.data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.response?.data['message'] ?? 'Update failed'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Location save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _getProfilePictureUrl() {
    final picture = _tutor?.profilePicture;
    if (picture == null || picture.isEmpty) return null;

    // Special case: default profile picture needs assets path prefix
    if (picture.contains('default_pfp.png')) {
      return '${_baseUrl}assets/pfp/default_pfp.png';
    }

    // Return absolute URL if already full, otherwise prepend base URL
    return picture.startsWith('http') ? picture : _baseUrl + picture;
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
      _isUploadingImage = true; // Show loading indicator
    });

    // Upload image to server
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
      await _client.uploadTutorProfilePicture(token, imageFile);

      // Refresh tutor data to get updated profile picture URL
      await _fetchTutorData();

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
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );

      debugPrint('Unexpected error: $e');
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bio updated')));
    } on DioException catch (e) {
      print('Bio save error: ${e.response?.data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.response?.data['message'] ?? 'Update failed'}',
          ),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferred place updated')));
    } on DioException catch (e) {
      print('Preferred place save error: ${e.response?.data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.response?.data['message'] ?? 'Update failed'}',
          ),
        ),
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
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed:
          onPressed ??
          () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(label))),
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
              appBar: AppBar(
                title: const Text('Tutor Profile'),
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
                title: const Text('Tutor Profile'),
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
                      onPressed: _fetchTutorData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
    }

    // Extract values
    final firstName = _tutor?.firstname.trim() ?? 'Teacher';
    final lastName = _tutor?.lastname.trim() ?? 'Name';
    final fullName = '$firstName $lastName'.trim();
    final dateOfBirth = _formatDateOfBirth(_tutor?.dateofbirth);
    final profileImageUrl = _getProfilePictureUrl();
    final gender = _tutor?.gender;
    final verified = _tutor?.verified;

    final province = _tutor?.province?.trim() ?? '';
    final location = _tutor?.location?.trim() ?? '';
    final displayLocation = [
      province,
      location,
    ].where((s) => s.isNotEmpty).join(', ');

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
                  onTap: (isOwner && !_isUploadingImage)
                      ? _showImageSourceActionSheet
                      : null,
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
                if (isOwner)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage
                          ? null
                          : _showImageSourceActionSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isUploadingImage
                              ? Colors.grey
                              : Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
          const SizedBox(height: 12),

          // Name + Gender + Verified
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_buildGenderIcon(gender) != null) ...[
                _buildGenderIcon(gender)!,
                const SizedBox(width: 6),
              ],
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_buildVerifiedBadge(verified) != null) ...[
                const SizedBox(width: 8),
                _buildVerifiedBadge(verified)!,
              ],
            ],
          ),

          // Location (below name)
          if (displayLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            // Location row with edit button (replace existing location display)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  [
                        _province,
                        _location,
                      ].where((s) => s.isNotEmpty).join(', ').isEmpty
                      ? 'Not specified'
                      : [
                          _province,
                          _location,
                        ].where((s) => s.isNotEmpty).join(', '),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Edit button - only visible to owner
                if (isOwner)
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.deepPurple,
                    ),
                    onPressed: _startLocationEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Edit location',
                  ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons
          if (!isOwner)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.chat_bubble,
                  label: 'Tap to chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ChatPage(
                          embedded: false,
                          initialPeerUserId: widget.userId,
                          initialPeerDisplayName: fullName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.calendar_month,
                  label: 'View schedule',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => SchedulePage(
                          userId: widget.userId,
                          embedded: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          if (!isOwner) const SizedBox(height: 24),
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.black87,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Reviews'),
                Tab(text: 'Subjects'),
              ],
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
        title: const Text(
          'Tutor Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
