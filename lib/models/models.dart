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
  email: json['email'] as String? ?? 'unknown@test.com', // Default email
  password: json['password'] as String? ?? '', // Default password
  fullName: json['fullName'] as String? ?? 'Unknown', // Default name
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
        'password': password,
        'fullName': fullName,
        'deviceToken': deviceToken,
        'isOnline': isOnline ? 1 : 0,
        'isVerified': isVerified ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? deviceToken,
    bool? isOnline,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      deviceToken: deviceToken ?? this.deviceToken,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Message {
  final int? id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final String status; // sent, delivered, seen
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    DateTime? sentAt,
    this.status = 'sent',
    this.isRead = false,
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
        'status': status,
        'isRead': isRead ? 1 : 0,
      };

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? sentAt,
    String? status,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AppNotification {
  final int? id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedUserId;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    DateTime? createdAt,
    this.relatedUserId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int?,
        userId: json['userId'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        isRead: (json['isRead'] as int?) == 1,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        relatedUserId: json['relatedUserId'] as String?,
      );
AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? relatedUserId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedUserId: relatedUserId ?? this.relatedUserId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'relatedUserId': relatedUserId,
      };
}