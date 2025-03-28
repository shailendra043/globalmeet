import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void startListening() {
    _postService.getPosts().listen(
      (posts) {
        _posts = posts;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> createPost({
    required String userId,
    required String userName,
    required String userProfilePic,
    required String content,
    required List<String> mediaUrls,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postService.createPost(
        userId: userId,
        userName: userName,
        userProfilePic: userProfilePic,
        content: content,
        mediaUrls: mediaUrls,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      await _postService.toggleLike(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, Comment comment) async {
    try {
      await _postService.addComment(postId, comment);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 