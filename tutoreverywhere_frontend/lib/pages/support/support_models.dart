class SupportTicket {
  SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.userFirstName,
    required this.userLastName,
    required this.userUsername,
    required this.userRole,
  });

  final String ticketId;
  final String userId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;
  final String userFirstName;
  final String userLastName;
  final String userUsername;
  final String userRole;

  bool get isArchived => status.toLowerCase() == 'archived';

  String get userDisplayName {
    final full = '$userFirstName $userLastName'.trim();
    if (full.isNotEmpty) return full;
    return userUsername;
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketId: _readString(json['ticket_id']),
      userId: _readString(json['user_id']),
      status: _readString(json['status']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
      archivedAt: _readDateTime(json['archived_at']),
      userFirstName: _readString(json['user_firstname']),
      userLastName: _readString(json['user_lastname']),
      userUsername: _readString(json['user_username']),
      userRole: _readString(json['user_role']),
    );
  }
}

class SupportMessage {
  SupportMessage({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.messageText,
    required this.createdAt,
  });

  final String messageId;
  final String ticketId;
  final String senderId;
  final String messageText;
  final DateTime? createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      messageId: _readString(json['message_id']),
      ticketId: _readString(json['ticket_id']),
      senderId: _readString(json['sender_id']),
      messageText: _readString(json['message_text']),
      createdAt: _readDateTime(json['created_at']),
    );
  }
}

class SupportUserSummary {
  SupportUserSummary({
    required this.userId,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.latestTicketId,
    required this.latestTicketStatus,
    required this.latestTicketCreatedAt,
    required this.openCount,
  });

  final String userId;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final String latestTicketId;
  final String latestTicketStatus;
  final DateTime? latestTicketCreatedAt;
  final int openCount;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (username.trim().isNotEmpty) return username.trim();
    return userId;
  }

  factory SupportUserSummary.fromJson(Map<String, dynamic> json) {
    return SupportUserSummary(
      userId: _readString(json['user_id']),
      username: _readString(json['username']),
      role: _readString(json['role']),
      firstName: _readString(json['firstname']),
      lastName: _readString(json['lastname']),
      latestTicketId: _readString(json['latest_ticket_id']),
      latestTicketStatus: _readString(json['latest_ticket_status']),
      latestTicketCreatedAt: _readDateTime(json['latest_ticket_created_at']),
      openCount: _readInt(json['open_count']),
    );
  }
}

String _readString(dynamic value) {
  return value?.toString() ?? '';
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
