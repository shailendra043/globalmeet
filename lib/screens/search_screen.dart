import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String currentUserId = 'currentUserId'; // Replace with actual current user ID

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: context.read<UserService>().searchUsers(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!
              .where((user) => user.id != currentUserId)
              .toList();

          if (_searchQuery.isEmpty) {
            return const Center(
              child: Text('Start typing to search for friends'),
            );
          }

          if (users.isEmpty) {
            return Center(
              child: Text('No users found matching "$_searchQuery"'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePicture.isNotEmpty
                      ? NetworkImage(user.profilePicture)
                      : null,
                  child: user.profilePicture.isEmpty
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: StreamBuilder<AppUser?>(
                  stream: context.read<UserService>().getUserStream(currentUserId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox.shrink();
                    
                    final currentUser = userSnapshot.data!;
                    final isFriend = currentUser.friends.contains(user.id);
                    final hasPendingRequest = currentUser.pendingFriendRequests.contains(user.id);

                    if (isFriend) {
                      return const Icon(Icons.check_circle, color: Colors.green);
                    }

                    if (hasPendingRequest) {
                      return const Icon(Icons.pending, color: Colors.orange);
                    }

                    return TextButton(
                      onPressed: () {
                        context.read<UserService>().sendFriendRequest(
                              currentUserId,
                              user.id,
                              currentUser.name,
                            );
                      },
                      child: const Text('Add Friend'),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: user.id),
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