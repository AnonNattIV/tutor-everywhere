import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutoreverywhere_frontend/constants/app_constants.dart';
import 'package:tutoreverywhere_frontend/pages/support/support_chat.dart';
import 'package:tutoreverywhere_frontend/pages/support/support_models.dart';
import 'package:tutoreverywhere_frontend/providers/auth_provider.dart';

class AdminSupportUsersPage extends StatefulWidget {
  const AdminSupportUsersPage({super.key});

  @override
  State<AdminSupportUsersPage> createState() => _AdminSupportUsersPageState();
}

class _AdminSupportUsersPageState extends State<AdminSupportUsersPage> {
  late final Dio _dio;
  bool _isLoading = true;
  List<SupportUserSummary> _users = <SupportUserSummary>[];

  @override
  void initState() {
    super.initState();
    // Dedicated client for admin support endpoints.
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

  Options _authOptions() {
    // Admin JWT is required for /support/admin/* routes.
    final token = context.read<AuthProvider>().token ?? '';
    return Options(headers: <String, dynamic>{'Authorization': token});
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Backend aggregates each user with latest/open-ticket metadata.
      final response = await _dio.get<dynamic>(
        'support/admin/users',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data is! List) {
        _showSnack('Failed to load support users');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final parsed = (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map(SupportUserSummary.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _users = parsed;
        _isLoading = false;
      });
    } catch (e) {
      _showSnack('Error loading support users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          children: [
            SizedBox(height: 120),
            Center(child: Text('No support tickets yet.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          final hasOpen = user.openCount > 0;

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            title: Text(user.displayName),
            subtitle: Text(
              hasOpen
                  ? 'Open tickets: ${user.openCount} • ${_formatTime(user.latestTicketCreatedAt)}'
                  : 'Latest: ${_formatTime(user.latestTicketCreatedAt)}',
            ),
            trailing: hasOpen
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${user.openCount} open',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminSupportUserTicketsPage(
                  userId: user.userId,
                  userDisplayName: user.displayName,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminSupportUserTicketsPage extends StatefulWidget {
  const AdminSupportUserTicketsPage({
    super.key,
    required this.userId,
    required this.userDisplayName,
  });

  final String userId;
  final String userDisplayName;

  @override
  State<AdminSupportUserTicketsPage> createState() =>
      _AdminSupportUserTicketsPageState();
}

class _AdminSupportUserTicketsPageState
    extends State<AdminSupportUserTicketsPage> {
  late final Dio _dio;
  bool _isLoading = true;
  List<SupportTicket> _tickets = <SupportTicket>[];

  @override
  void initState() {
    super.initState();
    // Recreate client per page to keep lifecycle straightforward.
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
    // Same auth header shape used across support pages.
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
      // Load all tickets for a selected user so admin can open any thread.
      final response = await _dio.get<dynamic>(
        'support/admin/users/${widget.userId}/tickets',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data is! List) {
        _showSnack('Failed to load user support tickets');
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
      _showSnack('Error loading user support tickets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userDisplayName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? const Center(child: Text('No support tickets for this user'))
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: ListView.builder(
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final ticket = _tickets[index];
                  final archived = ticket.isArchived;

                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: ListTile(
                      title: Text('Ticket ${ticket.ticketId}'),
                      subtitle: Text(
                        'Created: ${_formatTime(ticket.createdAt)}',
                      ),
                      trailing: Chip(
                        label: Text(archived ? 'Archived' : 'Open'),
                        backgroundColor: archived
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                      ),
                      onTap: () async {
                        // Reuse shared SupportChatPage for admin-side chat view.
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SupportChatPage(
                              ticketId: ticket.ticketId,
                              title: 'Support: ${widget.userDisplayName}',
                            ),
                          ),
                        );
                        await _loadTickets();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
