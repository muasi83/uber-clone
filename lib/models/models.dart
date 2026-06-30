class User {
  final int? id;
  final String? username;
  final String email;
  final String password;
  final String fullName;
  final String? deviceToken;
  bool isOnline;
  final bool isVerified;
  final DateTime createdAt;

  User({
    this.id,
    this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.deviceToken,
    this.isOnline = false,
    this.isVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

factory User.fromJson(Map<String, dynamic> json) => User(
  id: json['id'] as int?,
  username: json['username'] as String?,
  email: json['email'] as String? ?? 'unknown@test.com',
  password: json['password'] as String? ?? '',
  fullName: json['fullName'] as String? ?? 'Unknown',
  deviceToken: json['deviceToken'] as String?,
  isOnline: json['isOnline'] is bool 
      ? json['isOnline'] as bool 
      : (json['isOnline'] as int?) == 1,
  isVerified: json['isVerified'] is bool 
      ? json['isVerified'] as bool 
      : (json['isVerified'] as int?) == 1,
  createdAt: json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : DateTime.now(),
);

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'deviceToken': deviceToken,
        'isOnline': isOnline ? 1 : 0,
        'isVerified': isVerified ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Message {
  final int? id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final String status;
  final bool isRead;
  final bool isDelivered;
  final int? rideId;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    DateTime? sentAt,
    this.status = 'sent',
    this.isRead = false,
    this.isDelivered = false,
    this.rideId,
  }) : sentAt = sentAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as int?,
        senderId: json['senderId'] as int,
        receiverId: json['receiverId'] as int,
        content: json['content'] as String,
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : DateTime.now(),
        status: json['status'] as String? ?? 'sent',
        isRead: (json['isRead'] as int?) == 1,
        isDelivered: (json['isDelivered'] as int?) == 1,
        rideId: json['rideId'] as int?,
      );

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? sentAt,
    String? status,
    bool? isRead,
    bool? isDelivered,
    int? rideId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      rideId: rideId ?? this.rideId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
        'status': status,
        'isRead': isRead ? 1 : 0,
        'isDelivered': isDelivered ? 1 : 0,
        'rideId': rideId,
      };
}


