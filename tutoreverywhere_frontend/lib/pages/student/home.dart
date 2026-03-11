import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/main.dart';
import 'package:tutoreverywhere_frontend/models/tutors/find_tutors.dart';
import 'package:tutoreverywhere_frontend/pages/all/chat.dart';
import 'package:tutoreverywhere_frontend/pages/student/find_tutors.dart';
import 'package:tutoreverywhere_frontend/pages/student/profile.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/profile.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int currentPageIndex = 0;

  static const List<String> _featuredSubjects = AppConstants.featuredSubjects;

  static String get _baseUrl => AppConstants.normalizedBaseUrl;
  late final Dio _dio;

  // null = still loading, [] = loaded but empty
  final Map<String, List<FindTutors>?> _tutorsBySubject = {};

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchAllSubjects();
  }

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  void _fetchAllSubjects() {
    for (final subject in _featuredSubjects) {
      _fetchTutorsForSubject(subject);
    }
  }

  Future<void> _fetchTutorsForSubject(String subject) async {
    if (mounted) setState(() => _tutorsBySubject[subject] = null);

    try {
      final response = await _dio.get<dynamic>(
        'tutors',
        queryParameters: {'subject': subject, 'sortby': 'popular'},
      );

      if (!mounted) return;

      final data = response.data;
      List<FindTutors> results;

      if (data is List) {
        results = data
            .map((e) => FindTutors.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        results = [FindTutors.fromJson(data)];
      } else {
        results = [];
      }

      setState(() => _tutorsBySubject[subject] = results);
    } catch (e) {
      debugPrint('Error fetching $subject tutors: $e');
      if (mounted) setState(() => _tutorsBySubject[subject] = []);
    }
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

  Future<void> _openFindTutors({String? subject}) async {
    final selectedTab = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => FindTutorsPage(initialSubjectFilter: subject),
      ),
    );
    if (!mounted || selectedTab == null) return;
    setState(() => currentPageIndex = selectedTab);
  }

  Future<void> _openTeacherProfile(FindTutors tutor) async {
    final selectedTab = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => TutorProfilePage(userId: tutor.userUuid),
      ),
    );
    if (!mounted || selectedTab == null) return;
    setState(() => currentPageIndex = selectedTab);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage()),
                  (route) => false,
                );
                debugPrint("User Logged Out");
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _onMenuOptionSelected(String value) {
    switch (value) {
      case 'settings':
        debugPrint("Navigate to Settings");
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeTab(),
      const ChatPage(),
      StudentProfilePage(
        embedded: true,
        userId: context.read<AuthProvider>().userId!,
        showEmbeddedAppBar: false,
      ),
    ];

    return Scaffold(
      backgroundColor: currentPageIndex == 2
          ? Colors.grey.shade50
          : Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(index: currentPageIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPageIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => currentPageIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: _buildActiveNavIcon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: _buildActiveNavIcon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: _buildActiveNavIcon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final ThemeData theme = Theme.of(context);

    final menuItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: "settings",
        child: Row(
          children: [
            Icon(Icons.settings, color: theme.primaryColor, size: 20),
            const SizedBox(width: 12),
            const Text("Settings"),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            const Text("Logout", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];

    switch (currentPageIndex) {
      case 1:
        return AppBar(
          title: const Text(
            'Chat',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenuOptionSelected,
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              itemBuilder: (_) => menuItems,
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        );
      case 2:
        return AppBar(
          title: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenuOptionSelected,
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              itemBuilder: (_) => menuItems,
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        );
      default:
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _openFindTutors,
          ),
          title: const Text(
            'Home',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenuOptionSelected,
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              itemBuilder: (_) => menuItems,
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        );
    }
  }

  Widget _buildActiveNavIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.deepPurple),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recommended for you',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            for (final subject in _featuredSubjects) ...[
              _buildSubjectHeader(subject),
              const SizedBox(height: 12),
              _buildHorizontalCardList(subject),
              const SizedBox(height: 30),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openFindTutors(subject: title),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    const Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.lightBlue.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCardList(String subject) {
    final tutors = _tutorsBySubject[subject];

    // Still loading
    if (tutors == null) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Loaded but no tutors
    if (tutors.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No tutors available for $subject',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tutors.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildTutorCard(tutor: tutors[index]),
          );
        },
      ),
    );
  }

  Widget _buildTutorCard({required FindTutors tutor}) {
    final fullName = '${tutor.firstname} ${tutor.lastname}';
    final rating = double.tryParse(tutor.avgRating);
    final ratingLabel = rating != null
        ? rating.toStringAsFixed(1)
        : tutor.avgRating;

    // Show price from the first subject entry in subjectByPrice
    final firstSubject = tutor.subjectByPrice.entries.firstOrNull;

    // Profile picture
    ImageProvider? profileImage;
    final pic = tutor.profilePicture;
    if (pic.isNotEmpty) {
      final url = pic.contains('default_pfp.png')
          ? AppConstants.defaultProfilePictureUrl
          : AppConstants.resolveApiUrl(pic);
      profileImage = NetworkImage(url);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTeacherProfile(tutor),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: profileImage,
                child: profileImage == null
                    ? Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.deepPurple.shade200,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$fullName ($ratingLabel ⭐)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (tutor.location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tutor.location!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    if (firstSubject != null)
                      Text(
                        '${firstSubject.value} Baht / Hour',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
