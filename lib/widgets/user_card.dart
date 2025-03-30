import 'package:flutter/material.dart';
import 'profile_avatar.dart';

class UserCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool isActive;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: imageUrl,
            isActive: isActive,
          ),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 