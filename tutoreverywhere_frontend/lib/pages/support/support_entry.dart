import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/pages/support/support_chat.dart';
import 'package:tutoreverywhere_frontend/pages/support/support_models.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class SupportEntryPage extends StatefulWidget {
  const SupportEntryPage({super.key});

  @override
  State<SupportEntryPage> createState() => _SupportEntryPageState();
}

class _SupportEntryPageState extends State<SupportEntryPage> {
  late final Dio _dio;
  bool _isLoading = true;
  bool _isStarting = false;
  List<SupportTicket> _tickets = <SupportTicket>[];

  @override
  void initState() {
    super.initState();
    // Local Dio instance keeps support APIs isolated and easy to configure.
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

  Options _authOptions() {
    // Backend expects the JWT in Authorization for verifyToken middleware.
    final token = context.read<AuthProvider>().token ?? '';
    return Options(headers: <String, dynamic>{'Authorization': token});
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTickets() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Load this user's full support ticket history for the list section.
      final response = await _dio.get<dynamic>(
        'support/tickets/mine',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data is! List) {
        _showSnack('Failed to load support tickets');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final parsed = (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map(SupportTicket.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _tickets = parsed;
        _isLoading = false;
      });
    } catch (e) {
      _showSnack('Error loading support tickets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startSupportChat() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      // Endpoint returns the existing open ticket or creates a new one.
      final response = await _dio.post<dynamic>(
        'support/tickets/start',
        options: _authOptions(),
      );

      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        final message = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to start support chat';
        _showSnack(message);
        return;
      }

      final payload = response.data as Map<String, dynamic>;
      final ticketRaw = payload['ticket'];
      if (ticketRaw is! Map<String, dynamic>) {
        _showSnack('Invalid support ticket response');
        return;
      }

      final ticket = SupportTicket.fromJson(ticketRaw);
      if (!mounted) return;
      // Open the chat thread directly, then refresh list on return.
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SupportChatPage(
            ticketId: ticket.ticketId,
            title: 'Support: Admin',
          ),
        ),
      );
      await _loadTickets();
    } catch (e) {
      _showSnack('Error starting support chat: $e');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            SupportChatPage(ticketId: ticket.ticketId, title: 'Support: Admin'),
      ),
    );
    await _loadTickets();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildTicketStatusChip(SupportTicket ticket) {
    final archived = ticket.isArchived;
    return Chip(
      label: Text(archived ? 'Archived' : 'Open'),
      visualDensity: VisualDensity.compact,
      backgroundColor: archived
          ? Colors.orange.shade100
          : Colors.green.shade100,
      labelStyle: TextStyle(
        color: archived ? Colors.orange.shade900 : Colors.green.shade900,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need help from Support?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text('Do you want to talk to the support team now?'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _isStarting ? null : _startSupportChat,
                        child: _isStarting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Yes, Contact Support'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Support Tickets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tickets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No support tickets yet.'),
              )
            else
              ..._tickets.map((ticket) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('Ticket ${ticket.ticketId}'),
                    subtitle: Text(
                      'Created: ${_formatDateTime(ticket.createdAt)}',
                    ),
                    trailing: _buildTicketStatusChip(ticket),
                    onTap: () => _openTicket(ticket),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
