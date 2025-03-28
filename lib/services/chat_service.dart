import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get chat messages stream
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = Message(
      id: '', // Firestore will generate this
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      seenBy: [senderId],
      chatId: chatId,
    );

    await _firestore.collection('messages').add(message.toMap());
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    // Upload image to Firebase Storage
    final fileName = 'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref().child(fileName);
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    // Create message with image URL
    final message = Message(
      id: '', // Firestore will generate this
      senderId: senderId,
      senderName: senderName,
      content: 'Image message',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      seenBy: [senderId],
      chatId: chatId,
    );

    await _firestore.collection('messages').add(message.toMap());
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String messageId, String userId) async {
    final messageRef = _firestore.collection('messages').doc(messageId);
    final messageDoc = await messageRef.get();

    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final message = Message.fromFirestore(messageDoc);
    if (!message.seenBy.contains(userId)) {
      final updatedSeenBy = List<String>.from(message.seenBy)..add(userId);
      await messageRef.update({'seenBy': updatedSeenBy});
    }
  }

  // Get or create chat between two users
  Future<String> getOrCreateChat(String userId1, String userId2) async {
    // Sort user IDs to ensure consistent chat ID
    final sortedIds = [userId1, userId2]..sort();
    final chatId = '${sortedIds[0]}_${sortedIds[1]}';

    // Check if chat exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [userId1, userId2],
        'lastMessage': null,
        'lastMessageTime': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // Get user's chats
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chats = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((id) => id != userId);
        
        // Get other user's details
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final user = AppUser.fromFirestore(userDoc);
          chats.add({
            'chatId': doc.id,
            'otherUser': user,
            'lastMessage': data['lastMessage'],
            'lastMessageTime': data['lastMessageTime'],
          });
        }
      }
      
      return chats;
    });
  }

  // Update chat's last message
  Future<void> updateChatLastMessage(String chatId, String message) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
} 