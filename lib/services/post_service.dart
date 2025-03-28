import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    required String userProfilePic,
    required String content,
    required List<String> mediaUrls,
  }) async {
    final post = Post(
      id: '', // Will be set by Firestore
      userId: userId,
      userName: userName,
      userProfilePic: userProfilePic,
      content: content,
      mediaUrls: mediaUrls,
      likedBy: [],
      comments: [],
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  // Like/Unlike a post
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    
    if (postDoc.exists) {
      final post = Post.fromFirestore(postDoc);
      final likedBy = List<String>.from(post.likedBy);
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await postRef.update({'likedBy': likedBy});
    }
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
    }
  }

  // Upload media file
  Future<String> uploadMedia(String filePath) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('media/$fileName');
    
    final uploadTask = ref.putData(filePath as dynamic);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    
    if (postDoc.exists) {
      final post = Post.fromFirestore(postDoc);
      
      // Delete media files from storage
      for (final mediaUrl in post.mediaUrls) {
        try {
          final ref = _storage.refFromURL(mediaUrl);
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