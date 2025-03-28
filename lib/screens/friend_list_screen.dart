import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'profile_screen.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: context.read<UserService>().getUserFriends(
          context.read<UserService>().getCurrentUser()?.id ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final friends = snapshot.data ?? [];

          if (friends.isEmpty) {
            return const Center(
              child: Text('No friends yet'),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.profilePicture.isNotEmpty
                      ? NetworkImage(friend.profilePicture)
                      : null,
                  child: friend.profilePicture.isEmpty
                      ? Text(friend.name[0].toUpperCase())
                      : null,
                ),
                title: Text(friend.name),
                subtitle: Text(friend.email),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: friend.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 