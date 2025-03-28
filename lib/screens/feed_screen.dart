import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<String> _selectedMediaUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final url = await context.read<PostProvider>().uploadMedia(image.path);
        setState(() {
          _selectedMediaUrls.add(url);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _selectedMediaUrls.isEmpty) {
      return;
    }

    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await context.read<PostProvider>().createPost(
            userId: currentUser.uid,
            userName: currentUser.displayName ?? 'Anonymous',
            userProfilePic: currentUser.photoURL ?? '',
            content: _contentController.text,
            mediaUrls: _selectedMediaUrls,
          );

      _contentController.clear();
      setState(() {
        _selectedMediaUrls.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, _) {
          if (postProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postProvider.error != null) {
            return Center(
              child: Text('Error: ${postProvider.error}'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Implement pull-to-refresh
            },
            child: ListView.builder(
              itemCount: postProvider.posts.length + 1, // +1 for the create post card
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              hintText: 'What\'s on your mind?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          if (_selectedMediaUrls.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedMediaUrls.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.network(
                                          _selectedMediaUrls[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _selectedMediaUrls.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.image),
                                onPressed: _isLoading ? null : _pickImage,
                              ),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _createPost,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Post'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return PostCard(post: postProvider.posts[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
} 