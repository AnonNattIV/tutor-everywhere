import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();

  Timer? _pollTimer;
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;

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

    _loadConversations(autoselectIfNeeded: widget.initialPeerUserId == null);
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
      return '${_baseUrl}assets/pfp/default_pfp.png';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$_baseUrl${trimmed.substring(1)}';
    }
    return '$_baseUrl$trimmed';
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
          final subtitle = conversation.messageType == 'location'
              ? 'Shared location'
              : conversation.messageText.trim();

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
              subtitle.isEmpty ? 'No message' : subtitle,
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

  Widget _buildMessageBubble(_ChatMessage message) {
    final currentUserId = context.read<AuthProvider>().userId;
    final isMine = currentUserId != null && message.senderId == currentUserId;
    final bubbleColor = isMine
        ? Colors.deepPurple.shade100
        : Colors.grey.shade200;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    Widget body;
    if (message.isLocation &&
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
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
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.messageText,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String senderId;
  final String receiverId;
  final String messageType;
  final String messageText;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  bool get isLocation => messageType == 'location';

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      senderId: _readString(json['sender_id']),
      receiverId: _readString(json['receiver_id']),
      messageType: _readString(json['message_type']),
      messageText: _readString(json['message_text']),
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      createdAt: _readDateTime(json['created_at']),
    );
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

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
