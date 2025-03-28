import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'dart:io';

class PostProvider with ChangeNotifier {
  final PostService _postService;
  final UserService _userService;
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  PostProvider(this._postService, this._userService);

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
    required String content,
    File? mediaFile,
    MediaType? mediaType,
  }) async {
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }

      await _postService.createPost(
        userId: user.id,
        userName: user.name,
        userProfilePicture: user.profilePicture,
        content: content,
        mediaFile: mediaFile,
        mediaType: mediaType,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleLike(String postId, String userId, String userName) async {
    try {
      await _postService.toggleLike(postId, userId, userName);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> addComment(String postId, Comment comment) async {
    try {
      await _postService.addComment(postId, comment);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 