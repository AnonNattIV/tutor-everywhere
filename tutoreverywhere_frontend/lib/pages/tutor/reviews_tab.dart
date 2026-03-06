// lib/pages/tutor/reviews_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';
import 'package:tutoreverywhere_frontend/models/reviews/data.dart';
import 'package:tutoreverywhere_frontend/pages/student/profile.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({
    super.key,
    required this.tutorId,
    required this.tutorName,
  });

  final String tutorId;
  final String tutorName;

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  String? _errorMessage;

  late final Dio _dio;
  late final RestClient _client;
  static const String _baseUrl = AppConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchReviews();
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

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reviews = await _client.getReviewsByRevieweeId(widget.tutorId);
      
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data['message'] ?? e.message ?? 'Failed to load reviews';
        _isLoading = false;
      });
      debugPrint('Dio Error fetching reviews: ${e.type} - ${e.message}');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching reviews: $e\nStack: $stackTrace');
    }
  }

  /// Navigate to student profile page
  void _navigateToStudentProfile(String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfilePage(
          embedded: true,
          userId: studentId,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  /// Verified badge - matches your profile screen style
  Widget? _buildVerifiedBadge(bool verified) {
    if (!verified) return null;
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }

  /// Resolve profile picture URL (handles relative/absolute/default)
  ImageProvider? _getProfileImage(String? pictureUrl) {
    if (pictureUrl == null || pictureUrl.isEmpty) return null;
    if (pictureUrl.contains('default_pfp.png')) return null;
    if (pictureUrl.startsWith('http')) return NetworkImage(pictureUrl);
    return NetworkImage('$_baseUrl$pictureUrl');
  }

  Widget _buildReviewCard(Review review) {
    final reviewerImage = _getProfileImage(review.reviewerProfilePicture);
    final isClickable = review.reviewer.isNotEmpty; // Only navigate if we have a valid ID

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Header: Reviewer + Rating ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 Clickable Avatar
                GestureDetector(
                  onTap: isClickable ? () => _navigateToStudentProfile(review.reviewer) : null,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: reviewerImage,
                    child: reviewerImage == null
                        ? Icon(
                            review.reviewerGender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                            size: 24,
                            color: Colors.deepPurple,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 👇 Clickable Name + Verified + Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: isClickable ? () => _navigateToStudentProfile(review.reviewer) : null,
                        child: MouseRegion(
                          cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                review.reviewerFullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isClickable ? Colors.deepPurple : Colors.black87,
                                  decoration: isClickable ? TextDecoration.underline : TextDecoration.none,
                                ),
                              ),
                              _buildVerifiedBadge(review.reviewerVerified) ?? const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reviewed on ${_formatDate(review.reviewDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                // Stars (not clickable)
                _buildRatingStars(review.rating),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // === Subject Chip ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Text(
                review.subject,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ),
            
            // === Comment (optional) ===
            if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchReviews,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No reviews yet for ${widget.tutorName}',
              style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews will appear here once students start rating',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // List
    return RefreshIndicator(
      onRefresh: _fetchReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(_reviews[index]);
        },
      ),
    );
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }
}