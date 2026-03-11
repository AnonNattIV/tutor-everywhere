import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/requestMoney.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
import 'package:tutoreverywhere_frontend/service/api.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.initialPeerUserId,
    this.initialPeerDisplayName,
    this.embedded = true,
  });

  final String? initialPeerUserId;
  final String? initialPeerDisplayName;
  final bool embedded;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const Duration _pollInterval = Duration(seconds: 4);
  static const String _baseUrl = AppConstants.baseUrl;
  // Fallback center (Bangkok) when GPS is unavailable.
  static const LatLng _defaultMapCenter = LatLng(13.7563, 100.5018);

  late final Dio _dio;
  late final RestClient _client;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();

  Timer? _pollTimer;
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _isAcceptingPayment = false;

  List<_ConversationPreview> _conversations = <_ConversationPreview>[];
  List<_ChatMessage> _messages = <_ChatMessage>[];

  String? _activePeerUserId;
  String _activePeerDisplayName = '';

  @override
  void initState() {
    super.initState();
    _setupDio();

    _activePeerUserId = widget.initialPeerUserId;
    _activePeerDisplayName = widget.initialPeerDisplayName?.trim() ?? '';

    // Default behavior: show conversation list first when opening Chat tab.
    // A specific thread opens only when an initial peer is explicitly provided.
    _loadConversations(autoselectIfNeeded: false);
    if (_activePeerUserId != null) {
      _loadMessages(_activePeerUserId!);
    }
    _startPolling();
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

    _client = RestClient(_dio, baseUrl: _baseUrl);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _dio.close(force: true);
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Poll conversations/messages for near real-time updates without sockets.
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _loadConversations(silent: true);
      final peerId = _activePeerUserId;
      if (peerId != null) {
        _loadMessages(peerId, silent: true);
      }
    });
  }

  Options _authOptions() {
    // Backend expects raw JWT string in Authorization header.
    final token = context.read<AuthProvider>().token;
    return Options(headers: <String, dynamic>{'Authorization': token ?? ''});
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayNameForConversation(_ConversationPreview c) {
    final first = c.partnerFirstName.trim();
    final last = c.partnerLastName.trim();
    final fullName = '$first $last'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (c.partnerUsername.trim().isNotEmpty) return c.partnerUsername.trim();
    return c.partnerId;
  }

  String? _absoluteProfilePictureUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('default_pfp.png')) {
      return AppConstants.defaultProfilePictureUrl;
    }
    return AppConstants.resolveApiUrl(trimmed);
  }

  String? _absoluteAssetUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    return AppConstants.resolveApiUrl(trimmed);
  }

  String _conversationSubtitle(_ConversationPreview conversation) {
    final type = conversation.messageType.toLowerCase();
    if (type == 'location') return 'Shared location';
    if (type == 'image') return 'Sent an image';
    if (type == 'request_money') {
      final text = conversation.messageText.trim();
      return text.isEmpty ? 'Request money' : text;
    }
    final text = conversation.messageText.trim();
    return text.isEmpty ? 'No message' : text;
  }

  Future<void> _openRequestMoneyForm({RequestMoneyDraft? initialDraft}) async {
    final peerUserId = _activePeerUserId;
    if (peerUserId == null || _isSending) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RequestMoneyPage(
          initialPeerUserId: peerUserId,
          initialPeerDisplayName: _activePeerDisplayName,
          initialDraft: initialDraft,
        ),
      ),
    );

    if (result == true) {
      await _loadMessages(peerUserId, silent: true);
      await _loadConversations(silent: true);
    }
  }

  RequestMoneyDraft? _buildDraftFromPayload(_RequestMoneyPayload payload) {
    if (payload.latitude == null || payload.longitude == null) {
      return null;
    }
    final startDate = payload.startAtDate;
    final endDate = payload.endAtDate;
    if (startDate == null || endDate == null || !endDate.isAfter(startDate)) {
      return null;
    }

    final subject = payload.subject.trim().isEmpty
        ? AppConstants.featuredSubjects.first
        : payload.subject.trim();
    final placeName = payload.placeName.trim().isEmpty
        ? payload.locationLabel
        : payload.placeName.trim();

    return RequestMoneyDraft(
      subject: subject,
      placeName: placeName,
      description: payload.description,
      startDate: startDate,
      endDate: endDate,
      price: payload.amount.round(),
      pinnedLocation: LatLng(payload.latitude!, payload.longitude!),
    );
  }

  Future<void> _showPaidDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('You have already paid'),
          content: const Text('This payment has accepted by the tutor'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> acceptPayment(String messageId) async {
    if (_isAcceptingPayment) {
      print('Payment already in progress');
      return;
    }

    setState(() {
      _isAcceptingPayment = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      await _client.acceptPromptPay(token!, messageId);
      if (mounted) {
        _showAcceptedDialog();
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
    } catch (e) {
      print('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingPayment = false;
        });
      }
    }
  }

  Future<void> _showAcceptedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Accepted successfully'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<Position?> _getCurrentPosition({bool showErrors = true}) async {
    // Request permission lazily and return null if user/device blocks location.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showErrors) _showSnack('Please enable location services');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (showErrors) _showSnack('Location permission denied');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _loadConversations({
    bool silent = false,
    bool autoselectIfNeeded = false,
  }) async {
    if (!silent && mounted) {
      setState(() => _isLoadingConversations = true);
    }

    try {
      final response = await _dio.get<dynamic>(
        'chat/conversations',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data is! List) {
        if (!silent) {
          _showSnack('Failed to load conversations');
        }
        return;
      }

      final parsed = (response.data as List<dynamic>)
          .map(
            (dynamic item) =>
                _ConversationPreview.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _conversations = parsed;
        _isLoadingConversations = false;
      });

      if (_activePeerUserId != null) {
        final matches = parsed.where((c) => c.partnerId == _activePeerUserId);
        final match = matches.isEmpty ? null : matches.first;
        if (match != null && mounted) {
          setState(() {
            _activePeerDisplayName = _displayNameForConversation(match);
          });
        }
      } else if (autoselectIfNeeded && parsed.isNotEmpty) {
        final first = parsed.first;
        _openConversation(first.partnerId, _displayNameForConversation(first));
      }
    } catch (e) {
      if (!silent) {
        _showSnack('Error loading conversations: $e');
      }
      if (mounted) {
        setState(() => _isLoadingConversations = false);
      }
    }
  }

  Future<void> _loadMessages(String peerUserId, {bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingMessages = true);
    }

    try {
      final response = await _dio.get<dynamic>(
        'chat/messages/$peerUserId',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data is! List) {
        if (!silent) {
          _showSnack('Failed to load messages');
        }
        return;
      }

      final parsed = (response.data as List<dynamic>)
          .map(
            (dynamic item) =>
                _ChatMessage.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _messages = parsed;
        _isLoadingMessages = false;
      });
      _scrollMessagesToBottom();
    } catch (e) {
      if (!silent) {
        _showSnack('Error loading messages: $e');
      }
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _openConversation(String peerUserId, String peerDisplayName) {
    setState(() {
      _activePeerUserId = peerUserId;
      _activePeerDisplayName = peerDisplayName;
      _messages = <_ChatMessage>[];
    });
    _loadMessages(peerUserId);
  }

  void _closeConversation() {
    setState(() {
      _activePeerUserId = null;
      _activePeerDisplayName = '';
      _messages = <_ChatMessage>[];
    });
  }

  void _scrollMessagesToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) return;
      _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendTextMessage() async {
    final peerUserId = _activePeerUserId;
    if (peerUserId == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final response = await _dio.post<dynamic>(
        'chat/messages/$peerUserId',
        data: <String, dynamic>{'type': 'text', 'text': text},
        options: _authOptions(),
      );

      if (response.statusCode != 201) {
        _showSnack('Failed to send message');
        return;
      }

      _messageController.clear();
      await _loadMessages(peerUserId, silent: true);
      await _loadConversations(silent: true);
    } catch (e) {
      _showSnack('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendLocationMessage({
    required String peerUserId,
    required double latitude,
    required double longitude,
    required String text,
  }) async {
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      final response = await _dio.post<dynamic>(
        'chat/messages/$peerUserId',
        data: <String, dynamic>{
          'type': 'location',
          'latitude': latitude,
          'longitude': longitude,
          'text': text,
        },
        options: _authOptions(),
      );

      if (response.statusCode != 201) {
        _showSnack('Failed to share location');
        return;
      }

      await _loadMessages(peerUserId, silent: true);
      await _loadConversations(silent: true);
    } catch (e) {
      _showSnack('Error sharing location: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendImageMessage(
    XFile imageFile, {
    required String peerUserId,
    String? caption,
  }) async {
    if (_isSending) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      _showSnack('Not authenticated');
      return;
    }

    setState(() => _isSending = true);
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
        if (caption != null && caption.trim().isNotEmpty)
          'text': caption.trim(),
      });

      final response = await _dio.post<dynamic>(
        'chat/messages/$peerUserId/image',
        data: formData,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': token,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 201) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to send image';
        _showSnack(msg);
        return;
      }

      _messageController.clear();
      await _loadMessages(peerUserId, silent: true);
      await _loadConversations(silent: true);
    } catch (e) {
      _showSnack('Error sending image: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final peerUserId = _activePeerUserId;
    if (peerUserId == null || _isSending) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null) return;

    final caption = _messageController.text.trim();
    await _sendImageMessage(
      picked,
      peerUserId: peerUserId,
      caption: caption.isEmpty ? null : caption,
    );
  }

  Future<void> _openImagePickerOptions() async {
    if (_activePeerUserId == null || _isSending) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Photo from gallery'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'gallery') {
      await _pickAndSendImage(ImageSource.gallery);
    } else if (action == 'camera') {
      await _pickAndSendImage(ImageSource.camera);
    }
  }

  Future<void> _openPinnedLocationPicker() async {
    final peerUserId = _activePeerUserId;
    if (peerUserId == null || _isSending) return;

    // GPS is only the starting point; user still confirms adjusted pin before send.
    final currentPosition = await _getCurrentPosition(showErrors: false);
    final initialCenter = currentPosition == null
        ? _defaultMapCenter
        : LatLng(currentPosition.latitude, currentPosition.longitude);
    if (currentPosition == null) {
      _showSnack('Could not read GPS. Use map pin manually.');
    }

    if (!mounted) return;
    final picked = await showModalBottomSheet<_PinnedLocationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LocationPickerSheet(initialCenter: initialCenter),
    );

    if (picked == null) return;
    await _sendLocationMessage(
      peerUserId: peerUserId,
      latitude: picked.latitude,
      longitude: picked.longitude,
      text: picked.label,
    );
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

  Widget _buildConversationList() {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No conversations yet.\nOpen a tutor profile and tap "Tap to chat" to start.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadConversations(),
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final displayName = _displayNameForConversation(conversation);
          final profileUrl = _absoluteProfilePictureUrl(
            conversation.partnerProfilePicture,
          );
          final subtitle = _conversationSubtitle(conversation);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profileUrl == null
                  ? null
                  : NetworkImage(profileUrl),
              child: profileUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatTime(conversation.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => _openConversation(conversation.partnerId, displayName),
          );
        },
      ),
    );
  }

  Widget _buildEmbeddedThreadHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _closeConversation,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              _activePeerDisplayName.isEmpty ? 'Chat' : _activePeerDisplayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapPreview(double latitude, double longitude) {
    final target = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 260,
        height: 150,
        child: AbsorbPointer(
          // Preview-only map; tap on bubble opens navigation externally.
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 15),
            markers: <Marker>{
              Marker(
                markerId: MarkerId('msg-$latitude-$longitude'),
                position: target,
              ),
            },
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessageBody(_ChatMessage message) {
    final imageUrl = _absoluteAssetUrl(message.imagePath);
    final text = message.messageText.trim();
    final hasCaption = text.isNotEmpty && text.toLowerCase() != 'sent an image';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl == null)
          const Text('Image not available')
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 260,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 260,
                  height: 180,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text('Failed to load image'),
                );
              },
            ),
          ),
        if (hasCaption) ...[const SizedBox(height: 8), Text(text)],
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  Widget _buildRequestMoneyCard(_ChatMessage message, {required bool isMine}) {
    final payload = message.requestPayload;
    if (payload == null) {
      return Text(
        message.messageText.trim().isEmpty
            ? 'Request money'
            : message.messageText,
      );
    }

    final qrUrl = _absoluteAssetUrl(payload.promptpayPicturePath);
    final canOpenMap = payload.latitude != null && payload.longitude != null;
    final amountText = _formatAmount(payload.amount);
    final hourText = _formatAmount(payload.hours);
    final role = context.read<AuthProvider>().role?.toLowerCase();
    final showTutorActions = role == 'tutor' && isMine;
    final cardColor = isMine
        ? Colors.deepPurple.shade100
        : Colors.grey.shade200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request $amountText Baht for $hourText Hours',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Date: ${payload.dateLabel}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            'Location: ${payload.locationLabel}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (payload.subject.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Subject: ${payload.subject}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          if (payload.description.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              payload.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
              clipBehavior: Clip.antiAlias,
              child: qrUrl == null
                  ? const Center(
                      child: Text(
                        'PromptPay QR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Image.network(
                      qrUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text(
                              'PromptPay QR\nnot found',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canOpenMap
                  ? () => _openGoogleMapsNavigation(
                      payload.latitude!,
                      payload.longitude!,
                    )
                  : null,
              icon: const Icon(
                Icons.map_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Open map location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (message.messageType.contains('paid')) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _showPaidDialog,
              icon: const Icon(Icons.check_circle),
              label: const Text('Paid'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                backgroundColor: Colors.green,
              ),
            ),
          ],

          if (showTutorActions) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (!message.messageType.contains('paid')) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final draft = _buildDraftFromPayload(payload);
                        if (draft == null) {
                          _showSnack(
                            'Cannot edit this request (missing date/location data)',
                          );
                          return;
                        }
                        await _openRequestMoneyForm(initialDraft: draft);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ),
                ],
                if (!message.messageType.contains('paid')) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => acceptPayment(message.messageId),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final currentUserId = context.read<AuthProvider>().userId;
    final isMine = currentUserId != null && message.senderId == currentUserId;
    final bubbleColor = isMine
        ? Colors.deepPurple.shade100
        : Colors.grey.shade200;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    Widget body;
    if (message.isRequestMoney) {
      body = _buildRequestMoneyCard(message, isMine: isMine);
    } else if (message.isImage) {
      body = _buildImageMessageBody(message);
    } else if (message.isLocation &&
        message.latitude != null &&
        message.longitude != null) {
      final latitude = message.latitude!;
      final longitude = message.longitude!;
      body = InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openGoogleMapsNavigation(latitude, longitude),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'Location shared',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (message.messageText.isNotEmpty) ...[
                Text(message.messageText),
                const SizedBox(height: 6),
              ],
              _buildLocationMapPreview(latitude, longitude),
              const SizedBox(height: 6),
              Text(
                'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap map to open Google Maps navigation',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
        ),
      );
    } else {
      body = Text(message.messageText);
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: message.isRequestMoney
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: message.isRequestMoney ? Colors.transparent : bubbleColor,
          borderRadius: BorderRadius.circular(message.isRequestMoney ? 14 : 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final disabled = _activePeerUserId == null || _isSending;
    final isTutor = context.read<AuthProvider>().role == 'tutor';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            if (isTutor)
              IconButton(
                onPressed: disabled ? null : _openRequestMoneyForm,
                icon: const Icon(Icons.handshake),
                tooltip: 'Request money',
              ),
            IconButton(
              onPressed: disabled ? null : _openImagePickerOptions,
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Send image',
            ),
            IconButton(
              onPressed: disabled ? null : _openPinnedLocationPicker,
              icon: const Icon(Icons.add_location_alt),
              tooltip: 'Share location',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !disabled,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  isDense: true,
                ),
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            IconButton(
              onPressed: disabled ? null : _sendTextMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationThread() {
    return Column(
      children: [
        if (widget.embedded) _buildEmbeddedThreadHeader(),
        Expanded(
          child: _isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Send a message to start the conversation.',
                  ),
                )
              : ListView.builder(
                  controller: _messageScrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final showThread = _activePeerUserId != null;
    final body = showThread
        ? _buildConversationThread()
        : _buildConversationList();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showThread
              ? (_activePeerDisplayName.isEmpty
                    ? 'Chat'
                    : _activePeerDisplayName)
              : 'Chat',
        ),
        leading: showThread
            ? IconButton(
                onPressed: _closeConversation,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: body,
    );
  }
}

class _ConversationPreview {
  _ConversationPreview({
    required this.partnerId,
    required this.partnerFirstName,
    required this.partnerLastName,
    required this.partnerUsername,
    required this.partnerProfilePicture,
    required this.messageType,
    required this.messageText,
    required this.createdAt,
  });

  final String partnerId;
  final String partnerFirstName;
  final String partnerLastName;
  final String partnerUsername;
  final String partnerProfilePicture;
  final String messageType;
  final String messageText;
  final DateTime? createdAt;

  factory _ConversationPreview.fromJson(Map<String, dynamic> json) {
    return _ConversationPreview(
      partnerId: _readString(json['partner_id']),
      partnerFirstName: _readString(json['partner_firstname']),
      partnerLastName: _readString(json['partner_lastname']),
      partnerUsername: _readString(json['partner_username']),
      partnerProfilePicture: _readString(json['partner_profile_picture']),
      messageType: _readString(json['message_type']),
      messageText: _readString(json['message_text']),
      createdAt: _readDateTime(json['created_at']),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.messageText,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.requestPayload,
    required this.createdAt,
  });

  final String messageId;
  final String senderId;
  final String receiverId;
  final String messageType;
  final String messageText;
  final double? latitude;
  final double? longitude;
  final String imagePath;
  final _RequestMoneyPayload? requestPayload;
  final DateTime? createdAt;

  bool get isLocation => messageType == 'location';
  bool get isImage => messageType == 'image';
  bool get isRequestMoney => messageType.contains('request_money');

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      messageId: _readString(json['message_id']),
      senderId: _readString(json['sender_id']),
      receiverId: _readString(json['receiver_id']),
      messageType: _readString(json['message_type']),
      messageText: _readString(json['message_text']),
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      imagePath: _readString(json['image_path']),
      requestPayload: _RequestMoneyPayload.fromDynamic(json['request_payload']),
      createdAt: _readDateTime(json['created_at']),
    );
  }
}

class _RequestMoneyPayload {
  const _RequestMoneyPayload({
    required this.subject,
    required this.amount,
    required this.hours,
    required this.startAt,
    required this.endAt,
    required this.dateLabel,
    required this.locationLabel,
    required this.placeName,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.promptpayPicturePath,
    required this.tutorId,
  });

  final String subject;
  final double amount;
  final double hours;
  final String startAt;
  final String endAt;
  final String dateLabel;
  final String locationLabel;
  final String placeName;
  final String description;
  final double? latitude;
  final double? longitude;
  final String promptpayPicturePath;
  final String tutorId;

  DateTime? get startAtDate => _readDateTime(startAt);
  DateTime? get endAtDate => _readDateTime(endAt);

  factory _RequestMoneyPayload.fromMap(Map<String, dynamic> map) {
    return _RequestMoneyPayload(
      subject: _readString(map['subject']),
      amount: _readDouble(map['amount']) ?? 0,
      hours: _readDouble(map['hours']) ?? 0,
      startAt: _readString(map['startAt']),
      endAt: _readString(map['endAt']),
      dateLabel: _readString(map['dateLabel']),
      locationLabel: _readString(map['locationLabel']),
      placeName: _readString(map['placeName']),
      description: _readString(map['description']),
      latitude: _readDouble(map['latitude']),
      longitude: _readDouble(map['longitude']),
      promptpayPicturePath: _readString(map['promptpayPicturePath']),
      tutorId: _readString(map['tutorId']),
    );
  }

  static _RequestMoneyPayload? fromDynamic(dynamic value) {
    final mapped = _readMap(value);
    if (mapped == null) return null;
    return _RequestMoneyPayload.fromMap(mapped);
  }
}

class _PinnedLocationResult {
  _PinnedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.initialCenter});

  final LatLng initialCenter;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final TextEditingController _labelController = TextEditingController(
    text: 'Pinned location',
  );

  late LatLng _cameraTarget;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _cameraTarget = widget.initialCenter;
    _selectedPoint = widget.initialCenter;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _pinAtCenter() {
    // Convenience action after panning/zooming to desired area.
    setState(() {
      _selectedPoint = _cameraTarget;
    });
  }

  void _confirmSend() {
    final selectedPoint = _selectedPoint;
    if (selectedPoint == null) return;

    final label = _labelController.text.trim().isEmpty
        ? 'Pinned location'
        : _labelController.text.trim();

    Navigator.pop(
      context,
      _PinnedLocationResult(
        latitude: selectedPoint.latitude,
        longitude: selectedPoint.longitude,
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _selectedPoint != null;
    final height = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pin Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'GPS is used as the starting pin. Move/adjust the pin, then confirm to send.',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialCenter,
                    zoom: 15,
                  ),
                  onTap: (point) => setState(() => _selectedPoint = point),
                  onCameraMove: (cameraPosition) {
                    _cameraTarget = cameraPosition.target;
                  },
                  markers: <Marker>{
                    if (_selectedPoint != null)
                      Marker(
                        markerId: const MarkerId('pinned-location'),
                        position: _selectedPoint!,
                        draggable: true,
                        onDragEnd: (point) =>
                            setState(() => _selectedPoint = point),
                      ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pinAtCenter,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Pin center'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Optional label',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canSend ? _confirmSend : null,
                  child: const Text('Send pin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _readString(dynamic value) {
  return value?.toString() ?? '';
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, val) => MapEntry(key.toString(), val));
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
