import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/post_service.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == MediaType.video && widget.post.mediaUrl != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.post.mediaUrl!);
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.userProfilePicture.isNotEmpty
                  ? NetworkImage(widget.post.userProfilePicture)
                  : null,
              child: widget.post.userProfilePicture.isEmpty
                  ? Text(widget.post.userName[0].toUpperCase())
                  : null,
            ),
            title: Text(widget.post.userName),
            subtitle: Text(timeago.format(widget.post.createdAt)),
          ),
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post.content),
            ),
          if (widget.post.mediaUrl != null) ...[
            const SizedBox(height: 8),
            _buildMediaContent(),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    widget.post.likes.contains('currentUserId')
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  color: widget.post.likes.contains('currentUserId')
                      ? Colors.red
                      : Colors.grey,
                  onPressed: () {
                    context.read<PostService>().toggleLike(
                      widget.post.id,
                      'currentUserId',
                      'Current User', // Replace with actual user name
                    );
                  },
                ),
                Text('${widget.post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // TODO: Implement comment functionality
                  },
                ),
                Text('${widget.post.comments.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.mediaType == MediaType.image) {
      return Image.network(
        widget.post.mediaUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else if (widget.post.mediaType == MediaType.video) {
      if (!_isVideoInitialized) {
        return const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 50,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
} 