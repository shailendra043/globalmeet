import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final List<String> seenBy;
  final String chatId;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.seenBy,
    required this.chatId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
      chatId: data['chatId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
      'chatId': chatId,
    };
  }

  Message copyWith({
    String? content,
    String? imageUrl,
    List<String>? seenBy,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp,
      seenBy: seenBy ?? this.seenBy,
      chatId: chatId,
    );
  }
} 