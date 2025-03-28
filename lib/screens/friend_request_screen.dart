import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'profile_screen.dart';

class FriendRequestScreen extends StatelessWidget {
  const FriendRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: context.read<UserService>().getPendingFriendRequests(
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

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('No friend requests'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.profilePicture.isNotEmpty
                      ? NetworkImage(request.profilePicture)
                      : null,
                  child: request.profilePicture.isEmpty
                      ? Text(request.name[0].toUpperCase())
                      : null,
                ),
                title: Text(request.name),
                subtitle: Text(request.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        final userService = context.read<UserService>();
                        final currentUserId = userService.getCurrentUser()?.id ?? '';
                        await userService.acceptFriendRequest(currentUserId, request.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        final userService = context.read<UserService>();
                        final currentUserId = userService.getCurrentUser()?.id ?? '';
                        await userService.rejectFriendRequest(currentUserId, request.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: request.id),
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