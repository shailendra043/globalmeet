import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isActive;
  final bool hasBorder;
  final double radius;

  const ProfileAvatar({
    Key? key,
    required this.imageUrl,
    this.isActive = false,
    this.hasBorder = false,
    this.radius = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          backgroundImage: NetworkImage(imageUrl),
        ),
        if (isActive)
          Positioned(
            bottom: 0.0,
            right: 0.0,
            child: Container(
              height: 15.0,
              width: 15.0,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (hasBorder)
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.blue.withOpacity(0.3),
            child: CircleAvatar(
              radius: radius - 3,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
      ],
    );
  }
} 