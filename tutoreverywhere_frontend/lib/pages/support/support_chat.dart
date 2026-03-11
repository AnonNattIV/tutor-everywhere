import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/pages/support/support_models.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({
    super.key,
    required this.ticketId,
    required this.title,
    this.allowArchive = true,
  });

  final String ticketId;
  final String title;
  final bool allowArchive;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  static const Duration _pollInterval = Duration(seconds: 4);

  late final Dio _dio;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();

  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  SupportTicket? _ticket;
  List<SupportMessage> _messages = <SupportMessage>[];

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );
    _loadThread();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _dio.close(force: true);
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  Options _authOptions() {
    final token = context.read<AuthProvider>().token ?? '';
    return Options(headers: <String, dynamic>{'Authorization': token});
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _loadThread(silent: true);
    });
  }

  Future<void> _loadThread({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _dio.get<dynamic>(
        'support/tickets/${widget.ticketId}/messages',
        options: _authOptions(),
      );

      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        if (!silent) _showSnack('Failed to load support chat');
        return;
      }

      final payload = response.data as Map<String, dynamic>;
      final ticketRaw = payload['ticket'];
      final messagesRaw = payload['messages'];
      final parsedTicket = ticketRaw is Map<String, dynamic>
          ? SupportTicket.fromJson(ticketRaw)
          : null;
      final parsedMessages = messagesRaw is List
          ? messagesRaw
                .whereType<Map<String, dynamic>>()
                .map(SupportMessage.fromJson)
                .toList()
          : <SupportMessage>[];

      if (!mounted) return;
      setState(() {
        _ticket = parsedTicket;
        _messages = parsedMessages;
        _isLoading = false;
      });
      _scrollMessagesToBottom();
    } catch (e) {
      if (!silent) _showSnack('Error loading support chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_ticket?.isArchived == true) return;

    setState(() => _isSending = true);
    try {
      final response = await _dio.post<dynamic>(
        'support/tickets/${widget.ticketId}/messages',
        data: <String, dynamic>{'text': text},
        options: _authOptions(),
      );

      if (response.statusCode != 201) {
        final message = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to send support message';
        _showSnack(message);
        return;
      }

      _messageController.clear();
      await _loadThread(silent: true);
    } catch (e) {
      _showSnack('Error sending support message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _archiveTicket() async {
    final ticket = _ticket;
    if (ticket == null || ticket.isArchived) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive Chat'),
          content: const Text(
            'Archive this support chat and end this session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await _dio.post<dynamic>(
        'support/tickets/${widget.ticketId}/archive',
        options: _authOptions(),
      );

      if (response.statusCode != 200) {
        final message = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to archive support chat';
        _showSnack(message);
        return;
      }

      _showSnack('Support chat archived');
      await _loadThread(silent: true);
    } catch (e) {
      _showSnack('Error archiving support chat: $e');
    }
  }

  Widget _buildTicketBanner() {
    final ticket = _ticket;
    if (ticket == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: ticket.isArchived ? Colors.orange.shade100 : Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket ID: ${ticket.ticketId}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (ticket.isArchived)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'This chat is archived',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final currentUserId = context.read<AuthProvider>().userId;
    final isMine = currentUserId != null && currentUserId == message.senderId;
    final bubbleColor = isMine
        ? Colors.deepPurple.shade100
        : Colors.grey.shade200;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.messageText),
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final archived = _ticket?.isArchived == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.allowArchive && !archived)
            IconButton(
              onPressed: _archiveTicket,
              icon: const Icon(Icons.settings),
              tooltip: 'Archive chat',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTicketBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Start talking to support.'),
                  )
                : ListView.builder(
                    controller: _messageScrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !archived && !_isSending,
                      decoration: InputDecoration(
                        hintText: archived
                            ? 'Archived chat'
                            : 'Message Support',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: archived || _isSending ? null : _sendMessage,
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
          ),
        ],
      ),
    );
  }
}
