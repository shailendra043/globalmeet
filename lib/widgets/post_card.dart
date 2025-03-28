import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    final isLiked = currentUser != null && post.likedBy.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(post.userProfilePic),
            ),
            title: Text(post.userName),
            subtitle: Text(timeago.format(post.createdAt)),
            trailing: currentUser?.uid == post.userId
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<PostProvider>().deletePost(post.id);
                    },
                  )
                : null,
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(post.content),
          ),
          
          // Media content
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: post.mediaUrls.length,
                itemBuilder: (context, index) {
                  final url = post.mediaUrls[index];
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
          
          // Post actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: currentUser != null
                      ? () {
                          context
                              .read<PostProvider>()
                              .toggleLike(post.id, currentUser.uid);
                        }
                      : null,
                ),
                Text('${post.likedBy.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    // Show comments dialog
                    _showCommentsDialog(context);
                  },
                ),
                Text('${post.comments.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(BuildContext context) {
    final commentController = TextEditingController();
    final currentUser = context.read<AuthProvider>().user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(comment.userName),
                      subtitle: Text(comment.content),
                      trailing: Text(
                        timeago.format(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (commentController.text.isNotEmpty) {
                            final comment = Comment(
                              id: DateTime.now().toString(),
                              userId: currentUser.uid,
                              userName: currentUser.displayName ?? 'Anonymous',
                              content: commentController.text,
                              createdAt: DateTime.now(),
                            );
                            context
                                .read<PostProvider>()
                                .addComment(post.id, comment);
                            commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 