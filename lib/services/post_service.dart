import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';
import 'dart:io';
import '../services/notification_service.dart';
import 'package:video_compress/video_compress.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Get posts stream
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Create a new post
  Future<void> createPost({
    required String userId,
    required String userName,
    required String userProfilePicture,
    required String content,
    File? mediaFile,
    MediaType? mediaType,
  }) async {
    String? mediaUrl;
    if (mediaFile != null && mediaType != null) {
      mediaUrl = await _uploadMedia(mediaFile, mediaType);
    }

    final post = Post(
      id: '', // Firestore will generate this
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      likes: [],
      comments: [],
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  // Upload media file
  Future<String> _uploadMedia(File file, MediaType type) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref().child('posts/$fileName');
    
    File fileToUpload = file;
    
    // Compress video if it's a video file
    if (type == MediaType.video) {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      if (mediaInfo?.file != null) {
        fileToUpload = mediaInfo!.file!;
      }
    }
    
    final uploadTask = ref.putFile(fileToUpload);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId, String userId, String userName) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final post = Post.fromFirestore(postDoc);
    final likes = List<String>.from(post.likes);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
      // Send notification to post owner if they're not the one who liked
      if (post.userId != userId) {
        await _notificationService.sendNotification(
          userId: post.userId,
          title: 'New Like',
          body: '$userName liked your post',
          type: 'like',
          data: {'postId': postId},
        );
      }
    }

    await postRef.update({'likes': likes});
  }

  // Add a comment to a post
  Future<void> addComment(String postId, Comment comment) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    
    if (postDoc.exists) {
      final post = Post.fromFirestore(postDoc);
      final comments = List<Comment>.from(post.comments)..add(comment);
      
      await postRef.update({
        'comments': comments.map((comment) => comment.toMap()).toList(),
      });

      // Send notification to post owner
      if (post.userId != comment.userId) {
        await _notificationService.sendNotification(
          userId: post.userId,
          title: 'New Comment',
          body: '${comment.userName} commented on your post',
          type: 'comment',
          data: {
            'postId': postId,
            'commentId': comment.id,
            'userId': comment.userId,
            'userName': comment.userName,
          },
        );
      }
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    
    if (postDoc.exists) {
      final post = Post.fromFirestore(postDoc);
      
      // Delete media file from storage if exists
      if (post.mediaUrl != null) {
        try {
          final ref = _storage.refFromURL(post.mediaUrl!);
          await ref.delete();
        } catch (e) {
          print('Error deleting media file: $e');
        }
      }
      
      // Delete post document
      await postRef.delete();
    }
  }
} 