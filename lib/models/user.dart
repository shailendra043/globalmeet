import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String profilePicture;
  final String bio;
  final List<String> friends;
  final List<String> posts;
  final List<String> pendingFriendRequests;
  final List<String> searchIndex;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.bio,
    required this.friends,
    required this.posts,
    required this.pendingFriendRequests,
    required this.searchIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'friends': friends,
      'posts': posts,
      'pendingFriendRequests': pendingFriendRequests,
      'searchIndex': searchIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      bio: data['bio'] ?? '',
      friends: List<String>.from(data['friends'] ?? []),
      posts: List<String>.from(data['posts'] ?? []),
      pendingFriendRequests: List<String>.from(data['pendingFriendRequests'] ?? []),
      searchIndex: List<String>.from(data['searchIndex'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? profilePicture,
    String? bio,
    List<String>? friends,
    List<String>? posts,
    List<String>? pendingFriendRequests,
    List<String>? searchIndex,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      friends: friends ?? this.friends,
      posts: posts ?? this.posts,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
      searchIndex: searchIndex ?? this.searchIndex,
      createdAt: createdAt,
    );
  }
} 