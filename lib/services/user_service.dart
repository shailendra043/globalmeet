import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user.dart';
import '../models/post.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user stream
  Stream<AppUser?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  // Get user's posts stream
  Stream<List<Post>> getUserPostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Get current user
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromFirestore(doc);
  }

  // Get user by ID
  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    return AppUser.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? profilePicture,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (profilePicture != null) updates['profilePicture'] = profilePicture;

    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    File? profilePicture,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    Map<String, dynamic> updates = {};
    
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    
    if (profilePicture != null) {
      // Upload new profile picture
      final fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(profilePicture);
      final url = await ref.getDownloadURL();
      updates['profilePicture'] = url;
    }

    await userRef.update(updates);
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromUserId, String toUserId, String fromUserName) async {
    final toUserRef = _firestore.collection('users').doc(toUserId);
    final toUserDoc = await toUserRef.get();

    if (!toUserDoc.exists) {
      throw Exception('User not found');
    }

    // Add to pending requests
    await toUserRef.update({
      'pendingFriendRequests': FieldValue.arrayUnion([fromUserId])
    });

    // Send notification
    await _notificationService.sendNotification(
      userId: toUserId,
      title: 'New Friend Request',
      body: '$fromUserName sent you a friend request',
      type: 'friend_request',
      data: {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
      },
    );
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final friendRef = _firestore.collection('users').doc(friendId);
    
    final userDoc = await userRef.get();
    final friendDoc = await friendRef.get();
    
    if (!userDoc.exists || !friendDoc.exists) {
      throw Exception('User or friend not found');
    }

    final user = AppUser.fromFirestore(userDoc);
    final friend = AppUser.fromFirestore(friendDoc);
    
    // Remove from pending requests
    await userRef.update({
      'pendingFriendRequests': FieldValue.arrayRemove([friendId]),
      'friends': FieldValue.arrayUnion([friendId]),
    });
    
    // Add to friend's friends list
    await friendRef.update({
      'friends': FieldValue.arrayUnion([userId]),
    });

    // Send notification to friend
    await _notificationService.sendNotification(
      userId: friendId,
      title: 'Friend Request Accepted',
      body: '${user.name} accepted your friend request',
      type: 'friend_request_accepted',
      data: {
        'userId': userId,
        'userName': user.name,
      },
    );
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String userId, String friendId) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await userRef.update({
      'pendingFriendRequests': FieldValue.arrayRemove([friendId]),
    });
  }

  // Create new user
  Future<void> createUser({
    required String userId,
    required String name,
    required String email,
    String? profilePicture,
  }) async {
    // Create search index by splitting name and email into lowercase words
    final nameWords = name.toLowerCase().split(' ');
    final emailWords = email.toLowerCase().split('@')[0].split('.');
    final searchIndex = <String>{...nameWords, ...emailWords}.toList();

    final user = AppUser(
      id: userId,
      name: name,
      email: email,
      profilePicture: profilePicture ?? '',
      bio: '',
      friends: [],
      posts: [],
      pendingFriendRequests: [],
      searchIndex: searchIndex,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(userId).set(user.toMap());
  }

  // Search users
  Stream<List<AppUser>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  // Update user's search index
  Future<void> updateSearchIndex(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final user = AppUser.fromFirestore(userDoc);
    
    // Create search index by splitting name and email into lowercase words
    final nameWords = user.name.toLowerCase().split(' ');
    final emailWords = user.email.toLowerCase().split('@')[0].split('.');
    
    // Combine all words and remove duplicates
    final searchIndex = <String>{...nameWords, ...emailWords}.toList();

    await userRef.update({'searchIndex': searchIndex});
  }

  // Get pending friend requests
  Stream<List<AppUser>> getPendingFriendRequests(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      final user = AppUser.fromFirestore(userDoc);
      if (user.pendingFriendRequests.isEmpty) return [];

      // Get user details for each pending request
      final userDocs = await Future.wait(
        user.pendingFriendRequests.map((friendId) =>
            _firestore.collection('users').doc(friendId).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    });
  }

  // Get user's friends
  Stream<List<AppUser>> getUserFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      final friendIds = snapshot.docs.map((doc) => doc.id).toList();
      final friends = await Future.wait(
        friendIds.map((id) => getUser(id)),
      );
      return friends.whereType<AppUser>().toList();
    });
  }

  // Add friend
  Future<void> addFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    
    // Add to user's friends
    batch.set(
      _firestore.collection('users').doc(userId).collection('friends').doc(friendId),
      {'addedAt': FieldValue.serverTimestamp()},
    );
    
    // Add to friend's friends
    batch.set(
      _firestore.collection('users').doc(friendId).collection('friends').doc(userId),
      {'addedAt': FieldValue.serverTimestamp()},
    );
    
    await batch.commit();
  }

  // Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    
    // Remove from user's friends
    batch.delete(
      _firestore.collection('users').doc(userId).collection('friends').doc(friendId),
    );
    
    // Remove from friend's friends
    batch.delete(
      _firestore.collection('users').doc(friendId).collection('friends').doc(userId),
    );
    
    await batch.commit();
  }
} 